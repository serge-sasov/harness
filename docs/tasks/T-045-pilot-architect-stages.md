# T-045: Pilot the UoW model on the architect stages

| Field | Value |
|---|---|
| id | T-045 |
| title | Second pilot: R-01 and R-02 in ai-task-tracker under the UoW model |
| workflow | feature |
| stage | implementation |
| role | architect |
| status | pending |
| hold | true |
| depends_on | T-041, T-042, T-043 |
| inputs | `docs/metrics/T-041-pilot.md`, `C:/study/ai/research/ai-task-tracker/docs/architecture/architecture-ai-task-tracker.md`, `C:/study/ai/research/ai-task-tracker/docs/architecture/adr-ai-task-tracker.md`, `C:/study/ai/research/ai-task-tracker/docs/architecture/contracts-ai-task-tracker.md`, `C:/study/ai/research/ai-task-tracker/docs/architecture/openapi-api-*.yaml` |
| artifacts | `C:/study/ai/research/ai-task-tracker/docs/chunks/T-006.json`, `C:/study/ai/research/ai-task-tracker/docs/chunks/T-007.json`, `C:/study/ai/research/ai-task-tracker/docs/chunks/T-006/*.brief.md`, `C:/study/ai/research/ai-task-tracker/docs/chunks/T-007/*.brief.md`, `C:/study/ai/research/ai-task-tracker/docs/architecture/**` (only if a re-run is requested), `docs/metrics/T-045-pilot-architect.md` |
| e2e | not applicable (harness pilot) |
| ux | not applicable |
| chunks | A: derive the chunk plan for R-01 and R-02 from the completed work and verify it would have covered the artifacts; B: replay two architect chunks under the model and measure; C: record the comparison and the verdict |
| budget | 8/20/60 (Markdown) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] `docs/chunks/T-006.json` and `docs/chunks/T-007.json` exist and pass `chunk-validate.py`.
- [ ] The R-01 plan has one chunk per ADR, per contracts half, per architecture-description section group, and per diagram set (component plus at most three sequence diagrams), and the union of `owns` covers every artifact of T-006.
- [ ] The R-02 plan has one chunk per OpenAPI specification and one per model diagram group, and the union of `owns` covers every artifact of T-007.
- [ ] Two architect chunks are replayed under the model and measured.
- [ ] `docs/metrics/T-045-pilot-architect.md` compares the new chunks with the recorded baseline (R-01 chunk b: `in=202573`, `cr=1467126`, 68.7 min, one 22.9 KB file over budget; R-01 2.6.0: `in=402036`, `cr=1641389`, 123.5 min; R-02: `in=471089`, `cr=2395332`, 129.2 min) and states whether `cr/in <= 15x` was reached.
- [ ] Any adjustment to the ADR-006 per-role granularity is recorded as an ADR amendment and applied to `harness/process.md`.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | chunk plans | `T-006.json`, `T-007.json`, briefs | n/a | pending | `docs/checkpoints/T-045-CP-1.md` |
| CP-2 | replay and metrics | replayed chunks, metrics file | n/a | pending | `docs/checkpoints/T-045-CP-2.md` |
| CP-F | final acceptance | all task artifacts | n/a | pending | `docs/checkpoints/T-045-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-045 (phase B, step 4). `hold: true`: the architect is the role with the largest measured overshoot, so the replay must be reviewed by the user.
