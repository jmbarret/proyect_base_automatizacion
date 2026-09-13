"""Fusiona los JSON parciales de Newman (uno por lote) en un unico results.json.

Formato de salida identico al de `newman -r json`: lo que consume
skills/postman-newman-skill/reporter/newman_report.py
(collection.info.name, run.stats, run.timings, run.executions, run.failures).

Destino en repo: .github/scripts/grupo03/merge_results.py
Uso: python3 .github/scripts/grupo03/merge_results.py [--partials ...] [--output ...]
"""

import argparse
import glob
import json

DEFAULT_SRC = "postman/Grupo 03 - Pago de Servicios_collection.json"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--partials", default="newman/partials/results-*.json")
    ap.add_argument("--src", default=DEFAULT_SRC)
    ap.add_argument("--output", default="newman/results.json")
    args = ap.parse_args()

    files = sorted(glob.glob(args.partials))
    if not files:
        raise SystemExit("ERROR: sin parciales (todos los lotes fallaron antes de exportar)")
    print(f"fusionando {len(files)} parciales")

    executions, failures, stats = [], [], {}
    duration = 0
    for f in files:
        run = json.load(open(f, encoding="utf-8")).get("run", {})
        executions += run.get("executions", [])
        failures += run.get("failures", [])
        for k, v in run.get("stats", {}).items():
            s = stats.setdefault(k, {"total": 0, "pending": 0, "failed": 0})
            for fld in ("total", "pending", "failed"):
                s[fld] += v.get(fld, 0)
        t = run.get("timings", {})
        duration += max(0, t.get("completed", 0) - t.get("started", 0))

    orig = json.load(open(args.src, encoding="utf-8"))
    merged = {
        "collection": orig,
        "run": {
            "stats": stats,
            "timings": {"started": 0, "completed": duration},
            "executions": executions,
            "failures": failures,
        },
    }
    json.dump(merged, open(args.output, "w", encoding="utf-8"), ensure_ascii=False)
    a = stats.get("assertions", {})
    print(
        f"requests: {stats.get('requests', {}).get('total', 0)}, "
        f"assertions: {a.get('total', 0)} (fallidas: {a.get('failed', 0)}), "
        f"duracion API acumulada: {duration} ms -> {args.output}"
    )


if __name__ == "__main__":
    main()
