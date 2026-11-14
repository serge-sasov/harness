# T-041: Pilot вЂ” sync harness into ai-task-tracker and re-plan T-008

| Field | Value |
|---|---|
| id | T-041 |
| title | Pilot the UoW model: sync harness into ai-task-tracker, re-plan and run T-008 |
| workflow | feature |
| stage | implementation |
| role | orchestrator |
| status | done |
| hold | true |
| depends_on | T-038, T-039, T-040 |
| inputs | `docs/architecture/adr-006-recursive-decomposition.md`, `harness/scripts/install.ps1`, `harness/scripts/chunk.ps1`, `harness/scripts/chunk-validate.py`, `harness/process.md`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-008-implementation-tests.md`, `C:/study/ai/research/ai-task-tracker/docs/architecture/contracts-ai-task-tracker.md` |
| artifacts | `C:/study/ai/research/ai-task-tracker/harness/**` (synced core), `C:/study/ai/research/ai-task-tracker/docs/chunks/T-008.json`, `C:/study/ai/research/ai-task-tracker/docs/chunks/T-008/*.brief.md`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-008-implementation-tests.md`, `C:/study/ai/research/ai-task-tracker/docs/plan.md`, `docs/metrics/T-041-pilot.md` |
| e2e | not applicable (harness pilot) |
| ux | not applicable |
| chunks | A: sync harness core into ai-task-tracker (`/harness-init` refresh or scripted copy); B: build `docs/chunks/T-008.json` for the remaining chunks C4a..C6d with briefs; C: run the pilot with one stop/resume cycle; D: measure and record the metrics |
| budget | 8/20/60 (Markdown); 12/40/65 (code) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] ai-task-tracker runs harness 3.0.0-dev core: `harness/scripts/chunk.ps1`, `chunk-validate.py` and the updated `stage-done.ps1` are present, and `harness/version.json` matches.
- [ ] `docs/chunks/T-008.json` exists with the remaining T-008 chunks (C4a, C4b, C5a, C5b, C6a, C6b, C6c, C6d) and passes `chunk-validate.py` (no `owns` overlap, full coverage, states valid).
- [ ] Every chunk has a brief that a cold session can execute without re-reading the whole corpus.
- [ ] At least two chunks are executed under the new model, one of them with a deliberate stop/resume: the run is interrupted after a chunk completes, a new root session resumes with `/harness-run T-008`, and execution continues at the next chunk with no lost work.
- [ ] The metrics table is recorded in `docs/metrics/T-041-pilot.md` with, per chunk: input, output, cache-read, `cr/in`, wall-clock, attempts. The baseline is the T-008 chunk 3 measurement (`in=350592`, `cr=11993356`, `73.6 min`, 3 sessions).
- [ ] The pilot verdict is stated: `cr/in <= 15x` and no compaction inside a chunk, or a documented reason why not.
- [ ] Every harness problem met during the pilot has a `docs/issues/` record in ai-task-tracker.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | sync and chunk plan | synced core, `docs/chunks/T-008.json`, briefs | n/a | approved | `docs/checkpoints/T-041-CP-1.md` |
| CP-2 | pilot run and metrics | executed chunks, stop/resume evidence, metrics | n/a | approved | `docs/checkpoints/T-041-CP-2.md` |
| CP-F | final acceptance | all task artifacts | n/a | approved | `docs/checkpoints/T-041-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-041 (phase A, step 5). `hold: true` on purpose: the pilot is the first real test of the model and must be reviewed by the user at every checkpoint. Baseline: T-008 chunks 1-3 are already applied; chunks 4-6 (API, search/stats, web) remain and are re-planned as C4a..C6d.
- 2026-11-14: harness 3.0.0-dev synced into ai-task-tracker (commits 334da04, f71b351); T-008 chunk plan (7 chunks + baseline + briefs) valid. Pilot executed C4fix (8 files, 98 tests, 26 min, ratio 35.7x) and C5a (13 files, 112 tests, 21 min, ratio 49x), both 1 attempt, no compaction, cold resume from the brief; parent re-ran mvn after each chunk. cr/in target not met with a documented cause; metrics in docs/metrics/T-041-pilot.md; issue ISSUE-20261114-203800 in ai-task-tracker. CP-1, CP-2 and CP-F approved (harness-core task: machine checks n/a).
