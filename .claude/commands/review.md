---
description: Fait relire le travail en cours (ou une PR) par le sous-agent reviewer
argument-hint: "[numéro de PR optionnel]"
---

Utilise le sous-agent `reviewer` pour relire le travail.

- Si un numéro de PR est fourni ($ARGUMENTS), relis `gh pr diff $ARGUMENTS`.
- Sinon, relis `git diff main...HEAD` plus les modifications non commitées.

Ensuite, affiche son rapport tel quel. Ne corrige rien tant que je ne l'ai pas demandé.
