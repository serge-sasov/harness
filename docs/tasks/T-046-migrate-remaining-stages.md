# T-046: Migrate the remaining ai-task-tracker stages to the UoW model

| Field | Value |
|---|---|
| id | T-046 |
| title | Migrate I-02, Q-01, Q-02 to the UoW model and close the decomposition rollout |
| workflow | feature |
| stage | implementation |
| role | orchestrator |
| status | done |
| hold | false |
| depends_on | T-045 |
| inputs | `docs/metrics/T-041-pilot.md`, `docs/metrics/T-045-pilot-architect.md`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-009-e2e-automation.md`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-010-e2e-plan.md`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-011-qa-acceptance.md` |
| artifacts | `C:/study/ai/research/ai-task-tracker/docs/chunks/T-009.json`, `C:/study/ai/research/ai-task-tracker/docs/chunks/T-010.json`, `C:/study/ai/research/ai-task-tracker/docs/chunks/T-011.json`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-009-*.md`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-010-*.md`, `C:/study/ai/research/ai-task-tracker/docs/tasks/T-011-*.md`, `C:/study/ai/research/ai-task-tracker/docs/plan.md` |
| e2e | not applicable (harness rollout) |
| ux | not applicable |
| chunks | A: chunk plans for I-02, Q-01, Q-02; B: card updates and briefs; C: board update and rollout closure note |
| budget | 8/20/60 (Markdown) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] `docs/chunks/T-009.json`, `T-010.json`, `T-011.json` exist and pass `chunk-validate.py`.
- [ ] I-02 is split into runner skeleton, dataset validator, UC batches, cleanup/isolation, and the final full run.
- [ ] Q-01 is split by UC batch for the coverage matrix plus one chunk for the execution approach.
- [ ] Q-02 is split into code/artifact review, e2e evidence per UC batch, and findings/verdict, and its chunks never read the whole `src` tree.
- [ ] The three cards reference their ledgers, and the board reflects the new plan with no status change other than the card metadata.
- [ ] A rollout closure note states which stages are covered by ledgers, which are legacy, and that `harness/version.json` is 3.0.0 in both the harness and ai-task-tracker.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | chunk plans and cards | three ledgers, three cards | n/a | approved | `docs/checkpoints/T-046-CP-1.md` |
| CP-F | final acceptance | all task artifacts | n/a | approved | `docs/checkpoints/T-046-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-046 (phase B, step 5).
- 2026-11-14: cards and ledgers for T-009 (7), T-010 (3), T-011 (4) created and valid; harness re-synced to 3.0.0 in ai-task-tracker; rollout closure note docs/metrics/T-046-rollout.md; CP-1 and CP-F approved (harness-core task: machine checks n/a).
