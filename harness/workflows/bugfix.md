# Bugfix Workflow (bugfix.md)

Shared rules: `harness/process.md`. This file defines the `bugfix` workflow:
restore expected behavior with evidence, a minimal fix, and independent
verification.

## When to use

Use `workflow: bugfix` when the expected behavior already exists and is not
delivered:

- a reproducible defect in implemented behavior;
- a regression after a change;
- a data, security, or contract defect that does not require a new capability;
- a defect in docs/UX only when the intended behavior is already defined.

Use `workflow: feature` instead when the behavior must be designed, the public
contract/schema/security boundary changes, or the work is actually a new
capability. A bugfix escalates to a feature-style fragment when those triggers
appear.

## Bug report

Product bugs are `BUG-XXX` cards in `docs/bugs/`, separate from harness problems
in `docs/issues/`. The bug card is the report, triage record, root cause, fix
summary, verification, and postmortem link. The orchestrator owns it.

`/harness-bug` behavior:

1. If an active task exists, registering the bug is allowed, but no task is
   started.
2. Create `docs/bugs/BUG-XXX-<slug>.md` from `harness/templates/bug-card.md` and
   add a row to `docs/bugs/README.md`.
3. Triage severity, affected requirements/use cases, environment, and expected
   behavior. If expected behavior is unclear, create an analyst task and leave
   the bug `triaged` or `new` until the answer is available.
4. Create the bugfix task cards as `pending`:
   - coder task: reproduction/root cause and minimal fix/regression;
   - QA task: independent verification.
5. Set the bug status to `triaged` when tasks are created; never set tasks
   `in_progress`.
6. If required report data is missing, keep the bug `new`, create no fix task,
   and report exactly what is missing.

## Stage table

| ID | Stage | Content | Role | Artifacts | Depends on | Applicability | Checkpoint |
|---|---|---|---|---|---|---|---|
| B-00 | Triage | Validate report, severity, scope, duplicate check, affected requirements/UC, task links, escalation decision | orchestrator | `docs/bugs/BUG-XXX-*.md`, `docs/bugs/README.md`, pending task cards | Report, board | Always | bug status `triaged` |
| B-01 | Reproduction and root cause | Reproduce on base revision, write a failing regression test, identify root cause | coder | `tests/regression/` or existing suite, card log | B-00 | Always; analyst task if expected behavior unclear | CP-1 |
| B-02 | Minimal fix and regression | Minimal fix, regression test passes, relevant suites pass, no unrelated changes | coder | code, tests, card log | B-01 | Always; architect task if design-level | CP-2 |
| B-03 | Independent verification | Reproduce/verify fail-before, verify pass-after, run regression, verdict | qa | `docs/qa/review-T-XXX.md` | B-02 | Always | CP-1 report, CP-F |
| B-04 | Docs/changelog | Changelog, guide, or ADR note if behavior/docs changed | doc-writer | `CHANGELOG.md`, `docs/guides/*` | B-02 | Optional | CP-1 |
| B-05 | Closure and postmortem | Update bug status, plan/card, re-render activity as derived, commit; P0/P1 postmortem | orchestrator + lead | `docs/bugs/BUG-XXX-*.md`, `docs/bugs/README.md`, plan/card, git commit | B-03, B-04 if present | Always; postmortem for P0/P1 | CP-F |

## Task graph

Default:

`BUG-XXX (B-00) -> T-XXX coder (B-01/B-02) -> T-YYY qa (B-03) -> B-05 closure`

Optional insertions:

- expected behavior unclear: analyst task before the coder task;
- design-level defect: architect task before the coder task;
- UI/UX defect: UX task before the coder task; the UX task may update affected
  scenario pages and delegate their implementation to `harness-coder` under the
  prototype exception;
- docs/changelog affected: doc-writer task after the fix;
- P0/P1: postmortem by the orchestrator in the bug card before `closed`.

The coder task has CP-1 (reproduction/root cause and failing regression) and
CP-2 (fix/regression green). The QA task has CP-1 (verification plan) and CP-F.
Every task has CP-F.

## Severity and hotfix

| Severity | Meaning | Extra requirements |
|---|---|---|
| P0 | outage, data loss, security incident | immediate queue priority, architect/QA, postmortem |
| P1 | major broken flow / unsafe workaround | architect/QA, postmortem |
| P2 | normal defect | standard graph |
| P3 | minor/cosmetic | standard graph; docs optional |

`profile: hotfix` is allowed only for P0/P1 and means documentation may be
deferred to a follow-up task. It never waives reproduction, regression, QA, or
postmortem. `hotfix` is a modifier, not a third workflow.

Strict sequencing still applies: a hotfix waits for the current active task or
starts after the user explicitly stops it at a checkpoint. No parallel execution
or preemption.

## Escalation to feature-style work

The orchestrator must add analyst/architect/UX tasks and record the escalation
in the bug card when the fix:

- changes a public API, message format, data schema, or migration;
- crosses module boundaries or changes an architecture decision;
- changes authentication, authorization, secrets, or security behavior;
- changes a user flow, layout, or interaction contract;
- reveals a missing requirement rather than a defect.

The bug stays `BUG-XXX`; the linked tasks use `workflow: feature` for the
escalated fragment only when their stage is from the feature workflow. The bugfix
coder/QA tasks remain `workflow: bugfix`.

## Acceptance rules

Coder:

- reproduction and root cause are recorded;
- the regression test fails before the fix;
- the minimal fix passes the regression and relevant suites;
- no unrelated refactor or behavior change.

QA:

- independent fail-before/pass-after evidence;
- regression and relevant suites pass;
- no collateral changes;
- verdict in `docs/qa/review-T-XXX.md`.

Closure:

- bug status is correct (`fixed`/`verified`/`closed`/`duplicate`/`wontfix`);
- bug index links to all tasks and the fix commit;
- P0/P1 postmortem exists;
- activity artifacts are derived only, never status or acceptance evidence;
- no bug is closed without user approval at `CP-F`.
