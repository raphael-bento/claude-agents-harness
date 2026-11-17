#!/usr/bin/env bash
# Lance N agents Claude Code en parallèle, chacun dans son propre git worktree + sa branche,
# tous dans une session tmux (une fenêtre par agent).
#
# Usage :
#   scripts/agents-up.sh feature-a feature-b            # 2 agents, noms libres
#   scripts/agents-up.sh -p "Implémente l'issue #12" fix-12
#
# Chaque agent hérite du même harness (CLAUDE.md + .claude/) puisque c'est versionné dans le repo.
# Conseil quota Pro : 2-3 agents en parallèle max. Les 6 agents de ton pote, c'est du Max.
set -euo pipefail

PROMPT=""
if [[ "${1:-}" == "-p" ]]; then
  PROMPT="$2"; shift 2
fi
[[ $# -ge 1 ]] || { echo "Usage: $0 [-p \"prompt initial\"] <nom-agent> [nom-agent ...]"; exit 1; }

command -v tmux   >/dev/null || { echo "tmux requis (sudo apt install tmux / brew install tmux)"; exit 1; }
command -v claude >/dev/null || { echo "Claude Code requis : npm install -g @anthropic-ai/claude-code"; exit 1; }

ROOT=$(git rev-parse --show-toplevel)
REPO=$(basename "$ROOT")
WT_DIR="$(dirname "$ROOT")/${REPO}-worktrees"
SESSION="agents-${REPO}"
BASE=$(git -C "$ROOT" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || echo main)

mkdir -p "$WT_DIR"
git -C "$ROOT" fetch --quiet origin "$BASE" 2>/dev/null || true

tmux has-session -t "$SESSION" 2>/dev/null || tmux new-session -d -s "$SESSION" -n control -c "$ROOT"

for name in "$@"; do
  path="$WT_DIR/$name"
  branch="agent/$name"
  if [[ ! -d "$path" ]]; then
    if git -C "$ROOT" show-ref --quiet "refs/heads/$branch"; then
      git -C "$ROOT" worktree add "$path" "$branch"
    else
      git -C "$ROOT" worktree add -b "$branch" "$path" "origin/$BASE" 2>/dev/null \
        || git -C "$ROOT" worktree add -b "$branch" "$path" "$BASE"
    fi
  fi
  # Copie le .env local (ignoré par git) pour que l'agent ait les mêmes variables.
  [[ -f "$ROOT/.env" && ! -f "$path/.env" ]] && cp "$ROOT/.env" "$path/.env"

  if [[ -n "$PROMPT" ]]; then
    cmd="claude $(printf '%q' "$PROMPT")"
  else
    cmd="claude"
  fi
  tmux new-window -t "$SESSION" -n "$name" -c "$path" "$cmd; exec \$SHELL"
  echo "✔ agent '$name' → $path (branche $branch)"
done

echo
echo "Attacher la session : tmux attach -t $SESSION   (Ctrl-b n / p pour changer d'agent)"
echo "Tout arrêter        : scripts/agents-down.sh"
