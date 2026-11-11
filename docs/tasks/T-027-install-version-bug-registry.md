# T-027: Harness 2.2.0 installation and bug registry

| Field | Value |
|---|---|
| id | T-027 |
| title | Ship version 2.2.0 with workflows, new commands/templates, and docs/bugs |
| workflow | feature |
| stage | F-01 |
| role | orchestrator |
| status | done |
| depends_on | T-026 |
| inputs | version 2.2.0 sources, global installation scripts |
| artifacts | `harness/version.json`, `harness/scripts/`, `docs/bugs/README.md` |
| e2e | not applicable (tooling) |
| ux | not applicable (tooling) |
| issues | ISSUE-20261111-100017 (RAG sync lock) |
| commit | working tree (direct developer update) |

## Acceptance

- [x] `version.json` is `2.2.0` with workflows, both new commands, and all agents/skills.
- [x] `install.ps1` installs workflows, commands, and templates.
- [x] `init.ps1` copies workflows/templates and creates `docs/bugs/` with an index.
- [x] `doctor.ps1` verifies workflows, new templates/commands, and bug registry.
- [x] Initialized board uses the 9-column schema.
- [x] Script syntax parses under Windows PowerShell 5.1.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | scripts/version | install/init/doctor/version | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | scripts/version + bug registry | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: bumped version, updated scripts, and added the product bug registry skeleton.
