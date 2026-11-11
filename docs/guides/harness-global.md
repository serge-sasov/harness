# Global harness: installation and usage

This document describes how to install the harness once for the current user
and enable it in projects only by explicit command.

## 1. What is global and what is per project

| Part | Location | Contents |
|---|---|---|
| Harness tooling | `~/.config/opencode/` | `harness-*` agents, `/harness-*` commands, `harness` and `harness-issues` skills, workflow files, templates, scripts |
| Project state | `<project>/` | `harness/process.md`, `harness/workflows/`, `harness/version.json`, `docs/plan.md`, `docs/tasks/`, `docs/bugs/`, artifacts, git |

The board, task cards, bug registry, and artifacts cannot be global: they are
project state. Only role definitions, commands, workflows, templates, and scripts
are global.

## 2. Global installation

From the harness source repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1
```

The script:

1. copies agents, commands, skills, workflows, templates, and scripts to
   `~/.config/opencode/`;
2. backs up changed files to
   `~/.config/opencode/backups/harness-install-<timestamp>/`;
3. adds or updates permissions in `opencode.jsonc`:

```jsonc
"permission": {
  "task": {
    "harness-orchestrator": "allow",
    "harness-analyst": "allow",
    "harness-ux-designer": "allow",
    "harness-architect": "allow",
    "harness-coder": "allow",
    "harness-qa": "allow",
    "harness-qa-vision": "allow",
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
  workflows/
    feature.md
    bugfix.md
  templates/
    task-card.md
    task-card-feature.md
    task-card-bugfix.md
    bug-card.md
    adr.md
    plan-row.md
    issue.md
    checkpoint.md
    e2e-use-case.md
    e2e-test-data.yaml
    ux-spec.md
docs/
  plan.md
  activity.puml
  tasks/
  analysis/
  ux/
  architecture/
  qa/
  guides/
  issues/
  bugs/
  checkpoints/
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
| `/harness-feature <slug> [e2e] [ux]` | create a pending `P-00` feature planning task |
| `/harness-bug <report or BUG-XXX>` | create/triage a `BUG-XXX` card and pending bugfix tasks |
| `/harness-run T-XXX` | execute a task until a checkpoint, or resume after review |
| `/harness-board-update all / T-XXX` | sync the board, cards, bug index, checkpoints, activity, and SVG when no task is active |
| `/harness-board-report` | read-only board/bug summary, including pending reviews |
| `/harness-doctor` | check the installation and the project |

Run flow:

```text
/harness-feature <slug> | /harness-bug <report>
  -> harness-orchestrator: register pending planning/bugfix work only
/harness-run T-XXX
  -> primary agent harness (marker, workflow, depends_on, active-task checks)
  -> harness-orchestrator (in_progress, board, bug status, activity, SVG)
  -> harness-analyst | harness-ux-designer | harness-architect |
    harness-coder | harness-qa | harness-qa-vision | harness-doc-writer
  -> role stops: CHECKPOINT CP-N reached
  -> harness-orchestrator (checkpoint file, awaiting_review, snapshot commit)
  -> user reviews/edits artifacts and records a decision
  -> /harness-run T-XXX (resume; repeat until CP-F)
  -> harness-orchestrator (acceptance, bug status, done/failed, final commit)
```

The lead does not edit files itself; the orchestrator handles the board, bug
registry, checkpoints, and commits. Tasks run strictly sequentially across both
workflows: one ID per `/harness-run`, at most one active task (`in_progress` or
`awaiting_review`), no feature/bugfix preemption, and no parallel role calls via
`task`. New bug reports and pending cards may be registered while a task is
active; existing statuses and dependencies must not change.

## 4.1. User checkpoints

Every task card declares at least one checkpoint; `CP-F` (final acceptance) is
mandatory before a task can be `done`. Checkpoint records live in
`docs/checkpoints/T-XXX-CP-N.md` and are created from
`harness/templates/checkpoint.md`.

Flow:

1. The role stops at the declared checkpoint and reports
   `CHECKPOINT <ID> reached`.
2. The orchestrator writes the checkpoint file, sets the task to
   `awaiting_review`, updates the board/activity/SVG, and commits a snapshot.
3. The user reviews artifacts, edits files if needed, and records a decision:
   `approved`, `changes_requested`, or no decision (keep reviewing).
4. `/harness-run T-XXX` resumes:
   - `approved` -> `in_progress`, the role continues to the next checkpoint;
   - `changes_requested` -> the role applies the requested changes and returns
     to the same checkpoint;
   - missing decision -> stop and ask; never infer approval.
5. User edits are authoritative. The role reads the checkpoint file and the
   `git diff` since the snapshot before continuing and preserves those edits.

Status colors: `pending` `#D3D3D3`, `in_progress` `#FFE082`,
`awaiting_review` `#87CEFA`, `done` `#90EE90`, `failed` `#FF9090`, `blocked`
`#FFB347`.

## 4.2. E2E and UX artifacts

- Analyst: `docs/analysis/e2e-use-cases-<slug>.md` with `UC-E2E-NNN` use cases
  and `docs/analysis/e2e-test-data-<slug>.yaml` (schema `harness-e2e/1`).
- UX designer: `docs/ux/user-flows-<slug>.md`, `screens-<slug>.md`,
  `wireframes-<slug>.puml/.svg`, `ui-spec-<slug>.md`, and
  `docs/ux/prototype/<slug>/index.html` plus optional screenshots.
- Architect: contracts cover the screen IDs, use-case IDs, and the e2e
  environment/data consumption.
- Coder: `tests/e2e/`, an isolated runner (for example `scripts/e2e.ps1`), and
  a dataset validator (for example `scripts/validate-e2e-data.py`).
- QA: `docs/qa/e2e-plan-<slug>.md` (coverage matrix), `e2e-report-<slug>.md`
  (run evidence and defects), and `review-T-XXX.md` (verdict).

E2E runs only against local/staging resources, with isolated and cleaned-up test
data. Production is forbidden.

Bugfix evidence:

- `BUG-XXX` card in `docs/bugs/` with observed/expected behavior, reproduction,
  severity, and task links;
- coder `CP-1`: reproduction/root cause and a regression test that fails on the
  base revision; `CP-2`: minimal fix and regression green;
- QA: independent fail-before/pass-after evidence in `docs/qa/review-T-XXX.md`;
- optional docs/changelog for `B-04`; P0/P1 postmortem before `closed`;
- full e2e/UX/architecture only when the fix escalates to a contract, schema,
  security, multi-module, or UI-flow change.

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

## 5.2. Problem logs: harness issues vs product bugs

Harness problems use the `harness-issues` skill. Product defects use
`/harness-bug` and `docs/bugs/`; never put a product bug in `docs/issues/` or a
harness failure in the bug registry.

One file per harness problem:
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

- Current version: `2.2.1` (feature/bugfix workflows, BUG registry, new commands,
  reliability checks in `/harness-doctor`, and issue-registry enforcement).
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
| config was not patched | `opencode.jsonc` contains comments | add `permission.task` with allow manually; without comments, rerun install (it adds missing entries) |
| `task` fails with `Subagent depth limit reached` | compaction handoff created a child continuation session | do not run the role inline; update/disable the handoff plugin, start a new root session, resume `/harness-run`; doctor checks the plugin |
| QA returns an empty report or `finish=length` | configured `limit.context` is above the real `num_ctx`, or output budget is too small | run `/harness-doctor`, compare `ollama show <model>` with `limit.context`, reduce reads, resume the same session |
| `rag_sync` times out or returns `Sync already running` | indexing exceeds the local-rag MCP timeout; the lock remains | verify new content with `rag_search`, retry after the lock releases; consider a larger `local-rag` timeout; record an issue if it persists |
| issue files are missing from the index | a record was created outside `docs/issues/` or manually | move it to `docs/issues/`, add the index row, rerun `/harness-doctor` |
| `new-issue.ps1` is missing | the project was initialized by an older version | run `/harness-init -Force` with backup |
| checkpoint templates or `docs/checkpoints/` missing | the project was initialized by an older version | run `/harness-init -Force` with backup |
| `harness/workflows/` or `docs/bugs/` missing | the project was initialized by an older version | run `/harness-init -Force` with backup |
| task card has no `workflow`/`stage` | legacy 2.1.0 card | add `workflow: feature` and a stage, or recreate from the feature template; do not guess |
| bugfix card has no bug link | invalid card for `workflow: bugfix` | stop; the orchestrator must set `bug: BUG-XXX` and `severity` |
| bug cannot be reproduced | missing or unstable reproduction data | coder stops at `CP-1` with evidence; no speculative fix |
| product bug was filed in `docs/issues/` | wrong registry | move it to `docs/bugs/` from the bug card template; keep harness issues separate |
| task is stuck in `awaiting_review` | no explicit decision in the checkpoint file | review, record `approved`/`changes_requested`, resume `/harness-run T-XXX` |
| role does not stop at a checkpoint | card has no `checkpoints` list or old agent copies | add checkpoints to the card; rerun install and restart opencode |
| e2e runner cannot read test data | missing or invalid YAML dataset | check `docs/analysis/e2e-test-data-<slug>.yaml`; run the coder validator |
| version differs | the project was initialized by an older version | update the project deliberately; see pin |

`/harness-doctor` checks the global installation, `permission.task` allows,
`**/` path variants, the issue registry and index, the compaction handoff
plugin, the model `num_ctx` against `limit.context`, and the `local-rag` MCP
timeout. Use `-SkipModelProbe` for a fast run without Ollama probes.

## 9. Migration to opencode V2

Current installation uses opencode 1.18.33 and V1 fields. When migrating to V2:

- `permission` -> `permissions` (ordered rule array);
- `task` -> `subagent`;
- `disable` -> `disabled`;
- `agent` map -> `agents`;
- agent `temperature`/`options` move to the model variant.

File locations `.opencode/agents`, `.opencode/commands`, `.opencode/skills`
stay the same. Do not mix V1 and V2 fields in one agent file.
