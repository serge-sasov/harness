---
name: Harness Issues
description: "Harness problem and solution tracking: record errors, blockers, permission denies, MCP/RAG/model failures, git/board issues, and workarounds in docs/issues/*.md with an index. Use whenever a problem occurs during harness work; not for ordinary tasks outside harness."
---

# Harness Issues

## When to use

Load this skill when a problem occurred during harness work and had to be diagnosed, worked around, or fixed:

- permission denied, absolute path mismatch, `task: deny`;
- Ollama/model error, MCP `plantuml-render` or `local-rag` unavailable;
- git, board, activity, template, or agent failure;
- unexpected behavior of roles, commands, or `/harness-*`;
- a workaround or fix was found that should be kept for analysis.

Do not create an issue for every successful step and do not duplicate the task card. An issue is a log of a problem, its cause, and its solution.

## Hard check

Verify `harness/process.md` and `docs/plan.md`; if missing, stop and suggest `/harness-init`.

## Where to store

Store `docs/issues/ISSUE-YYYYMMDD-HHMMSS-<slug>.md` (one problem per file); index `docs/issues/README.md`; template `harness/templates/issue.md`; helper `harness/scripts/new-issue.ps1` (init copies it). On timestamp collision, append `-2`, `-3`.

## Workflow

1. Record the context **before** fixing:
   - source: `S-xx`, `T-xxx`, `/harness-*`, `build`;
   - role/agent and cwd;
   - absolute `location` (file:line, command, config);
   - error text and expected/actual behavior.
2. Create the record:

   `powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/new-issue.ps1 -Title "Short title" -Severity major -Status open -Type permission -Source "T-001" -Role "harness-analyst" -Location "C:\path\to\file:line"`

   If the script is missing, create the file manually from `harness/templates/issue.md`.
3. Fill the sections: symptoms, reproduction, cause, solution/workaround, verification, prevention/follow-up, links.
4. If the problem is resolved, set `status: resolved` and fill "Verification". If a workaround remains, set `status: workaround`.
5. Pass the issue ID to `harness-orchestrator`: it verifies the index `docs/issues/README.md` and includes issue files in the task commit.
6. Link the issue to the task card (`T-XXX`) and the artifacts/commit.

## Statuses

| Status | Meaning |
|---|---|
| `open` | problem recorded, cause not found |
| `investigating` | diagnosis in progress |
| `workaround` | a workaround exists, root cause not fixed |
| `resolved` | root cause fixed, verification passed |
| `wontfix` | no fix required/possible, reason stated |

`severity`: `blocker`, `major`, `minor`, `info`.
`type`: `permission`, `tool`, `model`, `mcp`, `rag`, `path`, `git`, `process`, `other`.

## Index

`docs/issues/README.md` is the list of all problems:

| ID | Summary | Severity | Status | Location | Source | Updated |
|---|---|---|---|---|---|---|

The script appends a row to the index. The orchestrator checks consistency and fixes mismatches. Do not delete issue file history.

## Rules

- One file per problem; never overwrite.
- Never write secrets/tokens/keys/`.env`; redact.
- Use absolute paths; relative paths may not match permissions.
- An issue does not replace a task. Process changes go to "Prevention / follow-up" and a separate task.
