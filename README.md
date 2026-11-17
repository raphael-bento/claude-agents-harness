# claude-agents-harness

Template pour travailler avec **plusieurs agents Claude Code en parallèle**, tous branchés sur
un **harness commun** versionné dans le repo, avec un **reviewer automatique** sur chaque Pull Request GitHub.

Pensé pour tourner sur un abonnement **Claude Pro** sans exploser le quota.

```
Toi ──► agents-up.sh ──► worktree A (agent/feature-a) ─┐
                    └──► worktree B (agent/feature-b) ─┼─► /ship ─► PR GitHub
                                                       │              │
              CLAUDE.md + .claude/ (règles communes) ──┘              ▼
                                                    CI (ruff + pytest) + Claude PR Review
                                                                      │
                                                     @claude pour corriger ◄──┘
```

## Contenu

| Élément | Rôle |
|---|---|
| `CLAUDE.md` | Règles communes lues par tous les agents (stack, workflow git, économie de quota) |
| `.claude/agents/reviewer.md` | Sous-agent **reviewer** (Sonnet, lecture seule) : bugs, sécurité, fuite de données, tests |
| `.claude/agents/tester.md` | Écrit et lance les tests manquants |
| `.claude/agents/data-scientist.md` | EDA, baselines, pipelines sklearn, évaluation honnête |
| `.claude/agents/doc-writer.md` | README / docstrings / changelog (Haiku, le moins cher) |
| `.claude/commands/` | Commandes `/review`, `/ship`, `/task <issue>` |
| `.claude/hooks/` | Formatage auto (ruff) après chaque édition + blocage si lint/tests cassés |
| `.claude/settings.json` | Permissions : autorise tests/lint/git local, demande avant push, interdit `.env` et `push --force` |
| `.github/workflows/claude-review.yml` | Review automatique de chaque PR par Claude |
| `.github/workflows/claude.yml` | `@claude` dans une issue ou une PR → il fait la tâche |
| `.github/workflows/ci.yml` | CI classique (gratuite) : ruff + pytest |
| `scripts/agents-up.sh` | Lance N agents en parallèle (1 worktree + 1 branche + 1 fenêtre tmux chacun) |
| `scripts/install-harness.sh` | Copie le harness dans un autre de tes repos |

## Installation (une fois)

```bash
# 1. Claude Code (connecte-toi avec ton compte Pro quand il le demande)
npm install -g @anthropic-ai/claude-code
claude

# 2. Outils
pip install -e ".[dev]"
sudo apt install tmux gh   # ou brew install tmux gh
gh auth login

# 3. Token pour GitHub Actions (utilise ton abonnement, pas de facturation API)
claude setup-token
gh secret set CLAUDE_CODE_OAUTH_TOKEN   # colle le token
gh label create claude-review --color 7057ff --description "Relancer la review Claude"
```

> ⚠️ Ne définis **pas** `ANTHROPIC_API_KEY` dans ton environnement : sinon Claude Code facture à l'usage via l'API au lieu d'utiliser ton abonnement.

## Mode duo : builder + reviewer (recommandé sur Pro)

```bash
python scripts/roadmap-to-issues.py --apply   # une fois : ROADMAP.md → issues GitHub
scripts/duo.sh                                # lance les 2 agents
tmux attach -t duo-claude-agents-harness
```

| Agent | Ce qu'il fait | Coût en quota |
|---|---|---|
| **builder** | `/next` : prend l'issue `builder` suivante, code, teste, ouvre la PR. Corrige avec `/fix-review` quand le reviewer demande des changements | Sonnet, seulement quand il travaille |
| **reviewer** | `reviewer-watch.sh` vérifie les PR toutes les 2 min avec `gh` (gratuit). Il réveille Claude seulement pour une PR pas encore relue, poste le rapport et pose `reviewed` / `changes-requested` | Nul tant qu'il n'y a pas de nouvelle PR |
| **toi** | Tu écris les issues, tu merges, tu tranches | — |

La feuille de route complète est dans [ROADMAP.md](ROADMAP.md).

## Utilisation au quotidien

**Une tâche, un agent :**
```bash
claude
> /task 12          # lit l'issue #12, crée la branche, propose un plan
> ...               # il implémente
> /review           # le sous-agent reviewer relit
> /ship             # tests → review → commit → PR
```

**Plusieurs agents en parallèle :**
```bash
scripts/agents-up.sh api-cleanup add-tests
tmux attach -t agents-claude-agents-harness     # Ctrl-b n / Ctrl-b p pour naviguer
scripts/agents-down.sh                           # nettoie ce qui est mergé
```

**Sur GitHub :**
- En mode duo, c'est l'agent reviewer local qui relit chaque PR.
- PC éteint ? Ajoute le label `claude-review` à la PR, et GitHub Actions fait la review à sa place.
- Écris `@claude corrige le point 🔴 du reviewer` en commentaire → il pousse le correctif.

## Pourquoi c'est optimisé pour un abonnement Pro

- **Bon modèle pour chaque rôle** : reviewer et tester sur Sonnet, docs sur Haiku. Opus seulement si tu le choisis pour la session principale.
- **Le reviewer ne consomme rien tant qu'il n'y a pas de nouvelle PR.** La surveillance passe par `gh`, et la review GitHub ne se lance que sur label.
- **Les hooks font le travail mécanique** (format, lint, tests) : ça ne consomme pas de quota.
- **`--max-turns`** borne chaque exécution dans GitHub Actions.
- **2 ou 3 agents en parallèle maximum sur Pro.** Le quota (sur 5 h et à la semaine) est partagé entre claude.ai, Claude Code et les Actions.

## Réutiliser sur un autre projet

```bash
scripts/install-harness.sh ../mon-projet-rag
```
Ensuite, adapte la section *Stack* de `CLAUDE.md`.
