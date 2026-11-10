---
description: "Sync the harness board (harness project only)"
agent: harness
---

Update planning artifacts according to `harness/process.md` section 5.

First verify that `harness/process.md` and `docs/plan.md` exist. If not, stop and suggest `/harness-init`.

Input: `$ARGUMENTS` - a task ID (for example, `T-007`) or `all` for a full reconciliation.

1. Give `harness-orchestrator` the task:
   - read `docs/plan.md`, the cards `docs/tasks/T-*.md`, and `docs/activity.puml`;
   - reconcile statuses with reality (the card is the source of truth);
   - fill the `Commit` column with actual hashes from `git log --oneline`;
   - update colors in `docs/activity.puml` and re-render `docs/activity.svg` via MCP `plantuml-render`;
   - commit `chore: board update ($ARGUMENTS)`.
2. Do not edit files yourself; that is the orchestrator's job.
3. Report: which statuses changed, which commits were recorded, the SVG path.
