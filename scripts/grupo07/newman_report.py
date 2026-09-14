#!/usr/bin/env python3
"""Juan Barreto's standalone Newman summary PDF; never copy request data."""

import argparse
import json
import math
from datetime import datetime, timezone
from html import escape
from pathlib import Path


def mapping(value):
    return value if isinstance(value, dict) else {}


def count(value, fallback=0):
    return value if type(value) is int and value >= 0 else fallback


def timestamp(value):
    if type(value) in (int, float) and math.isfinite(value) and value >= 0:
        return value
    return None


def summarize(document):
    run = document["run"]
    stats = mapping(run.get("stats"))
    executions = run.get("executions")
    executions = executions if isinstance(executions, list) else []
    checks = []
    for execution in executions:
        assertions = mapping(execution).get("assertions")
        if isinstance(assertions, list):
            checks.extend(item for item in assertions if isinstance(item, dict))

    assertion_stats = mapping(stats.get("assertions"))
    requests = count(mapping(stats.get("requests")).get("total"), len(executions))
    total = count(assertion_stats.get("total"), len(checks))
    failed = count(assertion_stats.get("failed"), sum(bool(c.get("error")) for c in checks))
    skipped = count(assertion_stats.get("pending"), sum(bool(c.get("skipped")) for c in checks))
    passed = max(0, total - failed - skipped)
    # Include transport/script failures, not just assertion failures.
    errors = bool(run.get("failures")) or any(
        count(mapping(value).get("failed")) > 0 for value in stats.values()
    )
    verdict = "PASS" if requests > 0 and total > 0 and passed == total and not errors else "FAIL"

    timings = mapping(run.get("timings"))
    started, completed = timestamp(timings.get("started")), timestamp(timings.get("completed"))
    runtime, executed_at = "Not available", "Not available"
    if started is not None and completed is not None and completed >= started:
        runtime = f"{(completed - started) / 1000:.2f} s"
    if started is not None:
        try:
            executed_at = datetime.fromtimestamp(started / 1000, tz=timezone.utc).isoformat(timespec="seconds")
        except (ValueError, OverflowError, OSError):
            pass

    info = mapping(mapping(document.get("collection")).get("info"))
    name = info.get("name")
    name = name[:180] if isinstance(name, str) and name else "Unknown collection"
    return {
        "Collection": name,
        "Total requests": requests,
        "Total assertions": total,
        "Passed assertions": passed,
        "Failed assertions": failed,
        "Skipped assertions": skipped,
        "Total runtime": runtime,
        "Execution date/time (UTC)": executed_at,
        "Result": verdict,
    }


def write_pdf(summary, output):
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    title = "Grupo 07 - Postman Regression Report"
    styles = getSampleStyleSheet()
    pdf = SimpleDocTemplate(str(output), pagesize=A4, title=title, author="Juan Barreto")
    rows = [[Paragraph(escape(key), styles["BodyText"]),
             Paragraph(escape(str(value)), styles["BodyText"])] for key, value in summary.items()]
    table = Table(rows, colWidths=[175, 275], hAlign="LEFT")
    table.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.4, colors.lightgrey),
        ("BACKGROUND", (0, 0), (0, -1), colors.whitesmoke),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
    ]))
    color = "#166534" if summary["Result"] == "PASS" else "#b91c1c"
    output.parent.mkdir(parents=True, exist_ok=True)
    pdf.build([
        Paragraph(title, styles["Title"]),
        Paragraph(f'<font color="{color}">{summary["Result"]}</font>', styles["Heading1"]),
        Spacer(1, 12), table, Spacer(1, 16),
        Paragraph("Summary only: no request headers, bodies, URLs or runtime variables are included.", styles["BodyText"]),
        Paragraph("FAIL also covers empty runs, skipped assertions, and recorded request/script failures. Missing optional timing fields are shown as unavailable.", styles["BodyText"]),
    ])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results", type=Path, default=Path("newman/results.json"))
    parser.add_argument("--output", type=Path, default=Path("newman/report.pdf"))
    args = parser.parse_args()
    try:
        with args.results.open(encoding="utf-8-sig") as source:
            document = json.load(source)
    except FileNotFoundError:
        parser.error(f"Newman results JSON not found: {args.results}. Check the Newman step.")
    except json.JSONDecodeError as error:
        parser.error(f"Invalid Newman JSON at line {error.lineno}, column {error.colno}.")
    except (OSError, UnicodeError):
        parser.error("Unable to read the Newman results JSON as UTF-8.")
    if not isinstance(document, dict) or not isinstance(document.get("run"), dict):
        parser.error("Newman results JSON must contain a run object.")
    summary = summarize(document)
    try:
        write_pdf(summary, args.output)
    except ImportError:
        parser.error("ReportLab is required: install it with python -m pip install reportlab.")
    except OSError:
        parser.error("Unable to write the PDF output.")
    print(f"PDF generated: {args.output}; result={summary['Result']}; "
          f"requests={summary['Total requests']}; assertions={summary['Total assertions']}; "
          f"passed={summary['Passed assertions']}; failed={summary['Failed assertions']}")
    return 0 if summary["Result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
