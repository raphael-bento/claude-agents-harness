---
description: Termine une tâche proprement - tests, review, commit, PR
argument-hint: "[titre de la PR]"
---

Termine la tâche en cours, dans cet ordre, en t'arrêtant au premier problème :

1. Vérifie qu'on n'est pas sur `main` (sinon crée une branche `agent/<sujet>`).
2. `ruff check . && pytest -q`. Si ça échoue, corrige puis relance.
3. Fais relire par le sous-agent `reviewer`. S'il y a du 🔴 Bloquant, corrige et refais relire (2 tours max).
4. Commit en Conventional Commits.
5. `git push -u origin HEAD` puis `gh pr create --fill` (titre : $ARGUMENTS si fourni).
   Colle le rapport du reviewer dans la description de la PR.
6. Donne-moi le lien de la PR.
