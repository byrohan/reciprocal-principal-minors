#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
browser="${CHROME_BIN:-}"
if [[ -z "$browser" ]]; then
    for candidate in chromium chromium-browser google-chrome google-chrome-stable; do
        if command -v "$candidate" >/dev/null; then browser="$candidate"; break; fi
    done
fi
if [[ -z "$browser" ]]; then echo "Set CHROME_BIN to a Chrome or Chromium executable." >&2; exit 1; fi
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
source_uri="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).as_uri())' "$root/paper/manuscript.html")"
"$browser" --headless --disable-background-networking --disable-extensions --no-first-run --no-pdf-header-footer \
  --user-data-dir="$scratch/profile" --print-to-pdf="$scratch/manuscript.pdf" "$source_uri"
test -s "$scratch/manuscript.pdf"
cp "$scratch/manuscript.pdf" "$root/paper/manuscript.pdf"
