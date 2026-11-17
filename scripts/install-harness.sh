#!/usr/bin/env bash
# Installe ce harness dans un autre repo (par ex. ton projet RAG).
# Usage : scripts/install-harness.sh ../mon-autre-projet
# Ne remplace jamais un fichier existant : il est sauté et signalé.
set -euo pipefail

SRC=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:?"Usage: $0 <chemin-du-repo-cible>"}
[[ -d "$DEST/.git" ]] || { echo "$DEST n'est pas un repo git"; exit 1; }

items=(
  CLAUDE.md
  .claude/settings.json
  .claude/agents
  .claude/commands
  .claude/hooks
  .github/workflows/claude-review.yml
  .github/workflows/claude.yml
  .github/pull_request_template.md
  scripts/agents-up.sh
  scripts/agents-down.sh
)

for item in "${items[@]}"; do
  if [[ -d "$SRC/$item" ]]; then
    find "$SRC/$item" -type f | while read -r f; do
      rel=${f#"$SRC/"}
      if [[ -e "$DEST/$rel" ]]; then echo "• existe déjà, sauté : $rel"
      else mkdir -p "$DEST/$(dirname "$rel")"; cp -p "$f" "$DEST/$rel"; echo "✔ $rel"; fi
    done
  else
    if [[ -e "$DEST/$item" ]]; then echo "• existe déjà, sauté : $item"
    else mkdir -p "$DEST/$(dirname "$item")"; cp -p "$SRC/$item" "$DEST/$item"; echo "✔ $item"; fi
  fi
done

grep -qxF '.env' "$DEST/.gitignore" 2>/dev/null || echo '.env' >> "$DEST/.gitignore"
grep -qxF '.claude/settings.local.json' "$DEST/.gitignore" 2>/dev/null || echo '.claude/settings.local.json' >> "$DEST/.gitignore"

echo
echo "Fait. Pense à adapter la section 'Stack' de CLAUDE.md à ce projet,"
echo "et à ajouter le secret CLAUDE_CODE_OAUTH_TOKEN dans les settings GitHub du repo."
