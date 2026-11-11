---
description: "Register and triage a product bug into a BUG-XXX card and bugfix tasks"
agent: harness
---

Register/triage a product bug from `$ARGUMENTS` per `harness/process.md` and
`harness/workflows/bugfix.md`.

Verify `harness/process.md`, `docs/plan.md`, and
`harness/workflows/bugfix.md`; if missing, stop and suggest `/harness-init`.

Input forms:
- a summary or report text for a new bug;
- `BUG-XXX` to inspect an existing bug and create missing triage/fix tasks.

Rules:

1. Product bugs use `docs/bugs/BUG-XXX-<slug>.md` and
   `docs/bugs/README.md`; never use `docs/issues/` for product defects.
2. Do not edit files yourself. Instruct `harness-orchestrator` to:
   - create the bug card from `harness/templates/bug-card.md` and append the
     index row;
   - triage severity (`P0`..`P3`), affected requirements/UC, environment, and
     expected behavior;
   - check for duplicates and decide whether the fix needs feature-style
     escalation (contract, schema, security, multi-module, UI flow);
   - create `pending` linked task cards from
     `harness/templates/task-card-bugfix.md`:
     `T-XXX` coder (`B-01`/`B-02`) and `T-YYY` qa (`B-03`), plus optional
     analyst/architect/UX/docs tasks when triage requires them;
   - set the bug status to `triaged` only when the report has enough data to
     reproduce; otherwise keep `new` and report exactly what is missing.
3. If the report lacks observed/expected behavior, reproduction steps, or
   environment, stop after creating the `new` bug card and ask the user for the
   missing fields. Do not create a speculative fix task.
4. Registering a pending bug/task while another task is active is allowed; do
   not change existing statuses, dependencies, or the active task. Never set a
   task `in_progress` or start a role from this command.
5. `P0`/`P1` sets `profile: hotfix` and requires postmortem, but still waits for
   the active task; no preemption.
6. Report: BUG ID, severity, status, linked task IDs, missing data, and the next
   command `/harness-run T-XXX`.
