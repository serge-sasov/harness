# Solution Architecture: <name>

| Field | Value |
|---|---|
| Task | T-XXX |
| Status | draft / accepted |
| Related ADRs | ADR-XXX, ADR-YYY |
| Component diagram | `components-<slug>.puml` |
| Data model | `data-model-<slug>.puml` |
| Class model | `class-<slug>.puml` |
| Requirement sources | `docs/analysis/requirements-*.md` |

<!--
Stage ownership (do not rewrite an earlier stage):
- R-01 Solution design: `## Scope and applicability`, `## Context and constraints`,
  `## Decisions`, `## Components`, `## Services`, `## Scenarios`, `## Diagram index`.
  Also `adr-NNN-<slug>.md` and `components-<slug>` / `sequence-scn-NNN` diagrams.
- R-02 Interfaces and data model: `## Data model`, `## Class model`,
  `## REST API`, `## Traceability`; `contracts-<slug>.md`; per-`SVC-NNN`
  swimlanes; per-`API-NNN` OpenAPI specs; complete the `Diagram index`.
Append at R-02 and preserve the R-01 sections and user edits.
-->

## Scope and applicability  (R-01)

State the architecture depth explicitly. Use `required` or
`not applicable (reason)` for every optional area.

`SCN`, `SVC`, and `API` identifiers are project-global: continue numbering
across architecture descriptions and never reuse an ID for another scenario,
service, or API.

- REST API: required / not applicable (reason)
- Microservices: required / not applicable (reason)
- Runtime scenarios: required / not applicable (reason)
- Data model: required / not applicable (reason)
- Class model: required / not applicable (reason)
- Waivers: none / list with reason

## Context and constraints

Solution context, actors, external systems, runtime/platform constraints,
security and data constraints. Link requirements `R-NNN` and ADRs.

## Decisions

| ADR | Decision | Impact |
|---|---|---|
| ADR-XXX | Short decision | Components, interfaces, data |

## Components

Describe the component decomposition. Every component has a responsibility,
public interface, and dependencies. The diagram is
`components-<slug>.puml` (`components-<slug>.svg`).

| Component | Responsibility | Interfaces | Depends on |
|---|---|---|---|
| Component A | | | |

## Services

List microservices and their ownership. If the solution has no microservices,
write `No microservices` and explain the deployment model. Every `SVC-NNN`
needs one swimlane process diagram.

| ID | Service | Responsibility | Interfaces | Swimlane |
|---|---|---|---|---|
| SVC-001 | | | | `swimlane-svc-001-<slug>.puml` |

## Scenarios

Every runtime scenario gets an `SCN-NNN` and one sequence diagram. Map each
scenario to requirements and, when e2e is in scope, to `UC-E2E-NNN`.

| ID | Scenario | Requirements | UC-E2E | Sequence diagram |
|---|---|---|---|---|
| SCN-001 | | R-001 | UC-E2E-001 | `sequence-scn-001-<slug>.puml` |

## Data model  (R-02)

Entities, relationships, ownership, identifiers, retention, and migration
constraints. The diagram is `data-model-<slug>.puml`
(`data-model-<slug>.svg`).

## Class model  (R-02)

Key domain classes, aggregates, value objects, invariants, and their
relationships. The diagram is `class-<slug>.puml` (`class-<slug>.svg`).

## REST API  (R-02)

List REST APIs and their OpenAPI 3.x specifications. If the solution has no
REST API, write `No REST API` and describe the actual interface style. One
canonical OpenAPI file per `API-NNN`.

| ID | Service | Base path | OpenAPI spec |
|---|---|---|---|
| API-001 | SVC-001 | `/api/v1` | `openapi-api-001-<slug>.yaml` |

## Diagram index

List every diagram and specification so the architecture description stays the
single entry point. Every existing `.puml`, `.svg`, and OpenAPI file must be
referenced here.

| Type | Source | Rendered |
|---|---|---|
| Components | `components-<slug>.puml` | `components-<slug>.svg` |
| Scenario SCN-001 | `sequence-scn-001-<slug>.puml` | `sequence-scn-001-<slug>.svg` |
| Data model | `data-model-<slug>.puml` | `data-model-<slug>.svg` |
| Class model | `class-<slug>.puml` | `class-<slug>.svg` |
| Service SVC-001 | `swimlane-svc-001-<slug>.puml` | `swimlane-svc-001-<slug>.svg` |
| REST API API-001 | `openapi-api-001-<slug>.yaml` | - |

## Traceability

| Requirement | ADR | Component / service | Scenario | API | Test / e2e |
|---|---|---|---|---|---|
| R-001 | ADR-XXX | Component A / SVC-001 | SCN-001 | API-001 | UC-E2E-001 / test |

## Open questions and risks

- Question or risk, owner, decision deadline.
