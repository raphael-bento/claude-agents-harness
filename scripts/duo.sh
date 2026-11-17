#!/usr/bin/env bash
# Lance le duo : 1 agent builder + 1 agent reviewer, chacun dans son worktree, dans une session tmux.
#
#   scripts/duo.sh                          # les deux sur Sonnet (recommandé sur Pro)
#   BUILDER_MODEL=opus scripts/duo.sh       # builder sur Opus pour une tâche difficile
#
# Fenêtre "builder"  : session Claude interactive qui démarre avec /next (prend les issues `builder`).
# Fenêtre "reviewer" : boucle reviewer-watch.sh (relit chaque nouvelle PR, poste le rapport).
set -euo pipefail

BUILDER_MODEL=${BUILDER_MODEL:-sonnet}
REVIEWER_MODEL=${REVIEWER_MODEL:-sonnet}

for bin in tmux claude gh git; do
  command -v "$bin" >/dev/null || { echo "Outil manquant : $bin (voir README > Installation)"; exit 1; }
done

ROOT=$(git rev-parse --show-toplevel)
REPO=$(basename "$ROOT")
WT_DIR="$(dirname "$ROOT")/${REPO}-worktrees"
SESSION="duo-${REPO}"
mkdir -p "$WT_DIR"
git -C "$ROOT" fetch --quiet origin 2>/dev/null || true

for name in builder reviewer; do
  path="$WT_DIR/$name"
  if [[ ! -d "$path" ]]; then
    git -C "$ROOT" worktree add --detach "$path" origin/main 2>/dev/null \
      || git -C "$ROOT" worktree add --detach "$path" main
  fi
  [[ -f "$ROOT/.env" && ! -f "$path/.env" ]] && cp "$ROOT/.env" "$path/.env"
done

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session déjà lancée : tmux attach -t $SESSION"; exit 0
fi

tmux new-session -d -s "$SESSION" -n builder -c "$WT_DIR/builder" \
  "claude --model $BUILDER_MODEL /next; exec \$SHELL"
tmux new-window -t "$SESSION" -n reviewer -c "$WT_DIR/reviewer" \
  "REVIEWER_MODEL=$REVIEWER_MODEL \"$ROOT/scripts/reviewer-watch.sh\"; exec \$SHELL"

echo "✔ duo lancé (builder: $BUILDER_MODEL, reviewer: $REVIEWER_MODEL)"
echo "  tmux attach -t $SESSION      Ctrl-b n / Ctrl-b p pour passer d'un agent à l'autre"
echo "  Arrêt : tmux kill-session -t $SESSION"
