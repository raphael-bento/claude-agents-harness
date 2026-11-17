---
description: Démarre une tâche à partir d'une issue GitHub
argument-hint: "<numéro d'issue>"
---

1. Lis l'issue : `gh issue view $ARGUMENTS`.
2. Crée la branche `agent/issue-$ARGUMENTS-<slug-court>`.
3. Propose un plan en 3 à 6 étapes et attends mon accord.
4. Une fois validé : implémente, puis enchaîne avec /ship (la PR doit contenir `Closes #$ARGUMENTS`).
