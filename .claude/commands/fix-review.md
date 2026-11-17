---
description: (Builder) Corrige une PR à partir du rapport du reviewer
argument-hint: "<numéro de PR>"
---

1. `gh pr view $ARGUMENTS --comments` : récupère le dernier rapport du reviewer.
2. `gh pr checkout $ARGUMENTS`.
3. Corrige tous les points 🔴 et 🟠. Pour les 🟢, applique seulement ceux qui sont rapides et sans risque.
   Si tu n'es pas d'accord avec un point, ne le corrige pas : explique pourquoi dans ta réponse.
4. `ruff check . && pytest -q`, puis commit `fix: address review` et push.
5. Retire le label pour déclencher une nouvelle relecture :
   `gh pr edit $ARGUMENTS --remove-label changes-requested --remove-label reviewed`
6. Commente la PR avec la liste de ce qui a été corrigé, et de ce qui ne l'a pas été (avec la raison).
