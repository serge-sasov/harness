# ADR-005: Responsibility zones for components, modules, and classes

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-11-14 |
| Task | T-036 |
| Related ADRs | ADR-002, ADR-003, ADR-004 |

## Context

The architecture description registered a component decomposition with a free-text
`Responsibility` column, a module decomposition for the coder handoff, and a
class model, but nothing tied those levels together and nothing prevented two
elements of the same level from owning the same functions. Reviews found
overlapping responsibilities (two components handling the same validation, two
modules of one application parsing the same payload, two classes of one module
persisting the same entity) that only surfaced during implementation, when the
coder had to guess which owner to follow. The user asked for a rule that makes
each element declare its zone of responsibility and that forbids duplicated or
overlapping zones inside one level of the hierarchy
`component -> module (optional) -> class`.

## Decision

1. The decomposition hierarchy is `component -> module (optional) -> class`.
   Every element on every level declares a zone of responsibility: what it owns
   (`Owns`) and what it explicitly does not own (`Does not own`).
2. Zones are exclusive within a level. Two components must not own the same
   functions; two modules of the same component (or application) must not own
   the same functions; two classes of the same module (or application) must not
   own the same functions.
3. Overlap is resolved, never documented: merge the elements, split one of them,
   or move the shared function to the level that owns it. A decomposition change
   is recorded in the ADR.
4. The zones are registered in the `## Responsibility zones` section of
   `docs/architecture/architecture-<slug>.md` with one table per level. The
   registry is authoritative; the `## Components` table lists the same
   components and the module boundaries in `contracts-<slug>.md` reference the
   module zones.
5. Modules get `MOD-NNN` and classes get `CLS-NNN` identifiers. They are
   project-global like `SCN`/`SVC`/`API`: numbering continues across
   architecture descriptions and an ID is never reused.
6. The module level is optional and the class level is optional. An absent
   level is waived only by an explicit `No module decomposition (reason)` or
   `No class model (reason)` statement; silence is not a waiver.
7. Enforcement: the deterministic check `responsibility-zones` (check type
   `zones-unique`) validates the section, the `Owns`/`Does not own` columns,
   zone uniqueness per level and parent, contradictions between `Owns` and a
   sibling's `Does not own`, and parent references. `module-ids` and `class-ids`
   validate the project-global identifiers. The semantic review (do two elements
   cover the same function in different words?) is the manual check
   `zones-overlap-review` at R-01 and R-02.

## Alternatives

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Keep a free-text `Responsibility` column only | no new section | nothing detects duplicated or overlapping zones; review stays manual and vague | the user asked for explicit zones with a strict no-overlap rule |
| Encode zones only in the class diagram | visual | not checkable, not reviewable in text, does not cover components and modules | the rule applies to the whole hierarchy |
| Add a new component ID scheme (`CMP-NNN`) | uniform IDs on all levels | ripples into the component diagram, contracts, and traceability; components are already named in the description | only modules and classes needed stable IDs |
| Deterministic checks only, no manual review | keeps P2 auto-approval at R-01/R-02 | functional overlap expressed in different words is undetectable by a script | the strict requirement needs a human semantic review at the checkpoint |
| Manual review only, no new check type | no engine change | duplicates, empty zones, and broken parents are found late and inconsistently | deterministic checks give a repeatable baseline |

## Consequences

- The architect role, the shared process rules, and the architecture description
  template describe the same rule; the description becomes the single source of
  truth for the zones.
- `zones-unique` is a new check type in `harness/scripts/verify-artifacts.ps1`
  with self-test cases (missing section, duplicated zone, empty `Owns`,
  contradiction, unknown parent, waived level, missing level, waiver with an
  unfilled table).
- `responsibility-zones`, `module-ids`, `class-ids`, and the manual
  `zones-overlap-review` are registered at R-01 and R-02. A manual check always
  waits for the user, so R-01 and R-02 are no longer auto-approved by policy P2.
- Migration: architecture descriptions written before 2.8.0 have no
  `## Responsibility zones` section and fail `responsibility-zones`. Add the
  section with the level tables and the explicit waiver statements before the
  next R-01 or R-02 checkpoint, or record the migration in the task log.
- `architecture-sections` was not extended with the new heading on purpose: the
  dedicated check reports the missing section with a targeted message instead of
  a generic heading failure.
- Version 2.8.0 updates the architect role, process, workflow, checks registry,
  templates, verification engine, and documentation.

## Contracts and diagrams

- Architecture description: `docs/architecture/architecture-<slug>.md` with the
  `## Responsibility zones` section (components and modules at R-01, classes at
  R-02).
- Template: `harness/templates/architecture-description.md`.
- Checks: `harness/checks/feature.json` (`responsibility-zones`, `module-ids`,
  `class-ids`, `zones-overlap-review`).
- Engine: `harness/scripts/verify-artifacts.ps1` (check type `zones-unique`).
- Component diagram: `docs/architecture/components-<slug>.puml` (R-01).
