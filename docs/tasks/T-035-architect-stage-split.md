# T-035: Architect feature work split into solution design (R-01) and interfaces/data model (R-02)

| Field | Value |
|---|---|
| id | T-035 |
| title | Version 2.7.0: architect stages R-01 design / R-02 interfaces + data model |
| workflow | feature |
| stage | R-01 / R-02 |
| role | architect |
| status | done |
| hold | false |
| depends_on | T-034 |
| inputs | `harness/agents/harness-architect.md`, `harness/workflows/feature.md`, `docs/plan.md`, `docs/analysis/requirements-*.md` |
| artifacts | `harness/checks/feature.json`, `harness/workflows/feature.md`, `harness-architect.md`, `harness-orchestrator.md`, `SKILL.md`, `harness/process.md`, templates, ADR-004, `docs/description/`, `docs/manual/README.md`, `README.md`, `harness-global.md`, `version.json`, global install |
| e2e | not applicable (harness workflow/checks update) |
| ux | not applicable |
| chunks | A-02a checks + docs, A-02b role/workflow, A-02c templates + ADR, A-02d version, A-02e global install |
| budget | 8/20/60 (Markdown); 12/40/65 (code) |
| base_commit | 3d2d73a feat: harness 2.6.0 architecture design package |
| usage | n/a |
| issues | - |
| commit | working tree |

## Acceptance

- [x] R-01 = Solution design: ADR, architecture description core, `SCN`/`SVC` IDs, component diagram + per-SCN sequence diagrams; `ADR-004` accepted; R-02 artifacts updated.
- [x] R-02 = Interfaces and data model: `contracts-*.md`, `API-NNN` IDs, OpenAPI 3.x specs, data/model/class diagrams, per-service swimlanes, full traceability; R-02 artifacts updated.
- [x] `architecture-description.md` template and `adr.md` template annotate R-01 vs R-02 sections.
- [x] checks registry: R-01 (adr, architecture, sequence, diagrams) + R-02 (architecture, contracts, data/class/API, OpenAPI, swimlane) + universal; new `contracts-requirement-trace` at R-02.
- [x] task-card-feature, workflows/feature, process, architect role, orchestrator note, SKILL.md, README, harness-global all updated to R-01/R-02 with diagram links.
- [x] version 2.7.0; global install + doctor pass.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | solution design | architecture-description core, ADR-004, component/sequence diagrams, checks registry, templates | n/a | approved | `docs/checkpoints/T-035-CP-1.md` |
| CP-2 | interfaces/data model | contracts, OpenAPI, data/class, swimlane docs, traceability, version, global install | n/a | approved | `docs/checkpoints/T-035-CP-2.md` |
| CP-F | final acceptance | all task artifacts | n/a | approved | `docs/checkpoints/T-035-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: ADR-004 accepted; R-01 Solution design (ADR, architecture description core, `SCN`/`SVC` IDs, component diagram + per-SCN sequence diagrams); R-02 Interfaces and data model (contracts, `API-NNN` IDs, OpenAPI 3.x specs, data/model/class diagrams, per-service swimlanes, full traceability); R-01/R-02 section ownership annotated in `architecture-description.md` and `adr.md` templates; checks registry updated (R-01/ADR, R-01/architecture core + sequence + diagrams, R-02/architecture all sections, R-02/contracts+API/OpenAPI+data/class, R-02/swimlane) plus universal and new `contracts-requirement-trace` at R-02; task-card feature/workflow/process/architect role/orchestrator note/SKILL/README/harness-global updated to R-01/R-02 with diagram links; version 2.7.0; global install and doctor passed.
