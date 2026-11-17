# CLAUDE.md — règles communes à tous les agents

Ce fichier est lu par **chaque** session Claude Code (agent principal, sous-agents, GitHub Action).
C'est le "harness" partagé : si une règle doit s'appliquer à tous les agents, elle va ici.

## Langue
- Réponds en français. Code, noms de variables et messages de commit en anglais.

## Stack
- Python ≥ 3.10, code dans `src/`, tests dans `tests/`.
- Lint/format : `ruff check . && ruff format .`
- Tests : `pytest -q`
- Dépendances déclarées dans `pyproject.toml` uniquement (pas de `pip install` sauvage).

## Workflow Git (obligatoire)
1. Ne jamais travailler sur `main`. Une branche par tâche : `agent/<nom-agent>/<sujet-court>`.
2. Commits petits et atomiques, format Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).
3. Avant d'ouvrir une PR : `ruff check . && pytest -q` doivent passer.
4. Ouvrir la PR avec `gh pr create --fill` et le template `.github/pull_request_template.md`.
5. Jamais de `git push --force` sur une branche partagée, jamais de merge sur `main` sans review.

## Économie de quota (abonnement Pro)
- Lis seulement les fichiers nécessaires (Grep/Glob avant Read sur un gros repo).
- Pas de refactor non demandé. Pas de réécriture complète d'un fichier pour une petite modif.
- Délègue la relecture au sous-agent `reviewer` (modèle Sonnet), pas besoin d'Opus pour relire.
- Si une tâche est floue, pose UNE question plutôt que d'explorer tout le repo.

## Qualité
- Toute nouvelle fonction publique a une docstring et au moins un test.
- Pas de secrets dans le code. Les clés vont dans `.env` (ignoré par git).
- Data science : seeds fixées (`random_state=42`), pas de fuite de données entre train/test,
  pas de notebook commité sans sorties nettoyées.

## Agents disponibles (`.claude/agents/`)
| Agent | Rôle | Modèle |
|---|---|---|
| `reviewer` | Relit le diff, signale bugs/risques, ne modifie rien | sonnet |
| `tester` | Écrit et lance les tests manquants | sonnet |
| `data-scientist` | EDA, features, modèles, métriques | inherit |
| `doc-writer` | README, docstrings, changelog | haiku |
