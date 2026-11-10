---
description: "Explicit harness task run T-XXX (only with harness/process.md)"
agent: harness
---

Execute task `$ARGUMENTS` per `harness/process.md`.

Verify `harness/process.md` and `docs/plan.md`; if missing, stop and suggest `/harness-init`. `$ARGUMENTS` must be exactly one task ID (`T-XXX`); multiple IDs, a range, or `all` -> stop without changes.

Use the harness task cycle: check dependencies and board, delegate status updates and closure to `harness-orchestrator`, call exactly one role, accept via `acceptance`, report status/commit/unblocked/blockers. Do not start the next task automatically. Do not edit files, call roles outside the harness list, run tasks in parallel, or use `git push`/`tag`/`reset`/`rebase`.
