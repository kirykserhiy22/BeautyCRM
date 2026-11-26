#!/usr/bin/env python3
"""
Сторінки сайту з юридичних текстів: docs/legal/*.md → website/privacy/, website/terms/.
Запуск з кореня проєкту після зміни текстів:   python3 docs/legal/build_pages.py
Простий перетворювач Markdown (заголовки, абзаци, списки, **жирний**, [посилання](url)) — без бібліотек.
"""

import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEGAL = ROOT / "docs" / "legal"
SITE = ROOT / "website"

PAGES = {
    "privacy": ("privacy-policy", "Політика конфіденційності", "Privacy Policy"),
    "terms": ("terms", "Умови користування", "Terms of Use"),
}


def inline(text: str) -> str:
    text = html.escape(text, quote=False)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\[(.+?)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', text)
    text = re.sub(r"(?<![\w/\">])(hello@getbeautybase\.com)", r'<a href="mailto:\1">\1</a>', text)
    return text


def markdown(md: str) -> str:
    out, para, items = [], [], []

    def flush():
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
            para.clear()
        if items:
            out.append("<ul>" + "".join("<li>" + inline(i) + "</li>" for i in items) + "</ul>")
            items.clear()

    for line in md.splitlines():
        s = line.strip()
        if not s:
            flush()
        elif s.startswith("# "):
            flush()
            out.append("<h1>" + inline(s[2:]) + "</h1>")
        elif s.startswith("## "):
            flush()
            out.append("<h2>" + inline(s[3:]) + "</h2>")
        elif s.startswith("- "):
            if para:
                flush()
            items.append(s[2:])
        else:
            if items:
                flush()
            para.append(s)
    flush()
    html_text = "\n".join(out)
    # Рядок дати під заголовком — сірим
    return re.sub(r"<p>((Набирає|Набирають|Effective)[^<]*)</p>", r'<p class="meta">\1</p>', html_text, count=1)


def page(title_uk: str, title_en: str, body_uk: str, body_en: str) -> str:
    return f"""<!doctype html>
<html lang="uk">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{title_uk} · Beauty Base</title>
<meta name="theme-color" content="#F7EFF2">
<link rel="icon" href="/assets/mark.svg" type="image/svg+xml">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Jost:wght@400;500&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/assets/site.css">
</head>
<body class="doc-page">
<header class="top solid light" id="top">
  <a class="wordmark" href="/">BEAUTY BASE</a>
  <div class="top-right">
    <div class="lang" role="group" aria-label="Language">
      <button type="button" data-set-lang="uk" aria-pressed="true">UA</button>
      <button type="button" data-set-lang="en" aria-pressed="false">EN</button>
    </div>
  </div>
</header>
<main class="doc">
  <div data-lang-block="uk">
{body_uk}
  </div>
  <div data-lang-block="en">
{body_en}
  </div>
</main>
<footer class="foot">
  <div class="foot-inner">
    <span class="wordmark">BEAUTY BASE</span>
    <nav>
      <a href="/privacy/" data-i18n="foot.privacy">Політика конфіденційності</a>
      <a href="/terms/" data-i18n="foot.terms">Умови користування</a>
      <a href="/support/" data-i18n="foot.support">Підтримка</a>
      <a href="mailto:hello@getbeautybase.com">hello@getbeautybase.com</a>
    </nav>
    <small>© 2026 Beauty Base</small>
  </div>
</footer>
<script src="/assets/site.js"></script>
</body>
</html>
"""


def main() -> None:
    for folder, (stem, title_uk, title_en) in PAGES.items():
        uk = markdown((LEGAL / f"{stem}.uk.md").read_text(encoding="utf-8"))
        en = markdown((LEGAL / f"{stem}.en.md").read_text(encoding="utf-8"))
        target = SITE / folder / "index.html"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(page(title_uk, title_en, uk, en), encoding="utf-8")
        print("written", target.relative_to(ROOT))


if __name__ == "__main__":
    main()
