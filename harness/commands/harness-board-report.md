---
description: "Harness board and bug queue summary (read-only, harness project only)"
agent: harness
---

Produce a summary of the harness plan state.

First verify that `harness/process.md` and `docs/plan.md` exist. If not, stop and
suggest `/harness-init`.

Give `harness-orchestrator` a read-only task:

1. Read `docs/plan.md`, the cards `docs/tasks/T-*.md`,
   `docs/checkpoints/T-*.md`, `docs/bugs/BUG-*.md`, and
   `docs/bugs/README.md`.
2. Print a task table grouped by `workflow`: ID, stage, role, status,
   dependencies, bug link, blockers (brief).
3. Print a bug queue table: ID, severity, status, linked task(s), age/open time.
4. List separately:
   - tasks ready to start (`pending`, all `depends_on` are `done`, no active
     task);
   - tasks `awaiting_review` with their pending checkpoint, review file, and
     requested date;
   - `failed`/`blocked` tasks with the cause from the card;
   - completed tasks and their commits;
   - bugs without a linked task or with stale status.
5. Check consistency: %done per workflow, dangling dependencies, plan <-> card
   mismatches, workflow/stage mismatches, checkpoints without decisions,
   missing `CP-F`, and bug index <-> card mismatches.
6. Change and commit nothing.

Format: brief, in English, as tables; at the end, 1-3 recommendations for the
next task to run, checkpoint to review, or bug to triage.
