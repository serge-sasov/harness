#!/usr/bin/env python3
"""Собрать самодостаточный HTML из README.md.

- Markdown -> HTML (Python-Markdown, TOC, таблицы, fenced code).
- Каждый SVG встраивается как data URI: index.html работает офлайн по file://.
- Каждая диаграмма оборачивается в figure и открывается в полноэкранной
  модалке с масштабированием колесом/кнопками, панорамированием и Fit.
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


def ru_slugify(value: str, separator: str, unicode: bool = False) -> str:
    """Slug, сохраняющий кириллицу (для якорей TOC)."""
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
        alt = attr(attrs, "alt") or "Диаграмма"
        if not src or src.startswith(("data:", "http://", "https://", "#")):
            return match.group(0)

        path = (base_dir / src).resolve()
        if not path.is_file():
            raise FileNotFoundError(f"Не найден файл диаграммы: {path}")

        data = path.read_bytes()
        if not looks_like_svg(data):
            raise ValueError(f"Файл не похож на SVG: {path}")

        encoded = base64.b64encode(data).decode("ascii")
        plain_alt = html.unescape(alt)
        alt_esc = html.escape(plain_alt, quote=True)
        embedded.append(src)

        return (
            f'<figure class="diagram" tabindex="0" role="button" '
            f'aria-label="Открыть схему: {alt_esc}" data-title="{alt_esc}">'
            f'<div class="diagram-frame">'
            f'<img src="data:image/svg+xml;base64,{encoded}" '
            f'alt="{alt_esc}" loading="lazy">'
            f'<span class="zoom-hint">Клик — открыть схему</span>'
            f"</div>"
            f"<figcaption>{alt_esc}</figcaption>"
            f"</figure>"
        )

    return IMAGE_RE.sub(repl, body), embedded


def build() -> int:
    if not SOURCE.is_file():
        print(f"Ошибка: не найден {SOURCE}", file=sys.stderr)
        return 1

    source = SOURCE.read_text(encoding="utf-8")
    md = markdown.Markdown(
        extensions=["toc", "tables", "fenced_code", "sane_lists", "attr_list"],
        extension_configs={
            "toc": {
                "toc_depth": "2-3",
                "slugify": ru_slugify,
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
        title = "Локальный harness: описание решения"

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

    print(f"Готово: {OUTPUT}")
    print(f"Диаграмм встроено: {len(embedded)}")
    for item in embedded:
        print(f"  - {item}")
    return 0


if __name__ == "__main__":
    raise SystemExit(build())
