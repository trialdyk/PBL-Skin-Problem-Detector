"""Convert pytest JUnit XML into CSV / XLSX spreadsheets.

Usage (from backend/)::

    python -m pytest --junitxml=tests/reports/pytest-results.xml
    python scripts/export_test_report.py
"""

from __future__ import annotations

import csv
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XML_PATH = ROOT / "tests" / "reports" / "pytest-results.xml"
OUT_DIR = ROOT / "tests" / "reports"
CSV_DETAILS = OUT_DIR / "api_test_results.csv"
CSV_SUMMARY = OUT_DIR / "api_test_summary.csv"
XLSX_PATH = OUT_DIR / "api_test_results.xlsx"


def _guess_area(classname: str, name: str) -> str:
    lower = f"{classname} {name}".lower()
    rules = [
        ("full_auth_flow", "Auth flow E2E"),
        ("login", "POST /auth/login"),
        ("register", "POST /auth/register"),
        ("google", "POST /auth/google"),
        ("users", "GET /users/status"),
        ("items", "GET /items/status"),
        ("ml", "POST /ml/predict"),
        ("predict", "POST /ml/predict"),
        ("health", "GET /health"),
        ("openapi", "OpenAPI contract"),
        ("protected", "Protected routes"),
        ("database", "Database"),
    ]
    for needle, label in rules:
        if needle in lower:
            return label
    if "api_suite" in lower:
        return "API suite"
    if "auth" in lower:
        return "Auth / API"
    return "other"


def _load_rows() -> list[dict[str, str]]:
    root = ET.parse(XML_PATH).getroot()
    suites = root.findall("testsuite")
    if not suites and root.tag == "testsuite":
        suites = [root]

    rows: list[dict[str, str]] = []
    for suite in suites:
        for case in suite.findall("testcase"):
            classname = case.get("classname", "")
            name = case.get("name", "")
            time_s = case.get("time", "0")
            status = "passed"
            detail = ""
            if case.find("failure") is not None:
                status = "failed"
                detail = (case.find("failure").get("message") or "")[:300]
            elif case.find("error") is not None:
                status = "error"
                detail = (case.find("error").get("message") or "")[:300]
            elif case.find("skipped") is not None:
                status = "skipped"
                detail = (case.find("skipped").get("message") or "")[:300]

            module = classname.rsplit(".", 1)[-1] if classname else ""
            rows.append(
                {
                    "module": module,
                    "test_name": name,
                    "api_area": _guess_area(classname, name),
                    "status": status,
                    "duration_sec": time_s,
                    "detail": detail.replace("\n", " "),
                    "classname": classname,
                }
            )

    order = {"failed": 0, "error": 1, "skipped": 2, "passed": 3}
    rows.sort(key=lambda r: (order.get(r["status"], 9), r["module"], r["test_name"]))
    return rows


def _write_csv(rows: list[dict[str, str]]) -> dict[str, int]:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with CSV_DETAILS.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "no",
                "module",
                "test_name",
                "api_area",
                "status",
                "duration_sec",
                "detail",
            ],
        )
        writer.writeheader()
        for i, row in enumerate(rows, 1):
            writer.writerow(
                {
                    "no": i,
                    "module": row["module"],
                    "test_name": row["test_name"],
                    "api_area": row["api_area"],
                    "status": row["status"],
                    "duration_sec": row["duration_sec"],
                    "detail": row["detail"],
                }
            )

    counts = {"passed": 0, "failed": 0, "skipped": 0, "error": 0}
    by_module: dict[str, dict[str, int]] = {}
    for row in rows:
        counts[row["status"]] = counts.get(row["status"], 0) + 1
        bucket = by_module.setdefault(
            row["module"], {"passed": 0, "failed": 0, "skipped": 0, "error": 0}
        )
        bucket[row["status"]] = bucket.get(row["status"], 0) + 1

    with CSV_SUMMARY.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["DermaScan Backend API Test Report"])
        w.writerow(
            ["Generated (UTC)", datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")]
        )
        w.writerow([])
        w.writerow(["Overall"])
        w.writerow(["metric", "count"])
        total = sum(counts.values())
        w.writerow(["total", total])
        for key in ("passed", "failed", "skipped", "error"):
            w.writerow([key, counts.get(key, 0)])
        w.writerow([])
        w.writerow(["By module"])
        w.writerow(["module", "passed", "failed", "skipped", "error", "total"])
        for mod, c in sorted(by_module.items()):
            w.writerow(
                [mod, c["passed"], c["failed"], c["skipped"], c["error"], sum(c.values())]
            )
    return counts


def _write_xlsx(rows: list[dict[str, str]], counts: dict[str, int]) -> bool:
    try:
        from openpyxl import Workbook
        from openpyxl.styles import Font, PatternFill
        from openpyxl.utils import get_column_letter
    except ImportError:
        return False

    wb = Workbook()
    ws = wb.active
    ws.title = "Results"
    headers = ["No", "Module", "Test Name", "API Area", "Status", "Duration (s)", "Detail"]
    ws.append(headers)
    for cell in ws[1]:
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor="1F4E79")

    fills = {
        "passed": PatternFill("solid", fgColor="C6EFCE"),
        "failed": PatternFill("solid", fgColor="FFC7CE"),
        "error": PatternFill("solid", fgColor="FFC7CE"),
        "skipped": PatternFill("solid", fgColor="FFEB9C"),
    }
    for i, row in enumerate(rows, 1):
        ws.append(
            [
                i,
                row["module"],
                row["test_name"],
                row["api_area"],
                row["status"],
                float(row["duration_sec"] or 0),
                row["detail"],
            ]
        )
        ws.cell(row=i + 1, column=5).fill = fills.get(row["status"], PatternFill())

    widths = {1: 6, 2: 18, 3: 55, 4: 22, 5: 12, 6: 14, 7: 40}
    for col, width in widths.items():
        ws.column_dimensions[get_column_letter(col)].width = width

    by_module: dict[str, dict[str, int]] = {}
    for row in rows:
        bucket = by_module.setdefault(
            row["module"], {"passed": 0, "failed": 0, "skipped": 0, "error": 0}
        )
        bucket[row["status"]] = bucket.get(row["status"], 0) + 1

    ws2 = wb.create_sheet("Summary")
    ws2["A1"] = "DermaScan Backend API Test Report"
    ws2["A1"].font = Font(bold=True, size=14)
    ws2["A2"] = (
        f"Generated (UTC): {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}"
    )
    ws2.append([])
    ws2.append(["Metric", "Count"])
    for cell in ws2[4]:
        cell.font = Font(bold=True)
    total = sum(counts.values())
    ws2.append(["total", total])
    for key in ("passed", "failed", "skipped", "error"):
        ws2.append([key, counts.get(key, 0)])
    ws2.append([])
    ws2.append(["Module", "Passed", "Failed", "Skipped", "Error", "Total"])
    for cell in ws2[ws2.max_row]:
        cell.font = Font(bold=True)
    for mod, c in sorted(by_module.items()):
        ws2.append([mod, c["passed"], c["failed"], c["skipped"], c["error"], sum(c.values())])
    for col in range(1, 7):
        ws2.column_dimensions[get_column_letter(col)].width = 18

    wb.save(XLSX_PATH)
    return True


def main() -> None:
    if not XML_PATH.is_file():
        raise SystemExit(
            f"Missing {XML_PATH}. Run first:\n"
            "  pytest --junitxml=tests/reports/pytest-results.xml"
        )
    rows = _load_rows()
    counts = _write_csv(rows)
    has_xlsx = _write_xlsx(rows, counts)
    print(f"CSV details : {CSV_DETAILS}")
    print(f"CSV summary : {CSV_SUMMARY}")
    if has_xlsx:
        print(f"XLSX        : {XLSX_PATH}")
    else:
        print("XLSX        : skipped (pip install openpyxl)")
    print(
        f"Total={sum(counts.values())} "
        f"passed={counts['passed']} failed={counts['failed']} skipped={counts['skipped']}"
    )


if __name__ == "__main__":
    main()
