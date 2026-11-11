# T-018: Coder e2e automation from analyst data

| Field | Value |
|---|---|
| id | T-018 |
| title | Deterministic e2e tests, isolated runner, and dataset validator |
| role | coder |
| status | done |
| depends_on | T-015, T-016 |
| inputs | `docs/analysis/e2e-use-cases-*.md`, `docs/analysis/e2e-test-data-*.yaml`, `docs/ux/`, contracts |
| artifacts | `tests/e2e/`, `scripts/e2e.ps1` or `make e2e`, `scripts/validate-e2e-data.py` (rules) |
| e2e | required |
| ux | required (verify UX states where applicable) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Coder prompt consumes `UC-E2E-NNN` and the YAML dataset.
- [x] Prompt requires deterministic e2e tests with seed and cleanup.
- [x] Prompt requires a machine-readable runner result and a dataset validator.
- [x] Local/staging only; production resources are forbidden.
- [x] Assertions are not weakened to obtain a green run.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | implementation + unit tests | `src/`, `tests/` | n/a (direct update) | validated by T-022 |
| CP-2 | e2e automation + local run | `tests/e2e/`, `scripts/e2e*` | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | all artifacts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: extended coder responsibilities and run/report contract for e2e.
