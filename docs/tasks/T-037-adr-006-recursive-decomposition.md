# T-037: ADR-006 recursive same-role decomposition

| Field | Value |
|---|---|
| id | T-037 |
| title | ADR-006: recursive same-role decomposition (unit of work, chunk ledger, depth 3) |
| workflow | feature |
| stage | R-01 |
| role | architect |
| status | pending |
| hold | false |
| depends_on | T-036 |
| inputs | `harness/process.md`, `harness/agents/harness-coder.md`, `harness/agents/harness-architect.md`, `harness/workflows/feature.md`, `harness/templates/task-card-feature.md`, `harness/scripts/check-budget.ps1`, `harness/scripts/stage-done.ps1`, `harness/scripts/measure-tokens.ps1`, `harness/checks/feature.json`, `harness/version.json`, `docs/architecture/adr-005-responsibility-zones.md` |
| artifacts | `docs/architecture/adr-006-recursive-decomposition.md`, `docs/architecture/adr-006-*.puml` + `.svg` (activity + component view of the decomposition model) |
| e2e | not applicable (harness rule and design decision) |
| ux | not applicable |
| chunks | A: context and decision (UoW model, depth policy, chunk fields); B: alternatives and consequences; C: diagrams (activity + component) and cross-references to `harness/process.md` sections 11.1/13 |
| budget | 8/20/60 (Markdown); 8/20/60 (PlantUML) |
| base_commit | c279af4 |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] ADR-006 exists at `docs/architecture/adr-006-recursive-decomposition.md` with `Context`, `Decision`, `Alternatives`, `Consequences`, and a `Contracts` section naming the scripts and artifacts it introduces.
- [ ] The unit-of-work (chunk) model is fully specified: node fields, state machine, ownership semantics, brief contract, return contract, and the parent/child relation.
- [ ] The depth policy is specified: d1 coordinator, d2 worker, d3 escalation; the exact condition that permits d3; the hard ceiling; and why the ceiling is not higher.
- [ ] The chunk ledger (`docs/chunks/T-XXX.json`) schema is specified field by field, including the budget object and the per-chunk usage accounting.
- [ ] The rule set that is uniform across roles is stated, and the per-role unit-of-work granularity table is included.
- [ ] The stop/resume contract is specified: what is persisted, what a cold session needs to continue, and which artifacts are machine-owned.
- [ ] Alternatives are compared (flat chunk list, deeper hierarchy, script-only budget enforcement, external scheduler) with the reason for rejection.
- [ ] Two PlantUML diagrams are authored and rendered to SVG next to the source: the decomposition activity flow and the component/artifact view.
- [ ] The ADR states the required changes to `harness/process.md` sections 0, 11.1, 13 and to `harness/scripts/install.ps1` / `doctor.ps1` so the implementation tasks (T-038..T-040) have a contract.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | R-01 solution design | ADR-006, diagrams | n/a | pending | `docs/checkpoints/T-037-CP-1.md` |
| CP-F | final acceptance | all task artifacts | n/a | pending | `docs/checkpoints/T-037-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-037 (phase A, step 1 of the recursive decomposition plan). Baseline for the decision: ai-task-tracker measured sessions (`harness` root chain of 16 compaction handoffs on T-008; `cr/in` from 10x to 64x per chunk; architect R-02 = 471089 in / 2395332 cr / 129 min in one session; ux-designer U-02 = 1046186 in in one session; coder chunk 1 of T-008 failed twice with an empty result).
