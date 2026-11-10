# Global harness: installation and usage

This document describes how to install the harness once for the current user
and enable it in projects only by explicit command.

## 1. What is global and what is per project

| Part | Location | Contents |
|---|---|---|
| Harness tooling | `~/.config/opencode/` | `harness-*` agents, `/harness-*` commands, `harness` and `harness-issues` skills, templates, scripts |
| Project state | `<project>/` | `harness/process.md`, `harness/version.json`, `docs/plan.md`, `docs/tasks/`, artifacts, git |

The board, task cards, and artifacts cannot be global: they are project state.
Only role definitions, commands, templates, and scripts are global.

## 2. Global installation

From the harness source repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1
```

The script:

1. copies agents, commands, skills, templates, and scripts to
   `~/.config/opencode/`;
2. backs up changed files to
   `~/.config/opencode/backups/harness-install-<timestamp>/`;
3. adds or updates permissions in `opencode.jsonc`:

```jsonc
"permission": {
  "task": {
    "harness-orchestrator": "allow",
    "harness-analyst": "allow",
    "harness-architect": "allow",
    "harness-coder": "allow",
    "harness-qa": "allow",
    "harness-doc-writer": "allow"
  }
}
```

These rules allow any primary agent to explicitly call harness roles.
Roles do not call each other: they keep `task: deny`. The primary `harness`
agent keeps its own allow rules.

If `opencode.jsonc` contains comments, the script does not edit the file
automatically; it prints a ready snippet for manual insertion.

After installation, **restart opencode**: agents and config are read at
startup. Check:

```text
/harness-doctor
```

Installation is per current user. The system-wide option
(`%ProgramData%\opencode`) is not used.

## 3. Project initialization

In the project:

```text
/harness-init
```

Created:

```text
harness/
  process.md
  version.json
  templates/
    task-card.md
    adr.md
    plan-row.md
docs/
  plan.md
  activity.puml
  tasks/
  analysis/
  architecture/
  qa/
  guides/
```

`/harness-init` does not copy global agents or commands: the global
installation is used. A repeat run without `-Force` stops; with `-Force` it
backs up to `.harness-backup-<timestamp>/`.

`harness/process.md` and `docs/plan.md` are marker files. Without them, the
`harness` agent stops even if it was selected manually.

## 4. Explicit activation only

`default_agent` is never switched to harness. Main commands:

| Command | Purpose |
|---|---|
| `/harness-init` | initialize the project |
| `/harness-run T-XXX` | execute a task, accept it, update the board, commit |
| `/harness-board-update all / T-XXX` | sync the board, cards, activity, and SVG |
| `/harness-board-report` | read-only board summary |
| `/harness-doctor` | check the installation and the project |

Run flow:

```text
/harness-run T-XXX
  -> primary agent harness (marker and depends_on checks)
  -> harness-orchestrator (in_progress, board, activity, SVG)
  -> harness-analyst | harness-architect | harness-coder |
    harness-qa | harness-doc-writer
  -> harness-orchestrator (acceptance, done/failed, commit)
```

The lead does not edit files itself; the orchestrator handles the board and
commits. Tasks run strictly sequentially: one ID per `/harness-run`, at most
one task `in_progress`, no parallel role calls via `task`.

## 5. Protection against accidental starts

1. Explicit `/harness-*` commands; harness is not the default agent.
2. Global `permission.task` allows any primary agent to explicitly call
   `harness-*`; roles do not call each other (`task: deny`).
3. Marker files `harness/process.md` and `docs/plan.md` are mandatory.
4. Harness instructions are not added to the global `AGENTS.md`.
5. The `harness` skill has an explicit description and is not auto-invoked.

Optionally, you can temporarily disable harness in a specific project (V1):

```jsonc
{
  "agent": {
    "harness": { "disable": true }
  }
}
```

## 5.1. Permissions and absolute paths

opencode matches `edit`/`write` against the absolute path (Windows separators
are normalized to `/`). Therefore the relative pattern `docs/**` is not enough:
it matches `docs/plan.md` but not `C:/project/docs/plan.md`.

Harness roles therefore include both variants:

```yaml
edit:
  "*": "deny"
  "docs/**": "allow"
  "**/docs/**": "allow"
  ".gitignore": "allow"
  "**/.gitignore": "allow"
```

`**/docs/**` and `**/.gitignore` match the absolute path wherever the project
is located and when workspace root is `/`. Do not remove the absolute
variants: the blanket deny `"*": "deny"` remains, and specific allow rules
must match the full path.

`.gitignore` is allowed for `harness-orchestrator` and `harness-coder`.
Other roles do not edit it - an intentional restriction.

If opencode shows workspace root `/`, start it from the project directory and
check `git rev-parse --show-toplevel`: the root must match the project.
Absolute patterns protect against this, but a correct workspace root is still
preferable.

## 5.2. Problem log (`harness-issues`)

The `harness-issues` skill records harness problems, their cause, location, and
solution. One file per problem:

```text
docs/issues/
  README.md
  ISSUE-20261107-230501-task-deny.md
```

Create a record:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/new-issue.ps1 `
  -Title "Short title" `
  -Severity major `
  -Status open `
  -Type permission `
  -Source "T-001" `
  -Role "harness-analyst" `
  -Location "C:\project\file:line"
```

The script creates the issue file, adds a row to `docs/issues/README.md`, and
prints the path. On timestamp collision, `-2`, `-3` is appended to the ID.
Required sections: symptoms, reproduction, cause, solution/workaround,
verification, prevention, links, timeline.

Rules:

- all harness roles create issues; `harness-orchestrator` verifies the index;
- the issue ID is recorded in the task card log;
- `status`: `open`, `investigating`, `workaround`, `resolved`, `wontfix`;
- never write secrets to an issue;
- an issue does not replace a task card and is not deleted after a fix.

If `harness/scripts/new-issue.ps1` or `harness/templates/issue.md` is missing
in the project, run `/harness-init -Force` (with backup) or create the record
manually from the template.

## 6. Versions and pins

- Global version: `~/.config/opencode/harness/version.json`.
- Project version: `harness/version.json`, created by `/harness-init`.
- `/harness-doctor` warns when the versions differ.

**Version record** (currently used) records the version, but the project keeps
using global files. This is convenient for a single user and frequent updates.

**Vendor pin** - if a project must be frozen:

1. copy `harness-*` agents and commands to the project's `.opencode/agents/`
   and `.opencode/commands/`;
2. fix the version in `harness/version.json`;
3. update the copies manually only.

Project files take priority over global ones, so vendor copies override the
global installation. Full vendor mode is not yet included in `harness-init`;
it can be added as a separate flag if needed.

## 7. Update and removal

Update the global installation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1
```

The script backs up and overwrites global files. Restart opencode after the
update.

Removal:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/uninstall.ps1
```

The script removes only global `harness-*` files, the skill, and
`~/.config/opencode/harness`; project `harness/` and `docs/` are not touched.
`permission.task` rules in `opencode.jsonc` must be removed manually (the
script prints a reminder).

## 8. Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| `/harness-*` command is not visible | opencode was not restarted after installation | restart opencode |
| harness agent is not visible | files did not reach `~/.config/opencode/agents/` | check `/harness-doctor`, rerun install |
| `build` can call roles | `permission.task` contains allow | expected; otherwise run install and restart opencode |
| `build` cannot call roles | an old `deny` block remains | run install.ps1, restart opencode; check `opencode debug agent build` |
| harness does not call roles | the `harness` agent lacks allow rules | check `opencode debug agent harness` |
| project does not start | no `harness/process.md` or `docs/plan.md` | run `/harness-init` |
| edit `docs/plan.md` is blocked despite a `docs/**` allow | the path is absolute; the relative pattern did not match | update harness, restart opencode; roles must include `**/docs/**` |
| write `.gitignore` is blocked | `.gitignore` is outside the role's write area | use `harness-orchestrator` or `harness-coder` |
| workspace root `/` | opencode was not started from the project root / wrong cwd | start from the project, check `git rev-parse --show-toplevel` |
| old agents bypass gating | `.opencode/agents/analyst.md` etc. remain | remove old copies or rename to `harness-*` |
| config was not patched | `opencode.jsonc` contains comments | add `permission.task` with allow manually |
| `new-issue.ps1` is missing | the project was initialized by an older version | run `/harness-init -Force` with backup |
| version differs | the project was initialized by an older version | update the project deliberately; see pin |

## 9. Migration to opencode V2

Current installation uses opencode 1.18.33 and V1 fields. When migrating to V2:

- `permission` -> `permissions` (ordered rule array);
- `task` -> `subagent`;
- `disable` -> `disabled`;
- `agent` map -> `agents`;
- agent `temperature`/`options` move to the model variant.

File locations `.opencode/agents`, `.opencode/commands`, `.opencode/skills`
stay the same. Do not mix V1 and V2 fields in one agent file.
