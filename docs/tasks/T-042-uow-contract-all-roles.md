# T-042: UoW contract for the remaining five roles

| Field | Value |
|---|---|
| id | T-042 |
| title | Unit-of-work contract for analyst, ux-designer, qa, doc-writer, and orchestrator |
| workflow | feature |
| stage | implementation |
| role | architect |
| status | pending |
| hold | false |
| depends_on | T-041 |
| inputs | `docs/architecture/adr-006-recursive-decomposition.md`, `harness/process.md`, `harness/agents/harness-analyst.md`, `harness/agents/harness-ux-designer.md`, `harness/agents/harness-qa.md`, `harness/agents/harness-doc-writer.md`, `harness/agents/harness-orchestrator.md`, `docs/metrics/T-041-pilot.md` |
| artifacts | `harness/agents/harness-analyst.md`, `harness/agents/harness-ux-designer.md`, `harness/agents/harness-qa.md`, `harness/agents/harness-doc-writer.md`, `harness/agents/harness-orchestrator.md`, `harness/agents/harness.md`, `harness/process.md`, `harness/skills/harness/SKILL.md` |
| e2e | not applicable (harness rules) |
| ux | not applicable |
| chunks | A: analyst + qa (document-producing roles); B: ux-designer (own granularity + coder delegation interplay); C: doc-writer + orchestrator (ledger ownership, no self-delegation); D: lead prompt and skill sync |
| budget | 8/20/60 (Markdown) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] Each of the five roles states its unit-of-work granularity explicitly (analyst: use case + YAML entry; ux-designer: screen group / one wireframe / 1-2 prototype pages / one UI-spec section; qa: one review section / one UC batch; doc-writer: one guide section; orchestrator: no delegation, ledger owner).
- [ ] Each role states whether it may delegate: `harness-analyst` self-allow (depth 2/3), `harness-ux-designer` keeps the `harness-coder` cross-role allow at depth 2 and does not self-delegate, `harness-qa` and `harness-doc-writer` are allowed self-delegation at depth 2 only, `harness-orchestrator` never delegates and never runs role work.
- [ ] The orchestrator prompt makes it the owner of `docs/chunks/T-XXX.json`: it creates the chunk plan from the card, records attempts and results, and never lets a role hand-edit the machine fields.
- [ ] The lead prompt describes the chunk plan as part of the task package and the routing of a resumed chunk.
- [ ] `harness/process.md` contains the uniform rule set and the per-role granularity table, so no role-specific rule is duplicated inconsistently.
- [ ] `harness/skills/harness/SKILL.md` matches the process and the role prompts.
- [ ] The pilot metrics from T-041 are cited when the default granularity differs from the ADR-006 estimate.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | role contracts | five role prompts + process + skill | n/a | pending | `docs/checkpoints/T-042-CP-1.md` |
| CP-F | final acceptance | all task artifacts | n/a | pending | `docs/checkpoints/T-042-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-042 (phase B, step 1). Depends on the pilot so the default granularity is calibrated on measured data, not on estimates.
