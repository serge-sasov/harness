---
description: "Sync the harness board and bug registry (harness project only)"
agent: harness
---

Update planning artifacts according to `harness/process.md` section 9.

First verify that `harness/process.md` and `docs/plan.md` exist. If not, stop and
suggest `/harness-init`.

Input: `$ARGUMENTS` - a task ID (for example, `T-007`) or `all` for a full
reconciliation.

If any task is `in_progress` or `awaiting_review`, stop: board reconciliation is
forbidden while a task is active. New pending work is registered only through
`/harness-feature` or `/harness-bug`.

1. Give `harness-orchestrator` the task:
   - run `harness/scripts/board-update.ps1 -All -DryRun` (or `-Task T-XXX
     -DryRun`) and report the planned changes; the script derives status from
     checkpoint files (`CP-F approved -> done`; any `awaiting_review ->
     awaiting_review`) and refuses a real run while a task is active.
   - then run `board-update.ps1 -All` (or `-Task T-XXX`). It updates plan/card
     status, re-renders `docs/activity.*`, and commits
     `chore: board update (...)`.
   - use `-SyncFields` only when the board `Artifacts`/`Commit` cells should be
     replaced from the card; otherwise status is the only reconciled field.
   - validate: every approved checkpoint has
     `docs/checkpoints/T-XXX-CP-N.checks.json`; `docs/evidence/T-XXX.md` has the
     latest hashes; `docs/bugs/README.md` matches the bug cards; no machine
     field was hand-edited.
   - do not read `docs/activity.puml` or its derivatives as a reconciliation
     input; they are informational visualizations, not status evidence.
   - fill the `Commit` column only with hashes that exist in `git log`; never
     invent a hash.
2. Do not edit files yourself; that is the orchestrator's job.
3. Report: which task/bug statuses changed, checkpoint mismatches, missing
   checks JSON, which commits were recorded, and the SVG path.
