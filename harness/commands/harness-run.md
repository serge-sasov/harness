---
description: "Explicit harness task run or checkpoint resume T-XXX (only with harness/process.md)"
agent: harness
---

Execute task `$ARGUMENTS` per `harness/process.md` and its workflow file.

Verify `harness/process.md`, `docs/plan.md`, and the workflow file; if missing,
stop and suggest `/harness-init`. `$ARGUMENTS` must be exactly one task ID
(`T-XXX`); multiple IDs, a range, or `all` -> stop without changes.

1. Read `docs/plan.md` and the card. Determine `workflow` (`feature` or
   `bugfix`; missing legacy value means `feature`) and `stage`; load
   `harness/workflows/<workflow>.md`. If the workflow, stage, or required
   `bug` link is missing/inconsistent, report `blocked`; do not guess.
2. Check the shared board invariant: no other task may be `in_progress` or
   `awaiting_review` across both workflows. A feature and a bugfix never run in
   parallel and no preemption is allowed.
3. Start or resume the task:
   - `pending`: check dependencies and the board, then delegate `in_progress` to
     `harness-orchestrator` and call exactly one role. Pass the card's `chunks`
     and `budget` fields; if chunks are planned, run the next unfinished chunk
     and use a fresh role session per chunk. Stop at the checkpoint only after
     the final chunk passes validation.
   - `awaiting_review`: read `docs/checkpoints/T-XXX-CP-N.md` and the user edits.
     Without an explicit `approved` decision, stop and ask; never infer approval.
     On `approved`, finalize at `CP-F` or set `in_progress` and continue past an
     intermediate checkpoint; on `changes_requested`, return to the same
     checkpoint after fixes.
   - `in_progress`: recover from the last checkpoint/role state; do not start a
     parallel task.
   - `failed`/`blocked`: follow process section 11; do not silently restart.
4. For `workflow: bugfix`, pass the `BUG-XXX` card to every role. The coder must
   record reproduction/root cause and a failing regression test before the fix;
   QA must verify fail-before/pass-after independently. Update the bug status
   only through the orchestrator.
5. At each checkpoint, the role must stop and report `CHECKPOINT <ID> reached`.
   For chunked stages, the role reports the chunk plan status and then one
   checkpoint after the final chunk; the orchestrator records failed attempts
   per chunk.
   The orchestrator creates/updates the checkpoint file, sets `awaiting_review`,
   updates the board/card/activity/SVG, updates the bug status when applicable,
   and commits the snapshot. The lead reports artifacts and the review checklist
   to the user and ends the run. A task becomes `done` only after the final role
   checkpoint and `CP-F` approval.
6. Close via `harness-orchestrator`: success -> `done`, update artifacts, bug
   status (`fixed`/`verified`/`closed` as appropriate), and commit; failure ->
   `failed`, cause in `Blockers`, up to 3 attempts per chunk, then `blocked` and
   escalate; verify issues/index and the bug index.
7. Do not edit files, call roles outside the harness list, start parallel work,
   or use `git push`/`tag`/`reset`/`rebase`.
