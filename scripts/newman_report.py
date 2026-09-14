import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


def parse_args():
    parser = argparse.ArgumentParser(description="Genera un informe PDF desde Newman JSON")
    parser.add_argument("--results", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--repository", default="")
    parser.add_argument("--commit", default="")
    parser.add_argument("--actor", default="")
    parser.add_argument("--run-url", default="")
    return parser.parse_args()


def load_results(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"run": {"stats": {}, "executions": [], "failures": []}}


def value(stats, key):
    item = stats.get(key, {})
    return f"{item.get('total', 0)} / {item.get('failed', 0)}"


def configure_fonts(styles):
    candidates = [
        ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
        ("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/arialbd.ttf"),
    ]
    regular = "Helvetica"
    bold = "Helvetica-Bold"
    for regular_path, bold_path in candidates:
        if Path(regular_path).exists() and Path(bold_path).exists():
            pdfmetrics.registerFont(TTFont("ReportRegular", regular_path))
            pdfmetrics.registerFont(TTFont("ReportBold", bold_path))
            regular, bold = "ReportRegular", "ReportBold"
            break
    for style_name in ("Normal", "Title", "Heading1", "Heading2", "Heading3"):
        styles[style_name].fontName = bold if style_name != "Normal" else regular
    return regular, bold


def main():
    args = parse_args()
    data = load_results(args.results)
    run = data.get("run", {})
    stats = run.get("stats", {})
    executions = run.get("executions", [])
    failures = run.get("failures", [])

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    styles = getSampleStyleSheet()
    regular_font, bold_font = configure_fonts(styles)
    doc = SimpleDocTemplate(
        str(output), pagesize=A4, rightMargin=16 * mm, leftMargin=16 * mm,
        topMargin=16 * mm, bottomMargin=16 * mm,
        title="Informe de pruebas Postman - Grupo 04",
    )
    story = [
        Paragraph("Informe de pruebas automatizadas - Grupo 04 Onboarding", styles["Title"]),
        Spacer(1, 5 * mm),
        Paragraph(
            f"Generado: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}",
            styles["Normal"],
        ),
        Paragraph(f"Repositorio: {args.repository or 'No informado'}", styles["Normal"]),
        Paragraph(f"Commit: {args.commit or 'No informado'}", styles["Normal"]),
        Paragraph(f"Ejecutado por: {args.actor or 'No informado'}", styles["Normal"]),
        Paragraph(f"Workflow: {args.run_url or 'No informado'}", styles["Normal"]),
        Spacer(1, 6 * mm),
        Paragraph("Resumen", styles["Heading2"]),
    ]

    summary = Table([
        ["Métrica", "Total / fallidas"],
        ["Iteraciones", value(stats, "iterations")],
        ["Solicitudes", value(stats, "requests")],
        ["Scripts", value(stats, "testScripts")],
        ["Aserciones", value(stats, "assertions")],
    ], colWidths=[85 * mm, 70 * mm])
    summary.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F4E78")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("FONTNAME", (0, 0), (-1, 0), bold_font),
        ("FONTNAME", (0, 1), (-1, -1), regular_font),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#EEF3F8")]),
    ]))
    story.extend([summary, Spacer(1, 6 * mm), Paragraph("Solicitudes ejecutadas", styles["Heading2"])])

    rows = [["Método", "Solicitud", "Estado", "Tiempo (ms)"]]
    for execution in executions:
        request = execution.get("request", {})
        response = execution.get("response") or {}
        rows.append([
            request.get("method", ""),
            execution.get("item", {}).get("name", ""),
            str(response.get("code", "sin respuesta")),
            str(response.get("responseTime", "")),
        ])
    if len(rows) == 1:
        rows.append(["-", "No hubo ejecuciones registradas", "-", "-"])

    details = Table(rows, repeatRows=1, colWidths=[22 * mm, 86 * mm, 25 * mm, 28 * mm])
    details.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F4E78")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), bold_font),
        ("FONTNAME", (0, 1), (-1, -1), regular_font),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.grey),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    story.extend([details, Spacer(1, 6 * mm), Paragraph("Resultado", styles["Heading2"])])
    if not executions:
        result = "SIN RESULTADOS: Newman no registró ejecuciones; revisar el log del workflow."
    elif failures:
        result = f"FALLIDO: {len(failures)} fallo(s)."
    else:
        result = "APROBADO: no se registraron fallos."
    story.append(Paragraph(result, styles["Heading3"]))
    for failure in failures[:20]:
        source = failure.get("source", {})
        story.append(Paragraph(
            f"- {source.get('name', 'Prueba')}: {failure.get('error', {}).get('message', 'Error sin detalle')}",
            styles["Normal"],
        ))
    doc.build(story)


if __name__ == "__main__":
    main()
