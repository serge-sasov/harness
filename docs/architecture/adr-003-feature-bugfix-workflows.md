# ADR-003: Separate feature and bugfix workflows

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-11-11 |
| Task | T-023 |
| Related ADRs | ADR-001, ADR-002 |

## Context

Harness 2.1.0 has one lifecycle for all work. A bug fix is forced through the
same analysis, UX, architecture, implementation, e2e, QA, and documentation
stages as a new feature. This is slow and encourages silent waivers, while the
critical bugfix evidence - reproduction and a failing regression test - is not a
first-class gate. At the same time, duplicating agents, statuses, or boards for
bugs would break the single dependency graph and the one-active-task invariant.

The user selected: strict sequential execution for both workflows, `BUG-XXX`
cards as bug reports, and explicit `/harness-feature` and `/harness-bug` entry
points.

## Decision

1. Keep one harness, one role set, one board, one status model, one checkpoint
   mechanism, and one active task across both workflows.
2. Add `workflow: feature | bugfix` and `stage` to every task card. The board
   gets a `Workflow` column and a `Bug` link for bugfix tasks.
3. Split process documentation:
   - `harness/process.md` - shared rules and routing;
   - `harness/workflows/feature.md` - feature/project stages and task graph;
   - `harness/workflows/bugfix.md` - defect stages, gates, and escalation.
4. Product bugs use `BUG-XXX` report cards in `docs/bugs/` with an index in
   `docs/bugs/README.md`. They are separate from harness problems in
   `docs/issues/`. A bug card is maintained by the orchestrator and links to one
   or more `T-XXX` tasks.
5. Bugfix tasks use the shortened graph:
   `B-00 triage -> B-01 reproduce/root cause -> B-02 minimal fix/regression ->
   B-03 independent verification -> B-05 closure`, with optional analyst,
   architect, UX, docs, and postmortem tasks.
6. A bugfix cannot start without reproduction and a failing regression test.
   QA verifies fail-before/pass-after independently. A fix that changes a public
   contract, schema, security boundary, multiple modules, or a UI flow escalates
   to a feature-style analysis/design fragment.
7. Add `/harness-feature` and `/harness-bug`; `/harness-run` stays the universal
   executor and reads the workflow from the card.
8. Strict sequential execution remains: no parallel feature and bugfix work, no
   preemption. New bug reports and pending task cards may be registered while a
   task is active; active-task statuses and board reconciliation must not change.

## Alternatives

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Separate agent sets, boards, and statuses | clear visual split | duplicated roles, two sources of truth, broken cross-dependencies | one harness and one board are enough |
| Keep one lifecycle and waive stages for bugs | minimal change | silent skips, no reproduction gate | does not fix the problem |
| Store product bugs in `docs/issues/` | one registry | mixes harness problems with product defects | different lifecycles and owners |
| Task card only, no `BUG-XXX` report | fewer artifacts | no durable report before a fix is planned | user selected dedicated bug cards |
| Parallel feature and bugfix streams | faster hotfixes | conflicts, two active tasks, model context races | strict sequential selected |

## Consequences

- Feature work keeps the current quality gates.
- Bug work gets a short, evidence-driven path and cannot silently skip
  reproduction.
- The board remains the single execution queue; the bug registry is a report
  queue, not a second execution board.
- Existing cards without `workflow` are treated as `feature` during migration.
- Version 2.2.0 adds workflows, templates, commands, scripts, and docs; the
  `docs/bugs/` directory is part of `/harness-init`.

## Contracts and diagrams

- Interfaces and schemas: `docs/architecture/contracts-workflows-bugfix.md`.
- Component diagram: `docs/description/diagrams/components-harness.puml`.
- Class model: `docs/description/diagrams/class-harness.puml`.
- Bugfix sequence: `docs/description/diagrams/seq-14-bugfix.puml`.
