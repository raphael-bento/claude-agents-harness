#!/usr/bin/env bash
# Agent reviewer en continu.
# Surveille les PR ouvertes avec `gh` (gratuit) et ne réveille Claude QUE quand une PR
# n'a pas encore été relue. Zéro quota consommé quand il n'y a rien à faire.
#
# Usage : scripts/reviewer-watch.sh            (intervalle par défaut : 120 s)
#         INTERVAL=300 REVIEWER_MODEL=sonnet scripts/reviewer-watch.sh
set -uo pipefail

INTERVAL=${INTERVAL:-120}
MODEL=${REVIEWER_MODEL:-sonnet}
ALLOWED='Read,Grep,Glob,Task,Agent,Bash(gh pr diff:*),Bash(gh pr view:*),Bash(gh pr comment:*),Bash(gh pr edit:*),Bash(gh pr checkout:*),Bash(git switch:*),Bash(git diff:*),Bash(git log:*),Bash(pytest:*),Bash(ruff:*)'

echo "👀 reviewer : surveillance des PR toutes les ${INTERVAL}s (modèle ${MODEL}). Ctrl-C pour arrêter."

while true; do
  prs=$(gh pr list --state open --search "draft:false -label:reviewed" --json number --jq '.[].number' 2>/dev/null)
  for pr in $prs; do
    echo "── $(date +%H:%M) relecture de la PR #$pr"
    # La consigne passe par stdin : --allowedTools accepte plusieurs valeurs et avalerait
    # une consigne passée en argument juste après lui.
    prompt="Tu es l'agent reviewer du duo. Relis la PR #$pr en utilisant le sous-agent \`reviewer\`
(méthode et format de .claude/agents/reviewer.md).
1. \`gh pr checkout $pr --detach\` pour pouvoir lancer ruff et pytest localement.
2. Poste le rapport complet avec \`gh pr comment $pr --body-file - <<'EOF'\` ... \`EOF\`.
3. Ajoute le label \`reviewed\`. Si le verdict est ❌ ou s'il y a au moins un 🔴,
   ajoute aussi le label \`changes-requested\` (\`gh pr edit $pr --add-label ...\`).
Ne modifie aucun fichier du code, ne merge pas."
    printf '%s\n' "$prompt" | claude -p --model "$MODEL" --max-turns 15 --allowedTools "$ALLOWED" \
      || echo "⚠️  échec sur la PR #$pr (voir le message ci-dessus) — nouvel essai au prochain tour"
    git switch --quiet --detach origin/main 2>/dev/null || true
  done
  sleep "$INTERVAL"
done
