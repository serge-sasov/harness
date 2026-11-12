# Feature Workflow (feature.md)

Shared rules: `harness/process.md`. This file defines the `feature` workflow for
new behavior and new projects. The project/feature scale is handled by
applicability and checkpoints, not by a third workflow.

## When to use

Use `workflow: feature` for:

- a new user-visible or programmatic capability;
- a new project or a new subsystem;
- a behavior change that requires requirements, design, or UX decisions;
- a bug fix that escalated because it changes a public contract, schema,
  security boundary, multiple modules, or a UI flow.

## Stage table

| ID | Stage | Content | Role | Artifacts | Depends on | Applicability | Checkpoint |
|---|---|---|---|---|---|---|---|
| P-00 | Feature planning | Fix scope, inputs, e2e/UX applicability, checkpoint list; create the task graph and cards | orchestrator | `docs/plan.md`, `docs/tasks/T-XXX-*.md` | Predecessor tasks | Always | CP-1 plan, CP-F |
| A-01 | Requirements analysis | Collect/refine FR/NFR, constraints, questions, glossary; atomic `R-NNN` | analyst | `docs/analysis/requirements-*.md`, `questions-*.md`, `glossary.md` | P-00 | Always | CP-1 |
| A-02 | E2E use cases and data | Derive e2e scenarios, assign `UC-E2E-NNN`, describe steps/data/expectations and traceability; produce YAML dataset in 2-3 UC chunks; one CP-2 after all chunks validate | analyst | `docs/analysis/e2e-use-cases-*.md`, `e2e-test-data-*.yaml` | A-01 | If e2e in scope; otherwise waiver | CP-2 |
| U-01 | UX flows and screens | Personas, journeys, information architecture, screen inventory, screen states | ux-designer | `docs/ux/user-flows-*.md`, `screens-*.md` (+ optional `.puml/.svg`) | A-01, A-02 | If UI in scope; otherwise waiver | CP-1 |
| U-02 | UX wireframes, prototype, UI spec | Salt wireframes, static HTML prototype with one page per `UC-E2E`, interaction/accessibility/UI copy, design tokens; coder may implement prototype pages | ux-designer (+ harness-coder) | `docs/ux/wireframes-*.puml/.svg`, `ui-spec-*.md`, `prototype/<slug>/index.html`, `prototype/<slug>/uc-e2e-*.html`, `prototype/<slug>/assets/*` | U-01 | If UI in scope | CP-2 |
| R-01 | Architecture and contracts | ADR with alternatives, API/formats/errors, module boundaries, decomposition | architect | `docs/architecture/adr-*.md`, `contracts-*.md` | A-01, A-02, U-02 | Always; UX input if UI | CP-1 |
| R-02 | Diagrams and handoff | Component/sequence diagrams, `check_syntax` + render, module handoff to coder | architect | `docs/architecture/*.puml`, `*.svg` | R-01 | Always | CP-2 |
| I-01 | Implementation and unit/integration tests | Code per ADR/contracts, tests, CI/CD, local run | coder | `src/`, `tests/`, `Dockerfile`, `docker-compose*.yml`, `Makefile` | R-02, U-02 | Always | CP-1 |
| I-02 | E2E automation | Tests from YAML, runner, data validator, isolated environment and cleanup; split by module/test group per process 11.1 | coder | `tests/e2e/`, `scripts/e2e.ps1`, `scripts/validate-e2e-data.py` | I-01, A-02, R-02 | If e2e in scope | CP-2 |
| Q-01 | E2E plan and coverage | Requirement -> UC -> test matrix, test data validation, execution approach | qa | `docs/qa/e2e-plan-*.md` | A-02, I-02 | If e2e in scope | CP-1 |
| Q-02 | QA and acceptance | Run tests/e2e, evidence, defects, text/code/vision review, final verdict | qa (+ qa-vision) | `docs/qa/e2e-report-*.md`, `docs/qa/review-T-XXX.md`, `vision-review-*` | Q-01, I-02, I-01, R-02, U-02 | Always; e2e part if in scope | CP-2 |
| D-01 | Documentation | README/runbook/guides, ADR finalization, document e2e/UX/checkpoint process | doc-writer | `README.md`, `docs/guides/*`, finalized ADRs | R-02, I-01, U-02, Q-02 | Per card | CP-1 |
| F-01 | Final acceptance and closure | Verify acceptance, update plan/card, re-render activity/SVG as derived, bug links, commit | orchestrator + lead | `docs/plan.md`, card, `docs/activity.puml/.svg`, git commit | Q-02, D-01 | Always | CP-F |

## Task graph

`/harness-feature <slug> [e2e] [ux]` creates one planning task:

- `workflow: feature`, `stage: P-00`, role `orchestrator`;
- e2e/UX flags from arguments; omitted flags default to `required` until the
  planning checkpoint records a waiver with a reason;
- checkpoints `CP-1` (task graph and cards) and `CP-F`.

At `CP-1`, the orchestrator creates the remaining cards:

`A-01 -> A-02? -> U-01? -> U-02? -> R-01 -> R-02 -> I-01 -> I-02? -> Q-01? -> Q-02 -> D-01?`

Rules:

- `?` stages are included only when applicable; otherwise the planning task
  records an explicit waiver in the feature card and the board task title.
- `P-00` closes at `CP-F`; its `Artifacts` lists the created cards.
- Cross-stage dependencies are explicit; no task starts before all predecessors
  are `done`.
- In U-02, `ux-designer` may delegate prototype page implementation to
  `harness-coder` under the process exception (depth 2, sequential, coder writes
  only `docs/ux/prototype/<slug>/**`); U-02 remains one UX task and one
  checkpoint.
- The orchestrator must not create a second active task.

## Default checkpoints

- A-01: CP-1 requirements baseline.
- A-02: CP-2 e2e use cases and dataset.
- U-01: CP-1 flows and screens.
- U-02: CP-2 wireframes, prototype, UI spec.
- R-01: CP-1 ADR and contracts.
- R-02: CP-2 diagrams and decomposition.
- I-01: CP-1 implementation and tests.
- I-02: CP-2 e2e automation and local run.
- Q-01: CP-1 e2e plan and coverage.
- Q-02: CP-2 e2e report and verdict.
- D-01: CP-1 documentation draft.
- Every task: CP-F.

## Acceptance rules

- Every feature task has an explicit `e2e` and `ux` decision with a reason.
- Requirements are atomic and traceable to use cases, UX screens, tests, and QA
  evidence.
- No `done` without all acceptance items and `CP-F`.
- `docs/activity.puml`/`.svg` are derived visualizations, never acceptance or
  status evidence; the plan/card/checkpoints are authoritative.
- A feature that reveals a defect in existing behavior may create a linked
  `BUG-XXX`; the feature task must not silently absorb an unrelated bugfix.
