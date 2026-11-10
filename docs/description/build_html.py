#!/usr/bin/env python3
"""Build a self-contained HTML file from README.md.

- Markdown -> HTML (Python-Markdown, TOC, tables, fenced code).
- Each SVG is embedded as a data URI: index.html works offline via file://.
- Each diagram is wrapped in a figure and opens in a full-screen modal with
  wheel/button zoom, panning, and Fit.
"""

from __future__ import annotations

import base64
import datetime as dt
import html
import re
import sys
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "README.md"
OUTPUT = ROOT / "index.html"

IMAGE_RE = re.compile(r"<img\b(?P<attrs>[^>]*?)/?>", re.IGNORECASE)
ATTR_RE = r'{name}\s*=\s*"([^"]*)"'


def slugify(value: str, separator: str, unicode: bool = False) -> str:
    """Slug that preserves Unicode letters (for TOC anchors)."""
    value = value.lower().strip()
    value = re.sub(r"[^\w\s-]", "", value, flags=re.UNICODE)
    value = re.sub(r"[%s\s]+" % re.escape(separator), separator, value)
    return value.strip(separator) or "section"


def attr(attrs: str, name: str) -> str | None:
    match = re.search(ATTR_RE.format(name=name), attrs, re.IGNORECASE)
    return match.group(1) if match else None


def looks_like_svg(data: bytes) -> bool:
    head = data.lstrip()[:512].lower()
    return b"<svg" in head or head.startswith(b"<?xml")


def embed_images(body: str, base_dir: Path) -> tuple[str, list[str]]:
    embedded: list[str] = []

    def repl(match: re.Match[str]) -> str:
        attrs = match.group("attrs")
        src = attr(attrs, "src")
        alt = attr(attrs, "alt") or "Diagram"
        if not src or src.startswith(("data:", "http://", "https://", "#")):
            return match.group(0)

        path = (base_dir / src).resolve()
        if not path.is_file():
            raise FileNotFoundError(f"Diagram file not found: {path}")

        data = path.read_bytes()
        if not looks_like_svg(data):
            raise ValueError(f"File does not look like SVG: {path}")

        encoded = base64.b64encode(data).decode("ascii")
        plain_alt = html.unescape(alt)
        alt_esc = html.escape(plain_alt, quote=True)
        embedded.append(src)

        return (
            f'<figure class="diagram" tabindex="0" role="button" '
            f'aria-label="Open diagram: {alt_esc}" data-title="{alt_esc}">'
            f'<div class="diagram-frame">'
            f'<img src="data:image/svg+xml;base64,{encoded}" '
            f'alt="{alt_esc}" loading="lazy">'
            f'<span class="zoom-hint">Click to open diagram</span>'
            f"</div>"
            f"<figcaption>{alt_esc}</figcaption>"
            f"</figure>"
        )

    return IMAGE_RE.sub(repl, body), embedded


def build() -> int:
    if not SOURCE.is_file():
        print(f"Error: {SOURCE} not found", file=sys.stderr)
        return 1

    source = SOURCE.read_text(encoding="utf-8")
    md = markdown.Markdown(
        extensions=["toc", "tables", "fenced_code", "sane_lists", "attr_list"],
        extension_configs={
            "toc": {
                "toc_depth": "2-3",
                "slugify": slugify,
                "permalink": False,
            }
        },
    )
    body = md.convert(source)

    h1 = re.search(r"<h1[^>]*>(.*?)</h1>", body, re.DOTALL | re.IGNORECASE)
    if h1:
        title = html.unescape(re.sub(r"<[^>]+>", "", h1.group(1))).strip()
        body = body[: h1.start()] + body[h1.end() :]
    else:
        title = "Local harness: solution description"

    body, embedded = embed_images(body, ROOT)
    body = re.sub(
        r"<p>\s*(<figure class=\"diagram\".*?</figure>)\s*</p>",
        r"\1",
        body,
        flags=re.DOTALL,
    )
    body = re.sub(
        r"(<table>.*?</table>)",
        r'<div class="table-scroll">\1</div>',
        body,
        flags=re.DOTALL,
    )

    template = (ROOT / "template.html").read_text(encoding="utf-8")
    document = (
        template.replace("%%TITLE%%", html.escape(title))
        .replace("%%TOC%%", md.toc)
        .replace("%%CONTENT%%", body)
        .replace("%%DATE%%", dt.date.today().isoformat())
        .replace("%%DIAGRAM_COUNT%%", str(len(embedded)))
    )
    OUTPUT.write_text(document, encoding="utf-8")

    print(f"Done: {OUTPUT}")
    print(f"Diagrams embedded: {len(embedded)}")
    for item in embedded:
        print(f"  - {item}")
    return 0


if __name__ == "__main__":
    raise SystemExit(build())
