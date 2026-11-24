---
description: "Record an explicit human checkpoint decision for harness T-XXX"
agent: harness
---

Record a human checkpoint decision for `$ARGUMENTS` per `harness/process.md`.

This is the only command that writes human approval decisions. Never infer
approval and never let a role approve its own checkpoint.

1. Read the task card and the checkpoint. Show the review packet with
   `harness/scripts/review.ps1 -Task T-XXX -Checkpoint CP-N` if needed.
2. Require an explicit user choice: `approved`, `changes_requested`, or
   `rejected`. If the user has not decided, stop and ask.
3. Require `-AcknowledgeManual` when the checks summary has `MANUAL > 0` and the
   decision is `approved`. Do not approve `FAIL > 0` or `UNCHECKED > 0`.
4. Run:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "harness/scripts/approve.ps1" -Task T-XXX -Checkpoint CP-N -Decision approved
   ```

   Add `-AcknowledgeManual` after explicit user confirmation, `-Remarks "..."`,
   and `-Reopen T-YYY` only as requested. Use `-DryRun` first when the state is
   ambiguous and `-NoCommit` only when the user asks.
5. Report the checkpoint status, task status, reviewer, decision, and commit.
   Do not start or resume another task.
