---
name: Local Harness
description: "Local multi-agent harness: roles, board, tasks, acceptance, artifacts. Use only on explicit user request and only in a project with harness/process.md. Do not use for ordinary coding tasks."
metadata:
  opencode/autoinvoke: false
---

# Local Harness

## When to use

Only when the user explicitly asks to run harness or execute `/harness-run`, `/harness-stage-done`, `/harness-feature`, `/harness-bug`, `/harness-board-update`, or `/harness-board-report` in a project that has `harness/process.md` and `docs/plan.md`.

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
- `/harness-stage-done T-XXX [CP-N]`: run checks, write the ledger/checkpoint, apply P2, and commit the snapshot.
- `/harness-board-update all|T-XXX`: reconcile the board from checkpoint files when no task is active.
- `/harness-board-report`: read-only board report.
- `/harness-doctor`: installation and project health check, including engine self-test, registry completeness, issue index, model context, compaction plugin, and RAG timeout checks.

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
| `harness-orchestrator` | board, bug registry, dependencies, checkpoints, acceptance, derived activity, commits |
| `harness-analyst` | requirements, RAG, questions, glossary, e2e use cases/test data; bug impact |
| `harness-ux-designer` | user flows, screen inventory, wireframes, UI spec, per-scenario HTML prototypes (may delegate page code to coder); UI bug impact |
| `harness-architect` | ADRs, overall architecture description, component/scenario/data/class/swimlane diagrams, OpenAPI specs, contracts; design-level root cause |
| `harness-coder` | code, unit/integration/e2e tests, CI/CD, local runs; reproduction and regression fix |
| `harness-qa` | text/code review, e2e coverage/run, independent bug verification, verdict |
| `harness-qa-vision` | visual review of diagrams, wireframes, and screenshots |
| `harness-doc-writer` | README, runbook, guides, ADR finalization, changelog |

The lead does not edit files itself; the orchestrator handles the board, bug registry, and commits.

## Artifacts

- `docs/plan.md`: board, the single source of truth for work scope;
- `docs/tasks/T-XXX-*.md`: feature/bugfix task cards with inputs, applicability, `workflow`, `stage`, and checkpoints;
- `docs/bugs/BUG-XXX-*.md` and `docs/bugs/README.md`: product bug reports and index, owned by the orchestrator;
- `docs/checkpoints/T-XXX-CP-N.md`: user review decisions, edits, remarks, and `*.checks.json` machine results;
- `docs/evidence/T-XXX.md`: append-only SHA256 ledger; `docs/metrics/`: token usage reports;
- `harness/checks/`: deterministic registry (`engine.json`, `feature.json`, `bugfix.json`);
- `docs/activity.puml` / `.svg`: derived visual progress aid only, never a
  status/routing/acceptance source; colors use `:task text; <<#RRGGBB>>`;
- `harness/workflows/`: feature and bugfix stage tables/task graphs;
- `docs/analysis/`: requirements, questions, glossary, e2e use cases and YAML test data;
- `docs/ux/`: user flows, screens, wireframes, UI spec, prototype catalog and
  one HTML page per `UC-E2E-NNN` under `docs/ux/prototype/<slug>/`;
- `docs/architecture/`: architecture description, ADRs, contracts, component/scenario/data/class/swimlane PlantUML diagrams, and OpenAPI 3.x specs;
- `docs/qa/`, `docs/guides/`: role artifacts;
- `docs/issues/`: harness problem and solution log (skill `harness-issues`);
- `src/`, `tests/`, `scripts/`, `Dockerfile`, `docker-compose*.yml`, `Makefile`: code and CI/CD.

Product defects go to `docs/bugs/`; harness problems go to `docs/issues/`. Never mix them.

## Statuses, checkpoints, and acceptance

Task statuses: `pending`, `in_progress`, `awaiting_review`, `done`, `failed`, `blocked`.
Transitions: `pending -> in_progress`; `in_progress -> awaiting_review` at a checkpoint; `awaiting_review -> in_progress` after approval or a change request (except `CP-F`, which goes to `done`); `awaiting_review -> done` only after `CP-F` approval; `awaiting_review -> failed` on user rejection; `in_progress -> failed`; `failed -> in_progress`; `* -> blocked`.

Tasks run strictly sequentially across both workflows: at most one active task (`in_progress` or `awaiting_review`); no parallel/preempted feature or bugfix work. New pending cards and bug reports may be registered, but existing statuses/dependencies and `/harness-board-update` are forbidden while a task is active.

Status decisions use the plan, task cards, checkpoints, bug cards, workflow files, and Git evidence. `docs/activity.puml`, `docs/activity.svg`, and derivatives are informational only; never use them to determine or reconcile status, dependencies, active task, acceptance, checkpoint decisions, or routing. If activity disagrees with the board/card, the board/card wins and activity is re-rendered.

Every task has at least one checkpoint; `CP-F` is mandatory before `done`. At a checkpoint the role stops and the orchestrator runs `stage-done.ps1`, which executes the registry checks, writes the checks JSON and evidence ledger, renders the checkpoint, and applies policy P2. An intermediate checkpoint with `FAIL=0`, `UNCHECKED=0`, `MANUAL=0`, and `hold: false` is approved by `auto (P2)`; manual items, failed/unchecked checks, `hold: true`, and `CP-F` wait for the user. Without explicit approval, the task stays `awaiting_review`.

A task is closed only by the card's `acceptance` criteria and `CP-F` approval. On failure, set `failed` with the cause in `Blockers`; up to 3 attempts per chunk, then `blocked`. A bug that cannot be reproduced after 3 attempts is `blocked` with evidence, not a speculative fix.

Generation is budgeted per `process.md` 11.1: A-02 and large code stages are chunked, artifacts are written incrementally, and a role stops at the context threshold with a handoff. `harness-analyst` and `harness-coder` may spawn self-sub-sessions of their own role for chunks (depth 2, sequential, no grandchildren). The single cross-role exception is `harness-ux-designer -> harness-coder` for prototype pages: one child at a time, same UX task, coder writes only `docs/ux/prototype/**`; all other cross-role calls are forbidden.

For any harness problem, blocker, or workaround, use the `harness-issues` skill and create a record in `docs/issues/`; the orchestrator updates the index and includes the issue in the task commit. `/harness-doctor` verifies that every issue file is indexed and that no issue lives in a root `harness-issues/` directory.

## Global installation and versions

- Agents/commands/workflows live in `~/.config/opencode/`; `/harness-init` copies `process.md`, workflow files, templates, and `version.json` into the project.
- `version.json` records the project version; `doctor` warns on mismatch. Global updates affect all projects; use a project-local vendor copy to freeze (if enabled).

## Security

- Do not add harness rules to the global `AGENTS.md`.
- Do not work outside the current project (`external_directory` is forbidden).
- Do not run `git push`, `git tag`, or rewrite history.
- Secrets only via environment variables.
