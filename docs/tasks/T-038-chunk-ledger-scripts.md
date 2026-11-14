# T-038: Chunk ledger and chunk scripts

| Field | Value |
|---|---|
| id | T-038 |
| title | Chunk ledger, chunk.ps1, chunk-validate.py, stage-done and measure-tokens integration |
| workflow | feature |
| stage | implementation |
| role | coder |
| status | done |
| hold | false |
| depends_on | T-037 |
| inputs | `docs/architecture/adr-006-recursive-decomposition.md`, `harness/scripts/harness-lib.ps1`, `harness/scripts/stage-done.ps1`, `harness/scripts/measure-tokens.ps1`, `harness/scripts/board-update.ps1`, `harness/scripts/verify-artifacts.ps1`, `harness/scripts/check-budget.ps1`, `harness/templates/task-card-feature.md` |
| artifacts | `harness/scripts/chunk.ps1`, `harness/scripts/chunk-validate.py`, `harness/scripts/stage-done.ps1`, `harness/scripts/measure-tokens.ps1`, `harness/scripts/init.ps1`, `harness/scripts/harness-lib.ps1` |
| e2e | not applicable (harness tooling) |
| ux | not applicable |
| chunks | A: `chunk-validate.py` (schema, ownership non-overlap, coverage, role-zone check); B: `chunk.ps1` (init/plan/claim/complete/fail/list/show) + ledger schema; C: `stage-done.ps1` integration (`-Chunk`, evidence rows, checkpoint gate) and `measure-tokens.ps1` per-chunk attribution; D: `init.ps1` skeleton + `harness-lib.ps1` helpers + self-tests |
| budget | 12/40/65 (code); 8/20/60 (Markdown docs in comments) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] `harness/scripts/chunk-validate.py` validates a ledger file and exits non-zero with a precise message on: invalid JSON, missing required field, duplicate chunk id, `owns` overlap between two chunks of the same task, a chunk that owns a path outside the role write area, a chunk whose `owns` does not cover the artifacts it declares, a child chunk whose `parent` does not exist, and a chunk whose `state` is not in the allowed set. It also supports `--json` output for machine consumption and a `--self-test` mode with its own green cases.
- [ ] `harness/scripts/chunk.ps1` implements `init`, `plan`, `claim`, `complete`, `fail`, `list`, `show` against `docs/chunks/T-XXX.json`; it creates the ledger from a task card, writes chunk records, transitions states (`pending` -> `in_progress` -> `done|failed|blocked`), records attempts, and never edits a chunk's `produced` hashes by hand.
- [ ] The ledger schema is documented in `harness/templates/chunk-ledger.md` (new template) with the field list, the state machine, and a filled example.
- [ ] `harness/scripts/stage-done.ps1` gains a `-Chunk <id>` mode: it validates the chunk, verifies the produced files exist and match the recorded SHA256, appends the rows to `docs/evidence/T-XXX.md`, updates the ledger and the card log, and refuses to close a checkpoint while a chunk of that stage is not `done`.
- [ ] `harness/scripts/measure-tokens.ps1` attributes usage to a chunk when the session title carries the chunk id, and `harness/scripts/chunk.ps1` can show the per-chunk usage of a task.
- [ ] `harness/scripts/init.ps1` creates the `docs/chunks/` skeleton in a new project.
- [ ] Every new script is covered by a self-test or an executable example that is run and reported green.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | chunk tooling | `chunk.ps1`, `chunk-validate.py`, template | n/a | approved | `docs/checkpoints/T-038-CP-1.md` |
| CP-F | final acceptance | all task artifacts | n/a | approved | `docs/checkpoints/T-038-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-038 (phase A, step 2). Implements the ledger and scripts required by ADR-006 (T-037).
- 2026-11-14: implemented `chunk-validate.py` (12 self-test cases green), `chunk.ps1` (init/add/plan/claim/complete/fail/list/show/status/usage/verify), `templates/chunk-ledger.md`, `stage-done.ps1 -Chunk` with the stage gate and `## Chunks`, `measure-tokens.ps1 -ByChunk`, `harness-lib.ps1` chunk usage, `init.ps1` docs/chunks; CP-1 and CP-F approved (harness-core task: machine checks n/a).
