from __future__ import annotations

import csv
import json
import re
from dataclasses import asdict, dataclass
from datetime import date
from html import unescape
from html.parser import HTMLParser
from typing import Any, Dict, Iterable, List, Optional
from urllib.parse import parse_qs, urljoin, urlparse


GWANBO_BASE_URL = "https://www.gwanbo.go.kr"


@dataclass(frozen=True)
class GwanboItem:
    section: str
    title: str
    published_date: str  # ISO date: YYYY-MM-DD
    gwanbo_issue_no: Optional[int]
    gwanbo_issue_text_raw: str
    gwanbo_publication_raw: str  # e.g. "관보(정호)", "관보(별권3권)"
    pdf_url: str
    content_id: str
    toc_id: str
    is_toc_order: str
    onclick_raw: str


def _parse_iso_date_from_korean_dot(s: str) -> Optional[str]:
    # "2025.12.30" -> "2025-12-30"
    m = re.match(r"^\s*(\d{4})\.(\d{2})\.(\d{2})\s*$", s)
    if not m:
        return None
    y, mo, d = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
    return date(y, mo, d).isoformat()


def _parse_issue_no(s: str) -> Optional[int]:
    # "21148 호" -> 21148
    m = re.search(r"(\d{3,})", s)
    if not m:
        return None
    try:
        return int(m.group(1))
    except ValueError:
        return None


def _parse_js_single_quoted_args(s: str) -> List[str]:
    """
    Parses a JavaScript argument list like:
      'a','b','c'
    into ["a","b","c"].

    Handles backslash escapes within single-quoted strings.
    """
    args: List[str] = []
    i = 0
    n = len(s)
    while i < n:
        # skip whitespace / commas
        while i < n and s[i] in " \t\r\n,":
            i += 1
        if i >= n:
            break
        if s[i] != "'":
            # Not a single-quoted string; stop parsing.
            break
        i += 1  # consume opening quote
        out: List[str] = []
        while i < n:
            ch = s[i]
            if ch == "\\" and i + 1 < n:
                out.append(s[i + 1])
                i += 2
                continue
            if ch == "'":
                i += 1  # consume closing quote
                break
            out.append(ch)
            i += 1
        args.append("".join(out))
        # loop continues, skipping commas/whitespace
    return args


def parse_click_highclass_gwanbo_onclick(
    onclick_raw: str,
    *,
    base_url: str = GWANBO_BASE_URL,
) -> Dict[str, str]:
    """
    Extracts link and IDs from onclick like:
      click_highclass_gwanbo('/ezpdf/customLayout.jsp?contentId=...&tocId=...&isTocOrder=N','제목',...)
    """
    onclick = unescape(onclick_raw or "").strip()
    m = re.search(r"click_highclass_gwanbo\s*\((.*)\)\s*;?\s*$", onclick)
    if not m:
        return {
            "pdf_url": "",
            "content_id": "",
            "toc_id": "",
            "is_toc_order": "",
        }

    arg_blob = m.group(1)
    args = _parse_js_single_quoted_args(arg_blob)
    pdf_path = args[0] if len(args) >= 1 else ""
    pdf_url = urljoin(base_url, pdf_path) if pdf_path else ""

    content_id = ""
    toc_id = ""
    is_toc_order = ""
    if pdf_url:
        parsed = urlparse(pdf_url)
        qs = parse_qs(parsed.query)
        content_id = (qs.get("contentId") or [""])[0]
        toc_id = (qs.get("tocId") or [""])[0]
        is_toc_order = (qs.get("isTocOrder") or [""])[0]

    return {
        "pdf_url": pdf_url,
        "content_id": content_id,
        "toc_id": toc_id,
        "is_toc_order": is_toc_order,
    }


class _SearchDetailHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.items: List[GwanboItem] = []

        self._current_section: str = ""

        self._in_h4 = False
        self._h4_buf: List[str] = []

        self._in_ul_list = False

        self._in_li = False
        self._in_a = False
        self._a_buf: List[str] = []

        self._in_span = False
        self._span_buf: List[str] = []

        self._li_onclick: str = ""
        self._li_spans: List[str] = []

    def handle_starttag(self, tag: str, attrs: List[tuple[str, Optional[str]]]) -> None:
        attrs_dict = {k: (v or "") for k, v in attrs}

        if tag == "h4":
            self._in_h4 = True
            self._h4_buf = []
            return

        if tag == "ul":
            cls = attrs_dict.get("class", "")
            # class can be space-separated
            if "list" in cls.split():
                self._in_ul_list = True
            return

        if tag == "li" and self._in_ul_list and self._current_section:
            self._in_li = True
            self._li_onclick = ""
            self._li_spans = []
            self._a_buf = []
            return

        if tag == "a" and self._in_li:
            self._in_a = True
            self._a_buf = []
            self._li_onclick = attrs_dict.get("onclick", "") or self._li_onclick
            return

        if tag == "span" and self._in_li:
            self._in_span = True
            self._span_buf = []
            return

    def handle_endtag(self, tag: str) -> None:
        if tag == "h4" and self._in_h4:
            self._in_h4 = False
            self._current_section = "".join(self._h4_buf).strip()
            self._h4_buf = []
            return

        if tag == "ul" and self._in_ul_list:
            self._in_ul_list = False
            return

        if tag == "a" and self._in_a:
            self._in_a = False
            return

        if tag == "span" and self._in_span:
            self._in_span = False
            txt = "".join(self._span_buf).strip()
            if txt:
                self._li_spans.append(txt)
            self._span_buf = []
            return

        if tag == "li" and self._in_li:
            self._in_li = False
            title = " ".join("".join(self._a_buf).split()).strip()
            spans = self._li_spans[:]
            published_raw = spans[0] if len(spans) >= 1 else ""
            issue_raw = spans[1] if len(spans) >= 2 else ""
            publication_raw = spans[2] if len(spans) >= 3 else ""

            published_date = _parse_iso_date_from_korean_dot(published_raw) or ""
            issue_no = _parse_issue_no(issue_raw)

            onclick_info = parse_click_highclass_gwanbo_onclick(self._li_onclick)
            self.items.append(
                GwanboItem(
                    section=self._current_section,
                    title=title,
                    published_date=published_date,
                    gwanbo_issue_no=issue_no,
                    gwanbo_issue_text_raw=issue_raw,
                    gwanbo_publication_raw=publication_raw,
                    pdf_url=onclick_info["pdf_url"],
                    content_id=onclick_info["content_id"],
                    toc_id=onclick_info["toc_id"],
                    is_toc_order=onclick_info["is_toc_order"],
                    onclick_raw=self._li_onclick,
                )
            )
            self._li_onclick = ""
            self._li_spans = []
            self._a_buf = []
            return

    def handle_data(self, data: str) -> None:
        if self._in_h4:
            self._h4_buf.append(data)
        elif self._in_a:
            self._a_buf.append(data)
        elif self._in_span:
            self._span_buf.append(data)


def parse_search_detail_html(html: str) -> List[GwanboItem]:
    """
    Parses the HTML fragment from:
      https://www.gwanbo.go.kr/user/search/searchDetail.do

    Returns a flat list of items, each with 'section' (e.g. 법률/고시/공고...).
    """
    p = _SearchDetailHTMLParser()
    p.feed(html or "")
    p.close()
    return p.items


def items_to_dicts(items: Iterable[GwanboItem]) -> List[Dict[str, Any]]:
    return [asdict(i) for i in items]


def to_json(items: Iterable[GwanboItem], *, ensure_ascii: bool = False, indent: int = 2) -> str:
    return json.dumps(items_to_dicts(items), ensure_ascii=ensure_ascii, indent=indent)


def to_csv(items: Iterable[GwanboItem]) -> str:
    rows = items_to_dicts(items)
    fieldnames = list(rows[0].keys()) if rows else list(asdict(GwanboItem(  # type: ignore[arg-type]
        section="",
        title="",
        published_date="",
        gwanbo_issue_no=None,
        gwanbo_issue_text_raw="",
        gwanbo_publication_raw="",
        pdf_url="",
        content_id="",
        toc_id="",
        is_toc_order="",
        onclick_raw="",
    )).keys())

    # Write CSV to an in-memory string
    import io

    buf = io.StringIO()
    w = csv.DictWriter(buf, fieldnames=fieldnames)
    w.writeheader()
    for r in rows:
        w.writerow({k: r.get(k, "") for k in fieldnames})
    return buf.getvalue()

