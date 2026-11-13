# Local harness: architecture + implementation

A local harness for developing solution and software architecture followed by
implementation. The entire process is performed by role subagents based on local
Ollama models. The harness is installed globally for the current user but is
activated in a project only explicitly via `/harness-*`.

One harness supports two base workflows: `feature` (new behavior or a new
project) and `bugfix` (restore expected behavior with a failing regression test).
Both share one board, one role set, one status model, and one active task.

Detailed guide: [`docs/guides/harness-global.md`](docs/guides/harness-global.md).
Usage manual (RU, HTML): [`docs/manual/index.html`](docs/manual/index.html).

## Contents

- `harness/process.md` - shared production process rules
- `harness/workflows/feature.md`, `harness/workflows/bugfix.md` - stage tables,
  task graphs, gates, and escalation rules
- `harness/agents/` - primary agent `harness` and role subagents
  (`harness-orchestrator`, `harness-analyst`, `harness-ux-designer`,
  `harness-architect`, `harness-coder`, `harness-qa`, `harness-qa-vision`,
  `harness-doc-writer`)
- `harness/commands/` - opencode commands: `/harness-feature`, `/harness-bug`,
  `/harness-run`, `/harness-stage-done`, `/harness-board-update`,
  `/harness-board-report`, `/harness-init`, `/harness-doctor`
- `harness/skills/harness/SKILL.md` - global skill with a short workflow
- `harness/skills/harness-issues/SKILL.md` - harness issue tracking skill
- `harness/templates/` - artifact templates (feature/bugfix task cards, bug card,
  adr, plan-row, issue, checkpoint, e2e-use-case, e2e-test-data, ux-spec)
- `harness/checks/` - deterministic verification registry (`engine.json`,
  `feature.json`, `bugfix.json`)
- `harness/scripts/` - `install.ps1`, `init.ps1`, `doctor.ps1`,
  `uninstall.ps1`, `new-issue.ps1`, `verify-artifacts.ps1`, `verify-stage.ps1`,
  `stage-done.ps1`, `board-update.ps1`, `measure-tokens.ps1`
- `harness/version.json` - installation version
- `docs/bugs/` - product bug registry (`BUG-XXX` cards + index)
- `docs/issues/` - harness problem log (one MD per issue + index)
- `docs/plan.md` - shared board: workflow, status, role, dependencies, bug link
- `docs/tasks/` - task cards (one MD file per task)
- `docs/checkpoints/` - user checkpoint decisions, edits, remarks, and machine
  check results (`*.checks.json`)
- `docs/evidence/` - append-only SHA256 ledger per task (`T-XXX.md`)
- `docs/metrics/` - measured token usage reports
- `docs/qa/` - QA plans, reviews, and smoke reports
- `docs/analysis/` - requirements, e2e use cases and YAML test data
- `docs/ux/` - user flows, screens, wireframes, UI spec, prototype catalog, and
  one HTML page per `UC-E2E-NNN`
- `docs/activity.puml` / `activity.svg` - derived activity diagram, informational
  only; never a status, dependency, acceptance, or routing source
- `docs/manual/` - practical usage manual (RU) with scenario map, artifact map,
  checklists, and a self-contained full-width HTML version
- `requirements/` - initial requirements

## Role models

| Role | Agent | Model (Ollama) |
|---|---|---|
| harness lead | `harness` | qwen3.8:27b-64k (thinking: xhigh) |
| orchestrator | `harness-orchestrator` | qwen3.8:27b-64k (thinking: xhigh) |
| analyst | `harness-analyst` | qwen3.8:27b-64k (thinking: medium) |
| ux-designer | `harness-ux-designer` | qwen3.8:27b-64k (thinking: xhigh) |
| architect | `harness-architect` | qwen3.8:27b-64k (thinking: xhigh) |
| coder | `harness-coder` | tiel-coder:35b-a3b-mtp-128k-text |
| qa | `harness-qa` | qwen3.8:27b-64k (thinking: low, 64K) |
| qa-vision | `harness-qa-vision` | tiel-coder:35b-a3b-mtp-128k-vision |
| doc-writer | `harness-doc-writer` | qwen3.8:27b-64k (thinking: low) |

## Global installation (once)

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1
```

The script:

1. copies agents, commands, skills, workflows, templates, checks, and scripts to
   `~/.config/opencode/`;
2. backs up modified files to `~/.config/opencode/backups/`;
3. adds or updates the `permission.task` allow rule for `harness-*` roles in
   `opencode.jsonc`.

Restart opencode after installation. Check:

```text
/harness-doctor
```

## Project activation

Harness is not enabled automatically: `default_agent` stays unchanged. In the
project, run:

1. `/harness-init` - creates `harness/process.md`, `harness/version.json`,
   `harness/templates/`, `harness/workflows/`, `harness/checks/`,
   `harness/scripts/`, `docs/plan.md`, `docs/activity.puml`, `docs/bugs/`,
   `docs/evidence/`, `docs/metrics/`, and the directory skeleton.
2. Start work with `/harness-feature <slug> [e2e] [ux]` or
   `/harness-bug <report or BUG-XXX>`; both only register pending work.
3. `/harness-run T-XXX` - execute the task until the next checkpoint.
4. Review/edit artifacts in `docs/checkpoints/T-XXX-CP-N.md` and record a
   decision, or let policy P2 close an intermediate checkpoint when all checks
   are clean (`/harness-stage-done T-XXX`); then run `/harness-run T-XXX` again.
5. `/harness-board-update all` - sync the board from checkpoint files when no
   task is active.
6. `/harness-board-report` - summary without changes, including pending reviews
   and the bug queue.

If `harness/process.md` or `docs/plan.md` is missing, the `harness` agent stops
and suggests `/harness-init`.

## Task lifecycle

1. The harness lead reads the card's `workflow` and `stage`, loads
   `harness/workflows/<workflow>.md`, checks dependencies, and verifies that no
   task is active across either workflow.
2. `harness-orchestrator` sets the task to `in_progress` in the plan/card and
   re-renders the derived activity.
3. The role performs the stage strictly per the card's `acceptance` and stops at
   each declared checkpoint. A UX task may call `harness-coder` for prototype
   pages under the single cross-role exception.
4. At a checkpoint the orchestrator runs `stage-done.ps1`: it executes the
   registry checks, writes the checks JSON, SHA256 ledger, and checkpoint,
   applies policy P2, updates plan/card/activity, and commits the snapshot. An
   intermediate checkpoint with `FAIL=0`, `UNCHECKED=0`, `MANUAL=0`, and
   `hold: false` is approved automatically (`auto (P2)`); manual items or CP-F
   wait for the user.
5. `/harness-run T-XXX` resumes the task: `approved` continues the role,
   `changes_requested` returns to the same checkpoint. Silence is not approval.
6. After the final checkpoint and mandatory `CP-F` approval,
   `harness-orchestrator` accepts the result.
7. On success - `done`, plan/card update, derived activity/SVG re-render, and
   commit; on failure - `failed`, up to 3 attempts, then `blocked` and escalation.

### Feature workflow

`/harness-feature` creates a `P-00` planning task. At `CP-1` the orchestrator
creates the feature graph: requirements -> e2e data -> UX (if in scope) ->
architecture/contracts -> coder/tests -> QA -> docs -> `CP-F`.

### Bugfix workflow

`/harness-bug` creates a `BUG-XXX` report card in `docs/bugs/` and pending fix
tasks. The coder must reproduce the defect and land a failing regression test at
`CP-1` before the minimal fix at `CP-2`. QA independently verifies
fail-before/pass-after before the bug can move from `fixed` to `verified` and
`closed`. P0/P1 require a postmortem; `hotfix` is a modifier, not a third
workflow. A contract/schema/security/multi-module/UI-flow change escalates to
feature-style analysis and design.

New bug reports and pending cards may be registered while a task is active, but
no status/dependency changes, preemption, or parallel execution are allowed.

## E2E and UX flow

- The analyst formalizes `UC-E2E-NNN` use cases and a machine-readable YAML
  dataset in `docs/analysis/`.
- The UX designer produces user flows, screens, PlantUML wireframes, a UI spec,
  and a static offline HTML prototype in `docs/ux/`: `index.html` plus one
  `uc-e2e-NNN.html` page per in-scope use case (or a recorded waiver). Prototype
  page implementation may be delegated to `harness-coder` one page at a time;
  coder writes only `docs/ux/prototype/<slug>/**`, and UX validates the result.
- The architect maps screens/use cases to contracts; the coder implements
  deterministic e2e tests and an isolated runner; QA builds the coverage
  matrix, runs the suite, and reports traceability and defects.

## Versions

- Current version: `2.5.0` (deterministic check engine, SHA256 evidence ledger,
  `/harness-stage-done` with policy P2, executable acceptance criteria, token
  usage metrics; includes 2.4.0 per-scenario UX HTML pages and the derived
  activity rule, and 2.3.0 generation/context budgets).
- The global version is stored in `~/.config/opencode/harness/version.json`.
- A project records the version in `harness/version.json` during `/harness-init`.
- `/harness-doctor` warns about version divergence.
- `/harness-doctor` also checks issue-index consistency, role `**/` path
  variants, the compaction handoff plugin, model `num_ctx` vs `limit.context`,
  `subagent_depth`, self-session allows, and the `local-rag` MCP timeout.
- A global update affects all projects. To freeze the version in a specific
  project, a vendor copy of agents and commands can later be enabled in
  `.opencode/`.

## Bug and issue registries

- Product defects use `docs/bugs/BUG-XXX-*.md` with the index
  `docs/bugs/README.md`; the orchestrator owns both.
- Harness problems, blockers, permission denies, and MCP/RAG/model failures use
  `docs/issues/` via the `harness-issues` skill.
- Never mix product bugs and harness problems.

## Issue log

For any problem, blocker, or workaround found, a harness role uses the
`harness-issues` skill and creates an entry in `docs/issues/`:

- `docs/issues/ISSUE-YYYYMMDD-HHMMSS-<slug>.md` - one issue;
- `docs/issues/README.md` - list and index.

An entry contains symptoms, absolute location, cause, solution/workaround,
verification, and prevention. The orchestrator verifies the index and includes
issue files in the task commit. Secrets are never written to issues.

## Limitations

- Installation is per current user (`~/.config/opencode`).
- Harness is not used for ordinary tasks: activation only via `/harness-feature`,
  `/harness-bug`, `/harness-run`, or service commands.
- At most one task is active across both workflows; feature and bugfix never run
  in parallel and cannot preempt each other. Cross-role calls are forbidden
  except `ux-designer -> harness-coder` for prototype pages (depth 2, sequential).
- `docs/activity.puml/.svg` are derived visualizations; status and routing are
  taken only from the plan, cards, checkpoints, bug cards, workflows, and Git.
- `git push`, `git tag`, history rewrite, and prod deployment are forbidden.
- E2E tests target local/staging only, use isolated data, and must clean up.
- Checkpoints require an explicit user decision; a silence keeps the task in
  `awaiting_review` (P2 only auto-approves clean intermediate checkpoints).
- If `opencode.jsonc` contains comments, `install.ps1` cannot patch it: add the
  printed `harness-ux-designer` allow rule manually and restart opencode.
- Models and MCP (`plantuml-render`, `local-rag`) must be available locally.
