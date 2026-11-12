# T-XXX: Fix BUG-XXX - short title

| Field | Value |
|---|---|
| id | T-XXX |
| title | Full task title |
| workflow | bugfix |
| stage | B-01 / B-02 / B-03 / B-04 / B-05 |
| role | coder / qa / analyst / architect / ux-designer / doc-writer / orchestrator |
| status | pending |
| depends_on | T-YYY, T-ZZZ |
| bug | BUG-XXX |
| severity | P0 / P1 / P2 / P3 |
| profile | - / hotfix (P0/P1 only) |
| inputs | bug card, affected code/tests, requirements/UC |
| artifacts | regression test, code/tests, `docs/qa/review-T-XXX.md` |
| e2e | required / not applicable (reason) |
| ux | required / not applicable (reason) |
| chunks | planned chunks and ownership (for large reproduction/fix/test work) |
| budget | max_write_kb / max_session_kb / context_stop_pct (defaults: 8/20/60, code 12/40/65) |
| issues | ISSUE-... (links to docs/issues/ if problems occurred) |
| commit | commit hash after completion |

## Bug summary

- Observed:
- Expected:
- Reproduction:
- Root cause: (filled by coder at CP-1)

## Acceptance

- [ ] The regression test fails on the base revision.
- [ ] The root cause is documented.
- [ ] The minimal fix passes the regression test.
- [ ] Relevant existing tests pass.
- [ ] No unrelated behavior or files changed.
- [ ] QA verifies fail-before/pass-after independently.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | reproduction/root cause | failing test + card log | pending | `docs/checkpoints/T-XXX-CP-1.md` |
| CP-2 | fix/regression | code + tests | pending | `docs/checkpoints/T-XXX-CP-2.md` |
| CP-F | final acceptance | all task artifacts | pending | `docs/checkpoints/T-XXX-CP-F.md` |

Statuses: `pending`, `awaiting_review`, `approved`, `changes_requested`.

## Blockers

- (filled on status=failed|blocked: cause, output, what is needed to unblock)

## Log

- YYYY-MM-DD: reproduction evidence, root cause, fix, tests, checkpoint commits, user decisions.
