# Local harness: solution description

| Field | Value |
|---|---|
| Status | current |
| Date | 2026-11-07 |
| Scope | local multi-agent harness + pilot "Mini-CRUD service" |
| Requirements source | [`requirements/initial.txt`](../../requirements/initial.txt) |
| Process rules | [`harness/process.md`](../../harness/process.md) |
| Board | [`docs/plan.md`](../plan.md) |
| HTML version | [`index.html`](index.html) |

This document describes the solution end to end: purpose, architecture, scenario
map, sequence diagrams for each scenario, the conceptual class model, and the
pilot case that confirmed the full cycle. All diagrams are embedded in the text;
the PlantUML source is linked next to each one.

---

## 1. Purpose and scope

A local harness is needed for designing solution and software architecture and
then implementing it. The process is performed by different roles within
individual tasks and a shared plan: tasks have dependencies, statuses, an
owning role, and acceptance criteria. Each role is a separate sub-agent running
on a local Ollama model; external APIs are not used.

The solution covers:

- harness: roles, board, task cards, process rules, commands, artifacts;
- local models and tools: Ollama, `local-rag`, MCP `plantuml-render`, Git;
- the pilot "Mini-CRUD service" as an end-to-end example: requirements -> ADR ->
  diagrams -> QA acceptance.

Out of scope: authentication, external integrations, production deployment,
multi-user operation, pagination, and note search.

### Key principles

1. **Single board** - `docs/plan.md` is the only source of truth for the work scope.
2. **Single process** - `harness/process.md` defines the lifecycle, statuses,
   artifact update order, and git discipline.
3. **Role isolation** - each role writes only to its area and stays within task
   boundaries; nested subagent calls are forbidden.
4. **Deterministic acceptance** - a task closes only by the card's `acceptance`
   criteria; failure is recorded in `Blockers`.
5. **Locality** - models, embeddings, diagram rendering, and tests run locally.
6. **Traceability** - decisions, diagrams, contracts, reviews, and commits are
   linked through task IDs.

---

## 2. Architecture

### 2.1 Component diagram

![Harness component diagram](diagrams/components-harness.svg)

Source: [`diagrams/components-harness.puml`](diagrams/components-harness.puml).

Solution layers:

| Layer | Components | Purpose |
|---|---|---|
| Control | opencode, primary agent `harness`, `/harness-*` commands, global installation | explicit start, role routing, artifact sync |
| Roles | `harness-orchestrator`, `harness-analyst`, `harness-architect`, `harness-coder`, `harness-qa`, `harness-doc-writer` | work within responsibility areas |
| Models | `qwen3.8:27b-64k`, `tiel-coder:35b-a3b-mtp-128k-text` | local inference without external APIs |
| Sources of truth | `docs/plan.md`, `docs/tasks/*.md` | work scope, statuses, dependencies, acceptance |
| Artifacts | `docs/analysis`, `docs/architecture`, `docs/qa`, `docs/guides`, `docs/issues`, `src`, `tests` | role results |
| Tools | MCP `plantuml-render`, `local-rag`, Git | diagram validation/rendering, source search, versioning |
| Pilot | FastAPI REST API, NoteService, NoteRepository, SQLite | end-to-end implementation example |

Control flow: the user calls `/harness-run T-XXX` -> the command switches the
session to the primary agent `harness` -> the lead checks the marker and
`depends_on` -> `harness-orchestrator` maintains the board and acceptance -> the
responsible role writes artifacts -> the orchestrator updates the board/diagram
and commits.

### 2.2 Roles and models

| Role | Ollama model | Thinking | Main task |
|---|---|---|---|
| harness lead | `qwen3.8:27b-64k` | xhigh | explicit start, marker, routing, report |
| orchestrator | `qwen3.8:27b-64k` | xhigh | board, dependencies, acceptance, commits |
| analyst | `qwen3.8:27b-64k` | medium | requirements, RAG analysis, questions, glossary |
| architect | `qwen3.8:27b-64k` | xhigh | ADR, PlantUML diagrams, contracts |
| coder | `tiel-coder:35b-a3b-mtp-128k-text` | - | code, tests, CI/CD, local deployment |
| qa | `qwen3.8:27b-64k` | - | review, visual diagram checks (64K), verdict |
| doc-writer | `qwen3.8:27b-64k` | low | README, runbook, guides, ADR finalization |

Agents are installed globally as `harness`, `harness-orchestrator`,
`harness-analyst`, `harness-architect`, `harness-coder`, `harness-qa`,
`harness-doc-writer`; the lead calls them via `task`.

### 2.3 Permissions and write areas

| Role | Write area | Forbidden |
|---|---|---|
| harness lead | writes no files; reads and delegates only | edit/write, git commit, calling roles outside harness |
| orchestrator | `docs/**`, `README.md`, `.gitignore` | other roles' work, `git push/tag/reset/rebase` |
| analyst | `docs/analysis/**`, `docs/tasks/**` (own status/log) | architecture, code, tests, commits |
| architect | `docs/architecture/**`, `docs/tasks/**` | code, tests, editing `docs/analysis` |
| coder | `src/**`, `tests/**`, `scripts/**`, `Dockerfile`, `docker-compose*.yml`, `Makefile`, `.gitignore` | prod actions, `git commit`, `docker push`, cloud CLIs |
| qa | `docs/qa/**`, `docs/tasks/**` | fixing code/artifacts, commits, deployment |
| doc-writer | `README.md`, `docs/guides/**`, `docs/architecture/adr-*.md` (editing) | code, tests, CI/CD, changing ADR meaning |

Permissions include both relative and `**/...` pattern variants: opencode
matches edit/write against the absolute path, so the blanket deny `"*": "deny"`
is overridden by a specific allow matching the full path. `.gitignore` is
allowed for orchestrator and coder. All roles may create issue files in
`docs/issues/**`; the orchestrator maintains the index.

Common prohibitions: editing `~/.config/opencode/**`, secrets in code/logs/commits,
nested subagent calls, access outside drive `C:`, production deployment.

### 2.4 Sources of truth and artifacts

| Artifact | Path | Owner |
|---|---|---|
| Board | `docs/plan.md` | orchestrator |
| Task card | `docs/tasks/T-XXX-*.md` | task role + orchestrator |
| Requirements | `docs/analysis/requirements-*.md` | analyst |
| Questions and assumptions | `docs/analysis/questions-*.md` | analyst |
| Glossary | `docs/analysis/glossary.md` | analyst |
| ADR | `docs/architecture/adr-NNN-*.md` | architect (finalization: doc-writer) |
| Diagrams | `docs/architecture/*.puml`, `*.svg` | architect |
| Contracts | `docs/architecture/contracts-*.md` | architect |
| QA report | `docs/qa/review-T-XXX.md` | qa |
| Code and tests | `src/`, `tests/`, `scripts/`, `Dockerfile`, compose, `Makefile` | coder |
| Activity diagram | `docs/activity.puml`, `docs/activity.svg` | orchestrator |
| Guides | `docs/guides/**`, `README.md` | doc-writer |
| Issue log | `docs/issues/ISSUE-*.md`, `docs/issues/README.md` | all roles; index: orchestrator |

---

## 3. Scenario map

![Scenario map](diagrams/scenario-map.svg)

Source: [`diagrams/scenario-map.puml`](diagrams/scenario-map.puml).

| ID | Scenario | Trigger | Roles | Result |
|---|---|---|---|---|
| S-01 | Installation and bootstrap | `install.ps1`, then `/harness-init` | opencode, global harness, Ollama | global agents installed, project initialized |
| S-02 | Full task cycle | `/harness-run T-XXX` | harness lead + orchestrator + role | task `done`/`failed`, commit, dependents unblocked |
| S-03 | Requirements analysis | analyst task | analyst, local-rag | requirements, questions, glossary |
| S-04 | Architecture and diagrams | architect task | architect, MCP PlantUML | ADR, `.puml`/`.svg`, contracts, decomposition |
| S-05 | Implementation and tests | coder task | coder, test runner, Docker | code, tests, CI/CD, local run |
| S-06 | QA acceptance | qa task | qa, test runner, vision | review report and `accept`/`reject` verdict |
| S-07 | Documentation | doc-writer task | doc-writer | README, runbook, guides, ADR finalization |
| S-08 | Board sync | `harness-board-update all / T-XXX` | orchestrator, MCP, Git | statuses, commits, SVG, chore commit |
| S-09 | Board report | `harness-board-report` | orchestrator | summary and recommendations (read-only) |
| S-10 | Errors and blockers | acceptance failure | orchestrator, role, user | `failed` -> retry <=3 -> `blocked`/`done` |
| S-11 | Pilot end-to-end | task T-013 | orchestrator, analyst, architect, qa | confirmed full cycle on "Mini-CRUD" |

---

## 4. Scenarios

### S-01. Harness installation and bootstrap

**Goal:** install harness globally once and initialize it in the project.
**Preconditions:** the harness source repository is available, Ollama is running,
models are loaded.

![S-01 Installation and bootstrap](diagrams/seq-01-bootstrap.svg)

Source: [`diagrams/seq-01-bootstrap.puml`](diagrams/seq-01-bootstrap.puml).

**Result:** agents, commands, skill, templates, and scripts are in
`~/.config/opencode/`; the project has `harness/process.md`,
`harness/version.json`, and `docs/plan.md`. **Note:** `default_agent` is not
changed; an opencode restart is required after installing agents. Activation is
only via explicit `/harness-*`.

### S-02. Full task cycle (`/harness-run`)

**Goal:** take a task from dependency checks through acceptance and commit.
**Preconditions:** the project is initialized (`harness/process.md`), the card
`docs/tasks/T-XXX-*.md` exists, all `depends_on` are `done`, and no other task
is `in_progress`. Tasks run strictly sequentially - parallel starts are forbidden.

![S-02 Full task cycle](diagrams/seq-02-harness-run.svg)

Source: [`diagrams/seq-02-harness-run.puml`](diagrams/seq-02-harness-run.puml).

**Result:** the task is `done`, the board, card, activity diagram, and SVG are
updated, and a commit `T-XXX: ...` is made; dependent tasks are unblocked.
**Errors:** no marker - stop and suggest `/harness-init`; unmet dependencies -
stop without starting; another task `in_progress` - stop without changing
statuses; `acceptance` failure - `failed` and cause in `Blockers`.

### S-03. Requirements analysis (analyst)

**Goal:** collect and refine requirements and check existing materials via RAG.
**Preconditions:** a statement exists and `local-rag` is available (when Ollama
is unavailable, RAG works in FTS5 mode).

![S-03 Requirements analysis](diagrams/seq-03-analyst.svg)

Source: [`diagrams/seq-03-analyst.puml`](diagrams/seq-03-analyst.puml).

**Result:** `docs/analysis/requirements-*.md` with atomic verifiable
requirements `R-NNN`, `questions-*.md` with open questions and assumptions,
`glossary.md`; an orchestrator report with risks and blockers. **Errors:**
missing data is recorded as a question, not as an invented requirement.

### S-04. Architecture and diagrams (architect)

**Goal:** make an architectural decision with alternatives, produce diagrams and
contracts. **Preconditions:** analyst requirements are accepted.

![S-04 Architecture and diagrams](diagrams/seq-04-architect.svg)

Source: [`diagrams/seq-04-architect.puml`](diagrams/seq-04-architect.puml).

**Result:** an ADR from the template, component/sequence diagrams `.puml` + `.svg`,
interface contracts, and decomposition for the coder. **Mandatory control:**
every diagram passes `check_syntax`, then `render_file`; syntax errors are fixed
before handoff. A decision without alternatives is not acceptable.

### S-05. Implementation and tests (coder)

**Goal:** implement strictly per ADRs and contracts. **Preconditions:** ADRs and
contracts are accepted; the task includes a local run target.

![S-05 Implementation and tests](diagrams/seq-05-coder.svg)

Source: [`diagrams/seq-05-coder.puml`](diagrams/seq-05-coder.puml).

**Result:** code in `src/`, tests in `tests/`, CI/CD preparation (`Dockerfile`,
compose, Makefile, scripts), green tests, and a locally running service.
**Errors:** failing tests are fixed without weakening assertions; when context is
insufficient - stop with a blocker, not a partial implementation.

### S-06. QA acceptance (qa)

**Goal:** independently verify artifacts against `acceptance`. **Preconditions:**
the role results were passed by the orchestrator.

![S-06 QA acceptance](diagrams/seq-06-qa.svg)

Source: [`diagrams/seq-06-qa.puml`](diagrams/seq-06-qa.puml).

**Result:** `docs/qa/review-T-XXX.md` with a "criterion -> pass/fail" table,
findings by severity, and an `accept`/`reject` verdict; an independent test run
(read-only) and visual diagram review. **Errors:** `reject` returns the task for
fixes; QA does not edit artifacts itself.

### S-07. Documentation (doc-writer)

**Goal:** bring documentation in line with the actual solution. **Preconditions:**
ADRs, contracts, and implementation are available.

![S-07 Documentation](diagrams/seq-07-doc-writer.svg)

Source: [`diagrams/seq-07-doc-writer.puml`](diagrams/seq-07-doc-writer.puml).

**Result:** README, runbook, guides, ADR finalization from the template; relative
links, verified commands. **Constraint:** do not change the meaning of ADRs and
contracts - only form and completeness.

### S-08. Board sync (`harness-board-update`)

**Goal:** bring the plan, cards, and activity diagram in line with the actual
state. **Preconditions:** the project is initialized; tasks are completed or
statuses changed.

![S-08 Board sync](diagrams/seq-08-harness-board-update.svg)

Source: [`diagrams/seq-08-harness-board-update.puml`](diagrams/seq-08-harness-board-update.puml).

**Result:** the `harness` lead delegates to `harness-orchestrator`: update
`docs/plan.md`, cards, `docs/activity.puml` colors, re-render
`docs/activity.svg`, record commit hashes, and commit `chore: board update (...)`.
**Rule:** on divergence, the task card is the source of truth.

### S-09. Board report (`harness-board-report`)

**Goal:** get a summary without changing artifacts. **Preconditions:** the project
is initialized.

![S-09 Board report](diagrams/seq-09-harness-board-report.svg)

Source: [`diagrams/seq-09-harness-board-report.puml`](diagrams/seq-09-harness-board-report.puml).

**Result:** the `harness` lead delegates to `harness-orchestrator` for a read-only
summary: status table, tasks ready to start, `failed`/`blocked` with causes,
%done, dangling dependency check, 1-3 recommendations. **Rule:** the scenario is
strictly read-only; nothing is committed.

### S-10. Errors, retries, and blockers

**Goal:** handle acceptance failure predictably without losing history.
**Preconditions:** the role returned a result; the orchestrator performed acceptance.

![S-10 Errors and blockers](diagrams/seq-10-errors.svg)

Source: [`diagrams/seq-10-errors.puml`](diagrams/seq-10-errors.puml).

**Result:** on failure the task becomes `failed`, the cause and output are written
to the card; up to 3 fix attempts are made; after exhaustion - `blocked` and
escalation to the user. Error history is not deleted during fixes.

### S-11. Pilot end-to-end cycle T-013

**Goal:** prove the full cycle works on a separate task. **Preconditions:**
harness is assembled (T-001..T-012), roles are available.

![S-11 Pilot end-to-end](diagrams/seq-11-pilot-e2e.svg)

Source: [`diagrams/seq-11-pilot-e2e.puml`](diagrams/seq-11-pilot-e2e.puml).

**Result:** the analyst produced pilot requirements, the architect - an ADR and
component diagram, QA - a review with verdict `accept`; T-013 is `done`, a commit
is made. The pilot confirmed that role prompts are sufficiently deterministic.

---

## 5. Conceptual class model

![Harness classes](diagrams/class-harness.svg)

Source: [`diagrams/class-harness.puml`](diagrams/class-harness.puml).

The model is conceptual: it describes the harness domain (board, tasks, roles,
artifacts), not the classes of a specific application.

| Class | Purpose |
|---|---|
| `PlanBoard` | board `docs/plan.md`: load tasks, change status, record a commit |
| `TaskCard` | task card: id, role, dependencies, acceptance, artifacts, blockers, log |
| `TaskStatus` | statuses `pending`, `in_progress`, `done`, `failed`, `blocked` |
| `Role` | abstract role: model, permissions, write areas, task execution |
| `Orchestrator`, `Analyst`, `Architect`, `Coder`, `QA`, `DocWriter` | concrete harness roles |
| `ModelProfile` | local model, thinking mode, purpose |
| `Artifact` | role artifact with path, type, and producer |
| `Diagram` | PlantUML source and SVG render; validation and rendering |
| `Review` | QA report: verdict and findings list |
| `Finding` | finding with ID, severity, and text |
| `Commit` | task git commit: hash and message |
| `Command` | opencode command: `/harness-run`, `/harness-board-update`, `/harness-board-report` |
| `HarnessLead` | primary agent `harness`: marker, routing, report; writes no files |
| `LogEntry` | task card log entry |
| `RoleResult` | role result: status, files, summary |

Key relationships: `PlanBoard 1 *-- 0..* TaskCard`; `TaskCard` depends on other
cards (`dependsOn`), is assigned to one role, and has one status; a role produces
many artifacts; `Diagram` and `Review` inherit `Artifact`; `HarnessLead` is
selected by a command, reads the board/cards, and calls roles; the orchestrator
updates the board and creates commits.

---

## 6. Process, statuses, and control

### 6.1 Task lifecycle

1. The `harness` lead checks the project marker, `depends_on` (all `done`), and
   that no other task is `in_progress`.
2. `harness-orchestrator` sets the task to `in_progress` (plan, card, diagram
   color).
3. The role performs the task strictly per the card's `acceptance`.
4. `harness-orchestrator` accepts the result; on failure - `failed`.
5. Status -> `done`, log entry, board/activity/SVG update, and commit.

Tasks run strictly sequentially: at most one `in_progress` at a time; parallel
task starts are forbidden.

### 6.2 Statuses

| Status | Color | Meaning |
|---|---|---|
| `pending` | `#D3D3D3` | not started |
| `in_progress` | `#FFE082` | in progress |
| `done` | `#90EE90` | completed and accepted |
| `failed` | `#FF9090` | error, fix required |
| `blocked` | `#FFB347` | external blocker |

Allowed transitions: `pending -> in_progress -> done`; `in_progress -> failed`;
`failed -> in_progress` (after a fix); `* -> blocked` on an external blocker.

### 6.3 Mandatory artifact update order

1. `docs/plan.md` - status, artifacts, commit hash.
2. `docs/tasks/T-XXX-*.md` - status, log, blockers.
3. `docs/activity.puml` - task block color.
4. Re-render `docs/activity.svg` via MCP `plantuml-render`.
5. `git commit` with message `T-XXX: ...`.

### 6.4 Git discipline

- Repository at the project root; default branch `master`.
- At least one commit per task; format `T-XXX: short description`.
- Forbidden: `git push`, `git tag`, history rewrite, committing secrets and `.env`.
- Only task files are included in the commit.

### 6.5 Plan execution diagram

![Activity diagram T-001..T-013](../activity.svg)

Source: [`docs/activity.puml`](../activity.puml). Green - `done`, gray -
`pending`, yellow - `in_progress`, red - `failed`, orange - `blocked`.

### 6.6 Issue log

Harness problems are recorded by the `harness-issues` skill:

- `docs/issues/ISSUE-YYYYMMDD-HHMMSS-<slug>.md` - one problem;
- [`docs/issues/README.md`](../issues/README.md) - index list.

A record contains status, severity, type, source, role, absolute location,
symptoms, reproduction, cause, solution/workaround, verification, prevention,
and timeline. All roles may create issue files; `harness-orchestrator` verifies
the index and includes them in the task commit. Secrets are never written to issues.

---

## 7. Pilot case "Mini-CRUD service" (T-013)

The pilot checks the analyst -> architect -> qa cycle on a separate task: REST CRUD
for notes, SQLite, local Docker, deterministic tests. One user, no auth, no
external integrations.

### 7.1 Requirements

| ID | Requirement |
|---|---|
| R-001 | `POST /notes` with `title`, `body`; response 201 with `id`. |
| R-002 | `GET /notes` - array of notes, sorted by `created_at` descending. |
| R-003 | `GET /notes/{id}`; 404 if missing. |
| R-004 | `PUT /notes/{id}` with `title`, `body`; 404 if missing. |
| R-005 | `DELETE /notes/{id}`; 204 on success, 404 if missing. |
| R-006 | Validation: `title` 1..200 characters, `body` up to 10000; error 422. |
| NFR-1 | `docker compose up` starts the service on port 8080. |
| NFR-2 | SQLite file in a volume; survives container restart. |
| NFR-3 | Unit + API tests, deterministic, no network. |

Pilot open questions: pagination is not needed (Q-001), full-text search is out
of scope (Q-002). Risks: SQLite file growth (R1), no auth - local/staging only
(R2). Full requirements: [`docs/analysis/pilot-requirements.md`](../analysis/pilot-requirements.md).

### 7.2 Architectural decision (ADR-001)

Stack: Python 3.12 + FastAPI + SQLAlchemy 2.x (SQLite) + Pydantic v2. Structure:
thin API layer -> service layer -> repository. Tests: pytest + httpx (ASGI
transport). Container: `python:3.12-slim`, docker compose with a DB volume.

| Alternative | Why rejected |
|---|---|
| Flask + SQLite | manual validation, less typing |
| Node/Express + better-sqlite3 | second stack in the local environment |
| Django + DRF | overkill for one CRUD |

Full ADR: [`docs/architecture/pilot-adr.md`](../architecture/pilot-adr.md).

### 7.3 REST contract

| Method | Path | Body | Response |
|---|---|---|---|
| POST | `/notes` | `{title, body}` | 201 `{id, title, body, created_at}` |
| GET | `/notes` | - | 200 `[...]` |
| GET | `/notes/{id}` | - | 200 / 404 |
| PUT | `/notes/{id}` | `{title, body}` | 200 / 404 |
| DELETE | `/notes/{id}` | - | 204 / 404 |

Errors: `{"detail": "..."}`; validation - 422 (Pydantic).

### 7.4 Pilot component diagram

![Pilot CRUD components](../architecture/pilot-components.svg)

Source: [`docs/architecture/pilot-components.puml`](../architecture/pilot-components.puml).

### 7.5 Pilot class model

![Pilot CRUD classes](diagrams/class-pilot.svg)

Source: [`diagrams/class-pilot.puml`](diagrams/class-pilot.puml).

`Note` - domain entity; `NoteCreate`/`NoteUpdate` - input schemas; `NoteRead` -
output schema; `NoteService` - domain logic; `NoteRepository` - SQLite access;
`NoteNotFound` - 404 error.

### 7.6 QA result

Verdict: **accept**. Minor findings: N-001 - the Python image version is not
pinned (pin in Dockerfile at the coder stage); N-002 - the `created_at` format is
not described (ISO-8601 UTC). Full report:
[`docs/qa/pilot-review.md`](../qa/pilot-review.md).

---

## 8. Operations

### 8.1 Global installation and quick start

1. From the repository root, run the global installation:
   `powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1`.
2. Restart opencode; check the installation with `/harness-doctor`.
3. In the project, run `/harness-init`; check `harness/process.md` and
   `docs/plan.md`.
4. Fill in `docs/plan.md` and create a card from
   `harness/templates/task-card.md`.
5. Start a task with `/harness-run T-XXX`.
6. Summary: `/harness-board-report`; sync: `/harness-board-update all`.
7. Diagram: `docs/activity.puml`, render: `docs/activity.svg`.

`default_agent` is not switched to harness: activation is only via explicit
`/harness-*`. Global installation is per current user (`~/.config/opencode`).

### 8.2 Commands

| Command | Argument | Purpose |
|---|---|---|
| `/harness-init` | - | create harness and marker files in the current project |
| `/harness-run` | `T-XXX` | dependency checks, `in_progress`, role call, acceptance, commit |
| `/harness-board-update` | `T-XXX` or `all` | reconcile statuses, commits, activity diagram, and SVG |
| `/harness-board-report` | - | read-only summary: statuses, blockers, ready tasks, recommendations |
| `/harness-doctor` | - | check the global installation and the current project |

### 8.3 How to add a task

1. Create a card from `harness/templates/task-card.md`.
2. Add a row to `docs/plan.md` from `harness/templates/plan-row.md`.
3. Specify the role, `depends_on`, `acceptance`, and artifacts.
4. Run `harness-run T-XXX` after dependencies are done.
5. After the task, update the board/card/diagram and commit.

### 8.4 Limitations and risks

- SQLite is not designed for concurrent writes - accepted for the pilot.
- No auth - the service is local/staging only.
- Models are local: quality and speed depend on hardware; when Ollama is
  unavailable, RAG works in FTS5 mode.
- Diagrams and documentation require periodic reconciliation with code.
- Role prompts are deterministic but do not guarantee a perfect first pass -
  `failed` and retry <= 3 are provided.

### 8.5 HTML build

The HTML version is generated from this file and requires no network:

```powershell
python docs/description/build_html.py
```

The script embeds all SVGs as `data:` URIs, wraps diagrams in zoomable figures,
and builds `docs/description/index.html`. The page template and modal styles/JS
are in `docs/description/template.html`. Python 3.12 and the `markdown` package
are required.

### 8.6 Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| role is not visible in opencode | agents were added after startup | restart opencode |
| model is unavailable | Ollama is not running / model is not loaded | start Ollama, `ollama pull` |
| RAG answers without embeddings | Ollama is unavailable | FTS5 mode; does not block the task |
| diagram does not render | PlantUML error | `check_syntax`, fix `.puml`, rerun `render_file` |
| task does not start | a dependency is not `done` | check `depends_on` and card statuses |

---

## 9. Traceability

| Scenario | Artifacts | Source |
|---|---|---|
| S-01 | global agents, project marker | [`harness/scripts/install.ps1`](../../harness/scripts/install.ps1), [`harness/commands/harness-init.md`](../../harness/commands/harness-init.md) |
| S-02 | plan, card, activity, commit | [`harness/commands/harness-run.md`](../../harness/commands/harness-run.md) |
| S-03 | requirements, questions, glossary | [`harness/agents/harness-analyst.md`](../../harness/agents/harness-analyst.md) |
| S-04 | ADR, diagrams, contracts | [`harness/agents/harness-architect.md`](../../harness/agents/harness-architect.md) |
| S-05 | code, tests, CI/CD | [`harness/agents/harness-coder.md`](../../harness/agents/harness-coder.md) |
| S-06 | review report | [`harness/agents/harness-qa.md`](../../harness/agents/harness-qa.md) |
| S-07 | README, guides, ADR | [`harness/agents/harness-doc-writer.md`](../../harness/agents/harness-doc-writer.md) |
| S-08 | board, cards, activity | [`harness/commands/harness-board-update.md`](../../harness/commands/harness-board-update.md) |
| S-09 | board summary | [`harness/commands/harness-board-report.md`](../../harness/commands/harness-board-report.md) |
| S-10 | `failed`/`blocked`, log | [`harness/process.md`](../../harness/process.md), section 7 |
| S-11 | pilot requirements, ADR, QA | [`docs/tasks/T-013-smoke-test.md`](../tasks/T-013-smoke-test.md) |

---

## 10. File map

| Path | Contents |
|---|---|
| `README.md` | harness overview and quick start |
| `requirements/initial.txt` | initial requirements |
| `harness/process.md` | process rules |
| `harness/agents/*.md` | primary agent `harness` and role subagents |
| `harness/commands/*.md` | `/harness-*` commands |
| `harness/skills/harness/SKILL.md` | global harness skill |
| `harness/skills/harness-issues/SKILL.md` | problem and solution tracking skill |
| `harness/templates/*.md` | card, ADR, plan-row, issue templates |
| `harness/scripts/*.ps1` | install, init, doctor, uninstall, new-issue |
| `harness/version.json` | installation version |
| `docs/plan.md` | task board |
| `docs/tasks/*.md` | task cards |
| `docs/issues/` | problem and solution log |
| `docs/analysis/` | pilot requirements |
| `docs/architecture/` | pilot ADR and diagrams |
| `docs/qa/` | pilot review report |
| `docs/activity.puml/.svg` | plan activity diagram |
| `docs/description/` | this description, diagrams, and HTML |
| `docs/description/README.md` | source description (Markdown) |
| `docs/description/diagrams/` | `.puml` sources and `.svg` renders |
| `docs/description/build_html.py` | self-contained HTML build |
| `docs/description/template.html` | HTML template, CSS, and pan/zoom modal |
| `docs/description/index.html` | self-contained HTML version with zoom modal |
| `docs/guides/harness-global.md` | global installation, activation, pin, troubleshooting |

---

## Appendix. Glossary

| Term | Meaning |
|---|---|
| Harness | local system of role subagents with a shared plan and process |
| Sub-agent | a role called by a primary agent via `task` |
| Board | `docs/plan.md` - task table with statuses and dependencies |
| Task card | MD file with id, role, `depends_on`, `acceptance`, log |
| Acceptance | verifiable task acceptance criteria |
| Artifact | a file or set of files created by a role |
| ADR | Architecture Decision Record |
| MCP | tool protocol; here - `plantuml-render` and `local-rag` |
| RAG | search over a local index (FTS5 + LanceDB + Ollama) |
| SVG | vector diagram format, scales without quality loss |
| Pan/zoom | drag and scale a diagram in an HTML modal |

---

## Sources

- [`requirements/initial.txt`](../../requirements/initial.txt) - initial requirements.
- [`README.md`](../../README.md) - repository layout and quick start.
- [`docs/guides/harness-global.md`](../guides/harness-global.md) - global installation and activation.
- [`harness/process.md`](../../harness/process.md) - process rules.
- [`docs/plan.md`](../plan.md) - task board T-001..T-013.
- [`docs/analysis/pilot-requirements.md`](../analysis/pilot-requirements.md) - pilot requirements.
- [`docs/architecture/pilot-adr.md`](../architecture/pilot-adr.md) - ADR-001.
- [`docs/qa/pilot-review.md`](../qa/pilot-review.md) - pilot QA review.
- [`docs/tasks/T-013-smoke-test.md`](../tasks/T-013-smoke-test.md) - pilot cycle card.
