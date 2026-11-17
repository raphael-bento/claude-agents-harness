#!/usr/bin/env python3
"""Transforme les tâches de ROADMAP.md en issues GitHub (et crée les labels nécessaires).

Format d'une tâche reconnue :
    - [ ] **[builder]** Titre — description

Usage :
    python scripts/roadmap-to-issues.py            # aperçu, ne crée rien
    python scripts/roadmap-to-issues.py --apply    # crée labels + issues (via gh)
    python scripts/roadmap-to-issues.py --apply --phase 1
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

PHASE_RE = re.compile(r"^## Phase (\d+) — (.+)$")
TASK_RE = re.compile(r"^- \[ \] \*\*\[(\w+)\]\*\* (.+?) — (.+)$")

LABELS = {
    "builder": ("0e8a16", "Tâche pour l'agent builder"),
    "human": ("fbca04", "Tâche pour toi"),
    "reviewed": ("c5def5", "Relue par l'agent reviewer"),
    "changes-requested": ("d93f0b", "Le reviewer demande des corrections"),
    "claude-review": ("7057ff", "Relancer la review Claude sur GitHub"),
}


@dataclass
class Task:
    phase: int
    phase_name: str
    owner: str
    title: str
    body: str


def parse_roadmap(text: str) -> list[Task]:
    """Extrait les tâches non cochées de la roadmap, avec leur phase."""
    tasks: list[Task] = []
    phase, phase_name = 0, ""
    for line in text.splitlines():
        if m := PHASE_RE.match(line.strip()):
            phase, phase_name = int(m.group(1)), m.group(2).strip()
        elif m := TASK_RE.match(line.strip()):
            owner, title, body = m.groups()
            tasks.append(Task(phase, phase_name, owner, title.strip(), body.strip()))
    return tasks


def gh(*args: str) -> str:
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout


def existing_issue_titles() -> set[str]:
    out = gh("issue", "list", "--state", "all", "--limit", "500", "--json", "title")
    return {i["title"] for i in json.loads(out)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--apply", action="store_true", help="crée réellement labels et issues")
    parser.add_argument("--phase", type=int, help="ne traiter qu'une phase")
    parser.add_argument("--roadmap", default=Path(__file__).parent.parent / "ROADMAP.md")
    args = parser.parse_args()

    tasks = parse_roadmap(Path(args.roadmap).read_text(encoding="utf-8"))
    if args.phase is not None:
        tasks = [t for t in tasks if t.phase == args.phase]
    else:
        # La phase 0 (setup) se fait avant que le repo existe : pas besoin d'issues.
        tasks = [t for t in tasks if t.phase > 0]

    if not args.apply:
        for t in tasks:
            print(f"[phase-{t.phase}] [{t.owner:7}] {t.title}")
        print(f"\n{len(tasks)} issues seraient créées. Relance avec --apply pour les créer.")
        return 0

    phases = {t.phase: t.phase_name for t in tasks}
    for name, (color, desc) in LABELS.items():
        gh("label", "create", name, "--color", color, "--description", desc, "--force")
    for num, pname in phases.items():
        gh(
            "label",
            "create",
            f"phase-{num}",
            "--color",
            "bfd4f2",
            "--description",
            pname,
            "--force",
        )

    already = existing_issue_titles()
    created = 0
    for t in tasks:
        if t.title in already:
            print(f"• existe déjà : {t.title}")
            continue
        body = f"{t.body}\n\n_Phase {t.phase} — {t.phase_name} (voir ROADMAP.md)_"
        url = gh(
            "issue",
            "create",
            "--title",
            t.title,
            "--body",
            body,
            "--label",
            t.owner,
            "--label",
            f"phase-{t.phase}",
        ).strip()
        print(f"✔ {url}  {t.title}")
        created += 1
    print(f"\n{created} issues créées.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
