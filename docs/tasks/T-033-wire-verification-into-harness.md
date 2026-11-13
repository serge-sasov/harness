# T-033: Wire verification into process, roles, and docs

| Field | Value |
|---|---|
| id | T-033 |
| title | Process 2.5.0: deterministic checks, P2, stage-done, usage |
| workflow | feature |
| stage | D-01 |
| role | orchestrator |
| status | done |
| hold | false |
| depends_on | T-032 |
| inputs | T-032 scripts, existing process/templates/agents |
| artifacts | `harness/process.md`, templates, workflows, agents, commands, skill, README, guide |
| e2e | not applicable (documentation and prompt wiring) |
| ux | not applicable |
| chunks | process, templates/workflows, agents/commands, README/guide |
| budget | 8/20/60 (Markdown) |
| base_commit | - |
| usage | n/a |
| issues | - |
| commit | working tree |

## Acceptance

- [x] `process.md` defines deterministic verification, script-owned machine fields, P2, evidence ledger, usage, and stage-done flow.
- [x] Checkpoint, task-card, and plan-row templates carry `Checks`, `Usage`, `hold`, `base_commit`, and commit semantics.
- [x] Feature/bugfix workflows list check IDs and universal checks.
- [x] Lead/orchestrator allow the five harness scripts; all role prompts have verification/evidence sections.
- [x] `harness-run`, `harness-board-update`, and `harness-stage-done` commands and the harness skill describe the 2.5.0 flow.
- [x] README and global guide document commands, checks/evidence/metrics, P2, and troubleshooting.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | documentation | process/templates/roles | - | approved | - |
| CP-F | final acceptance | all task artifacts | - | approved | - |

## Blockers

- none

## Log

- 2026-11-13: process, templates, workflows, agents, commands, skill, README, and guide updated; applied directly as harness core (board rule 7).
