# T-043: Chunk checks in the verification registries

| Field | Value |
|---|---|
| id | T-043 |
| title | Chunk-level checks: chunk-ownership-no-overlap, chunk-coverage, chunk-budget |
| workflow | feature |
| stage | implementation |
| role | architect |
| status | done |
| hold | false |
| depends_on | T-041 |
| inputs | `harness/checks/engine.json`, `harness/checks/feature.json`, `harness/checks/bugfix.json`, `harness/scripts/verify-artifacts.ps1`, `harness/scripts/chunk-validate.py`, `docs/architecture/adr-006-recursive-decomposition.md` |
| artifacts | `harness/checks/feature.json`, `harness/checks/bugfix.json`, `harness/scripts/verify-artifacts.ps1`, `harness/scripts/chunk-validate.py` |
| e2e | not applicable (harness tooling) |
| ux | not applicable |
| chunks | A: new check type in the engine + self-tests; B: stage mapping in `feature.json` and `bugfix.json`; C: documentation of the check ids and their failure messages |
| budget | 12/40/65 (code); 8/20/60 (Markdown) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] The engine gains a check type that delegates to the chunk ledger validator, with at least five self-test cases: valid ledger, `owns` overlap, uncovered declared artifact, budget overrun, missing ledger.
- [ ] `chunk-ownership-no-overlap` is mapped to every stage that produces artifacts on more than one file or role (R-01, R-02, I-01, I-02, A-02, U-02, Q-01, Q-02) and to the bugfix stages that produce code and tests.
- [ ] `chunk-coverage` fails when a chunk declares an output that is not inside its `owns` set, or when the union of `owns` does not cover the artifacts the card declares for that stage.
- [ ] `chunk-budget` fails when a chunk produced more than `max_write_kb` in a single file or more than `max_session_kb` in one session, using the ledger's recorded sizes.
- [ ] A task without a ledger is `NOT_APPLICABLE` (legacy cards stay runnable), never `FAIL`.
- [ ] The new checks are documented in the check-id list used by `verify-stage.ps1` and in the role prompts' verification sections.
- [ ] A regression run over the existing harness repository and over ai-task-tracker produces no new `FAIL` on tasks that predate the ledger.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | engine and registry | engine, registries, validator | n/a | approved | `docs/checkpoints/T-043-CP-1.md` |
| CP-F | final acceptance | all task artifacts | n/a | approved | `docs/checkpoints/T-043-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-043 (phase B, step 2).
- 2026-11-14: check type chunk-ledger (ownership/coverage/budget) added with 5 self-tests; check ids registered in feature (A-01..D-01) and bugfix (B-00..B-04); T-008/I-01 PASS, legacy T-007/R-02 and T-036/R-01 N/A; CP-1 and CP-F approved (harness-core task: machine checks n/a).
