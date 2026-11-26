# Сайт getbeautybase.com

Статичний сайт без збірки й трекерів (Cloudflare Pages, тека `website/`).
- `index.html` — головна («Живий день»), `assets/` — стилі, скрипт, знак.
- `privacy/`, `terms/` — генеруються: `python3 docs/legal/build_pages.py` (тексти в `docs/legal/`).
- `support/` — пишеться вручну.
- Перегляд локально: `python3 -m http.server 8080 -d website` → http://localhost:8080
