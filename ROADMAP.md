# Roadmap — claude-agents-harness

Objectif : faire tourner **2 agents Claude Code en parallèle** (un *builder* qui code, un *reviewer*
qui relit) sur un abonnement Pro, puis appliquer le setup à un vrai projet (finRAG) et en faire
une vitrine pour le CV.

Les tâches marquées `[builder]` deviennent des issues GitHub que l'agent builder prend tout seul
(`/next`). Les tâches `[human]` sont pour toi.
Pour créer les issues d'un coup : `python scripts/roadmap-to-issues.py --apply`.

```
 Phase 0        Phase 1          Phase 2          Phase 3             Phase 4
 Setup    ──►   Duo sur la  ──►  Boucle      ──►  Application   ──►   Vitrine CV
 (toi)          démo             GitHub           à finRAG
 ~1 h           semaine 1        semaine 2        semaines 3-4        semaine 5
```

---

## Phase 0 — Setup
- [ ] **[human]** Créer le repo GitHub vide claude-agents-harness — puis pousser le code du template
- [ ] **[human]** Installer Claude Code et se connecter avec le compte Pro — `npm install -g @anthropic-ai/claude-code` puis `claude`
- [ ] **[human]** Brancher GitHub Actions sur l'abonnement — `claude setup-token` puis `gh secret set CLAUDE_CODE_OAUTH_TOKEN`
- [ ] **[human]** Créer les labels et les issues — `python scripts/roadmap-to-issues.py --apply`
- [ ] **[human]** Faire un premier /review à la main sur la démo — vérifier que le sous-agent reviewer répond au bon format

**Terminé quand :** `claude` démarre dans le repo, `/review` produit un rapport, le secret est présent sur GitHub.

## Phase 1 — Duo builder + reviewer sur la démo
- [ ] **[builder]** Ajouter accuracy et matrice de confusion — dans `src/harness_demo/metrics.py`, avec tests paramétrés et cas limites (listes vides, une seule classe)
- [ ] **[builder]** Ajouter les métriques multi-classes — precision/recall/F1 en moyenne macro et micro, comparées à scikit-learn dans les tests
- [ ] **[builder]** Ajouter une CLI d'évaluation — `python -m harness_demo eval preds.csv` qui lit les colonnes y_true,y_pred et affiche les métriques
- [ ] **[human]** Lancer le duo et observer — `scripts/duo.sh`, puis noter le temps et la part du quota de 5 h consommée pour les 3 issues

**Terminé quand :** 3 PR mergées, chacune relue par le reviewer, CI verte.
**Point quota :** si la limite de 5 h tombe avant la fin, garder le builder sur Sonnet et découper les issues plus finement.

## Phase 2 — Boucle GitHub complète
- [ ] **[human]** Protéger la branche main — Settings → Branches : PR obligatoire + CI verte obligatoire
- [ ] **[builder]** Ajouter les badges CI et licence au README — et un fichier LICENSE MIT
- [ ] **[builder]** Créer un CHANGELOG — format Keep a Changelog, rempli à partir de l'historique git, via le sous-agent doc-writer
- [ ] **[human]** Tester @claude sur une PR — commenter `@claude corrige le point 🔴 du reviewer` et vérifier qu'il pousse un commit
- [ ] **[human]** Tester la review GitHub en secours — ajouter le label `claude-review` à une PR quand le PC est éteint

**Terminé quand :** une PR a fait le cycle complet builder → reviewer → correction → merge sans que tu touches au code.

## Phase 3 — Appliquer le harness à finRAG
- [ ] **[human]** Installer le harness dans finRAG — `scripts/install-harness.sh ../finRAG` puis adapter la section Stack de CLAUDE.md
- [ ] **[human]** Écrire 5 à 8 issues finRAG précises — une issue = une PR de moins de 300 lignes, avec critère d'acceptation
- [ ] **[builder]** Créer un sous-agent rag-evaluator — `.claude/agents/rag-evaluator.md` : évalue recall@k, MRR et fidélité des réponses sur un petit jeu de questions
- [ ] **[builder]** Ajouter un jeu d'évaluation finRAG — 20 à 30 questions/réponses de référence dans `eval/`, lancées par `pytest -m eval`
- [ ] **[human]** Passer à 3 agents si le quota tient — `scripts/agents-up.sh` avec un deuxième builder sur une issue indépendante

**Terminé quand :** finRAG a au moins 5 PR produites par le duo et une métrique d'évaluation suivie dans la CI.

## Phase 4 — Vitrine CV
- [ ] **[builder]** Ajouter un schéma d'architecture au README — diagramme Mermaid du flux builder / reviewer / CI / GitHub
- [ ] **[human]** Enregistrer une démo — GIF ou vidéo courte du duo dans tmux qui produit et relit une PR
- [ ] **[human]** Écrire le retour d'expérience — post LinkedIn ou article : setup, chiffres (PR, temps, quota), limites rencontrées
- [ ] **[human]** Épingler les deux repos sur le profil GitHub — et les ajouter au CV dans la section projets

**Terminé quand :** les repos sont épinglés, le README se comprend en 30 secondes, le post est publié.

---

## Règles du duo
- **Builder** : une issue à la fois, une branche par issue, PR de moins de 300 lignes. Il ne merge jamais lui-même.
- **Reviewer** : relit chaque PR ouverte et non relue, poste le rapport, pose le label `reviewed`.
  Si le verdict est ❌, il pose aussi `changes-requested` et le builder corrige via `/fix-review <PR>`.
- **Toi** : tu écris les issues, tu merges, tu tranches les désaccords.
- **Quota** : les deux agents tournent sur Sonnet par défaut. Opus seulement pour une tâche difficile (`BUILDER_MODEL=opus scripts/duo.sh`).
