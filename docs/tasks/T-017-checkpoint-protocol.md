# T-017: Checkpoint protocol and `awaiting_review` status

| Field | Value |
|---|---|
| id | T-017 |
| title | User review checkpoints with resumable task runs |
| role | orchestrator |
| status | done |
| depends_on | T-014 |
| inputs | `docs/architecture/contracts-e2e-ux-checkpoints.md`, `harness/process.md` |
| artifacts | `harness/process.md`, `harness/templates/checkpoint.md`, `harness/templates/task-card.md`, `harness/commands/harness-run.md` |
| e2e | not applicable (process) |
| ux | applicable (UX checkpoints) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Status `awaiting_review` and its color are defined in process/templates/scripts.
- [x] At most one active task (`in_progress` or `awaiting_review`).
- [x] Checkpoint file records artifacts, snapshot commit, remarks, edits, and decision.
- [x] `CP-F` is mandatory before `done`; silence is not approval.
- [x] `/harness-run` resumes from `awaiting_review`; user edits are authoritative.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | protocol + templates | process, checkpoint template, card, command | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | all artifacts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: rewrote the lifecycle/checkpoint sections and updated lead/orchestrator prompts.
