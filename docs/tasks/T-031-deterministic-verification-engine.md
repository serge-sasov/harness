# T-031: Deterministic verification engine

| Field | Value |
|---|---|
| id | T-031 |
| title | Registry-driven artifact verification (verify-artifacts.ps1) |
| workflow | feature |
| stage | I-01 |
| role | orchestrator |
| status | done |
| hold | false |
| depends_on | T-030 |
| inputs | T-030 working tree, `harness/process.md` |
| artifacts | `harness/scripts/verify-artifacts.ps1`, `harness/checks/` |
| e2e | not applicable (harness tooling; validated on T-005 replay) |
| ux | not applicable |
| chunks | engine, registry, self-test, replay |
| budget | 8/20/60 (Markdown); 12/40/65 (code) |
| base_commit | - |
| usage | n/a |
| issues | - |
| commit | working tree |

## Acceptance

- [x] `verify-artifacts.ps1` runs universal + stage checks from `harness/checks/*.json` with `PASS/FAIL/MANUAL/NOT_APPLICABLE` results and `UNCHECKED` artifacts.
- [x] 21 check types implemented; registry covers 13 feature and 6 bugfix stages.
- [x] `-SelfTest` passes 13 negative cases and 2 sanity cases; config errors exit 2, failures exit 1.
- [x] T-005 CP-F replay yields 15 PASS, 0 FAIL, 1 MANUAL, 1 N/A, 0 UNCHECKED.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | implementation | engine, registry | - | approved | - |
| CP-F | final acceptance | all task artifacts | - | approved | - |

## Blockers

- none

## Log

- 2026-11-13: engine, registry, self-test, and T-005 replay completed; applied directly as harness core (board rule 7).
