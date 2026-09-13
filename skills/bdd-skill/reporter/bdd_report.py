"""
bdd_report.py v1 — Generador de reporte PDF para resultados de Cucumber (.json)
Powered by skill bdd · aiquaa.com

Uso:
    python bdd_report.py --results results/cucumber-report.json
    python bdd_report.py --results results/cucumber-report.json \\
        --output INFORME_BDD_GRUPO_03.pdf \\
        --grupo "Grupo 3 — Pagos de Servicios" \\
        --author "Juan Pérez — juan@empresa.com" \\
        --repo-url "https://github.com/org/repo"

Entrada: el JSON formatter nativo de cucumber-js
  (cucumber.js → format: ['json:results/cucumber-report.json']).
Extrae: features, escenarios, pasos, duración, y comentarios "# criterio: <texto>"
sobre cada Scenario para armar la matriz de trazabilidad.
"""

import argparse
import json
import os
import re
from datetime import datetime

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    HRFlowable, KeepTogether, PageBreak, Paragraph,
    SimpleDocTemplate, Spacer, Table, TableStyle,
)

# ─── Paleta (misma familia que jmeter_report.py / playwright_report.py) ──────
BLACK       = colors.HexColor("#000000")
WHITE       = colors.HexColor("#FFFFFF")
NAVY        = colors.HexColor("#0D1B40")
GRAY_DARK   = colors.HexColor("#1A1A1A")
GRAY_MID    = colors.HexColor("#4A4A4A")
GRAY_LIGHT  = colors.HexColor("#F5F5F5")
GRAY_BORDER = colors.HexColor("#DDDDDD")
GREEN_PASS  = colors.HexColor("#16A34A")
RED_FAIL    = colors.HexColor("#DC2626")
AMBER_WARN  = colors.HexColor("#D97706")
BLUE_INFO   = colors.HexColor("#2563EB")
GREEN_BG    = colors.HexColor("#F0FDF4")
RED_BG      = colors.HexColor("#FEF2F2")
AMBER_BG    = colors.HexColor("#FFFBEB")

PAGE_W, PAGE_H = A4
MARGIN = 18 * mm

STATUS_COLOR = {
    "passed": GREEN_PASS,
    "failed": RED_FAIL,
    "pending": AMBER_WARN,
    "undefined": AMBER_WARN,
    "skipped": GRAY_MID,
}
STATUS_ICON = {
    "passed": "PASS",
    "failed": "FAIL",
    "pending": "PEND",
    "undefined": "UNDEF",
    "skipped": "SKIP",
}


def styles():
    return {
        "title": ParagraphStyle("title", fontName="Helvetica-Bold", fontSize=24,
                                 textColor=WHITE, alignment=TA_CENTER, leading=28),
        "subtitle": ParagraphStyle("subtitle", fontName="Helvetica", fontSize=12,
                                    textColor=WHITE, alignment=TA_CENTER, leading=16),
        "h1": ParagraphStyle("h1", fontName="Helvetica-Bold", fontSize=15,
                              textColor=NAVY, spaceBefore=14, spaceAfter=6),
        "h2": ParagraphStyle("h2", fontName="Helvetica-Bold", fontSize=11,
                              textColor=GRAY_DARK, spaceBefore=8, spaceAfter=4),
        "body": ParagraphStyle("body", fontName="Helvetica", fontSize=9.5,
                                textColor=GRAY_DARK, leading=13, alignment=TA_LEFT),
        "small": ParagraphStyle("small", fontName="Helvetica", fontSize=8,
                                 textColor=GRAY_MID, leading=11),
        "mono": ParagraphStyle("mono", fontName="Courier", fontSize=8,
                                textColor=GRAY_DARK, leading=11),
    }


def parse_results(path):
    with open(path, "r", encoding="utf-8") as f:
        raw = json.load(f)

    features = []
    totals = {"scenarios": 0, "passed": 0, "failed": 0, "pending": 0, "undefined": 0, "skipped": 0}
    trace = []  # (criterio, feature, escenario, status)

    for feat in raw:
        feat_name = feat.get("name", "(sin nombre)")
        feat_scenarios = []
        for el in feat.get("elements", []):
            if el.get("type") != "scenario":
                continue
            steps = el.get("steps", [])
            statuses = [s.get("result", {}).get("status", "skipped") for s in steps]
            if "failed" in statuses:
                status = "failed"
            elif "undefined" in statuses:
                status = "undefined"
            elif "pending" in statuses:
                status = "pending"
            elif all(s == "skipped" for s in statuses):
                status = "skipped"
            else:
                status = "passed"

            totals["scenarios"] += 1
            totals[status] = totals.get(status, 0) + 1

            failed_step = next((s for s in steps if s.get("result", {}).get("status") == "failed"), None)
            criterio = None
            for comment in el.get("comments", []) or []:
                m = re.search(r"criterio:\s*(.+)", comment.get("text", ""))
                if m:
                    criterio = m.group(1).strip()

            feat_scenarios.append({
                "name": el.get("name", "(sin nombre)"),
                "status": status,
                "tags": [t.get("name") for t in el.get("tags", [])],
                "criterio": criterio,
                "fail_step": failed_step.get("name") if failed_step else None,
                "fail_msg": (failed_step.get("result", {}).get("error_message", "") or "")[:400]
                            if failed_step else None,
            })
            trace.append((criterio or "(sin criterio documentado)", feat_name,
                           el.get("name", ""), status))

        features.append({"name": feat_name, "scenarios": feat_scenarios})

    return features, totals, trace


def veredicto(totals):
    if totals["failed"] > 0:
        return "CRITERIOS NO CUMPLIDOS", RED_FAIL, RED_BG
    if totals["undefined"] > 0 or totals["pending"] > 0:
        return "PARCIAL — HAY PASOS SIN IMPLEMENTAR", AMBER_WARN, AMBER_BG
    return "CRITERIOS CUMPLIDOS", GREEN_PASS, GREEN_BG


def build_pdf(output, features, totals, trace, args):
    st = styles()
    doc = SimpleDocTemplate(output, pagesize=A4,
                             topMargin=MARGIN, bottomMargin=MARGIN,
                             leftMargin=MARGIN, rightMargin=MARGIN)
    story = []

    # ── Portada ──
    cover = Table([[Paragraph("INFORME DE PRUEBAS BDD", st["title"])],
                    [Spacer(1, 4)],
                    [Paragraph(args.grupo or "Sin grupo especificado", st["subtitle"])]],
                   colWidths=[PAGE_W - 2 * MARGIN])
    cover.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), NAVY),
        ("TOPPADDING", (0, 0), (-1, -1), 22),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 22),
    ]))
    story.append(cover)
    story.append(Spacer(1, 10 * mm))

    meta_rows = [
        ["Fecha", datetime.now().strftime("%Y-%m-%d %H:%M")],
        ["Autor", args.author or "no proporcionado"],
        ["Repositorio", args.repo_url or "no proporcionado"],
        ["Escenarios", str(totals["scenarios"])],
    ]
    meta = Table(meta_rows, colWidths=[45 * mm, (PAGE_W - 2 * MARGIN - 45 * mm)])
    meta.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9.5),
        ("TEXTCOLOR", (0, 0), (-1, -1), GRAY_DARK),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LINEBELOW", (0, 0), (-1, -1), 0.4, GRAY_BORDER),
    ]))
    story.append(meta)
    story.append(Spacer(1, 8 * mm))

    # ── Resumen ──
    story.append(Paragraph("Resumen", st["h1"]))
    resumen_rows = [["Estado", "Cantidad"]]
    for key in ("passed", "failed", "undefined", "pending", "skipped"):
        if totals.get(key):
            resumen_rows.append([STATUS_ICON[key], str(totals[key])])
    resumen = Table(resumen_rows, colWidths=[60 * mm, 30 * mm])
    resumen.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), GRAY_LIGHT),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9.5),
        ("GRID", (0, 0), (-1, -1), 0.4, GRAY_BORDER),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.append(resumen)

    # ── Veredicto ──
    texto, color, bg = veredicto(totals)
    story.append(Spacer(1, 6 * mm))
    v = Table([[Paragraph(f"VEREDICTO: {texto}", ParagraphStyle(
        "v", fontName="Helvetica-Bold", fontSize=12, textColor=color, alignment=TA_CENTER))]],
        colWidths=[PAGE_W - 2 * MARGIN])
    v.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), bg),
                            ("TOPPADDING", (0, 0), (-1, -1), 10),
                            ("BOTTOMPADDING", (0, 0), (-1, -1), 10)]))
    story.append(v)

    # ── Matriz de trazabilidad ──
    story.append(PageBreak())
    story.append(Paragraph("Matriz de trazabilidad", st["h1"]))
    story.append(Paragraph(
        "Criterio de aceptación → escenario → resultado. Los criterios se toman de comentarios "
        '"# criterio: &lt;texto&gt;" sobre cada Scenario en el .feature.', st["small"]))
    story.append(Spacer(1, 3 * mm))
    trace_rows = [["Criterio", "Escenario", "Resultado"]]
    for criterio, feat_name, scen_name, status in trace:
        trace_rows.append([
            Paragraph(criterio, st["body"]),
            Paragraph(scen_name, st["body"]),
            Paragraph(STATUS_ICON.get(status, status), ParagraphStyle(
                "s", fontName="Helvetica-Bold", fontSize=9, textColor=STATUS_COLOR.get(status, GRAY_MID))),
        ])
    trace_table = Table(trace_rows, colWidths=[70 * mm, 70 * mm, 24 * mm], repeatRows=1)
    trace_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), GRAY_LIGHT),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.4, GRAY_BORDER),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.append(trace_table)

    # ── Detalle por feature ──
    for feat in features:
        story.append(PageBreak())
        story.append(Paragraph(feat["name"], st["h1"]))
        for scen in feat["scenarios"]:
            color = STATUS_COLOR.get(scen["status"], GRAY_MID)
            block = [Paragraph(
                f'[{STATUS_ICON.get(scen["status"], scen["status"])}] {scen["name"]}',
                ParagraphStyle("sc", fontName="Helvetica-Bold", fontSize=10, textColor=color))]
            if scen["tags"]:
                block.append(Paragraph(" ".join(scen["tags"]), st["small"]))
            if scen["fail_step"]:
                block.append(Paragraph(f'Paso fallido: {scen["fail_step"]}', st["h2"]))
                block.append(Paragraph(scen["fail_msg"] or "", st["mono"]))
            story.append(KeepTogether(block))
            story.append(Spacer(1, 3 * mm))

    doc.build(story)


def main():
    p = argparse.ArgumentParser(description="Genera INFORME_BDD_*.pdf desde el JSON de cucumber-js")
    p.add_argument("--results", required=True, help="Path al JSON de cucumber (format json:...)")
    p.add_argument("--output", default=None, help="Path del PDF de salida")
    p.add_argument("--grupo", default=None, help='Ej: "Grupo 3 — Pagos de Servicios"')
    p.add_argument("--author", default=None)
    p.add_argument("--repo-url", default=None)
    args = p.parse_args()

    if not os.path.exists(args.results):
        raise SystemExit(f"No se encontró {args.results}")

    output = args.output
    if not output:
        base = re.sub(r"[^A-Za-z0-9_]+", "_", (args.grupo or "BDD")).upper()
        output = f"INFORME_BDD_{base}.pdf"

    features, totals, trace = parse_results(args.results)
    build_pdf(output, features, totals, trace, args)
    print(f"Generado: {output}")
    print(f"Escenarios: {totals['scenarios']} — "
          f"passed={totals.get('passed',0)} failed={totals.get('failed',0)} "
          f"undefined={totals.get('undefined',0)} pending={totals.get('pending',0)}")


if __name__ == "__main__":
    main()
