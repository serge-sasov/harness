---
description: "Read-only pending, task, group, or statistics checkpoint review for harness"
agent: harness
---

Review checkpoint approvals for `$ARGUMENTS` per `harness/process.md`.

First verify `harness/process.md` and `docs/plan.md`; otherwise stop and suggest
`/harness-init`. This command is read-only: do not approve, reject, edit, or
commit anything.

Use `harness/scripts/review.ps1`:

1. No arguments or `-Pending`: list every checkpoint awaiting review with task,
   stage, risk tier, review group, gate, wait time, and check counters.
2. `T-XXX`: show the task packet. Add `-Checkpoint CP-N` to include the full
   checkpoint file and the exact approve command.
3. `RG-...`: show the batch group, its stages/gate, and open checkpoints.
4. `-Stats`: show counts, auto/human decisions, risk tiers, and average wait.
5. Add `-Json` for machine-readable output or `-OutFile <path>` to save it.

Report the result to the user. For a human decision, use `/harness-approve` only
after the user explicitly chooses approved, changes_requested, or rejected.
