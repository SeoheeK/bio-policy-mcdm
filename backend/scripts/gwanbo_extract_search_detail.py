#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.gwanbo import parse_search_detail_html, to_csv, to_json


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Parse gwanbo.go.kr searchDetail HTML and extract list items (법률/고시/공고...)."
    )
    ap.add_argument(
        "--html",
        dest="html_path",
        default="-",
        help="HTML file path to parse. Use '-' to read from stdin (default).",
    )
    ap.add_argument(
        "--format",
        choices=["json", "csv"],
        default="json",
        help="Output format (default: json).",
    )
    args = ap.parse_args()

    if args.html_path == "-":
        html = sys.stdin.read()
    else:
        html = Path(args.html_path).read_text(encoding="utf-8")

    items = parse_search_detail_html(html)
    if args.format == "csv":
        sys.stdout.write(to_csv(items))
    else:
        sys.stdout.write(to_json(items) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

