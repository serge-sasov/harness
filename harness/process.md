# Harness Process Rules (process.md)

Mandatory for all harness roles. A violation is a task blocker.

## 0. Installation and activation

- Harness is installed per user in `~/.config/opencode/`: agents `harness-*`, commands `/harness-*`, skill `harness`, templates, scripts.
- A project receives harness only via `/harness-init`: `harness/process.md`, `harness/version.json`, `harness/templates/`, `docs/plan.md`, `docs/activity.puml`, docs skeleton.
- Activation is explicit only; `default_agent` is never switched to harness.
- Before work, `harness` checks for `harness/process.md` and `docs/plan.md`; if missing, stop and ask for `/harness-init`.
- Global permissions allow any primary agent to call `harness-*` subagents. Roles must not call each other (`task: deny`); the primary agent routes.
- Role permissions include relative and `**/...` path variants: edit/write match absolute paths, so a blanket deny needs a specific allow for the full path.
- Problems go to `docs/issues/` via `harness-issues`; the orchestrator maintains the index.
- `harness/version.json` records the installed version; `/harness-doctor` warns on mismatch.

## 1. General rules

- Harness = role subagents + shared plan. All tasks use local Ollama models; no external APIs.
- `docs/plan.md` is the single source of work scope; this file is the single source of process rules.
- Each task is performed by exactly one role within its task/artifact boundaries.
- Tasks run strictly sequentially: at most one `in_progress`; no parallel `/harness-run`, multiple IDs, or concurrent role calls.

## 2. Role models

| Role | Model (Ollama) | Use |
|---|---|---|
| harness (lead) | `qwen3.8:27b-64k` (xhigh) | routing/reporting |
| orchestrator | `qwen3.8:27b-64k` (xhigh) | planning/context |
| analyst | `qwen3.8:27b-64k` (medium) | requirements/RAG |
| architect | `qwen3.8:27b-64k` (xhigh) | design |
| coder | `tiel-coder:35b-a3b-mtp-128k-text` | code/tests |
| qa | `qwen3.8:27b-64k` (low) | vision/QA; incremental report |
| doc-writer | `qwen3.8:27b-64k` (low) | docs |

## 3. Plan and board

- `docs/plan.md`: columns `ID | Task | Role | Dependencies | Status | Artifacts | Commit`.
- `docs/tasks/T-XXX-<slug>.md`: fields `id, title, role, status, depends_on, acceptance, artifacts, blockers, log`.
- Statuses: `pending`, `in_progress`, `blocked`, `done`, `failed`.
- Transitions: `pending -> in_progress -> done`; `in_progress -> failed`; `failed -> in_progress` after a fix; `* -> blocked` on an external blocker.
- Invariant: at most one `in_progress`; parallel execution forbidden.

## 4. Task lifecycle

1. Orchestrator checks the board: another `in_progress` forbids start; stop and report without changing statuses.
2. Check `depends_on`: all predecessors must be `done`.
3. Set `in_progress` in plan, card, diagram.
4. The role performs the task per the card's `acceptance`.
5. Verify acceptance; on failure set `failed` (section 7).
6. Set `done`; log what was done, files, commands, results.

## 5. Artifact updates (mandatory order)

1. `docs/plan.md`: status, artifacts, commit.
2. Task card: status, log, blockers.
3. `docs/activity.puml`: color `done` green `#90EE90`, `pending` gray `#D3D3D3`, `in_progress` yellow `#FFE082`, `failed` red `#FF9090`, `blocked` orange `#FFB347`.
4. Re-render `docs/activity.svg` via MCP `plantuml-render`.
5. `git commit` (section 6).

## 6. Git discipline

- Repository root; default branch `master` unless the repo uses another default.
- Commit after each meaningful task; at least one commit per task.
- Message: `T-XXX: short description`; service changes: `chore: ...`.
- Forbidden: `git push`, `git tag`, secrets/`.env`, history rewrite.
- Include only task files; unrelated changes go in a separate commit.

## 7. Error handling

- Acceptance failure -> `failed`; record what failed, output, hypothesis.
- Dependents wait for `done`.
- Max 3 fix attempts; then `blocked` and escalate.
- Empty subagent result or `finish=length` = failed attempt; record in the card log; do not leave `in_progress`.
- QA (`limit.output=16384`): write the report incrementally via `write`; final message <=10 lines; a long single message hitting `finish=length` is a failed attempt.
- Keep the failure cause in the log after fixing.

## 8. Role artifacts

| Role | Write area |
|---|---|
| harness | no files; reads board/cards, routes roles |
| orchestrator | `docs/plan.md`, `docs/tasks/`, `docs/activity.puml`, `README.md`, `.gitignore` |
| analyst | `docs/analysis/` |
| architect | `docs/architecture/` |
| coder | `src/`, `backend/`, `tests/`, `scripts/`, `Dockerfile`, `docker-compose*.yml`, `Makefile`, `.gitignore`, `requirements.txt`, `pyproject.toml`, `.env.example`, `alembic.ini`, `sources.yaml` |
| qa | `docs/qa/` |
| doc-writer | `docs/guides/`, `README.md`, ADR finalization |

All roles may create `docs/issues/` records; the orchestrator verifies the index.

## 9. Prohibitions

- Editing `~/.config/opencode/**` or system configs.
- Production actions: `git push`, `docker push`, deployment outside local/staging, production migrations.
- Secrets/tokens/keys in code, logs, or commits.
- Nested subagent calls (`task: deny` on roles; `harness` allows only harness roles).
- Parallel task execution: >1 `in_progress`, concurrent `/harness-run`, batch/parallel `task`, or `board-update` while a task is active.
- Access outside drive `C:` (see agent permissions).

## 10. Problem tracking

- Any problem, blocker, permission deny, MCP/RAG/model failure, git/board issue, or workaround creates an issue.
- Use `harness-issues` and `harness/scripts/new-issue.ps1`; fallback: `harness/templates/issue.md`.
- One file per problem: `docs/issues/ISSUE-YYYYMMDD-HHMMSS-<slug>.md`.
- Index: `docs/issues/README.md`; orchestrator verifies and commits.
- Required: status, severity, type, source, role, absolute location, symptoms, cause, solution/workaround, verification, prevention, links.
- Put the issue ID in the card log; an issue does not replace the card.
- Never write secrets/tokens/`.env` to an issue.
- On resolution set `resolved`/`workaround`; do not delete history.
