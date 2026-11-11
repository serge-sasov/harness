# ADR-002: E2E use-case data, UX artifacts, and user checkpoints

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-11-11 |
| Task | T-014 |
| Related ADRs | ADR-001 |

## Context

The harness produced requirements, architecture, code, and QA verdicts, but had
no formal bridge from requirements to end-to-end tests, no UI/UX design role,
and no reliable point where the user could review and edit artifacts before the
task closed. Requirements were often interpreted independently by the analyst,
architect, coder, and QA. A task could reach `done` without explicit user
acceptance.

## Decision

1. The analyst formalizes end-to-end use cases as `UC-E2E-NNN` in Markdown and a
   machine-readable YAML dataset with schema `harness-e2e/1`.
2. A new `harness-ux-designer` role owns user flows, screen inventory, PlantUML
   wireframes, a UI specification, and a static HTML prototype under `docs/ux/`.
3. Tasks move through explicit user checkpoints recorded in
   `docs/checkpoints/T-XXX-CP-N.md`. The card declares checkpoints; `CP-F` is
   mandatory before `done`.
4. Add status `awaiting_review`; at most one task may be active
   (`in_progress` or `awaiting_review`).
5. The coder consumes the analyst dataset and provides deterministic e2e tests,
   an isolated runner, and a dataset validator. QA owns the coverage matrix,
   execution evidence, and verdict.
6. User edits at a checkpoint are authoritative; roles must read the checkpoint
   decision and `git diff` since the snapshot before continuing.

## Alternatives

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Free-form e2e descriptions in requirements | no new artifacts | not automatable, ambiguous | cannot drive deterministic tests |
| Analyst writes code-level e2e tests | one owner | analyst cannot run/own code | violates role boundaries |
| UX artifacts only as prose | simple | no visual review | user cannot validate interaction design |
| Checkpoints as chat messages only | no extra files | lost on restart, no audit trail | unreliable across sessions |
| `blocked` status for user review | no new status | conflates external blockers with review | misleading board and reports |
| Implicit approval on silence | faster | dangerous, violates user control | unacceptable |

## Consequences

- Positive: traceability from requirements to e2e evidence; earlier UX
  validation; auditable user decisions; resumable runs.
- Negative/risks: more artifacts and status transitions; checkpoint files can
  become stale if users edit without recording a decision.
- Mitigation: orchestrator reconciles checkpoints during board updates and
  refuses to close a task without `CP-F`; doctor checks new templates and dirs.
- Changes: process, agents, commands, skill, scripts, templates, board, docs,
  diagrams, version `2.1.0`.

## Contracts and diagrams

- Interfaces and schemas: `docs/architecture/contracts-e2e-ux-checkpoints.md`.
- Component diagram: `docs/description/diagrams/components.puml`.
- Checkpoint sequence: `docs/description/diagrams/seq-13-checkpoints.puml`.
- UX flow sequence: `docs/description/diagrams/seq-12-ux-designer.puml`.
