#!/usr/bin/env bash
# PostToolUse : formate automatiquement chaque fichier Python que Claude vient d'écrire.
# Gratuit en quota : c'est ruff qui travaille, pas le modèle.
set -euo pipefail

file=$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)

if [[ "$file" == *.py ]] && command -v ruff >/dev/null 2>&1; then
  ruff format --quiet "$file" || true
  ruff check --fix --quiet "$file" || true
fi
exit 0
