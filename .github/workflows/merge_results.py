"""Fusiona los JSON parciales de Newman (lotes + reintentos 429) en results.json.

Formato de salida identico al de `newman -r json`: lo que consume
skills/postman-newman-skill/reporter/newman_report.py
(collection.info.name, run.stats, run.timings, run.executions).

Empareja cada parcial con su chunk (results-NN[-rA].json <-> chunk-NN[-rA].json)
y correlaciona executions <-> requests por POSICION con los ids estables
g03-NNNN de split_chunks.py. Ante reintento gana la ULTIMA ejecucion y las
stats se recalculan desde las ejecuciones finales (sin doble conteo).
run.failures queda []: el reporter no lo consume (lee el error de cada
assertion en executions) y asi no sobreviven fallos ya superados.

Convive con el workflow en .github/workflows/.
Uso: python3 .github/workflows/merge_results.py [--partials ...] [--output ...]
"""

import argparse
import glob
import json
import os

DEFAULT_SRC = "postman/Grupo 03 - Pago de Servicios_collection.json"


def walk_leaves(items):
    for it in items:
        if "item" in it:
            yield from walk_leaves(it["item"])
        else:
            yield it


def execution_key(execution, fallback):
    item = execution.get("item", {}) or {}
    return item.get("id") or fallback


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--partials", default="newman/partials/results-*.json")
    ap.add_argument("--chunks-dir", default="newman/chunks")
    ap.add_argument("--src", default=DEFAULT_SRC)
    ap.add_argument("--output", default="newman/results.json")
    args = ap.parse_args()

    def sort_key(f):
        # results-01.json < results-01-r2.json < results-01-r3.json < results-02.json:
        # el parcial base siempre antes que sus reintentos (gana la ultima).
        # OJO: sort() plano ordenaria '-r2' antes que '.json' ('-' < '.').
        tag = os.path.basename(f)[len("results-"):-len(".json")]
        if "-r" in tag:
            base, _, r = tag.rpartition("-r")
            return (base, int(r) if r.isdigit() else 99)
        return (tag, 0)

    files = sorted(glob.glob(args.partials), key=sort_key)
    if not files:
        raise SystemExit("ERROR: sin parciales (todos los lotes fallaron antes de exportar)")
    print(f"fusionando {len(files)} parciales")

    merged = {}  # uid -> execution (gana la ultima)
    order = []
    retries_used = 0
    duration = 0
    for f in files:
        tag = os.path.basename(f)[len("results-"):-len(".json")]  # NN o NN-rA
        chunk_fn = os.path.join(args.chunks_dir, f"chunk-{tag}.json")
        chunk_uids = None
        if os.path.exists(chunk_fn):
            chunk_uids = [leaf.get("id") for leaf in
                          walk_leaves(json.load(open(chunk_fn, encoding="utf-8")).get("item", []))]
        else:
            print(f"WARN: sin chunk para {f}; correlacion por id/nombre")
        if "-r" in tag:
            retries_used += 1
        run = json.load(open(f, encoding="utf-8")).get("run", {})
        executions = run.get("executions", [])
        if chunk_uids is not None and len(chunk_uids) != len(executions):
            print(f"WARN: executions ({len(executions)}) != requests ({len(chunk_uids)}) en {f}")
            chunk_uids = None
        for pos, ex in enumerate(executions):
            if chunk_uids is not None:
                uid = chunk_uids[pos]
                item_id = (ex.get("item", {}) or {}).get("id")
                if item_id and item_id != uid:
                    print(f"WARN: id newman ({item_id}) != id chunk ({uid}) en {f} pos {pos}")
            else:
                uid = execution_key(ex, f"{ex.get('item', {}).get('name', '?')}#{pos}")
            if uid not in merged:
                order.append(uid)
            merged[uid] = ex
        t = run.get("timings", {})
        duration += max(0, t.get("completed", 0) - t.get("started", 0))

    final = [merged[uid] for uid in order]
    total_a = failed_a = failed_r = 0
    for ex in final:
        asserts = ex.get("assertions", []) or []
        total_a += len(asserts)
        errs = sum(1 for a in asserts if a.get("error"))
        failed_a += errs
        if errs or not ex.get("response"):
            failed_r += 1
    stats = {
        "requests": {"total": len(final), "pending": 0, "failed": failed_r},
        "assertions": {"total": total_a, "pending": 0, "failed": failed_a},
    }

    orig = json.load(open(args.src, encoding="utf-8"))
    merged_doc = {
        "collection": orig,
        "run": {
            "stats": stats,
            "timings": {"started": 0, "completed": duration},
            "executions": final,
            "failures": [],
        },
    }
    json.dump(merged_doc, open(args.output, "w", encoding="utf-8"), ensure_ascii=False)
    print(
        f"requests finales: {len(final)}, assertions: {total_a} (fallidas: {failed_a}), "
        f"reintentos usados: {retries_used}, duracion API acumulada: {duration} ms -> {args.output}"
    )


if __name__ == "__main__":
    main()
