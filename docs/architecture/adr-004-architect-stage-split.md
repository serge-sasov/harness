# ADR-004: Split architect feature work into solution design and interfaces/data model

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-11-14 |
| Task | T-035 |
| Related ADRs | ADR-001, ADR-003 |

## Context

The feature workflow defined architect work as a single block split only into
`R-01` (design, contracts, OpenAPI, decomposition) and `R-02` (all diagrams and
handoff). In practice the design phase mixes solution design with interface and
data-model work, so a checkpoint review is either delayed past the OpenAPI/spec
phase or overloaded with diagrams before the core architecture is stable. Design
feedback on components and scenario flows should reach the user before
interface, data, and service details are added, and the interface/data phase
must be able to run to completion without re-opening the design. The user asked
to move solution design (component diagrams and sequence diagrams) to stage one
and interfaces and the data model to stage two.

## Decision

1. The architect feature work stays on two stage IDs, but each has a single
   responsibility. `R-01` is **Solution design** (the design phase) and
   `R-02` is **Interfaces and data model** (the interface/data phase).
2. `R-01` produces the ADR, the architecture description core
   (`Scope and applicability`, `Context and constraints`, `Decisions`,
   `Components`, `Services`, `Scenarios`, partial `Diagram index`), one component
   diagram, one sequence diagram per `SCN-NNN`, and `SCN`/`SVC` IDs. It stops at
   `CP-1`.
3. `R-02` extends the same `architecture-<slug>.md` at `CP-2` with the data
   model, class model, REST API, traceability, `API-NNN` IDs, one OpenAPI 3.x
   spec per `API-NNN`, per-service swimlanes, contracts, and a complete diagram
   index and traceability table. `R-02` appends and never rewrites the `R-01`
   content or the user's edits.
4. `swimlane` and `API-NNN`/OpenAPI work stays in `R-02` because they are
   interface/data details of the design phase, not design decisions.
5. The design phase is the design phase: components, services, and scenarios are
   authored at `R-01`; the interface and data-model work is added at `R-02` on
   top of the accepted design.

## Alternatives

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Keep the current split, R-01 = design + contracts, R-02 = diagrams | minimal change to checks and docs | design review is delayed past interfaces/data; one stage still does too much | does not isolate the design review |
| Keep R-01/R-02 titles but move design content to R-02 | reuse the diagram-oriented R-02 | moves design decisions into the interface phase and keeps the split unbalanced | design must precede interfaces |
| Move `swimlane`/`API-NNN` to R-01 | one architect stage for all service/interface work | inflates the design phase, mixes design with interface/data detail | interfaces/data belong to R-02 |
| Merge R-01 and R-02 into one architect stage | fewer checkpoints | no design-first review, overloaded checkpoint | user selected a design/interface split |

## Consequences

- The design review at `CP-1` happens once the architecture core, component
  diagram, and scenario sequences are stable.
- The interface/data review at `CP-2` completes after contracts, OpenAPI, data
  model, class model, and swimlanes are added on the accepted design.
- The architecture description is authored in two phases but written to one file;
  `R-02` must append and preserve the `R-01` sections and user edits.
- In-flight `R-01` and `R-02` cards need their `artifacts` updated: `R-01`
  `artifacts` include the component and per-SCN sequence diagrams, `R-02`
  `artifacts` include the architecture description, contracts, and the full
  diagram set.
- Old project contracts that do not list requirement IDs may fail the new
  `contracts-requirement-trace` at `R-02`; they must be reconciled before a
  resumed `R-02` task, or the waivers in `Scope and applicability` recorded.
- `contracts-exist` and `contracts-requirement-trace` live at `R-02`, so the
  interface phase owns the contracts; the `R-01` requirement-trace target drops
  the contracts file.
- Version 2.7.0 updates the checks registry, workflow, architect role, process,
  templates, and documentation.

## Contracts and diagrams

- Interfaces and schemas: `docs/architecture/contracts-workflows-bugfix.md`
  (unchanged stage IDs; the content split is described in this ADR).
- Component diagram: `docs/description/diagrams/components-harness.puml` (R-01).
- Scenario sequences: `docs/description/diagrams/*.puml` (R-01).
- Data and class models: `docs/description/diagrams/*.puml` (R-02).
- Service swimlanes: `docs/description/diagrams/*.puml` (R-02).
- OpenAPI: OpenAPI 3.x specs (R-02).
