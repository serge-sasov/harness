# T-026: Commands, lead/orchestrator, role prompts, and harness skill

| Field | Value |
|---|---|
| id | T-026 |
| title | Make every command, agent, and skill workflow-aware |
| workflow | feature |
| stage | P-00 / F-01 |
| role | orchestrator |
| status | done |
| depends_on | T-025 |
| inputs | ADR-003, workflow contracts, shared process, templates |
| artifacts | `harness/commands/`, `harness/agents/`, `harness/skills/harness/SKILL.md` |
| e2e | not applicable (process design) |
| ux | not applicable (process design) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] `/harness-feature` creates one pending `P-00` planning task; `/harness-bug` triages but never starts work.
- [x] `/harness-run` reads the workflow from the card and resumes either workflow.
- [x] Board commands understand workflow and bug queues; board update stays forbidden while active.
- [x] Lead and orchestrator enforce strict sequencing, bug ownership, and checkpoint gates.
- [x] All role prompts read the selected workflow; bugfix roles respect reproduction, regression, and read-only bug cards.
- [x] Harness skill documents commands, workflows, artifacts, and statuses.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | commands and roles | commands + agents + skill | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | commands + agents + skill | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: added workflow commands; updated lead, orchestrator, all role prompts, and the harness skill.
