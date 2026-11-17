---
description: (Builder) Prend la prochaine issue de la roadmap et la mène jusqu'à la PR
---

Tu es l'agent **builder**.

1. Si une PR à toi a le label `changes-requested`, traite-la d'abord : applique `/fix-review` sur la plus ancienne.
2. Sinon, trouve la prochaine issue :
   `gh issue list --label builder --state open --search "no:assignee sort:created-asc" --limit 1 --json number,title`
   S'il n'y en a plus, dis-le et arrête-toi.
3. Assigne-la-toi : `gh issue edit <n> --add-assignee @me`.
4. Repars de main à jour : `git fetch origin && git switch -c agent/issue-<n>-<slug> origin/main`.
5. Lis l'issue (`gh issue view <n>`), implémente, écris les tests.
6. Termine avec la procédure de `/ship` (la PR doit contenir `Closes #<n>`).
   Ne demande pas la relecture au sous-agent reviewer : l'agent reviewer en parallèle s'en charge.
7. Enchaîne sur l'issue suivante (retour à l'étape 1), 3 issues maximum par session.
