---
description: "Harness board summary (read-only, harness project only)"
agent: harness
---

Produce a summary of the harness plan state.

First verify that `harness/process.md` and `docs/plan.md` exist. If not, stop and suggest `/harness-init`.

Give `harness-orchestrator` a read-only task:

1. Read `docs/plan.md` and the cards `docs/tasks/T-*.md`.
2. Print a table: ID, role, status, dependencies, blockers (brief).
3. List separately:
   - tasks ready to start (`pending`, all `depends_on` are `done`);
   - `failed`/`blocked` tasks with the cause from the card;
   - completed tasks and their commits.
4. Check consistency: %done, dangling dependencies, plan <-> card mismatches.
5. Change and commit nothing.

Format: brief, in English, as a table; at the end, 1-3 recommendations for the next task to run.
