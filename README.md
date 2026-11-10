# Local harness: architecture + implementation

A local harness for developing solution and software architecture followed by
implementation. The entire process is performed by role subagents based on local
Ollama models. The harness is installed globally for the current user but is
activated in a project only explicitly via `/harness-*`.

Detailed guide: [`docs/guides/harness-global.md`](docs/guides/harness-global.md).

## Contents

- `harness/process.md` - unified production process requirements (rules)
- `harness/agents/` - primary agent `harness` and role subagents
  (`harness-orchestrator`, `harness-analyst`, `harness-architect`,
  `harness-coder`, `harness-qa`, `harness-qa-vision`, `harness-doc-writer`)
- `harness/commands/` - opencode commands: `/harness-run`,
  `/harness-board-update`, `/harness-board-report`, `/harness-init`,
  `/harness-doctor`
- `harness/skills/harness/SKILL.md` - global skill with a short workflow
- `harness/skills/harness-issues/SKILL.md` - issue and solution tracking skill
- `harness/templates/` - artifact templates (task-card, adr, plan-row, issue)
- `harness/scripts/` - `install.ps1`, `init.ps1`, `doctor.ps1`,
  `uninstall.ps1`, `new-issue.ps1`
- `harness/version.json` - installation version
- `docs/issues/` - issue and solution log (one MD per issue + index)
- `docs/plan.md` - shared plan (task board: status, role, dependencies)
- `docs/tasks/` - task cards (one MD file per task)
- `docs/activity.puml` / `activity.svg` - activity diagram
- `requirements/` - initial requirements

## Role models

| Role | Agent | Model (Ollama) |
|---|---|---|
| harness lead | `harness` | qwen3.8:27b-64k (thinking: xhigh) |
| orchestrator | `harness-orchestrator` | qwen3.8:27b-64k (thinking: xhigh) |
| analyst | `harness-analyst` | qwen3.8:27b-64k (thinking: medium) |
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

1. copies agents, commands, skills, templates, and scripts to
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
   `harness/templates/`, `docs/plan.md`, `docs/activity.puml`, and the directory
   skeleton.
2. Fill in `docs/plan.md` and create a card from
   `harness/templates/task-card.md`.
3. `/harness-run T-XXX` - execute the task.
4. `/harness-board-update all` - sync the board and activity.
5. `/harness-board-report` - summary without changes.

If `harness/process.md` or `docs/plan.md` is missing, the `harness` agent stops
and suggests `/harness-init`.

## Task lifecycle

1. The harness lead checks the project marker and `depends_on` (all `done`).
2. `harness-orchestrator` sets the task to `in_progress` and updates the board.
3. The role performs the task strictly per the card's `acceptance`.
4. `harness-orchestrator` accepts the result.
5. On success - `done`, board/card/activity/SVG update, and commit; on failure -
   `failed`, up to 3 attempts, then `blocked` and escalation.

## Versions

- The global version is stored in `~/.config/opencode/harness/version.json`.
- A project records the version in `harness/version.json` during `/harness-init`.
- `/harness-doctor` warns about version divergence.
- A global update affects all projects. To freeze the version in a specific
  project, a vendor copy of agents and commands can later be enabled in
  `.opencode/`.

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
- Harness is not used for ordinary tasks: activation only via `/harness-run`
  and service commands.
- `git push`, `git tag`, history rewrite, and prod deployment are forbidden.
- Models and MCP (`plantuml-render`, `local-rag`) must be available locally.
