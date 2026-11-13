# Harness Process Rules (process.md)

Mandatory for all harness roles. A violation is a task blocker. Shared rules live
here; workflow-specific stages and task graphs live in
`harness/workflows/feature.md` and `harness/workflows/bugfix.md`.

## 0. Installation and activation

- Harness is installed per user in `~/.config/opencode/`: agents `harness-*`,
  commands `/harness-*`, skill `harness`, templates, workflows, scripts.
- A project receives harness only via `/harness-init`: `harness/process.md`,
  `harness/version.json`, `harness/templates/`, `harness/workflows/`,
  `harness/checks/`, `harness/scripts/`, `docs/plan.md`, `docs/activity.puml`,
  and the docs skeleton (`analysis`, `ux`, `architecture`, `qa`, `guides`,
  `issues`, `checkpoints`, `bugs`, `evidence`, `metrics`).
- Verification is deterministic: `harness/scripts/verify-artifacts.ps1` runs the
  registry `harness/checks/engine.json` plus `harness/checks/<workflow>.json`.
  Machine results are `PASS`, `FAIL`, `MANUAL`, `NOT_APPLICABLE`; declared
  artifacts not covered by any check are `UNCHECKED`. Results are recorded in
  `docs/checkpoints/T-XXX-CP-N.checks.json`; prose never replaces a check.
- Activation is explicit only; `default_agent` is never switched to harness.
- Before work, `harness` checks for `harness/process.md`, the selected workflow
  file, and `docs/plan.md`; if missing, stop and ask for `/harness-init`.
- Global permissions allow any primary agent to call `harness-*` subagents.
  Roles must not call other roles, with one exception: `ux-designer` may call
  `harness-coder` to implement static web UI mockups under
  `docs/ux/prototype/<slug>/`. This nested call is depth 2, sequential, one
  child at a time; the UX designer remains the task owner and accepts the
  result. A generator role may spawn a self-sub-session of its own role for a
  decomposed chunk (depth 2, sequential) when its agent declares `task`
  self-allow. The primary agent routes all other cross-role work.
- Role permissions include relative and `**/...` path variants: edit/write match
  absolute paths, so a blanket deny needs a specific allow for the full path.
- Harness problems go only to `docs/issues/`; product defects go to `docs/bugs/`.
  The orchestrator maintains both indexes. A root `harness-issues/` directory is
  not a valid registry; `/harness-doctor` warns when issue files are outside
  `docs/issues/` or missing from the index.
- Issue records use the `harness-issues` schema: severity
  `blocker|major|minor|info`; type
  `permission|tool|model|mcp|rag|path|git|process|checkpoint|e2e|ux|other`.
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
  boundaries. Exceptions: the lead may call `harness-qa` and `harness-qa-vision`
  as two independent passes when visuals are in scope; the orchestrator combines
  both reports into one verdict. The `ux-designer` may call `harness-coder` for
  prototype pages as part of the same UX task; this is not a second active task
  or parallel role call, and the UX designer remains accountable.
- Status and routing decisions use only `docs/plan.md`, task cards, checkpoint
  files, bug cards, workflow files, and Git evidence. `docs/activity.puml`,
  `docs/activity.svg`, and their derivatives (rendered images, screenshots, or
  HTML that embeds them) are visual progress aids only: never use them to
  determine or reconcile task or bug status, dependencies, the active task,
  acceptance, checkpoint decisions, or role routing. If an activity artifact
  disagrees with the board or a card, the board/card wins; the orchestrator
  re-renders the activity artifact from the authoritative sources.
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
- Feature tasks with architecture scope must produce
  `docs/architecture/architecture-*.md` plus component, data, and class
  diagrams, a sequence diagram for every `SCN-NNN`, a swimlane for every
  `SVC-NNN`, and an OpenAPI 3.x specification for every `API-NNN`. The
  architecture description's `Scope and applicability` section is authoritative:
  no `SVC-`/`API-` definitions means an explicit `No microservices`/`No REST API`
  statement and disables those conditional checks; silence is not a waiver.
  `SCN`/`SVC`/`API` identifiers are project-global; never reuse them across
  architecture descriptions.
- Bugfix tasks use reproduction evidence and regression tests instead of a new
  e2e dataset by default; e2e/UX/architecture are add-ons when the fix changes a
  contract, crosses modules, or affects a UI flow.
- User edits made at a checkpoint are authoritative; roles must preserve them
  and report conflicts instead of overwriting.
- Checkpoints are closed by `harness/scripts/stage-done.ps1`: it runs the
  deterministic checks, writes the checks JSON, records artifact hashes in
  `docs/evidence/T-XXX.md`, renders the checkpoint from machine data, applies
  approval policy P2 (section 11.2), updates plan/card/board machine fields,
  re-renders the derived activity diagram, and commits the snapshot.
- Scripts own machine fields: checks, hashes, `base_commit`, `usage`,
  `snapshot_commit`, `generated_by`, and the board `Status`/`Usage`/`Commit`
  values. Roles own semantic fields (decision, remarks, role response, log).
  Never hand-edit a machine field; rerun the script or `board-update.ps1`.
- Token usage is measured per task from the local opencode database with
  `measure-tokens.ps1` and recorded in `docs/metrics/`, the board `Usage` column,
  and the card `usage` field. It is evidence for budgeting and later analysis,
  never an acceptance criterion.

## 2. Role models

| Role | Model (Ollama) | Use |
|---|---|---|
| harness (lead) | `qwen3.8:27b-64k` (xhigh) | routing/reporting |
| orchestrator | `qwen3.8:27b-64k` (xhigh) | planning/context, board, bug registry |
| analyst | `qwen3.8:27b-64k` (medium) | requirements/RAG/e2e; bug impact when behavior is unclear |
| ux-designer | `qwen3.8:27b-64k` (xhigh) | UX flows, wireframes, UI spec, per-scenario HTML mockups (coder-assisted); UI bugs on escalation |
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
  `ID | Workflow | Task | Role | Dependencies | Status | Bug | Artifacts | Usage | Commit`.
- Task cards use `harness/templates/task-card-feature.md` or
  `harness/templates/task-card-bugfix.md`; `task-card.md` is a deprecation
  pointer.
- Shared card fields: `id, title, workflow, stage, role, status, depends_on,
  inputs, artifacts, e2e, ux, chunks, budget, base_commit, usage, hold,
  checkpoints, issues, commit`.
- Bugfix cards add `bug, severity, profile`; feature cards add e2e/UX
  applicability. `profile: hotfix` is allowed only for P0/P1.
- `hold: true` forces human review at every checkpoint, including intermediate
  ones; it disables P2 auto-approval for that task.
- `base_commit` is the revision a checkpoint diff is measured from; when absent,
  the latest checkpoint snapshot is used, then the first commit of the task.
- Task statuses: `pending`, `in_progress`, `awaiting_review`, `done`, `failed`,
  `blocked`.
- Transitions: `pending -> in_progress`; `in_progress -> awaiting_review` at a
  checkpoint that needs a human; `in_progress -> in_progress` when P2
  auto-approves an intermediate checkpoint; `awaiting_review -> in_progress`
  after approval or a change request (intermediate checkpoints);
  `awaiting_review -> done` only after `CP-F` approval; `awaiting_review ->
  failed` if the user rejects the task; `in_progress -> failed`; `failed ->
  in_progress` after a fix; `* -> blocked` on an external blocker.
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
4. Set `in_progress` in the plan and card; then re-render the activity diagram
   as a derived visualization.
5. The role performs work up to the next checkpoint per the card's `acceptance`
   and checkpoint list.
6. At a checkpoint, the role stops and reports `CHECKPOINT <ID> reached` with
   artifacts and a verification checklist. It must not continue past a
   checkpoint.
7. Orchestrator runs
   `harness/scripts/stage-done.ps1 -Task T-XXX -Checkpoint CP-N` (or
   `verify-stage.ps1` first for a preview). The script runs the checks, writes
   the checks JSON, records hashes, renders the checkpoint, applies policy P2
   (section 11.2), updates the board/card machine fields, re-renders the derived
   activity diagram, and commits the checkpoint snapshot.
8. A checkpoint with `FAIL=0`, `UNCHECKED=0`, and `MANUAL=0` on an intermediate
   stage is `approved` by `auto (P2)` and the task stays `in_progress`; any
   other result sets `awaiting_review`. `CP-F` always waits for the user unless
   the user explicitly requested `-AutoApprove` and all checks are clean. A card
   with `hold: true` always waits for the user.
9. The lead reports the checkpoint to the user: artifacts, machine results,
   manual items, how to edit/comment, and resume command. The run ends; no
   auto-continue for human checkpoints.
10. On `/harness-run T-XXX` in `awaiting_review`: read the checkpoint file and
    user edits. If no decision, stop and ask. If `approved`, finalize at `CP-F`
    (step 11) or continue past an intermediate checkpoint. If
    `changes_requested`, return to the same checkpoint after fixes.
11. After the last role checkpoint and `CP-F` approval, verify acceptance, set
    `done`, log files/commands/results, update artifacts, update the linked bug
    status, and commit.
12. For diagrams/screenshots, the lead also calls `harness-qa-vision`; the
    orchestrator includes its findings in the single verdict.

## 6. Checkpoints and user verification

- A checkpoint is a mandatory process interruption for user verification of
  artifacts, edits, and remarks.
- Checkpoint file: `docs/checkpoints/T-XXX-CP-N.md`, rendered by
  `stage-done.ps1` from machine data; machine check details live in
  `docs/checkpoints/T-XXX-CP-N.checks.json`.
- Checkpoint statuses: `awaiting_review`, `approved`, `changes_requested`.
- Required fields: task, workflow, bug, checkpoint, role, stage, artifacts,
  status, requested_at, reviewed_at, reviewer, decision, snapshot_commit,
  generated_by, checks_file, user remarks, user edits, role response,
  next action, usage, diff stat.
- Machine fields (`status`, `reviewed_at`, `reviewer` for auto approvals,
  `snapshot_commit`, `generated_by`, `checks_file`, `usage`, `diff stat`) are
  written by the script. Semantic fields (a human `decision`, remarks, edits,
  role response) are written by the user or orchestrator.
- Approval policy P2 (section 11.2): an intermediate checkpoint with
  `FAIL=0`, `UNCHECKED=0`, `MANUAL=0`, and `hold: false` is approved
  automatically as `auto (P2)`. Any manual item, failed/unchecked check, or
  `hold: true` requires the user. `CP-F` always requires the user unless
  `-AutoApprove` was explicitly requested and the same all-zero condition holds.
- The user may edit artifacts directly and/or write remarks in the checkpoint
  file. Chat remarks may be transcribed by the orchestrator into the file.
- The role must read the checkpoint decision, user remarks, and `git diff` since
  the checkpoint snapshot before continuing; it must preserve user edits and
  report conflicts.
- The lead must not infer approval from silence, file changes, or unstated
  intent. Without an explicit `approved` decision, the task stays
  `awaiting_review`.
- A checkpoint without its `.checks.json` or evidence ledger rows is invalid:
  rerun `stage-done.ps1`; do not hand-write status or hashes.
- Default checkpoints per role:
  - analyst: CP-1 requirements, CP-2 e2e use cases and dataset (feature);
    CP-1 impact/acceptance (bugfix escalation);
  - ux-designer: CP-1 flows and screens, CP-2 wireframes/prototype/UI spec
    (feature); CP-1 UI impact/fix spec (bugfix escalation);
  - architect: CP-1 ADR, contracts, architecture description with scope,
    `SCN`/`SVC`/`API` IDs, and OpenAPI specs; CP-2 component, scenario sequence,
    data, class, and per-service swimlane diagrams plus decomposition
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
- Commit a checkpoint snapshot before asking the user to review; `stage-done.ps1`
  performs the commit and then records the hash in the checkpoint, board, and
  card. The board `Commit` column holds the latest task commit (checkpoint
  snapshot or closure); the card log lists the full history.

## 7. E2E use cases and test data

- Feature workflow: the analyst owns
  `docs/analysis/e2e-use-cases-<slug>.md` and
  `docs/analysis/e2e-test-data-<slug>.yaml` when e2e is in scope.
- Every functional requirement is covered by at least one `UC-E2E-NNN` or has an
  explicit `out_of_scope` question/waiver.
- Every use case defines: source requirements, actor, priority, preconditions,
  trigger, main/alternate/error flows, test data, expected result,
  postconditions, cleanup, and traceability. The architect maps each in-scope
  `UC-E2E-NNN` to an architecture scenario `SCN-NNN`; if e2e is waived,
  scenarios are still defined in `docs/architecture/architecture-*.md` with
  requirement traceability.
- The YAML dataset is the machine-readable test contract: schema, environment
  placeholders (no secrets), use-case entries, steps, data, expected values,
  cleanup.
- A-02 is chunked by default: 2-3 use cases per Markdown chunk and 2-3 entries
  per YAML chunk. Each chunk is authored in a separate role session with the
  budget in section 11.1; one CP-2 checkpoint is reported after all chunks pass
  validation.
- The analyst validates YAML syntax, UC coverage, and cross-reference anchors
  before CP-2; `harness/scripts/validate-e2e-data.py` (copied by `/harness-init`)
  is the baseline, and a project-specific validator may extend it.
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
- The prototype contains `index.html` and one page per in-scope `UC-E2E-NNN`
  (`docs/ux/prototype/<slug>/uc-e2e-001.html`) with the relevant
  empty/loading/success/error states. A use case without a web UI records an
  explicit waiver in the UI spec.
- The `ux-designer` may delegate prototype page implementation to
  `harness-coder` under the exception in section 0/1: one child at a time, a
  precise page brief, and coder writes only `docs/ux/prototype/<slug>/**`. The
  UX designer validates all pages and remains accountable at CP-2.
- The prototype must not use external CDNs or network APIs. Optional screenshots
  for visual QA are stored in
  `docs/ux/prototype/<slug>/screenshots/`.
- The UX-Designer hands off screen IDs and interaction contracts to the
  architect and coder; QA-vision checks wireframes/screenshots.
- UX checkpoints: CP-1 after flows and screens; CP-2 after wireframes,
  prototype, and UI spec (feature). A bugfix UX escalation uses CP-1 for the
  impact/fix spec.

## 9. Artifact updates (mandatory order)

1. At a checkpoint: run `stage-done.ps1`; it writes plan status, card status,
   usage and commit, checkpoint file, checks JSON, evidence ledger rows, and the
   derived activity color, then commits the snapshot. Do not edit those machine
   fields by hand.
2. Bug card and `docs/bugs/README.md`: status, task links, root cause, fix,
   verification; only the orchestrator edits them. Product evidence is committed
   separately as `chore: bug BUG-XXX ...` after the checkpoint snapshot.
3. On resume/closure: `docs/plan.md`: status, artifacts, commit (via the script
   or `board-update.ps1`).
4. Task card: status, log, blockers, checkpoint results; semantic log lines are
   role-owned, machine fields are script-owned.
5. `docs/activity.puml`: update it only after steps 1-4, as a derived
   visualization of the board/card/checkpoint/bug state. Never read the
   existing activity content to reconcile statuses. Node status color is a
   suffix stereotype after `;`: `:task text; <<#90EE90>>`. Never use the
   deprecated prefix form `#90EE90:task text;` — PlantUML 1.2026.6 renders a
   deprecation banner in the SVG. Colors: `done` green `#90EE90`, `pending`
   gray `#D3D3D3`, `in_progress` yellow `#FFE082`, `awaiting_review` blue
   `#87CEFA`, `failed` red `#FF9090`, `blocked` orange `#FFB347`.
6. Re-render `docs/activity.svg` via MCP `plantuml-render`; activity artifacts
   remain informational only.
7. `git commit` (section 10).

## 10. Git discipline

- Repository root; default branch `master` unless the repo uses another default.
- Commit after each meaningful task; at least one commit per task. Checkpoint
  snapshots use `T-XXX: checkpoint CP-N (<stage>)` and are made by
  `stage-done.ps1`, which then records the hash in a follow-up
  `T-XXX: record CP-N snapshot <hash>` commit. The final task commit uses
  `T-XXX: short description`; board and bug maintenance use `chore: ...`.
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
- Empty subagent result or `finish=length` = failed attempt; record it in the
  card log with time, error, token counts, context size, and artifact status.
  Do not leave the task `in_progress` and do not repeat the same oversized call.
- After the second size-related failure (output limit, SSE timeout on a large
  generation, or a write above the budget), split the chunk further. The third
  attempt must use a smaller chunk, not the same call.
- Count attempts per chunk, not per task. A chunk that still fails after 3
  attempts is `blocked` with evidence; other chunks may continue only after the
  lead records the blocker in the card.
- If `task` fails with `Subagent depth limit` or a routing/permission error, do
  not perform the role work inline. Stop, start a new root session or fix the
  routing tool/plugin, record an issue, and resume via `/harness-run`.
- A client timeout or canceled role call is not a failed attempt when the role
  already wrote its artifact and the session can be resumed; resume the same
  session. If the timeout happened during an oversized single generation, split
  the chunk and resume in a fresh session instead of repeating the call. Mark
  `failed` only after 3 attempts without a usable artifact or verdict.
- Before a long role run, compare the actual `num_ctx` (`ollama show <model>`)
  with `limit.context` in `~/.config/opencode/opencode.jsonc`; configured
  context greater than the actual value is a blocker for that role.
  `/harness-doctor` checks this mismatch.
- `rag_sync` timeout or `Sync already running` does not block the task when
  `rag_search` already returns the updated content; retry after the lock
  releases and record an issue if it persists.
- QA (`limit.output=16384`): write the report incrementally via `write`; final
  message <=10 lines; a long single message hitting `finish=length` is a failed
  attempt.
- Keep the failure cause in the log after fixing.
- A user `changes_requested` at a checkpoint is not a failure; it returns the
  task to `in_progress` for fixes. A user rejection sets `failed`.

### 11.1 Generation and context budget

These limits are mandatory for all roles. A role that cannot satisfy them must
stop and request decomposition instead of attempting a larger write.

| Artifact | Max per write/edit | Max new content per role session | Chunk size | Stop at context |
|---|---|---|---|---|
| Markdown docs (analyst, architect, ux-designer, qa, doc-writer) | 8 KB | 20 KB | 2-3 use cases or one section | 60% of `limit.context` |
| PlantUML diagrams (architect/ux-designer) | 8 KB | 20 KB | one diagram | 60% of `limit.context` |
| OpenAPI 3.x YAML/JSON contracts | 6 KB | 15 KB | one API specification | 60% of `limit.context` |
| YAML e2e data | 6 KB | 15 KB | 2-3 use-case entries | 60% of `limit.context` |
| Code (coder) | 12 KB | 40 KB | one module/file group | 65% of `limit.context` |
| HTML/CSS/JS prototype (ux-designer or delegated coder) | 12 KB | 40 KB | one scenario page or shared asset | 65% of `limit.context` |
| Any final report | 4 KB | - | - | - |

- Never create a large artifact in one `write`. Write a skeleton and fill it
  with one `edit` per section or use case.
- An artifact larger than 40 KB must be split into parts or generated in several
  role sessions; above 80 KB, split it into separate files.
- Do not use compaction as a decomposition tool. If compaction happens during
  artifact generation, stop, record the state, and continue in a fresh session
  with a handoff note.
- Use a deterministic script for arithmetic and fixtures; do not spend model
  reasoning re-deriving numbers a script can compute.
- Read only the inputs needed for the chunk (grep/offset), not the whole corpus;
  after a handoff, do not re-read inputs that are already summarized.
- The orchestrator estimates the artifact size at planning time and records
  `chunks`, `max_write_kb`, `max_session_kb`, and `context_stop_pct` in the card.
- A generator role may process chunks in self-sub-sessions: same role only, one
  child at a time, explicit chunk brief, non-overlapping file or section, and a
  return of the artifact path plus a summary of at most 10 lines. The parent
  remains accountable and must not read the full artifact into its own context;
  it validates with grep, a script, or targeted reads.
- The `ux-designer` may delegate prototype pages to one `harness-coder` child at
  a time: explicit page brief, non-overlapping files under
  `docs/ux/prototype/<slug>/`, and a return of paths plus a summary of at most
  10 lines. This is the only cross-role child call.
- A depth-2 call may be a same-role self-sub-session or the allowed
  `ux-designer -> harness-coder` prototype call. The child must not spawn
  another child; depth 3 and all other cross-role calls are forbidden. The
  global `subagent_depth` must be 2.

### 11.2 Verification and approval policy (P2)

`stage-done.ps1` is the only writer of checkpoint status. The decision matrix:

| Result | Intermediate CP | CP-F |
|---|---|---|
| `FAIL>0` or `UNCHECKED>0` | `awaiting_review`; no auto-approval | `awaiting_review` |
| `MANUAL>0` | `awaiting_review`; user checks the listed items | `awaiting_review` |
| all zero, `hold: false` | `approved` by `auto (P2)`; task stays `in_progress` | user approves; only explicit `-AutoApprove` may auto-approve |
| `hold: true` | `awaiting_review` | `awaiting_review` |

- `UNCHECKED` means a declared artifact is not covered by any check. Fix the
  registry or the card; never mark it approved.
- A failed check cannot be waived with prose. If the registry is wrong, fix the
  registry and record why in the card log.
- `-AutoApprove` is allowed only for `CP-F`, only when the user explicitly asked
  for it in the current session, and only with `FAIL=0`, `UNCHECKED=0`,
  `MANUAL=0`, and `hold: false`.
- Manual checks are review items, not failures. The user decides them; the role
  must not set their result.
- Approval is never inferred from silence, file edits, an empty remarks section,
  or a passing exit code alone.

### 11.3 Evidence ledger, hashes, and usage

- `docs/evidence/T-XXX.md` is the append-only hash ledger:
  `| Checkpoint | Stage | Artifact | SHA256 | Recorded |`.
  The latest row per path wins; a 64-hex SHA256 is required.
- `hash-match` fails when a declared artifact differs from the latest recorded
  hash after a checkpoint snapshot. Never edit or delete ledger rows to hide a
  change; record a new checkpoint.
- Checks JSON is machine evidence: `task`, `stage`, `workflow`, `base_commit`,
  `results`, `summary`. Do not rewrite results by hand.
- Usage comes from `measure-tokens.ps1` (local opencode database, sessions
  attributed by task title). Record it in `docs/metrics/tokens-<slug>.md`, the
  board `Usage` column, and the card `usage` field.
- Unattributed sessions (`~`) are a measurement gap, not zero usage. If more
  than 20% of a project's tokens are unattributed, `/harness-doctor` warns and
  the orchestrator records an issue.
- Token budgets in section 11.1 remain process limits; usage evidence never
  overrides a failed check or an acceptance criterion.

## 12. Role artifacts

| Role | Write area |
|---|---|
| harness | no files; reads board/cards/bugs, routes roles |
| orchestrator | `docs/plan.md`, `docs/tasks/`, `docs/checkpoints/`, `docs/bugs/`, `docs/activity.puml`, `README.md`, `.gitignore`; `docs/evidence/` and `docs/metrics/` are machine-generated by scripts |
| analyst | `docs/analysis/` |
| ux-designer | `docs/ux/` |
| architect | `docs/architecture/` (`architecture-*.md`, `adr-*.md`, `contracts-*.md`, `*.puml`, `*.svg`, `openapi-api-*.yaml/.json`) |
| coder | `src/`, `backend/`, `tests/`, `scripts/`, `Dockerfile`, `docker-compose*.yml`, `Makefile`, `.gitignore`, `requirements.txt`, `pyproject.toml`, `.env.example`, `alembic.ini`, `sources.yaml`; `docs/ux/prototype/**` only when invoked by `ux-designer` for mockups |
| qa | `docs/qa/` |
| qa-vision | `docs/qa/` |
| doc-writer | `docs/guides/`, `README.md`, ADR finalization |

All roles may create `docs/issues/` records; the orchestrator verifies the
index. The user may edit any artifact and checkpoint file during a checkpoint;
the role must preserve those edits. Product bug evidence is reported to the
orchestrator; roles do not edit `docs/bugs/`. The hash ledger
`docs/evidence/T-XXX.md` and checks JSON are machine evidence: scripts append,
roles never edit them.

## 13. Prohibitions

- Editing `~/.config/opencode/**` or system configs.
- Production actions: `git push`, `docker push`, deployment outside
  local/staging, production migrations.
- Secrets/tokens/keys in code, logs, or commits.
- Cross-role subagent calls, except the single `ux-designer -> harness-coder`
  prototype delegation: depth 2, sequential, one child at a time, coder writes
  only `docs/ux/prototype/**`, no children. Self-sub-sessions of the same role
  are allowed only for decomposed chunks, one at a time, when the agent declares
  `task` self-allow and `subagent_depth` is 2. `harness` allows only harness
  roles.
- Using `docs/activity.puml`, `docs/activity.svg`, or any derivative as a
  decision input for task/bug status, dependencies, active-task detection,
  acceptance, checkpoint decisions, or role routing. These artifacts are
  informational visualizations only.
- Parallel task execution: >1 active task, concurrent `/harness-run`, batch or
  parallel `task`, feature/bugfix preemption, or `board-update` while a task is
  active.
- Silently overwriting user edits made at a checkpoint.
- Hand-editing machine fields: checks JSON results, ledger hashes, checkpoint
  `snapshot_commit`/`generated_by`, or board/card `Usage`/`Commit`; bypassing a
  `FAIL`/`UNCHECKED` result with prose; setting a checkpoint `status` without a
  decision or a P2 all-zero result.
- Deleting or rewriting evidence ledger rows or checkpoint snapshots.
- Broadening harness `allow` patterns to `*`, `git*`, or `Remove-Item`; the five
  approved script patterns are exact and doctor-checked.
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
- The index must list every `ISSUE-*.md` file and contain no orphan rows;
  `/harness-doctor` checks both directions.
- Only `docs/issues/` is valid; never keep issue files in a root
  `harness-issues/` directory.
- Required: status, severity, type, source, role, absolute location, symptoms,
  cause, solution/workaround, verification, prevention, links.
- Put the issue ID in the card log; an issue does not replace the card.
- Never write secrets/tokens/`.env` to an issue.
- `resolved` means the root cause is fixed. Prevention that requires a process,
  agent, or script change gets a follow-up task and a link in the issue; record
  the implemented prevention in the issue.
- On resolution set `resolved`/`workaround`; do not delete history.
