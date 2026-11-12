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
   - read `docs/plan.md`, the cards `docs/tasks/T-*.md`,
     `docs/checkpoints/T-*.md`, `docs/bugs/BUG-*.md`, `docs/bugs/README.md`,
     the workflow files, and Git evidence;
   - do not read `docs/activity.puml` or its derivatives as a reconciliation
     input; they are informational visualizations, not status evidence;
   - reconcile task statuses with the authoritative sources, including
     `awaiting_review` and checkpoint decisions;
   - validate `workflow`, `stage`, and `bug` links against the workflow files;
   - reconcile bug statuses with linked tasks and QA evidence; keep
     `docs/bugs/README.md` in sync;
   - ensure every checkpoint in a card has a matching `docs/checkpoints/` file
     and a recorded decision;
   - fill the `Commit` column with actual hashes from `git log --oneline`;
   - only after reconciliation, update colors in `docs/activity.puml` using
     `:task text; <<#RRGGBB>>` and re-render `docs/activity.svg` via MCP
     `plantuml-render`; verify the SVG has no `syntax is deprecated` banner;
   - commit `chore: board update ($ARGUMENTS)`.
2. Do not edit files yourself; that is the orchestrator's job.
3. Report: which task/bug statuses changed, checkpoint mismatches, which commits
   were recorded, and the SVG path.
