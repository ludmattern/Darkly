#!/usr/bin/env bash
set -euo pipefail
BASE="http://127.0.0.1:8080/.hidden/"
OUT="${1:-./hidden-dl}"

mkdir -p "$OUT"
wget -r -np -nH --cut-dirs=1 -e robots=off -P "$OUT" "$BASE"

grep -R --text "flag" "$OUT" || true
