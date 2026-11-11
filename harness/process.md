# Harness Process Rules (process.md)

Mandatory for all harness roles. A violation is a task blocker. Shared rules live
here; workflow-specific stages and task graphs live in
`harness/workflows/feature.md` and `harness/workflows/bugfix.md`.

## 0. Installation and activation

- Harness is installed per user in `~/.config/opencode/`: agents `harness-*`,
  commands `/harness-*`, skill `harness`, templates, workflows, scripts.
- A project receives harness only via `/harness-init`: `harness/process.md`,
  `harness/version.json`, `harness/templates/`, `harness/workflows/`,
  `docs/plan.md`, `docs/activity.puml`, and the docs skeleton (`analysis`,
  `ux`, `architecture`, `qa`, `guides`, `issues`, `checkpoints`, `bugs`).
- Activation is explicit only; `default_agent` is never switched to harness.
- Before work, `harness` checks for `harness/process.md`, the selected workflow
  file, and `docs/plan.md`; if missing, stop and ask for `/harness-init`.
- Global permissions allow any primary agent to call `harness-*` subagents.
  Roles must not call each other (`task: deny`); the primary agent routes.
- Role permissions include relative and `**/...` path variants: edit/write match
  absolute paths, so a blanket deny needs a specific allow for the full path.
- Harness problems go to `docs/issues/`; product defects go to `docs/bugs/`.
  The orchestrator maintains both indexes.
- `harness/version.json` records the installed version; `/harness-doctor` warns
  on mismatch.

## 1. General rules

- Harness = role subagents + shared plan. All tasks use local Ollama models; no
  external APIs.
- There is one harness with two base workflows: `feature` (new behavior or a new
  project) and `bugfix` (restore expected behavior). There is no third base
  workflow; scale and special cases are modifiers inside these two.
- `docs/plan.md` is the single source of execution scope; this file is the single
  source of shared process rules; the workflow file is the source of stages for
  its workflow.
- Each task is performed by exactly one role within its task/artifact
  boundaries. Exception: the lead may call `harness-qa` and `harness-qa-vision`
  as two independent passes when visuals are in scope; the orchestrator combines
  both reports into one verdict.
- Tasks run strictly sequentially for both workflows: at most one active task
  (`in_progress` or `awaiting_review`); no parallel `/harness-run`, multiple IDs,
  concurrent role calls, or feature/bugfix preemption.
- New bug reports and new `pending` task cards may be registered while another
  task is active. Existing statuses, dependencies, and the active task must not
  change; `/harness-board-update` remains forbidden while a task is active.
- Every task has at least one user checkpoint; the final checkpoint `CP-F` is
  mandatory before a task can become `done`.
- Feature tasks with end-to-end scope must include an analyst e2e deliverable or
  an explicit waiver in the card.
- Feature tasks with a user-facing interface must include a UX-Designer
  deliverable or an explicit waiver in the card.
- Bugfix tasks use reproduction evidence and regression tests instead of a new
  e2e dataset by default; e2e/UX/architecture are add-ons when the fix changes a
  contract, crosses modules, or affects a UI flow.
- User edits made at a checkpoint are authoritative; roles must preserve them
  and report conflicts instead of overwriting.

## 2. Role models

| Role | Model (Ollama) | Use |
|---|---|---|
| harness (lead) | `qwen3.8:27b-64k` (xhigh) | routing/reporting |
| orchestrator | `qwen3.8:27b-64k` (xhigh) | planning/context, board, bug registry |
| analyst | `qwen3.8:27b-64k` (medium) | requirements/RAG/e2e; bug impact when behavior is unclear |
| ux-designer | `qwen3.8:27b-64k` (xhigh) | UX flows, wireframes, UI spec, prototypes; UI bugs on escalation |
| architect | `qwen3.8:27b-64k` (xhigh) | design; design-level defects on escalation |
| coder | `tiel-coder:35b-a3b-mtp-128k-text` | code/tests/e2e; bug reproduction/strict regression fix |
| qa | `qwen3.8:27b-64k` (low) | text/code QA, e2e coverage/run/verdict; independent bug verification |
| qa-vision | `tiel-coder:35b-a3b-mtp-128k-vision` | image/visual QA; visual UI bugs |
| doc-writer | `qwen3.8:27b-64k` (low) | docs; changelog/guide updates for bugfixes |

## 3. Workflows and routing

- Every task card declares `workflow: feature | bugfix` and `stage`.
- Missing `workflow` in legacy cards is read as `feature`.
- The lead and orchestrator read the workflow file indicated by the card before
  delegating or accepting work:
  - `harness/workflows/feature.md`;
  - `harness/workflows/bugfix.md`.
- `/harness-feature` creates a feature planning task (`P-00`); the orchestrator
  decomposes the feature into cards at its planning checkpoint.
- `/harness-bug` triages a report into a `BUG-XXX` card and creates linked
  bugfix tasks, but never starts them.
- `/harness-run T-XXX` is the only task executor and resumes checkpoints for
  either workflow.
- The orchestrator uses the workflow stage table to validate `depends_on` and the
  next role; the lead uses it to route the task.
- A task whose `workflow`, `stage`, or required `bug` link is missing or
  inconsistent with the workflow file is `blocked` until the card is fixed.

## 4. Plan, board, and bug registry

- `docs/plan.md` columns:
  `ID | Workflow | Task | Role | Dependencies | Status | Bug | Artifacts | Commit`.
- Task cards use `harness/templates/task-card-feature.md` or
  `harness/templates/task-card-bugfix.md`; `task-card.md` is a deprecation
  pointer.
- Shared card fields: `id, title, workflow, stage, role, status, depends_on,
  inputs, artifacts, e2e, ux, checkpoints, issues, commit`.
- Bugfix cards add `bug, severity, profile`; feature cards add e2e/UX
  applicability. `profile: hotfix` is allowed only for P0/P1.
- Task statuses: `pending`, `in_progress`, `awaiting_review`, `done`, `failed`,
  `blocked`.
- Transitions: `pending -> in_progress`; `in_progress -> awaiting_review` at a
  checkpoint; `awaiting_review -> in_progress` after approval or a change
  request (intermediate checkpoints); `awaiting_review -> done` only after
  `CP-F` approval; `awaiting_review -> failed` if the user rejects the task;
  `in_progress -> failed`; `failed -> in_progress` after a fix; `* -> blocked`
  on an external blocker.
- Invariant: at most one active task (`in_progress` or `awaiting_review`) across
  both workflows; parallel execution and preemption are forbidden.
- Product bugs: `docs/bugs/BUG-XXX-<slug>.md`, index `docs/bugs/README.md`;
  fields `id, title, status, severity, reported_at, reporter, affected,
  requirements, use_cases, tasks, duplicate_of, commit, issues`.
- Bug statuses: `new`, `triaged`, `in_progress`, `fixed`, `verified`, `closed`,
  `duplicate`, `wontfix`. Only the orchestrator edits bug cards and the index.
- `docs/issues/` is only for harness problems; product defects never go there.
- Task `e2e` and `ux` fields record `required` or `not applicable` with a reason
  on feature tasks. The orchestrator must not accept a silent waiver.

## 5. Task lifecycle

1. Orchestrator checks the board: another active task (`in_progress` or
   `awaiting_review`) forbids start; stop and report without changing statuses.
2. Check `depends_on`: all predecessors must be `done`.
3. Create/verify the card fields for its workflow: stage, inputs, e2e/ux or
   bug/severity, checkpoints; ensure `CP-F` exists.
4. Set `in_progress` in plan, card, and activity diagram.
5. The role performs work up to the next checkpoint per the card's `acceptance`
   and checkpoint list.
6. At a checkpoint, the role stops and reports `CHECKPOINT <ID> reached` with
   artifacts and a verification checklist. It must not continue past a
   checkpoint.
7. Orchestrator creates `docs/checkpoints/T-XXX-CP-N.md`, sets
   `awaiting_review`, updates plan/card/activity/SVG, updates the bug status
   when applicable, and commits the checkpoint snapshot.
8. The lead reports the checkpoint to the user: artifacts, checklist, how to
   edit/comment, and resume command. The run ends; no auto-continue.
9. On `/harness-run T-XXX` in `awaiting_review`: read the checkpoint file and
   user edits. If no decision, stop and ask. If `approved`, finalize at `CP-F`
   (step 10) or set `in_progress` and continue past an intermediate checkpoint.
   If `changes_requested`, return to the same checkpoint after fixes.
10. After the last role checkpoint and `CP-F` approval, verify acceptance, set
    `done`, log files/commands/results, update artifacts, update the linked bug
    status, and commit.
11. For diagrams/screenshots, the lead also calls `harness-qa-vision`; the
    orchestrator includes its findings in the single verdict.

## 6. Checkpoints and user verification

- A checkpoint is a mandatory process interruption for user verification of
  artifacts, edits, and remarks.
- Checkpoint file: `docs/checkpoints/T-XXX-CP-N.md`, created from
  `harness/templates/checkpoint.md`.
- Checkpoint statuses: `awaiting_review`, `approved`, `changes_requested`.
- Required fields: task, checkpoint, role, stage, artifacts, status,
  requested_at, reviewer, decision, user remarks, user edits, role response,
  next action, snapshot commit.
- The user may edit artifacts directly and/or write remarks in the checkpoint
  file. Chat remarks may be transcribed by the orchestrator into the file.
- The role must read the checkpoint decision, user remarks, and `git diff` since
  the checkpoint snapshot before continuing; it must preserve user edits and
  report conflicts.
- The lead must not infer approval from silence, file changes, or unstated
  intent. Without an explicit `approved` decision, the task stays
  `awaiting_review`.
- Default checkpoints per role:
  - analyst: CP-1 requirements, CP-2 e2e use cases and dataset (feature);
    CP-1 impact/acceptance (bugfix escalation);
  - ux-designer: CP-1 flows and screens, CP-2 wireframes/prototype/UI spec
    (feature); CP-1 UI impact/fix spec (bugfix escalation);
  - architect: CP-1 ADR and contracts, CP-2 diagrams and decomposition
    (feature); CP-1 design/root-cause decision (bugfix escalation);
  - coder: CP-1 reproduction/root cause and failing regression (bugfix) or
    implementation and unit/integration tests (feature); CP-2 fix/regression or
    e2e automation and local run;
  - qa: CP-1 verification plan/e2e coverage, CP-2 report and verdict;
  - doc-writer: CP-1 documentation/changelog draft;
  - `CP-F` final acceptance for every task.
- The checkpoint list is declared in the card; if omitted, the workflow and role
  defaults apply. Every working-role task needs at least one intermediate
  checkpoint; every task needs `CP-F`.
- Commit a checkpoint snapshot before asking the user to review. Record
  checkpoint commits in the card log; the final task commit is recorded on the
  board.

## 7. E2E use cases and test data

- Feature workflow: the analyst owns
  `docs/analysis/e2e-use-cases-<slug>.md` and
  `docs/analysis/e2e-test-data-<slug>.yaml` when e2e is in scope.
- Every functional requirement is covered by at least one `UC-E2E-NNN` or has an
  explicit `out_of_scope` question/waiver.
- Every use case defines: source requirements, actor, priority, preconditions,
  trigger, main/alternate/error flows, test data, expected result,
  postconditions, cleanup, and traceability.
- The YAML dataset is the machine-readable test contract: schema, environment
  placeholders (no secrets), use-case entries, steps, data, expected values,
  cleanup.
- The coder owns e2e automation for features: tests consume the YAML dataset and
  provide a deterministic local runner (`scripts/e2e.ps1` or equivalent), data
  validation, isolation, cleanup, and machine-readable results.
- The QA owns feature e2e coverage and verification:
  `docs/qa/e2e-plan-<slug>.md` (matrix requirement -> UC -> test),
  `docs/qa/e2e-report-<slug>.md` (execution evidence, pass/fail per UC,
  defects), and the final review/verdict.
- Bugfix workflow: a failing regression test is mandatory; full e2e is required
  only when the bug changes a contract or crosses a service boundary. Existing
  `UC-E2E` artifacts are updated when expected behavior was wrong.
- QA runs e2e only through the approved runner in an isolated local/staging test
  environment. Production is forbidden.
- If e2e automation is missing or the dataset is invalid, QA rejects or blocks
  the task instead of weakening coverage.

## 8. UX design

- Feature workflow: the UX-Designer role is required when the task includes a
  user-facing interface; otherwise the card records `ux: not applicable` with a
  reason.
- Bugfix workflow: UX is required only for a UI/UX defect or a fix that changes
  a user flow; otherwise the card records `ux: not applicable` with a reason.
- UX inputs: analyst requirements and e2e use cases, architecture contracts,
  brand/accessibility constraints, bug card for a UI defect.
- UX artifacts in `docs/ux/`: user flows, screen inventory and states, PlantUML
  Salt wireframes (`.puml` + `.svg`), UI spec/interaction/accessibility/UI copy,
  and a static offline HTML prototype.
- The prototype must not use external CDNs or network APIs. Optional screenshots
  for visual QA are stored in
  `docs/ux/prototype/<slug>/screenshots/`.
- The UX-Designer hands off screen IDs and interaction contracts to the
  architect and coder; QA-vision checks wireframes/screenshots.
- UX checkpoints: CP-1 after flows and screens; CP-2 after wireframes,
  prototype, and UI spec (feature). A bugfix UX escalation uses CP-1 for the
  impact/fix spec.

## 9. Artifact updates (mandatory order)

1. At a checkpoint: plan status `awaiting_review`, card status, activity color,
   checkpoint file, bug card status when applicable, commit snapshot.
2. On resume/closure: `docs/plan.md`: status, artifacts, commit.
3. Task card: status, log, blockers, checkpoint results.
4. Bug card and `docs/bugs/README.md`: status, task links, root cause, fix,
   verification; only the orchestrator edits them.
5. `docs/activity.puml`: color `done` green `#90EE90`, `pending` gray
   `#D3D3D3`, `in_progress` yellow `#FFE082`, `awaiting_review` blue `#87CEFA`,
   `failed` red `#FF9090`, `blocked` orange `#FFB347`.
6. Re-render `docs/activity.svg` via MCP `plantuml-render`.
7. `git commit` (section 10).

## 10. Git discipline

- Repository root; default branch `master` unless the repo uses another default.
- Commit after each meaningful task; at least one commit per task. Checkpoint
  snapshots use `T-XXX: checkpoint CP-N (<stage>)`; the final task commit uses
  `T-XXX: short description`; service changes use `chore: ...`.
- Forbidden: `git push`, `git tag`, secrets/`.env`, history rewrite.
- Include only task files; unrelated changes go in a separate commit.
- User edits made between checkpoint runs are committed by the orchestrator on
  resume; if they conflict with role changes, record the resolution in the
  checkpoint file.

## 11. Error handling

- Acceptance failure -> `failed`; record what failed, output, hypothesis.
- Dependents wait for `done`.
- Max 3 fix attempts; then `blocked` and escalate.
- A bug that cannot be reproduced after 3 attempts is `blocked` with evidence,
  not a speculative fix.
- Empty subagent result or `finish=length` = failed attempt; record in the card
  log; do not leave `in_progress`.
- QA (`limit.output=16384`): write the report incrementally via `write`; final
  message <=10 lines; a long single message hitting `finish=length` is a failed
  attempt.
- Keep the failure cause in the log after fixing.
- A user `changes_requested` at a checkpoint is not a failure; it returns the
  task to `in_progress` for fixes. A user rejection sets `failed`.

## 12. Role artifacts

| Role | Write area |
|---|---|
| harness | no files; reads board/cards/bugs, routes roles |
| orchestrator | `docs/plan.md`, `docs/tasks/`, `docs/checkpoints/`, `docs/bugs/`, `docs/activity.puml`, `README.md`, `.gitignore` |
| analyst | `docs/analysis/` |
| ux-designer | `docs/ux/` |
| architect | `docs/architecture/` |
| coder | `src/`, `backend/`, `tests/`, `scripts/`, `Dockerfile`, `docker-compose*.yml`, `Makefile`, `.gitignore`, `requirements.txt`, `pyproject.toml`, `.env.example`, `alembic.ini`, `sources.yaml` |
| qa | `docs/qa/` |
| qa-vision | `docs/qa/` |
| doc-writer | `docs/guides/`, `README.md`, ADR finalization |

All roles may create `docs/issues/` records; the orchestrator verifies the
index. The user may edit any artifact and checkpoint file during a checkpoint;
the role must preserve those edits. Product bug evidence is reported to the
orchestrator; roles do not edit `docs/bugs/`.

## 13. Prohibitions

- Editing `~/.config/opencode/**` or system configs.
- Production actions: `git push`, `docker push`, deployment outside
  local/staging, production migrations.
- Secrets/tokens/keys in code, logs, or commits.
- Nested subagent calls (`task: deny` on roles; `harness` allows only harness
  roles).
- Parallel task execution: >1 active task, concurrent `/harness-run`, batch or
  parallel `task`, feature/bugfix preemption, or `board-update` while a task is
  active.
- Silently overwriting user edits made at a checkpoint.
- Mixing product bugs (`docs/bugs/`) with harness problems (`docs/issues/`).
- Access outside drive `C:` (see agent permissions).

## 14. Problem tracking

- Any harness problem, blocker, permission deny, MCP/RAG/model failure, git/board
  issue, or workaround creates an issue.
- Product defects are not issues; use `/harness-bug` and `docs/bugs/`.
- Use `harness-issues` and `harness/scripts/new-issue.ps1`; fallback:
  `harness/templates/issue.md`.
- One file per problem: `docs/issues/ISSUE-YYYYMMDD-HHMMSS-<slug>.md`.
- Index: `docs/issues/README.md`; orchestrator verifies and commits.
- Required: status, severity, type, source, role, absolute location, symptoms,
  cause, solution/workaround, verification, prevention, links.
- Put the issue ID in the card log; an issue does not replace the card.
- Never write secrets/tokens/`.env` to an issue.
- On resolution set `resolved`/`workaround`; do not delete history.
