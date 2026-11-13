# T-032: stage-done, P2, evidence ledger, token usage

| Field | Value |
|---|---|
| id | T-032 |
| title | Deterministic stage closure with P2 approval and usage metrics |
| workflow | feature |
| stage | I-01 |
| role | orchestrator |
| status | done |
| hold | false |
| depends_on | T-031 |
| inputs | T-031 engine, `harness/process.md` |
| artifacts | `harness/scripts/stage-done.ps1`, `verify-stage.ps1`, `board-update.ps1`, `measure-tokens.ps1`, `harness-lib.ps1` |
| e2e | not applicable (harness tooling; fixture run) |
| ux | not applicable |
| chunks | stage-done, board-update, usage, fixture integration |
| budget | 8/20/60 (Markdown); 12/40/65 (code) |
| base_commit | - |
| usage | n/a |
| issues | - |
| commit | working tree |

## Acceptance

- [x] `stage-done.ps1` runs checks, writes the checks JSON and SHA256 ledger, renders the checkpoint, applies P2, updates board/card/activity, and makes snapshot + record commits.
- [x] `-DryRun`, `-NoCommit`, `-Force`, and CP-F `-AutoApprove` behave as specified; `hold: true` and MANUAL/FAIL/UNCHECKED force `awaiting_review`.
- [x] `verify-stage.ps1` forwards stage previews; `board-update.ps1` derives status from checkpoint files, supports `-SyncFields`, and guards active tasks.
- [x] `measure-tokens.ps1` feeds usage into the checkpoint, card, and board with invariant number formatting.
- [x] Fixture integration: CP-1 auto-approved and committed; CP-F awaited review, then explicit approval closed the task.
- [x] T-005 `-DryRun` renders the expected checkpoint and status.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | implementation | scripts | - | approved | - |
| CP-F | final acceptance | all task artifacts | - | approved | - |

## Blockers

- none

## Log

- 2026-11-13: stage-done, board-update, usage, and fixture integration completed; applied directly as harness core (board rule 7).
