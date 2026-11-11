# Contracts: feature and bugfix workflows

This file defines the interfaces between the shared harness, the two workflow
definitions, the task board, the bug registry, and the commands. Any change here
requires an ADR update.

## 1. Workflow and task contract

Every task card has the shared fields `id, title, workflow, stage, role, status,
depends_on, inputs, artifacts, e2e, ux, checkpoints, issues, commit`.

- `workflow`: `feature` or `bugfix`. Missing values in legacy cards mean
  `feature`.
- `stage`: a stage ID from the selected workflow document.
  - feature: `P-00`, `A-01`, `A-02`, `U-01`, `U-02`, `R-01`, `R-02`, `I-01`,
    `I-02`, `Q-01`, `Q-02`, `D-01`, `F-01`;
  - bugfix: `B-00`, `B-01`, `B-02`, `B-03`, `B-04`, `B-05`.
- `bug`: required for `workflow: bugfix`; value `BUG-XXX`.
- `severity`: required on a bug card, not on feature tasks.
- Task statuses and checkpoint rules are shared and defined in
  `harness/process.md`.
- A role reads `harness/process.md` and the workflow file for the card's
  `workflow`; no role may infer a workflow from the task title.

Workflow files are the source for stage tables, default task graphs, required
artifacts, checkpoint defaults, and escalation rules.

## 2. Bug card contract

Path: `docs/bugs/BUG-XXX-<slug>.md`; ID `BUG-XXX` is immutable and unique.
Index: `docs/bugs/README.md`, columns
`ID | Summary | Severity | Status | Tasks | Updated`.

Required fields:

| Field | Values |
|---|---|
| id | `BUG-XXX` |
| title | short observable defect |
| status | `new`, `triaged`, `in_progress`, `fixed`, `verified`, `closed`, `duplicate`, `wontfix` |
| severity | `P0`, `P1`, `P2`, `P3` |
| reported_at | ISO-8601 timestamp |
| reporter | user or role |
| affected | component, environment, version/build |
| requirements | `R-NNN` list or `unknown` |
| use_cases | `UC-E2E-NNN` list or `not applicable` |
| tasks | `T-XXX` list |
| duplicate_of | `BUG-XXX` or `-` |
| commit | fix commit or `-` |
| issues | `ISSUE-...` harness issues only, or `-` |

Required sections: observed behavior, expected behavior, reproduction steps,
evidence, impact/severity rationale, triage, root cause, fix summary,
verification, postmortem (P0/P1), links, log.

Status transitions:

- `new -> triaged`: severity, scope, affected requirements, and task links are
  recorded; unresolved expected behavior requires an analyst task.
- `triaged -> in_progress`: the first linked bugfix task starts.
- `in_progress -> fixed`: the coder fix task is accepted at its `CP-F`.
- `fixed -> verified`: the QA verification task is accepted at `CP-F`.
- `verified -> closed`: closure is complete; P0/P1 postmortem exists.
- `new|triaged -> duplicate`: `duplicate_of` is set and the user confirms.
- `new|triaged -> wontfix`: reason and user approval are recorded.
- A regression reopens a `closed` bug as `new` with a new task link; history is
  never deleted.

Ownership: only the orchestrator edits bug cards and the bug index. Roles report
root cause, fix, and verification evidence to the orchestrator; they do not edit
the bug card directly.

Product bugs are not `docs/issues/`. `docs/issues/` contains harness process
problems only.

## 3. Board and registry contract

`docs/plan.md` is the only execution board:

`ID | Workflow | Task | Role | Dependencies | Status | Bug | Artifacts | Commit`

- `Workflow` is `feature` or `bugfix`.
- `Bug` is `BUG-XXX` for bugfix tasks and `-` for feature tasks.
- IDs are global `T-XXX`; no separate task ID namespace for bugs.
- At most one task is `in_progress` or `awaiting_review` across both workflows.
- Intake of new `pending` task cards and new bug cards is allowed while a task
  is active. Editing existing task statuses, dependencies, or running
  `/harness-board-update` is forbidden while a task is active.
- The bug index is not a second execution board; it is a report queue. Its
  `Tasks` column points to the execution task(s).

## 4. Command contract

| Command | Input | Behavior |
|---|---|---|
| `/harness-feature` | `<slug> [e2e] [ux]` | creates a `workflow: feature`, `stage: P-00` planning task; the orchestrator decomposes it into feature cards at CP-1; omitted flags default to `required` until the planning checkpoint records a waiver |
| `/harness-bug` | `<summary or BUG-XXX>` | triages the report; creates `docs/bugs/BUG-XXX-*.md` and linked bugfix task(s); no fix starts automatically |
| `/harness-run T-XXX` | one task ID | starts or resumes the task using the workflow in its card |
| `/harness-board-update` | `all` or `T-XXX` | reconciles tasks and bug index when no task is active |
| `/harness-board-report` | - | read-only report grouped by workflow and bug severity |

Command rules:

- Missing required bug data leaves the card in `new`; no speculative fix task is
  created.
- `/harness-bug` never sets a task `in_progress`; it only creates `pending`
  work.
- `/harness-feature` never skips the planning checkpoint.
- `/harness-run` refuses a card whose `workflow` or `stage` is missing or
  inconsistent with its workflow file.
- No command may start a second active task.

## 5. Bugfix acceptance contract

A bugfix coder task is accepted only when:

1. reproduction is recorded and a regression test fails on the base revision;
2. the root cause is documented in the task card;
3. the minimal fix is applied without unrelated refactor;
4. the regression test passes after the fix;
5. existing relevant tests pass.

A bugfix QA task is accepted only when:

1. QA independently reproduces the failure on the base revision or validates a
   stored evidence artifact;
2. QA confirms pass-after on the fix;
3. the regression test and relevant suites pass;
4. no unrelated behavior or artifact changed;
5. a verdict is recorded in `docs/qa/review-T-XXX.md`.

Escalation is mandatory when a fix changes a public contract, data schema,
security boundary, more than one module, or a UI flow. The orchestrator adds
analyst/architect/UX tasks before the coder task; the bug remains the same
`BUG-XXX`.

## 6. Compatibility

- Version 2.2.0; legacy cards without `workflow` are read as `feature`.
- `docs/bugs/` is optional for projects without bug reports but is created by
  `/harness-init` and checked by `/harness-doctor`.
- The previous `harness/templates/task-card.md` is a deprecation pointer; new
  cards use `task-card-feature.md` or `task-card-bugfix.md`.
