# T-040: Unit-of-work contract in the pilot role prompts and process rules

| Field | Value |
|---|---|
| id | T-040 |
| title | UoW contract for harness-coder and harness-architect; process.md depth-3 rules |
| workflow | feature |
| stage | implementation |
| role | architect |
| status | pending |
| hold | false |
| depends_on | T-037, T-038, T-039 |
| inputs | `docs/architecture/adr-006-recursive-decomposition.md`, `harness/process.md`, `harness/agents/harness-coder.md`, `harness/agents/harness-architect.md`, `harness/workflows/feature.md` |
| artifacts | `harness/agents/harness-coder.md`, `harness/agents/harness-architect.md`, `harness/process.md`, `harness/workflows/feature.md`, `harness/skills/harness/SKILL.md` |
| e2e | not applicable (harness rules) |
| ux | not applicable |
| chunks | A: process.md sections 0, 11.1, 13 (depth policy, chunk contract, prohibitions); B: harness-coder prompt (plan-first, brief, d2/d3, handoff, ownership); C: harness-architect prompt and workflow rows; D: skill sync |
| budget | 8/20/60 (Markdown) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] `harness/process.md` section 0 permits a same-role chain of three subagent levels for decomposed chunks and states that the single cross-role exception (`ux-designer -> harness-coder`) stays at depth 2.
- [ ] `harness/process.md` section 11.1 replaces the "depth 3 forbidden" rule with the explicit d1/d2/d3 contract: who may spawn whom, the budget, the ownership rule, the return contract, and the prohibition on parallel children.
- [ ] `harness/process.md` section 13 removes the blanket depth-3 prohibition and keeps the prohibitions that still apply (cross-role calls, parallel children, hand-editing machine fields).
- [ ] The coder prompt requires the first action of a stage to be writing the chunk plan into `docs/chunks/T-XXX.json` (via `chunk.ps1`), not writing code.
- [ ] The coder prompt defines the chunk brief fields, the `owns` rule, the d3 escalation condition, and the obligation to write a handoff note instead of continuing through compaction.
- [ ] The architect prompt carries the same UoW contract with its own granularity (one ADR, one description section, one diagram set, one OpenAPI spec per chunk).
- [ ] `harness/workflows/feature.md` and `harness/skills/harness/SKILL.md` describe the chunk plan as part of the task package and the d3 escalation.
- [ ] The wording is consistent across process, both role prompts, the workflow, and the skill (same field names, same state names, same depth names).

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | rules and pilot prompts | process.md, coder/architect prompts | n/a | pending | `docs/checkpoints/T-040-CP-1.md` |
| CP-F | final acceptance | all task artifacts | n/a | pending | `docs/checkpoints/T-040-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-040 (phase A, step 4). Applies the ADR-006 contract to the two pilot roles only; the other five roles are T-042.
