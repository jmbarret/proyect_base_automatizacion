"""
newman_report.py v2 — Generador de reporte PDF para resultados de Newman
Logos: Postman (izquierda) + aiquaa circular azul marino (derecha)
Footer: "Powered by skill postman-newman · https://aiquaa.com/"

Uso:
    python newman_report.py --results results/output.json
    python newman_report.py --results results/output.json --output INFORME_DE_AUT_MYTHS_API.pdf
    python newman_report.py --results results/output.json \\
        --logo-aiquaa logo_aiquaa_circle.png \\
        --logo-postman logo_postman_clean.png
"""

import json
import argparse
import os
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether, Image, PageBreak
)

# ─── Paleta ───────────────────────────────────────────────────────────────────
BLACK        = colors.HexColor("#000000")
WHITE        = colors.HexColor("#FFFFFF")
NAVY         = colors.HexColor("#0D1B40")
POSTMAN_ORG  = colors.HexColor("#FF6C37")
GRAY_DARK    = colors.HexColor("#1A1A1A")
GRAY_MID     = colors.HexColor("#4A4A4A")
GRAY_LIGHT   = colors.HexColor("#F5F5F5")
GRAY_BORDER  = colors.HexColor("#DDDDDD")
GREEN_PASS   = colors.HexColor("#16A34A")
RED_FAIL     = colors.HexColor("#DC2626")
YELLOW_SKIP  = colors.HexColor("#D97706")
GREEN_BG     = colors.HexColor("#F0FDF4")
RED_BG       = colors.HexColor("#FEF2F2")

METHOD_COLORS = {
    "GET":    colors.HexColor("#2563EB"),
    "POST":   colors.HexColor("#16A34A"),
    "PUT":    colors.HexColor("#D97706"),
    "PATCH":  colors.HexColor("#7C3AED"),
    "DELETE": colors.HexColor("#DC2626"),
}

PAGE_W, PAGE_H = A4
MARGIN = 18 * mm
HEADER_H = 16 * mm   # altura reservada para el header
FOOTER_H = 14 * mm


# ─── Estilos ──────────────────────────────────────────────────────────────────
def build_styles():
    return {
        "title": ParagraphStyle("title",
            fontName="Helvetica-Bold", fontSize=22,
            textColor=GRAY_DARK, leading=28),
        "subtitle": ParagraphStyle("subtitle",
            fontName="Helvetica", fontSize=11,
            textColor=GRAY_MID, leading=16),
        "section": ParagraphStyle("section",
            fontName="Helvetica-Bold", fontSize=13,
            textColor=GRAY_DARK, leading=18, spaceBefore=10),
        "req_name": ParagraphStyle("req_name",
            fontName="Helvetica-Bold", fontSize=11,
            textColor=GRAY_DARK, leading=15),
        "label": ParagraphStyle("label",
            fontName="Helvetica-Bold", fontSize=8,
            textColor=GRAY_MID, leading=11, spaceAfter=2, spaceBefore=6),
        "url": ParagraphStyle("url",
            fontName="Courier", fontSize=9,
            textColor=GRAY_MID, leading=12),
        "body": ParagraphStyle("body",
            fontName="Courier", fontSize=8,
            textColor=GRAY_DARK, leading=11,
            backColor=GRAY_LIGHT, leftIndent=6, rightIndent=6),
        "test_pass": ParagraphStyle("test_pass",
            fontName="Helvetica", fontSize=9,
            textColor=GREEN_PASS, leading=13),
        "test_fail": ParagraphStyle("test_fail",
            fontName="Helvetica", fontSize=9,
            textColor=RED_FAIL, leading=13),
        "stat_num": ParagraphStyle("stat_num",
            fontName="Helvetica-Bold", fontSize=20,
            textColor=GRAY_DARK, leading=24, alignment=TA_CENTER),
        "stat_label": ParagraphStyle("stat_label",
            fontName="Helvetica", fontSize=9,
            textColor=GRAY_MID, leading=12, alignment=TA_CENTER),
        "footer_link": ParagraphStyle("footer_link",
            fontName="Helvetica", fontSize=8,
            textColor=NAVY, alignment=TA_CENTER),
        "cover_meta_key": ParagraphStyle("cover_meta_key",
            fontName="Helvetica-Bold", fontSize=9,
            textColor=GRAY_MID, leading=14),
        "cover_meta_val": ParagraphStyle("cover_meta_val",
            fontName="Helvetica", fontSize=10,
            textColor=GRAY_DARK, leading=14),
    }


# ─── Helpers ──────────────────────────────────────────────────────────────────
def method_pill(method):
    col = METHOD_COLORS.get(method.upper(), GRAY_MID)
    return Table(
        [[Paragraph(
            f'<font color="white"><b>{method.upper()}</b></font>',
            ParagraphStyle("m", fontName="Helvetica-Bold", fontSize=8,
                           textColor=WHITE, alignment=TA_CENTER)
        )]],
        colWidths=[14*mm],
        style=TableStyle([
            ("BACKGROUND",    (0,0), (-1,-1), col),
            ("TOPPADDING",    (0,0), (-1,-1), 2),
            ("BOTTOMPADDING", (0,0), (-1,-1), 2),
            ("LEFTPADDING",   (0,0), (-1,-1), 4),
            ("RIGHTPADDING",  (0,0), (-1,-1), 4),
        ])
    )


def status_info(passed, failed):
    if failed > 0:
        return "FALLIDO", RED_FAIL, RED_BG
    elif passed > 0:
        return "APROBADO", GREEN_PASS, GREEN_BG
    else:
        return "OMITIDO", YELLOW_SKIP, GRAY_LIGHT


def truncate_body(text, max_chars=600):
    if len(text) <= max_chars:
        return text
    return text[:max_chars] + f"\n... [{len(text)-max_chars} caracteres omitidos]"


def deep_parse_json(value):
    """Parsea recursivamente strings que a su vez son JSON (comun en
    campos tipo error.details que la API serializa como string escapado)
    para que salgan indentados en vez de una sola linea con \\n literales."""
    if isinstance(value, str):
        s = value.strip()
        if s[:1] in ("{", "["):
            try:
                return deep_parse_json(json.loads(s))
            except Exception:
                pass
        return value
    if isinstance(value, dict):
        return {k: deep_parse_json(v) for k, v in value.items()}
    if isinstance(value, list):
        return [deep_parse_json(v) for v in value]
    return value


def safe_json(raw):
    try:
        return json.dumps(deep_parse_json(json.loads(raw)), indent=2, ensure_ascii=False)
    except Exception:
        return raw


def build_url(url_obj):
    """Reconstruye la URL completa. El export json de Newman no siempre
    trae url.raw -- solo protocol/host[]/path[]/query[] sueltos."""
    if not url_obj:
        return ""
    if not isinstance(url_obj, dict):
        return str(url_obj)
    if url_obj.get("raw"):
        return url_obj["raw"]

    protocol = url_obj.get("protocol", "")
    host = ".".join(str(h) for h in url_obj.get("host", []))
    path = "/".join(str(p) for p in url_obj.get("path", []))

    url = f"{protocol}://{host}" if protocol and host else host
    if path:
        url += f"/{path}"

    query = [q for q in url_obj.get("query", []) if not q.get("disabled")]
    if query:
        qs = "&".join(f"{q.get('key', '')}={q.get('value', '')}" for q in query)
        url += f"?{qs}"

    return url


# ─── Parser Newman ────────────────────────────────────────────────────────────
def parse_newman_results(data):
    run  = data.get("run", {})
    info = data.get("collection", {}).get("info", {})
    stats   = run.get("stats", {})
    timings = run.get("timings", {})

    total_assert  = stats.get("assertions", {}).get("total", 0)
    failed_assert = stats.get("assertions", {}).get("failed", 0)
    now = datetime.now()

    summary = {
        "collection_name": info.get("name", "N/A"),
        "total_requests":  stats.get("requests", {}).get("total", 0),
        "total_tests":     total_assert,
        "failed_tests":    failed_assert,
        "passed_tests":    total_assert - failed_assert,
        "duration_ms":     timings.get("completed", 0) - timings.get("started", 0),
        "fecha":           now.strftime("%d/%m/%Y"),
        "hora":            now.strftime("%H:%M:%S"),
    }

    executions = []
    for ex in run.get("executions", []):
        item    = ex.get("item", {})
        req     = ex.get("request", {})
        resp    = ex.get("response", {})
        asserts = ex.get("assertions", [])

        url = build_url(req.get("url", {}))

        resp_body = ""
        if resp:
            raw = resp.get("body", "") or resp.get("stream", {})
            if isinstance(raw, dict):
                raw = raw.get("data", b"")
            if isinstance(raw, list):
                raw = bytes(raw)
            if isinstance(raw, (bytes, bytearray)):
                try:
                    raw = raw.decode("utf-8")
                except Exception:
                    raw = str(raw)
            resp_body = safe_json(str(raw)) if raw else ""

        tests = []
        for a in asserts:
            err = a.get("error")
            tests.append({
                "name":   a.get("assertion", ""),
                "passed": err is None,
                "error":  str(err.get("message", "")) if err else "",
            })

        executions.append({
            "name":        item.get("name", "Unnamed"),
            "method":      req.get("method", "GET"),
            "url":         url,
            "status_code": resp.get("code", 0) if resp else 0,
            "resp_time":   resp.get("responseTime", 0) if resp else 0,
            "resp_body":   resp_body,
            "tests":       tests,
        })

    return summary, executions


# ─── Header / Footer ──────────────────────────────────────────────────────────
class ReportCanvas:
    def __init__(self, logo_postman, logo_aiquaa, author=None):
        self.logo_postman = logo_postman
        self.logo_aiquaa  = logo_aiquaa
        self.author       = author

    def __call__(self, canvas, doc):
        canvas.saveState()
        w, h = A4

        # ── Header ──────────────────────────────────────────────────────────
        # Línea divisoria
        canvas.setStrokeColor(GRAY_BORDER)
        canvas.setLineWidth(0.5)
        canvas.line(MARGIN, h - HEADER_H, w - MARGIN, h - HEADER_H)

        logo_h = 9 * mm
        logo_y = h - HEADER_H + (HEADER_H - logo_h) / 2

        # Logos en header — sólo a partir de página 2
        if doc.page > 1:
            if self.logo_postman and os.path.exists(self.logo_postman):
                try:
                    logo_w = logo_h * (659 / 200)
                    canvas.drawImage(
                        self.logo_postman, MARGIN, logo_y,
                        width=logo_w, height=logo_h,
                        preserveAspectRatio=True, mask="auto"
                    )
                except Exception:
                    pass
            if self.logo_aiquaa and os.path.exists(self.logo_aiquaa):
                try:
                    aq_size = logo_h + 2*mm
                    canvas.drawImage(
                        self.logo_aiquaa,
                        w - MARGIN - aq_size, logo_y - 1*mm,
                        width=aq_size, height=aq_size,
                        preserveAspectRatio=True, mask="auto"
                    )
                except Exception:
                    pass

        # ── Footer ──────────────────────────────────────────────────────────
        canvas.line(MARGIN, FOOTER_H, w - MARGIN, FOOTER_H)

        canvas.setFont("Helvetica", 7)
        canvas.setFillColor(NAVY)

        # Izquierda: link aiquaa.com
        footer_left = f"Automatización: {self.author}  |  Powered by skill postman-newman · aiquaa.com" if self.author else f"Powered by skill postman-newman · https://aiquaa.com/"
        canvas.drawString(MARGIN, FOOTER_H - 5*mm, footer_left)

        # Derecha: número de página
        canvas.setFillColor(GRAY_MID)
        canvas.drawRightString(w - MARGIN, FOOTER_H - 5*mm, f"Pág. {doc.page}")

        canvas.restoreState()


# ─── Portada ──────────────────────────────────────────────────────────────────
def build_cover(summary, logo_postman, logo_aiquaa, styles, api_version=None, repo_url=None, banner=None, author=None, run_url=None):
    story = []
    w_content = PAGE_W - 2 * MARGIN

    story.append(Spacer(1, 8*mm))

    # ── Banda de logos en portada ──────────────────────────────────────────
    logo_h_cover = 20 * mm

    # Banner principal (API + Postman + Newman) — ancho completo
    if banner and os.path.exists(banner):
        try:
            from PIL import Image as PILImage
            _bw, _bh = PILImage.open(banner).size
            _ratio = _bw / _bh
            # Calcular dimensiones respetando aspect ratio
            # Intentar llenar el ancho disponible
            banner_w = w_content
            banner_h = banner_w / _ratio
            # Si es muy alto, limitarlo a 42mm y recalcular ancho
            if banner_h > 42 * mm:
                banner_h = 42 * mm
                banner_w = banner_h * _ratio
            banner_img = Image(banner, width=banner_w, height=banner_h)
            banner_img.hAlign = "CENTER"
            story.append(banner_img)
            story.append(Spacer(1, 8*mm))
        except Exception:
            story.append(Spacer(1, 8*mm))
    else:
        # Fallback: logo aiquaa solo si no hay banner
        if logo_aiquaa and os.path.exists(logo_aiquaa):
            try:
                aq_img = Image(logo_aiquaa, width=logo_h_cover, height=logo_h_cover)
                aq_img.hAlign = "CENTER"
                story.append(aq_img)
                story.append(Spacer(1, 6*mm))
            except Exception:
                story.append(Spacer(1, 8*mm))
        else:
            story.append(Spacer(1, 8*mm))

    # ── Título ────────────────────────────────────────────────────────────
    story.append(Paragraph(
        f'Informe de Automatizacion de Pruebas',
        styles["title"]))
    story.append(Spacer(1, 2*mm))
    story.append(Paragraph(
        f'<font color="#4A4A4A">{summary["collection_name"]}</font>',
        styles["subtitle"]))
    story.append(Spacer(1, 4*mm))
    story.append(HRFlowable(width="100%", thickness=0.5, color=GRAY_BORDER))
    story.append(Spacer(1, 8*mm))

    # ── Estadísticas ──────────────────────────────────────────────────────
    passed = summary["passed_tests"]
    failed = summary["failed_tests"]
    total  = summary["total_tests"]
    reqs   = summary["total_requests"]
    dur    = summary["duration_ms"]
    stat_col = w_content / 4

    def stat_cell(num, label, color=GRAY_DARK):
        return [
            Paragraph(f'<font color="{color.hexval()}">{num}</font>', styles["stat_num"]),
            Paragraph(label, styles["stat_label"]),
        ]

    stat_table = Table(
        [[
            stat_cell(reqs,   "Peticiones"),
            stat_cell(total,  "Pruebas"),
            stat_cell(passed, "Aprobadas", GREEN_PASS),
            stat_cell(failed, "Fallidas",  RED_FAIL if failed > 0 else GRAY_MID),
        ]],
        colWidths=[stat_col] * 4,
        style=TableStyle([
            ("ALIGN",         (0,0), (-1,-1), "CENTER"),
            ("VALIGN",        (0,0), (-1,-1), "MIDDLE"),
            ("TOPPADDING",    (0,0), (-1,-1), 8),
            ("BOTTOMPADDING", (0,0), (-1,-1), 8),
            ("BACKGROUND",    (0,0), (-1,-1), GRAY_LIGHT),
            ("BOX",           (0,0), (-1,-1), 0.5, GRAY_BORDER),
            ("INNERGRID",     (0,0), (-1,-1), 0.5, GRAY_BORDER),
        ])
    )
    story.append(stat_table)
    story.append(Spacer(1, 6*mm))

    # ── Metadata ──────────────────────────────────────────────────────────
    result_col = GREEN_PASS if failed == 0 else RED_FAIL
    result_txt = "APROBADO" if failed == 0 else "FALLIDO"

    dur_display = f"{dur/1000:,.2f} s ({dur:,} ms)" if dur >= 1000 else f"{dur} ms"

    meta = [
        ["Fecha",             summary["fecha"]],
        ["Hora",              summary["hora"]],
        ["Tiempo de ejecución", dur_display],
        ["Resultado",
         f'<font color="{result_col.hexval()}"><b>{result_txt}</b></font>'],
    ]
    if api_version:
        # Si es una URL de release la mostramos como link, si no como texto plano
        if api_version.startswith("http"):
            ver_display = f'<font color="#0D1B40"><u>{api_version}</u></font>'
        else:
            ver_display = api_version
        meta.insert(3, ["Versión / release", ver_display])
    if author:
        meta.append(["Ejecutado por", author])
    if repo_url:
        meta.append(["Repositorio",
                     f'<font color="#0D1B40"><u>{repo_url}</u></font>'])
    if run_url:
        meta.append(["Ejecución CI",
                     f'<font color="#0D1B40"><u>{run_url}</u></font>'])
    meta_table = Table(
        [[Paragraph(r[0], styles["cover_meta_key"]),
          Paragraph(r[1], styles["cover_meta_val"])] for r in meta],
        colWidths=[42*mm, w_content - 42*mm],
        style=TableStyle([
            ("VALIGN",        (0,0), (-1,-1), "MIDDLE"),
            ("TOPPADDING",    (0,0), (-1,-1), 5),
            ("BOTTOMPADDING", (0,0), (-1,-1), 5),
            ("LINEBELOW",     (0,0), (-1,-2), 0.3, GRAY_BORDER),
        ])
    )
    story.append(meta_table)

    # ── Crédito pie de portada ────────────────────────────────────────────
    story.append(Spacer(1, 12*mm))
    story.append(HRFlowable(width="100%", thickness=0.3, color=GRAY_BORDER))
    story.append(Spacer(1, 3*mm))
    credit_lines = ['Powered by skill <font color="#0D1B40"><b>postman-newman</b></font> · <font color="#0D1B40"><u>https://aiquaa.com/</u></font>']
    if author:
        credit_lines.append(f'Automatización realizada por: <font color="#0D1B40"><b>{author}</b></font>')
    story.append(Paragraph('<br/>'.join(credit_lines),
        ParagraphStyle('cover_credit', fontName='Helvetica', fontSize=9,
                       textColor=GRAY_MID, alignment=TA_CENTER, leading=14)))

    story.append(PageBreak())
    return story


# ─── Detalle de requests ──────────────────────────────────────────────────────
def build_results(executions, styles):
    story = []
    w_content = PAGE_W - 2 * MARGIN

    story.append(Paragraph("Detalle de Peticiones", styles["section"]))
    story.append(Spacer(1, 3*mm))

    for i, ex in enumerate(executions, 1):
        passed  = sum(1 for t in ex["tests"] if t["passed"])
        failed  = sum(1 for t in ex["tests"] if not t["passed"])

        block = []

        # Encabezado
        badge_text, badge_col, badge_bg = status_info(passed, failed)
        badge_style = ParagraphStyle(
            "badge", fontName="Helvetica-Bold", fontSize=9,
            textColor=badge_col, alignment=TA_CENTER, leading=11,
        )
        header = Table(
            [[method_pill(ex["method"]),
              Paragraph(f'<b>{i}. {ex["name"]}</b>', styles["req_name"]),
              Paragraph(badge_text, badge_style)]],
            colWidths=[16*mm, w_content - 46*mm, 30*mm],
            style=TableStyle([
                ("VALIGN",        (0,0), (-1,-1), "MIDDLE"),
                ("ALIGN",         (2,0), (2,0), "CENTER"),
                ("LEFTPADDING",   (0,0), (-1,-1), 4),
                ("RIGHTPADDING",  (0,0), (-1,-1), 4),
                ("TOPPADDING",    (0,0), (-1,-1), 6),
                ("BOTTOMPADDING", (0,0), (-1,-1), 6),
                ("BACKGROUND",    (0,0), (1,0), GRAY_LIGHT),
                ("BACKGROUND",    (2,0), (2,0), badge_bg),
                ("BOX",           (0,0), (-1,-1), 0.5, GRAY_BORDER),
            ])
        )
        block.append(header)

        # URL
        block.append(Spacer(1, 1*mm))
        block.append(Paragraph("URL", styles["label"]))
        block.append(Paragraph(ex["url"] or "—", styles["url"]))

        # Status code + tiempo
        sc_col = GREEN_PASS if 200 <= ex["status_code"] < 300 else RED_FAIL
        block.append(Spacer(1, 1*mm))
        block.append(Paragraph(
            f'<font color="{sc_col.hexval()}"><b>HTTP {ex["status_code"]}</b></font>'
            f'  <font color="{GRAY_MID.hexval()}">{ex["resp_time"]} ms</font>',
            styles["subtitle"]))

        # Tests
        if ex["tests"]:
            block.append(Paragraph("Pruebas", styles["label"]))
            for t in ex["tests"]:
                icon  = "✓" if t["passed"] else "✗"
                sty   = styles["test_pass"] if t["passed"] else styles["test_fail"]
                line  = f'{icon}  {t["name"]}'
                if not t["passed"] and t["error"]:
                    line += f' — {t["error"]}'
                block.append(Paragraph(line, sty))

        # Response body
        if ex["resp_body"]:
            block.append(Paragraph("Cuerpo de respuesta", styles["label"]))
            safe = (truncate_body(ex["resp_body"])
                    .replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;"))
            block.append(Paragraph(safe, styles["body"]))

        block.append(Spacer(1, 5*mm))
        block.append(HRFlowable(width="100%", thickness=0.3, color=GRAY_BORDER))
        block.append(Spacer(1, 3*mm))

        story.append(KeepTogether(block[:6]))
        story.extend(block[6:])

    return story


# ─── Entry point ──────────────────────────────────────────────────────────────
def generate_report(results_path, output_path,
                    logo_aiquaa=None, logo_postman=None,
                    api_version=None, repo_url=None,
                    banner=None, author=None, run_url=None):
    with open(results_path, encoding="utf-8") as f:
        data = json.load(f)

    summary, executions = parse_newman_results(data)

    doc = SimpleDocTemplate(
        output_path, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=HEADER_H + 6*mm, bottomMargin=FOOTER_H + 8*mm,
        title=f"Informe de Automatizacion de Pruebas - {summary['collection_name']}",
        author="aiquaa — https://aiquaa.com/",
    )

    styles  = build_styles()
    on_page = ReportCanvas(logo_postman, logo_aiquaa, author=author)

    story  = build_cover(summary, logo_postman, logo_aiquaa, styles,
                     api_version=api_version, repo_url=repo_url,
                     banner=banner, author=author, run_url=run_url)
    story += build_results(executions, styles)

    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)

    print(f"✅ Reporte: {output_path}")
    print(f"   Requests : {summary['total_requests']}")
    print(f"   Tests    : {summary['total_tests']} "
          f"({summary['passed_tests']} passed, {summary['failed_tests']} failed)")
    print(f"   Duración : {summary['duration_ms']} ms")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Newman PDF Report — aiquaa.com")
    parser.add_argument("--results",
                        required=True,
                        help="JSON de resultados Newman (--reporter-json-export)")
    parser.add_argument("--output",
                        default=None,
                        help="Nombre del PDF. Default: INFORME_DE_AUT_<NOMBRE_API>.pdf")
    parser.add_argument("--logo-aiquaa",
                        default=None,
                        help="Path al logo aiquaa circular PNG")
    parser.add_argument("--logo-postman",
                        default=None,
                        help="Path al logo Postman PNG")
    parser.add_argument("--api-version",
                        default=None,
                        help="Versión o link del release de la API (opcional)")
    parser.add_argument("--repo-url",
                        default=None,
                        help="URL del repositorio de la API (opcional)")
    parser.add_argument("--banner",
                        default=None,
                        help="Imagen de portada (banner con íconos API/Postman/Newman)")
    parser.add_argument("--author",
                        default=None,
                        help="Nombre y/o email del creador de la automatización (opcional)")
    parser.add_argument("--run-url",
                        default=None,
                        help="URL de la ejecución de CI que genero este informe (opcional)")
    args = parser.parse_args()

    # Derivar nombre de salida desde la colección si no se pasó --output
    output_path = args.output
    if not output_path:
        import json as _json, re as _re
        try:
            with open(args.results, encoding='utf-8') as _f:
                _name = _json.load(_f).get('collection', {}).get('info', {}).get('name', 'API')
        except Exception:
            _name = 'API'
        _slug = _re.sub(r'[^A-Z0-9]+', '_', _name.upper()).strip('_')
        output_path = f'INFORME_DE_AUT_{_slug}.pdf'

    generate_report(
        args.results,
        output_path,
        logo_aiquaa=args.logo_aiquaa,
        logo_postman=args.logo_postman,
        api_version=args.api_version,
        repo_url=args.repo_url,
        banner=args.banner,
        author=args.author,
        run_url=args.run_url,
    )
