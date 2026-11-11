---
name: Local Harness
description: "Local multi-agent harness: roles, board, tasks, acceptance, artifacts. Use only on explicit user request and only in a project with harness/process.md. Do not use for ordinary coding tasks."
metadata:
  opencode/autoinvoke: false
---

# Local Harness

## When to use

Only when the user explicitly asks to run harness or execute `/harness-run`, `/harness-feature`, `/harness-bug`, `/harness-board-update`, or `/harness-board-report` in a project that has `harness/process.md` and `docs/plan.md`.

Do not use for ordinary development, analysis, or documentation tasks.

## Project check

Before any action:

1. Verify that `harness/process.md` and `docs/plan.md` exist.
2. If not, stop and suggest `/harness-init`.
3. Read `harness/process.md`; it is the source of shared process rules.
4. Read the workflow file selected by the task card:
   `harness/workflows/feature.md` or `harness/workflows/bugfix.md`.
5. Read `docs/plan.md` and the task card `docs/tasks/T-XXX-*.md`. For bugfix, also read the linked `docs/bugs/BUG-XXX-*.md`.

## Commands

- `/harness-init`: initialize the current project.
- `/harness-feature <slug> [e2e] [ux]`: create a pending `feature` planning task (`P-00`); does not start work.
- `/harness-bug <report or BUG-XXX>`: create/triage a `BUG-XXX` card and pending bugfix tasks; does not start work.
- `/harness-run T-XXX`: execute or resume exactly one task from either workflow.
- `/harness-board-update all|T-XXX`: board reconciliation when no task is active.
- `/harness-board-report`: read-only board report.
- `/harness-doctor`: installation and project health check.

Explicit only; `default_agent` is never switched to harness.

## Workflows

There is one harness with two base workflows:

- `feature`: new behavior or a new project. Planning task `P-00`, then analyst,
  UX (if in scope), architect, coder, QA, docs, and final acceptance.
- `bugfix`: restore expected behavior. `BUG-XXX` report, triage, reproduction
  and failing regression, minimal fix, independent QA verification, optional
  docs, closure. P0/P1 get a postmortem; `hotfix` is a modifier, not a workflow.

Legacy cards without `workflow` are read as `feature`. A bugfix escalates to
feature-style analyst/architect/UX tasks when it changes a public contract,
schema, security boundary, multiple modules, or a UI flow.

## Roles

| Agent | Role |
|---|---|
| `harness` | primary lead: routing, marker checks, checkpoints, reporting |
| `harness-orchestrator` | board, bug registry, dependencies, checkpoints, acceptance, activity, commits |
| `harness-analyst` | requirements, RAG, questions, glossary, e2e use cases/test data; bug impact |
| `harness-ux-designer` | user flows, screen inventory, wireframes, UI spec, HTML prototypes; UI bug impact |
| `harness-architect` | ADRs, PlantUML, contracts; design-level root cause |
| `harness-coder` | code, unit/integration/e2e tests, CI/CD, local runs; reproduction and regression fix |
| `harness-qa` | text/code review, e2e coverage/run, independent bug verification, verdict |
| `harness-qa-vision` | visual review of diagrams, wireframes, and screenshots |
| `harness-doc-writer` | README, runbook, guides, ADR finalization, changelog |

The lead does not edit files itself; the orchestrator handles the board, bug registry, and commits.

## Artifacts

- `docs/plan.md`: board, the single source of truth for work scope;
- `docs/tasks/T-XXX-*.md`: feature/bugfix task cards with inputs, applicability, `workflow`, `stage`, and checkpoints;
- `docs/bugs/BUG-XXX-*.md` and `docs/bugs/README.md`: product bug reports and index, owned by the orchestrator;
- `docs/checkpoints/T-XXX-CP-N.md`: user review decisions, edits, and remarks;
- `docs/activity.puml` / `.svg`: task statuses;
- `harness/workflows/`: feature and bugfix stage tables/task graphs;
- `docs/analysis/`: requirements, questions, glossary, e2e use cases and YAML test data;
- `docs/ux/`: user flows, screens, wireframes, UI spec, HTML prototypes;
- `docs/architecture/`, `docs/qa/`, `docs/guides/`: role artifacts;
- `docs/issues/`: harness problem and solution log (skill `harness-issues`);
- `src/`, `tests/`, `scripts/`, `Dockerfile`, `docker-compose*.yml`, `Makefile`: code and CI/CD.

Product defects go to `docs/bugs/`; harness problems go to `docs/issues/`. Never mix them.

## Statuses, checkpoints, and acceptance

Task statuses: `pending`, `in_progress`, `awaiting_review`, `done`, `failed`, `blocked`.
Transitions: `pending -> in_progress`; `in_progress -> awaiting_review` at a checkpoint; `awaiting_review -> in_progress` after approval or a change request (except `CP-F`, which goes to `done`); `awaiting_review -> done` only after `CP-F` approval; `awaiting_review -> failed` on user rejection; `in_progress -> failed`; `failed -> in_progress`; `* -> blocked`.

Tasks run strictly sequentially across both workflows: at most one active task (`in_progress` or `awaiting_review`); no parallel/preempted feature or bugfix work. New pending cards and bug reports may be registered, but existing statuses/dependencies and `/harness-board-update` are forbidden while a task is active.

Every task has at least one checkpoint; `CP-F` is mandatory before `done`. At a checkpoint the role stops, the orchestrator creates the checkpoint file and sets `awaiting_review`, and the user reviews/edits artifacts and records a decision. Without explicit approval, the task stays `awaiting_review`.

A task is closed only by the card's `acceptance` criteria and `CP-F` approval. On failure, set `failed` with the cause in `Blockers`; up to 3 attempts, then `blocked`. A bug that cannot be reproduced after 3 attempts is `blocked` with evidence, not a speculative fix.

For any harness problem, blocker, or workaround, use the `harness-issues` skill and create a record in `docs/issues/`; the orchestrator updates the index and includes the issue in the task commit.

## Global installation and versions

- Agents/commands/workflows live in `~/.config/opencode/`; `/harness-init` copies `process.md`, workflow files, templates, and `version.json` into the project.
- `version.json` records the project version; `doctor` warns on mismatch. Global updates affect all projects; use a project-local vendor copy to freeze (if enabled).

## Security

- Do not add harness rules to the global `AGENTS.md`.
- Do not work outside the current project (`external_directory` is forbidden).
- Do not run `git push`, `git tag`, or rewrite history.
- Secrets only via environment variables.
