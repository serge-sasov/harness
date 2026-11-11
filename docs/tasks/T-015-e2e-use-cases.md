# T-015: Analyst e2e use cases and YAML dataset

| Field | Value |
|---|---|
| id | T-015 |
| title | Formalized e2e use cases as QA test data source |
| role | analyst |
| status | done |
| depends_on | T-014 |
| inputs | `docs/architecture/contracts-e2e-ux-checkpoints.md`, `harness/templates/e2e-use-case.md` |
| artifacts | `docs/analysis/e2e-use-cases-*.md`, `docs/analysis/e2e-test-data-*.yaml` (rules/templates) |
| e2e | required |
| ux | linked (screen IDs referenced when applicable) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Analyst prompt requires `UC-E2E-NNN` use cases with actor, flow, expected result, cleanup, and traceability.
- [x] Analyst prompt requires the YAML dataset with schema `harness-e2e/1` and no secrets.
- [x] Coverage rule: every functional requirement is covered or explicitly `out_of_scope`.
- [x] Templates `e2e-use-case.md` and `e2e-test-data.yaml` exist and match the contract.
- [x] Coder and QA prompts consume the same IDs and paths.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | e2e use cases + dataset | `docs/analysis/e2e-*` | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | all artifacts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: updated analyst role, added templates, and aligned coder/QA responsibilities.
