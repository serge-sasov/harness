# T-022: Harness 2.2.1 smoke test: feature and bugfix workflows

| Field | Value |
|---|---|
| id | T-022 |
| title | End-to-end validation of feature/bugfix routing, checkpoints, and e2e flow |
| workflow | feature |
| stage | F-01 |
| role | qa |
| status | pending |
| depends_on | T-019, T-021, T-029 |
| inputs | harness 2.2.1, workflows, agents, templates, scripts, docs |
| artifacts | `docs/qa/smoke-2.2.1.md` |
| e2e | required (sample `UC-E2E` + runner) |
| ux | required (sample prototype + visual review) |
| issues | ISSUE-20261108-005859 (depth), ISSUE-20261108-170347 (QA context), ISSUE-20261111-100017 (RAG sync) |
| commit | - |

## Acceptance

- [ ] `/harness-doctor` reports no critical problems after global install.
- [ ] Doctor reliability checks pass: issue index matches all issue files, no root `harness-issues/`, role `**/` paths, compaction plugin, and model `num_ctx` vs `limit.context`; the local-rag timeout warning is reviewed.
- [ ] `install.ps1` adds a missing harness allow to an existing `permission.task` block in a test config copy and validates the JSON.
- [ ] After docs/diagram updates, `rag_sync` completes and `rag_status` advances; if not, ISSUE-20261111-100017 is updated.
- [ ] `/harness-feature` creates one pending `P-00` planning task and no active work.
- [ ] `/harness-bug` creates a `BUG-XXX` card and pending fix tasks without starting them.
- [ ] A sample feature task stops at `CP-1`, creates `docs/checkpoints/T-XXX-CP-1.md`, and becomes `awaiting_review`.
- [ ] A bugfix coder task cannot pass `CP-1` without reproduction and a failing regression test.
- [ ] QA independently verifies fail-before/pass-after for the bug; the bug moves `fixed` -> `verified` -> `closed`.
- [ ] A second task cannot start while one is `in_progress` or `awaiting_review`, including feature/bugfix overlap.
- [ ] User edits at a checkpoint are preserved after resume; `changes_requested` returns to the same checkpoint.
- [ ] After `CP-F` approval, the task becomes `done` and a final commit is made.
- [ ] Analyst/UX/e2e sample artifacts validate; QA maps every functional requirement to a use case/test.
- [ ] No production resources, secrets, or mixed bug/issue registries.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | smoke report draft | `docs/qa/smoke-2.2.1.md` | pending | `docs/checkpoints/T-022-CP-1.md` |
| CP-F | final acceptance | smoke report + verdict | pending | `docs/checkpoints/T-022-CP-F.md` |

## Blockers

- (none yet)

## Log

- 2026-11-11: card created for the 2.1.0 checkpoint flow.
- 2026-11-11: recorded ISSUE-20261111-100017 for the local-rag sync timeout during verification.
- 2026-11-11: retargeted to 2.2.0 feature and bugfix workflows.
- 2026-11-11: renamed from `T-022-smoke-test-2.1.0.md`; T-029 is done, so the smoke test is ready to start.
- 2026-11-11: retargeted to 2.2.1; added doctor reliability, issue-index, install repair, and RAG sync checks.
