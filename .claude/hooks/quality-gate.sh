#!/usr/bin/env bash
# Stop : quand Claude pense avoir fini, on vérifie lint + tests.
# Si ça casse, on renvoie l'erreur à Claude (exit 2) pour qu'il corrige avant de rendre la main.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}"

# Évite une boucle infinie : si on est déjà dans une relance provoquée par ce hook, on laisse passer.
input=$(cat)
if echo "$input" | grep -q '"stop_hook_active": *true'; then
  exit 0
fi

# Rien de modifié en Python ? Pas besoin de lancer quoi que ce soit.
if ! git status --porcelain 2>/dev/null | grep -qE '\.py$'; then
  exit 0
fi

errors=""
if command -v ruff >/dev/null 2>&1; then
  out=$(ruff check . 2>&1) || errors+=$'ruff check a échoué :\n'"$out"$'\n'
fi
if command -v pytest >/dev/null 2>&1 && [ -d tests ]; then
  out=$(pytest -q -x 2>&1 | tail -n 30) || errors+=$'pytest a échoué :\n'"$out"$'\n'
fi

if [ -n "$errors" ]; then
  echo "$errors" >&2
  exit 2
fi
exit 0
