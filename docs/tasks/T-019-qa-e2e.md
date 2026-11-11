# T-019: QA e2e coverage, execution, and report

| Field | Value |
|---|---|
| id | T-019 |
| title | Independent e2e coverage verification and execution evidence |
| role | qa |
| status | done |
| depends_on | T-018 |
| inputs | `UC-E2E` use cases, YAML dataset, `tests/e2e/`, runner, contracts |
| artifacts | `docs/qa/e2e-plan-*.md`, `docs/qa/e2e-report-*.md`, `docs/qa/review-T-XXX.md` |
| e2e | required |
| ux | linked (visual review via qa-vision) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] QA prompt requires a requirement -> `UC-E2E-NNN` -> test coverage matrix.
- [x] QA validates dataset completeness and runs only the coder-provided runner.
- [x] Report includes pass/fail per use case, defects, traceability, and residual risks.
- [x] E2E runs only against local/staging with isolated/cleaned test data.
- [x] QA does not fix code/tests or weaken acceptance criteria.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | e2e plan + coverage | `docs/qa/e2e-plan-*` | n/a (direct update) | validated by T-022 |
| CP-2 | e2e report + verdict | `docs/qa/e2e-report-*`, review | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | all artifacts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: extended QA permissions/prompt and reporting contract for e2e.
