"""Reintento ante HTTP 429 para la regresion por lotes (colapso entre grupos).

Lo invoca el workflow, no a mano:
  python3 retry_429.py plan --results newman/partials/results-01.json
      --chunk newman/chunks/chunk-01.json --attempt 1
      --build-out newman/chunks/chunk-01-r2.json

- Reintentable = respuesta ausente (fallo de red) o codigo 429. Otros 4xx/5xx
  son resultado deterministico de casos negativos: no se reintentan.
- Correlacion parcial<->chunk por POSICION (newman ejecuta secuencial 1:1) con
  los ids estables g03-NNNN de split_chunks.py como clave.
- La espera respeta el header Retry-After (si viene): max(75, ra+10), tope 180.
  Piso 75s para vaciar la ventana deslizante de 30 req/min.
- Exit 2 = hay reintento (imprime RETRY_WAIT/RETRY_COUNT); 0 = nada que
  reintentar (limpio, intentos agotados o datos inconsistentes).
"""

import argparse
import json
import sys

BASE_WAIT = 75
MAX_WAIT = 180


def walk_leaves(items):
    for it in items:
        if "item" in it:
            yield from walk_leaves(it["item"])
        else:
            yield it


def code_of(execution):
    resp = execution.get("response") or {}
    return resp.get("code")


def retry_after_of(execution):
    resp = execution.get("response") or {}
    for h in resp.get("header", []) or []:
        if str(h.get("key", "")).lower() == "retry-after":
            try:
                return int(str(h.get("value", "")).strip())
            except (ValueError, TypeError):
                return None
    return None


def cmd_plan(args):
    try:
        partial = json.load(open(args.results, encoding="utf-8"))
        chunk = json.load(open(args.chunk, encoding="utf-8"))
    except (OSError, ValueError) as e:
        print(f"WARN: no se pudo leer parcial/chunk ({e}); sin reintento")
        return 0
    executions = partial.get("run", {}).get("executions", [])
    leaves = list(walk_leaves(chunk.get("item", [])))
    if len(executions) != len(leaves):
        print(f"WARN: executions ({len(executions)}) != requests ({len(leaves)}); sin reintento")
        return 0
    if any(not leaf.get("id") for leaf in leaves):
        print("WARN: chunk sin ids estables; sin reintento")
        return 0

    targets = []
    for pos, ex in enumerate(executions):
        code = code_of(ex)
        if code is None or code == 429:
            targets.append((pos, leaves[pos]["id"], code))
    if not targets:
        print("COUNT=0 (sin 429 ni fallos de red)")
        return 0
    if args.attempt >= args.max_attempts:
        print(f"COUNT={len(targets)} (intentos agotados: quedan como fallo)")
        return 0

    waits = [retry_after_of(executions[p]) for p, _, _ in targets]
    waits = [w for w in waits if w is not None]
    wait = min(max(BASE_WAIT, (max(waits) + 10) if waits else BASE_WAIT), MAX_WAIT)

    keep = {uid for _, uid, _ in targets}

    def filt(nodes):
        out = []
        for nd in nodes:
            if "item" in nd:
                sub = filt(nd["item"])
                if sub:
                    nd2 = dict(nd)
                    nd2["item"] = sub
                    out.append(nd2)
            elif nd.get("id") in keep:
                out.append(nd)
        return out

    retry = {
        "info": {
            "name": f"{chunk['info']['name']} (reintento {args.attempt + 1})",
            "schema": chunk["info"]["schema"],
        },
        "item": filt(chunk["item"]),
    }
    for k in ("event", "variable", "auth"):
        if k in chunk:
            retry[k] = chunk[k]
    json.dump(retry, open(args.build_out, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    kinds = {}
    for _, _, code in targets:
        kinds[code] = kinds.get(code, 0) + 1
    print(f"RETRY_WAIT={wait} RETRY_COUNT={len(targets)}")
    print(f"detalle 429/red: {kinds} -> {args.build_out}")
    return 2


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("plan")
    p.add_argument("--results", required=True)
    p.add_argument("--chunk", required=True)
    p.add_argument("--attempt", type=int, required=True)
    p.add_argument("--max-attempts", type=int, default=3)
    p.add_argument("--build-out", required=True)
    args = ap.parse_args()
    if args.cmd == "plan":
        sys.exit(cmd_plan(args))


if __name__ == "__main__":
    main()
