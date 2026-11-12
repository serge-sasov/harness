---
description: "Create a feature workflow planning task (harness project only)"
agent: harness
---

Create a `feature` workflow entry for `$ARGUMENTS` per `harness/process.md` and
`harness/workflows/feature.md`.

Verify `harness/process.md`, `docs/plan.md`, and
`harness/workflows/feature.md`; if missing, stop and suggest `/harness-init`.

`$ARGUMENTS` must be a non-empty feature slug/title plus optional `e2e` and `ux`
flags. If it is empty or ambiguous, stop and ask for the feature name and the
e2e/UX applicability. Never create a feature card without a name.

1. Do not edit files yourself. Instruct `harness-orchestrator` to create exactly
   one `pending` planning task:
   - `workflow: feature`, `stage: P-00`, role `orchestrator`;
   - card from `harness/templates/task-card-feature.md`;
   - `e2e: required` and `ux: required` unless the user explicitly passed
     `no-e2e`/`no-ux`; a waiver must include a reason and must be confirmed at
     the planning checkpoint;
   - checkpoints `CP-1` (task graph and cards) and `CP-F`;
   - acceptance: the remaining feature task graph and cards are created with
     explicit dependencies, applicability, and `CP-F`.
2. The orchestrator appends the row to `docs/plan.md`, creates the card, then
   re-renders `docs/activity.puml`/SVG as derived. Registering a new `pending` task is allowed
   while another task is active, but no existing status, dependency, or active
   task may change.
3. Do not start the task, call another role, or create parallel work.
4. Report: task ID, card path, workflow, e2e/UX flags, checkpoint list, and the
   next command `/harness-run T-XXX`.
