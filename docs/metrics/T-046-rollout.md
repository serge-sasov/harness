# T-046 rollout closure: recursive decomposition in ai-task-tracker

Date: 2026-11-14. Harness 3.0.0, project `C:/study/ai/research/ai-task-tracker`.

## Stage coverage

| Task | Stage | Ledger | Chunks | State |
|---|---|---|---|---|
| T-006 | R-01 | `docs/chunks/T-006.json` | 8 | 8 done (retrospective + replay) |
| T-007 | R-02 | `docs/chunks/T-007.json` | 13 | 13 done (retrospective + replay) |
| T-008 | I-01 | `docs/chunks/T-008.json` | 7 | 2 done (C4fix, C5a), 5 pending |
| T-009 | I-02 | `docs/chunks/T-009.json` | 7 | 0 done (planned) |
| T-010 | Q-01 | `docs/chunks/T-010.json` | 3 | 0 done (planned) |
| T-011 | Q-02 | `docs/chunks/T-011.json` | 4 | 0 done (planned) |

Legacy stages without a ledger: A-01 (T-002), A-02 (T-003), U-01 (T-004), U-02
(T-005), P-00 (T-001). They stay runnable: the chunk checks are
`NOT_APPLICABLE` for a task without a ledger.

## What changed in the project

- `harness/**` is 3.0.0: process rules with the UoW contract, `chunk.ps1`,
  `chunk-validate.py`, `chunk-ledger.md`, the `chunk-ledger` check type, depth-3
  install/doctor.
- Every active or planned stage from R-01 onward has a ledger; T-009..T-011 now
  have cards as well, so every board row has both.
- `docs/bugs/BUG-001` records a real contract defect found by the architect
  replay.
- `docs/issues/ISSUE-20261114-203800` records the two tool gaps found during the
  coder pilot (coverage against coarse globs, per-chunk usage attribution).

## Deviations

- Depth 3 was enabled in the global config but the host process enforced depth 2
  during the coder pilot (`ISSUE-20261114-193500`), so those chunks ran at depth
  1. The architect replays also ran at depth 0/1. The depth-3 path was verified
  separately in a fresh `opencode run` process (`DEPTH3_OK`).
- The T-006/T-007 plans are retrospective and use the observed artifact sizes in
  their budget objects; under the 3.0.0 defaults those artifacts would have been
  split.

## Rollout status

Complete for the harness (3.0.0 released) and for the ai-task-tracker pilot at
the plan level. The remaining work is ordinary task execution: T-008 chunks
C5b/C6a..C6d, then T-009..T-011, then T-008 `CP-F`.
