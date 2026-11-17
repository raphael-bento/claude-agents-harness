#!/usr/bin/env bash
# Ferme la session tmux des agents et supprime les worktrees dont la branche est déjà mergée.
# Les worktrees avec du travail non mergé sont conservés (rien n'est perdu).
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
REPO=$(basename "$ROOT")
WT_DIR="$(dirname "$ROOT")/${REPO}-worktrees"
SESSION="agents-${REPO}"
BASE=$(git -C "$ROOT" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || echo main)

tmux kill-session -t "$SESSION" 2>/dev/null && echo "✔ session tmux fermée" || true

[[ -d "$WT_DIR" ]] || exit 0
for path in "$WT_DIR"/*/; do
  path=${path%/}
  name=$(basename "$path")
  branch="agent/$name"
  if [[ -n "$(git -C "$path" status --porcelain)" ]]; then
    echo "• $name : modifications non commitées → conservé"
  elif git -C "$ROOT" merge-base --is-ancestor "$branch" "$BASE" 2>/dev/null; then
    git -C "$ROOT" worktree remove "$path" && git -C "$ROOT" branch -d "$branch" >/dev/null
    echo "✔ $name : mergé → worktree supprimé"
  else
    echo "• $name : pas encore mergé → conservé"
  fi
done
git -C "$ROOT" worktree prune
