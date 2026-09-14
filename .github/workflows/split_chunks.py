"""Parte la coleccion unificada en lotes de <=CAP llamadas HTTP estimadas.

Cada request cuenta 1 (llamada principal) + sus pm.sendRequest de
pre-request/test scripts (verificacion SQL, fixtures). El sandbox limita a
30 req/min por API key: con lotes de <=28 y pausa de 75s entre lotes, ninguna
ventana deslizante de 60s supera el limite.

Convive con el workflow en .github/workflows/.
Uso: python3 .github/workflows/split_chunks.py [--src ...] [--out ...] [--cap 28]

Ademas inyecta un id estable (g03-0001, ...) en cada request: sin ids la
correlacion lote<->ejecucion y la deduplicacion de reintentos 429 en
merge_results.py serian ambiguas (hay nombres repetidos entre integrantes).
"""

import argparse
import json
import os

DEFAULT_SRC = "postman/Grupo 03 - Pago de Servicios_collection.json"


def calls_of(item):
    """Llamadas HTTP que dispara un request: 1 principal + sub-llamadas."""
    n = 1
    for ev in item.get("event", []):
        for line in ev.get("script", {}).get("exec", []) or []:
            n += line.count("pm.sendRequest")
    return n


def walk_leaves(items):
    for it in items:
        if "item" in it:
            yield from walk_leaves(it["item"])
        else:
            yield it


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=DEFAULT_SRC)
    ap.add_argument("--out", default="newman/chunks")
    ap.add_argument("--partials-dir", default="newman/partials")
    ap.add_argument("--cap", type=int, default=28)
    args = ap.parse_args()

    col = json.load(open(args.src, encoding="utf-8"))
    for i, it in enumerate(walk_leaves(col["item"]), 1):
        it.setdefault("id", f"g03-{i:04d}")
    leaves = [(it, calls_of(it)) for it in walk_leaves(col["item"])]
    total = sum(c for _, c in leaves)
    print(f"requests: {len(leaves)}, llamadas estimadas: {total}, cap/lote: {args.cap}")

    chunks, cur, cur_calls = [], [], 0
    for it, c in leaves:
        if cur and cur_calls + c > args.cap:
            chunks.append((cur, cur_calls))
            cur, cur_calls = [], 0
        cur.append(it)
        cur_calls += c
    if cur:
        chunks.append((cur, cur_calls))

    os.makedirs(args.out, exist_ok=True)
    os.makedirs(args.partials_dir, exist_ok=True)
    n = len(chunks)
    for i, (items, calls) in enumerate(chunks, 1):
        keep = {id(it) for it in items}

        def filt(nodes):
            out = []
            for nd in nodes:
                if "item" in nd:
                    sub = filt(nd["item"])
                    if sub:
                        nd2 = dict(nd)
                        nd2["item"] = sub
                        out.append(nd2)
                elif id(nd) in keep:
                    out.append(nd)
            return out

        chunk = {
            "info": {
                "name": f"{col['info']['name']} - lote {i}/{n}",
                "schema": col["info"]["schema"],
            },
            "item": filt(col["item"]),
        }
        for k in ("event", "variable", "auth"):
            if k in col:
                chunk[k] = col[k]
        fn = os.path.join(args.out, f"chunk-{i:02d}.json")
        json.dump(chunk, open(fn, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        print(f"lote {i}/{n}: {len(items)} requests, ~{calls} llamadas -> {fn}")


if __name__ == "__main__":
    main()
