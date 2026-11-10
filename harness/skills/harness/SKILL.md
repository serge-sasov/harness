---
name: Local Harness
description: "Local multi-agent harness: roles, board, tasks, acceptance, artifacts. Use only on explicit user request and only in a project with harness/process.md. Do not use for ordinary coding tasks."
metadata:
  opencode/autoinvoke: false
---

# Local Harness

## When to use

Only when the user explicitly asks to run harness or execute `/harness-run`, `/harness-board-update`, `/harness-board-report` in a project that has `harness/process.md` and `docs/plan.md`.

Do not use for ordinary development, analysis, or documentation tasks.

## Project check

Before any action:

1. Verify that `harness/process.md` and `docs/plan.md` exist.
2. If not, stop and suggest `/harness-init`.
3. Read `harness/process.md`; it is the source of process rules.
4. Read `docs/plan.md` and the task card `docs/tasks/T-XXX-*.md`.

## Commands

`/harness-init`, `/harness-run T-XXX`, `/harness-board-update all|T-XXX`, `/harness-board-report`, `/harness-doctor`. Explicit only; `default_agent` is never switched to harness.

## Roles

| Agent | Role |
|---|---|
| `harness` | primary lead: routing, marker checks, reporting |
| `harness-orchestrator` | board, dependencies, acceptance, activity, commits |
| `harness-analyst` | requirements, RAG, questions, glossary |
| `harness-architect` | ADRs, PlantUML, contracts |
| `harness-coder` | code, tests, CI/CD, local runs |
| `harness-qa` | review, vision, accept/reject verdict |
| `harness-doc-writer` | README, runbook, guides, ADR finalization |

The lead does not edit files itself; the orchestrator handles the board and commits.

## Artifacts

- `docs/plan.md`: board, the single source of truth for work scope;
- `docs/tasks/T-XXX-*.md`: task cards;
- `docs/activity.puml` / `.svg`: task statuses;
- `docs/analysis/`, `docs/architecture/`, `docs/qa/`, `docs/guides/`: role artifacts;
- `docs/issues/`: problem and solution log (skill `harness-issues`);
- `src/`, `tests/`, `scripts/`, `Dockerfile`, `docker-compose*.yml`, `Makefile`: code and CI/CD.

## Statuses and acceptance

`pending -> in_progress -> done`; `in_progress -> failed`; `failed -> in_progress`; `* -> blocked` on an external blocker.

Tasks run strictly sequentially: at most one `in_progress`; parallel task execution is forbidden. `/harness-run` accepts exactly one task ID.

A task is closed only by the card's `acceptance` criteria. On failure, set `failed` with the cause in `Blockers`; up to 3 attempts, then `blocked`.

For any problem, blocker, or workaround, use the `harness-issues` skill and create a record in `docs/issues/`; the orchestrator updates the index and includes the issue in the task commit.

## Global installation and versions

- Agents/commands live in `~/.config/opencode/`; `/harness-init` copies `process.md`, templates, and `version.json` into the project.
- `version.json` records the project version; `doctor` warns on mismatch. Global updates affect all projects; use a project-local vendor copy to freeze (if enabled).

## Security

- Do not add harness rules to the global `AGENTS.md`.
- Do not work outside the current project (`external_directory` is forbidden).
- Do not run `git push`, `git tag`, or rewrite history.
- Secrets only via environment variables.
