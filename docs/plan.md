# Plan (board)

Process rules: `harness/process.md`.
Workflows: `harness/workflows/feature.md`, `harness/workflows/bugfix.md`.
Derived diagram: `docs/activity.puml` is informational only; re-render it from this
board after every task (process section 9). Never use it to determine status,
dependencies, the active task, acceptance, checkpoint decisions, or routing.

## Status legend

| Status | Diagram color | Meaning |
|---|---|---|
| `pending` | gray `#D3D3D3` | not started |
| `in_progress` | yellow `#FFE082` | in progress |
| `awaiting_review` | blue `#87CEFA` | waiting for user checkpoint review |
| `done` | green `#90EE90` | completed, `CP-F` approved |
| `failed` | red `#FF9090` | error, fix required |
| `blocked` | orange `#FFB347` | external blocker |

At most one task is active (`in_progress` or `awaiting_review`) across both workflows.
This board and the task cards/checkpoints are authoritative; activity colors are
derived visualizations only.

## Board

| ID | Workflow | Task | Role | Dependencies | Status | Bug | Artifacts | Usage | Commit |
|---|---|---|---|---|---|---|---|---|---|
| T-001 | feature | Git bootstrap: `git init`, `.gitignore`, README | orchestrator | - | done | - | `.gitignore`, `README.md` | - | 2a19b33 |
| T-002 | feature | Unified process rules | orchestrator | T-001 | done | - | `harness/process.md` | - | 9d713d8 |
| T-003 | feature | Board + task cards | orchestrator | T-002 | done | - | `docs/plan.md`, `docs/tasks/` | - | c621012 |
| T-004 | feature | Activity diagram + SVG render | orchestrator | T-003 | done | - | `docs/activity.puml`, `docs/activity.svg` | - | 1ede40d |
| T-005 | feature | Artifact templates | orchestrator | T-002 | done | - | `harness/templates/` | - | see T-006 |
| T-006 | feature | Sub-agent `analyst` | analyst | T-005 | done | - | `harness/agents/analyst.md` | - | 9ad3ec9 |
| T-007 | feature | Sub-agent `architect` | architect | T-005 | done | - | `harness/agents/architect.md` | - | 061f8e5 |
| T-008 | feature | Sub-agent `coder` | coder | T-005 | done | - | `harness/agents/coder.md` | - | e4a4686 |
| T-009 | feature | Sub-agent `qa` | qa | T-005 | done | - | `harness/agents/qa.md` | - | 95b3949 |
| T-010 | feature | Sub-agent `doc-writer` | doc-writer | T-005 | done | - | `harness/agents/doc-writer.md` | - | 876e943 |
| T-011 | feature | Sub-agent `orchestrator` | orchestrator | T-005 | done | - | `harness/agents/orchestrator.md` | - | e021349 |
| T-012 | feature | opencode commands | orchestrator | T-006..T-011 | done | - | `harness/commands/harness-*.md` | - | cbf393f |
| T-013 | feature | Full-cycle smoke test | qa | T-012 | done | - | `docs/analysis/`, `docs/architecture/`, `docs/qa/` | - | fb145b6 |
| T-014 | feature | ADR-002 + contracts for e2e/UX/checkpoints | architect | T-013 | done | - | `docs/architecture/adr-002-*.md`, `contracts-e2e-ux-checkpoints.md` | - | working tree |
| T-015 | feature | Analyst e2e use cases + YAML dataset | analyst | T-014 | done | - | `docs/analysis/e2e-*` templates/rules | - | working tree |
| T-016 | feature | UX-Designer role + artifacts | ux-designer | T-014 | done | - | `harness/agents/harness-ux-designer.md`, `docs/ux/` rules | - | working tree |
| T-017 | feature | Checkpoint protocol + board status | orchestrator | T-014 | done | - | `process.md`, `docs/checkpoints/`, plan/templates | - | working tree |
| T-018 | feature | Coder e2e automation | coder | T-015, T-016 | done | - | `tests/e2e/`, `scripts/e2e.ps1`, validator rules | - | working tree |
| T-019 | feature | QA e2e coverage/run/report | qa | T-018 | done | - | `docs/qa/e2e-plan-*`, `e2e-report-*`, review | - | working tree |
| T-020 | feature | Install/version/docs integration | orchestrator | T-016, T-017 | done | - | `install/init/doctor`, `version.json`, README/guide | - | working tree |
| T-021 | feature | Description, diagrams, HTML, activity | architect | T-020 | done | - | `docs/description/`, `docs/activity.*` | - | working tree |
| T-023 | feature | ADR-003 + contracts for feature/bugfix workflows | architect | T-021 | done | - | `docs/architecture/adr-003-*.md`, `contracts-workflows-bugfix.md` | - | working tree |
| T-024 | feature | Split process into shared rules + workflow files | orchestrator | T-023 | done | - | `harness/process.md`, `harness/workflows/` | - | working tree |
| T-025 | feature | Workflow/bug templates and 9-column board schema | orchestrator | T-024 | done | - | `task-card-feature/bugfix`, `bug-card`, `plan-row`, `checkpoint` | - | working tree |
| T-026 | feature | Commands, lead/orchestrator, role prompts, skill | orchestrator | T-025 | done | - | `harness/commands/`, `harness/agents/`, `skills/harness/SKILL.md` | - | working tree |
| T-027 | feature | Version 2.2.0, init/install/doctor, bug registry | orchestrator | T-026 | done | - | `harness/scripts/`, `version.json`, `docs/bugs/` | - | working tree |
| T-028 | feature | Update README, guide, and description for workflows | doc-writer | T-027 | done | - | `README.md`, `docs/guides/harness-global.md`, `docs/description/README.md` | - | working tree |
| T-029 | feature | Bugfix/feature diagrams, activity, HTML rebuild | architect | T-028 | done | - | `docs/description/diagrams/`, `index.html`, `docs/activity.*`, `docs/qa/vision-review-T-029.md` | - | working tree |
| T-030 | feature | Harness 2.3.0: budgets, chunking, self-sub-sessions | orchestrator | T-029 | awaiting_review | - | `harness/process.md`, agents/templates, install/doctor, validators | - | working tree |
| T-031 | feature | Deterministic verification engine + checks registry | orchestrator | T-030 | done | - | `harness/scripts/verify-artifacts.ps1`, `harness/checks/` | - | working tree |
| T-032 | feature | stage-done, P2, evidence ledger, token usage | orchestrator | T-031 | done | - | `harness/scripts/stage-done.ps1`, `verify-stage.ps1`, `board-update.ps1`, `measure-tokens.ps1` | - | working tree |
| T-033 | feature | Process/templates/roles/commands 2.5.0 wiring | orchestrator | T-032 | done | - | `harness/process.md`, templates/workflows/agents/commands, README, guide | - | working tree |
| T-034 | feature | Release 2.5.0: install/init/doctor, pilot sync | orchestrator | T-033 | done | - | `install/init/doctor`, `version.json`, global install, ai-task-tracker | - | working tree |
| T-035 | feature | Release 2.7.0: architect stages R-01 design / R-02 interfaces+data model | architect | T-034 | done | - | `harness/checks/feature.json`, `workflows/feature.md`, `harness-architect.md`, `process.md`, templates, `docs/architecture/adr-004-*.md`, docs, `version.json`, global install | - | working tree |
| T-036 | feature | Release 2.8.0: architect responsibility zones (component -> module -> class) | architect | T-035 | done | - | `harness-architect.md`, `process.md`, `workflows/feature.md`, templates, `harness/checks/feature.json`, `verify-artifacts.ps1`, `docs/architecture/adr-005-*.md`, docs, `version.json`, global install | - | bfc9c25 |
| T-037 | feature | ADR-006: recursive same-role decomposition (UoW, chunk ledger, depth 3) | architect | T-036 | pending | - | `docs/architecture/adr-006-*.md`, `docs/architecture/adr-006-*.puml/.svg` | - | - |
| T-038 | feature | Chunk ledger + `chunk.ps1` + `chunk-validate.py` + stage-done/measure-tokens integration | coder | T-037 | pending | - | `harness/scripts/chunk.ps1`, `chunk-validate.py`, `stage-done.ps1`, `measure-tokens.ps1`, `harness/templates/chunk-ledger.md` | - | - |
| T-039 | feature | Depth 3: `subagent_depth: 3` in install/doctor/uninstall + smoke test | orchestrator | T-037 | pending | - | `harness/scripts/install.ps1`, `doctor.ps1`, `uninstall.ps1`, global install | - | - |
| T-040 | feature | UoW contract in `harness-coder`/`harness-architect` + `process.md` depth-3 rules | architect | T-037, T-038, T-039 | pending | - | `harness/agents/harness-coder.md`, `harness-architect.md`, `harness/process.md`, `workflows/feature.md`, skill | - | - |
| T-041 | feature | Pilot: sync harness into ai-task-tracker, re-plan and run T-008 chunks C4a..C6d | orchestrator | T-038, T-039, T-040 | pending | - | ai-task-tracker `harness/`, `docs/chunks/T-008.json`, `docs/metrics/T-041-pilot.md` | - | - |
| T-042 | feature | UoW contract for analyst, ux-designer, qa, doc-writer, orchestrator | architect | T-041 | pending | - | five role prompts, `harness.md`, `process.md`, skill | - | - |
| T-043 | feature | Chunk checks: `chunk-ownership-no-overlap`, `chunk-coverage`, `chunk-budget` | architect | T-041 | pending | - | `harness/checks/feature.json`, `bugfix.json`, `verify-artifacts.ps1` | - | - |
| T-044 | feature | Templates, docs, release 3.0.0 | doc-writer | T-042, T-043 | pending | - | templates, `README.md`, guide, `CHANGELOG.md`, `version.json`, docs rebuild | - | - |
| T-045 | feature | Second pilot: R-01/R-02 under the UoW model (ai-task-tracker) | architect | T-041, T-042, T-043 | pending | - | ai-task-tracker `docs/chunks/T-006.json`, `T-007.json`, `docs/metrics/T-045-pilot-architect.md` | - | - |
| T-046 | feature | Migrate I-02, Q-01, Q-02 to the UoW model and close the rollout | orchestrator | T-045 | pending | - | ai-task-tracker `docs/chunks/T-009..T-011.json`, cards, `docs/plan.md` | - | - |
| T-022 | feature | Harness 2.2.1 smoke test: feature + bugfix | qa | T-019, T-021, T-029 | pending | - | `docs/qa/smoke-2.2.1.md` | - | - |

## Board rules

1. Only the orchestrator changes status (or the role performing the task, on acceptance).
2. `done` only after all `acceptance` items in the card are met and `CP-F` is approved.
3. Record the commit hash after the task or checkpoint snapshot commit.
4. On `failed`, dependent tasks stay `pending`; record the cause in the card.
5. At most one task is active (`in_progress` or `awaiting_review`) across both workflows; parallel execution and preemption are forbidden.
6. Every task declares at least one checkpoint; `CP-F` is mandatory.
7. T-014..T-021 and T-023..T-027 were applied directly in the working tree (harness core is not role-writable); T-022 validates the shipped feature and bugfix flows in a pilot project.
