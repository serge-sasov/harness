---
description: "Close a harness checkpoint deterministically (checks, ledger, P2, snapshot) for T-XXX"
agent: harness
---

Close one checkpoint for task `$ARGUMENTS` per `harness/process.md` section 5/6
and section 11.2.

First verify `harness/process.md`, `docs/plan.md`, the task card, and the
workflow file. `$ARGUMENTS` must be one task ID (`T-XXX`) with an optional
checkpoint ID (`CP-N`); if the card has no unique active checkpoint, stop and
ask. If another task is active, stop: only the current task may be closed.

1. Preview with
   `harness/scripts/verify-stage.ps1 -Task T-XXX -Stage <stage>` (or
   `verify-artifacts.ps1 -Task T-XXX -Stage <stage>`). Report `FAIL`, `MANUAL`,
   and `UNCHECKED` items. Do not continue a role or accept work while a check
   fails.
2. Instruct `harness-orchestrator` to run
   `harness/scripts/stage-done.ps1 -Task T-XXX -Checkpoint CP-N`. Add
   `-AutoApprove` only for `CP-F` when the user explicitly requested it in this
   session AND the preview has `FAIL=0`, `UNCHECKED=0`, `MANUAL=0`, and the card
   has `hold: false`. Add `-Force` only to regenerate an existing checkpoint
   after a recorded reason.
3. The script writes `docs/checkpoints/T-XXX-CP-N.checks.json`, appends artifact
   hashes to `docs/evidence/T-XXX.md`, renders the checkpoint, applies policy
   P2, updates plan/card/board machine fields, re-renders `docs/activity.*`, and
   commits the snapshot (unless `-NoCommit`/`-DryRun`). Never hand-edit these
   machine fields.
4. If the script exits 1 or 2, do not approve: report the failing check or the
   configuration error, record it in the card log, and stop. The checkpoint may
   remain `awaiting_review`.
5. If a linked bug exists, instruct the orchestrator to update the bug card and
   index in a separate `chore: bug BUG-XXX ...` commit after the snapshot.
6. Report: task/checkpoint, machine summary, manual items, status
   (`approved`/`awaiting_review`), snapshot commit, board status, and the resume
   command. Do not start the next task.
