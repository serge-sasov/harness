# ADR-006: Recursive same-role decomposition

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-11-14 |
| Task | T-037 |
| Related ADRs | ADR-003, ADR-004, ADR-005 |

## Context

The harness already forbids compaction as a decomposition tool
(`process.md` section 11.1) and already allows one same-role self-sub-session per
decomposed chunk at depth 2. Measured work shows that the rule is not enough:

- `ai-task-tracker` T-008 ran the lead chain through 16 consecutive compaction
  handoffs. Each handoff re-read the upstream context, so the cost of a chunk was
  dominated by re-reading rather than by producing.
- The coder chunk 3 of T-008 cost `in=350592`, `cr=11993356` (34x cache-read to
  input) and 73.6 minutes. Chunk 1 needed three attempts; the first two produced
  an empty result.
- Chunk 3 ingestion alone cost `in=229367`, `cr=5423031` and 44 minutes; the
  tests-and-fix part cost `in=97335`, `cr=6256492` (64x).
- The architect R-02 cost `in=471089`, `cr=2395332` and 129 minutes in one
  session; R-01 in 2.6.0 cost `in=402036`; one architect chunk wrote a 22.9 KB
  contract, above the 8 KB per-write limit, reported as
  `ISSUE-20261113-115617`.
- The UX designer U-02 cost `in=1046186`, `cr=2981750` in one session.

Two causes are visible. First, the chunk plan lived in free text in the task card
and in the model's head, so a resumed session could not tell what was already
done. Second, the depth ceiling of 2 forced a single worker to do a whole role
stage, which is larger than one budget unit, so the worker either overshot the
context or compacted mid-chunk.

The user asked for a recursive decomposition in which a stage is split into
chunks, a chunk that is still too large is split again by the same role, and the
intermediate artifacts are explicit enough to stop after any chunk and resume in
a cold session.

## Decision

1. **The unit of work is a chunk.** A role stage is not executed as one session.
   The card declares a chunk plan and every chunk is one budget-sized unit of one
   role's output. A stage is complete when all of its chunks are `done`.
2. **The chunk plan is machine-readable.** It lives in `docs/chunks/T-XXX.json`
   and is the single source of truth for progress. The card and the board carry
   only a summary; they never duplicate the per-chunk state. The ledger schema is
   defined by `harness/templates/chunk-ledger.md` and validated by
   `harness/scripts/chunk-validate.py`.
3. **Chunk fields.** Each chunk record has: `id`, `parent` (or `null`), `stage`,
   `role`, `depth`, `title`, `state`, `owns`, `inputs`, `brief`, `acceptance`,
   `produced`, `base_commit`, `attempts`, `usage`, `issues`, `started`,
   `finished`. `owns` is a list of repo-relative paths or globs; `produced` is a
   list of `{path, sha256}`; `usage` is `{in, out, cr, min}`.
4. **States.** `pending -> in_progress -> done | failed | blocked`. `failed`
   returns to `in_progress` on the next attempt; `blocked` requires an issue
   record and is cleared only by the orchestrator. Only `done` chunks count as
   coverage; a partially written file makes a chunk `failed`, never `done`.
5. **Ownership is exclusive and total.** No two chunks that are not
   ancestor/descendant of each other may own overlapping paths, including chunks
   under different parents. A parent's `owns` is the union of its children's
   `owns`, so an ancestor may overlap a descendant by design. Every produced
   path must be inside the chunk's `owns`. The union of the top-level `owns` must
   cover the artifacts the card declares for that stage. Ownership is resolved at
   planning time; a re-plan is recorded in the ledger, not negotiated mid-chunk.
6. **Depth policy.** `d1` is the role session the lead calls; it plans, verifies,
   and may write the chunks that fit the budget. `d2` is a same-role child for a
   chunk that does not fit one session. `d3` is a further same-role split of a
   `d2` chunk that still does not fit. The ceiling is 3; a fourth level is never
   spawned. Children are sequential, one at a time, never parallel. Cross-role
   calls remain forbidden except `ux-designer -> harness-coder` at depth 2, and
   that coder may not delegate further.
7. **Escalation condition.** A chunk is split only when the estimate exceeds the
   budget: more than `max_session_kb` of new content, more than
   `max_input_tokens` of inputs, or more than one checkpoint-worthy artifact.
   Splitting for convenience is not allowed; a chunk that already fits is not
   re-split because a deeper chain exists.
8. **Budget object.** The ledger carries the effective limits for the task:
   `max_write_kb`, `max_session_kb`, `context_stop_pct`, `max_turns`,
   `max_input_tokens`, `max_wall_min`. Defaults come from `process.md` section
   11.1 per artifact type. The budget is data, not prose: `chunk-budget` reads
   it.
9. **Brief contract.** A chunk brief is a separate file
   `docs/chunks/T-XXX/<id>.brief.md` with: goal in one sentence, input pointers
   (path plus line range, never pasted content), `owns`, acceptance bullets, the
   stop rule, the return format, and the depth it is executed at. A cold session
   must be able to execute a chunk from the brief alone.
10. **Return contract.** A child returns at most ten lines: what it produced,
    the produced paths, the resulting chunk state, and any issue id. It never
    returns the artifact text. The parent validates with `chunk-validate.py`, a
    hash check, or a targeted read.
11. **Stop and resume.** The only safe stop point is a chunk boundary. A stop
    after chunk N leaves N chunks `done`, `produced` hashes recorded, and the
    next chunk `pending`; a cold session resumes by reading the card, the ledger,
    and the next brief. Compaction inside a chunk is a failure signal: the role
    must stop, mark the chunk `failed` with a note, and let the next session
    continue. Finished chunk artifacts are not re-read on resume.
12. **Machine-owned fields.** `state`, `attempts`, `produced.sha256`, `usage`,
    `base_commit`, and the evidence rows are written by `chunk.ps1` and
    `stage-done.ps1`, never by hand. `title`, `brief`, `owns`, `inputs`, and
    `acceptance` are planning fields, written by the orchestrator at `P-00` or by
    the role at `d1` planning time.
13. **Per-role granularity.** One chunk is one budget unit of the role's output:

    | Role and stage | Chunk |
    |---|---|
    | analyst A-01 | one business area with its `FR-NNN` group and questions |
    | analyst A-02 | one use case with its YAML entries |
    | ux-designer U-01 | one journey group or one screen group |
    | ux-designer U-02 | one wireframe set, one or two prototype pages, or one UI-spec section |
    | architect R-01 | one ADR, one description section group, or one diagram set (component plus at most three sequence diagrams) |
    | architect R-02 | one OpenAPI specification, one contract half, or one diagram group |
    | coder I-01 | one module or file group with its unit tests |
    | coder I-02 | runner, data validator, one UC batch, or cleanup |
    | qa Q-01 | one coverage-matrix batch |
    | qa Q-02 | one review section or one UC evidence batch |
    | doc-writer D-01 | one guide section |
    | orchestrator | no delegation; owns the ledger |

14. **Enforcement.** `chunk-validate.py` performs the deterministic checks
    (schema, unique ids, parent existence, state validity, sibling non-overlap,
    produced inside `owns`, coverage of card artifacts). The stage registry adds
    `chunk-ownership-no-overlap`, `chunk-coverage`, and `chunk-budget`. A legacy
    task without a ledger yields `NOT_APPLICABLE`, not `FAIL`, so pre-3.0.0
    cards stay runnable. The orchestrator is the only writer of the ledger's
    planning fields; `stage-done.ps1 -Chunk` is the only writer of the evidence
    and checkpoint rows.

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Keep the 2.x model: free-text chunk list in the card, depth 2 | no new artifacts, no script work | a resumed session cannot tell what is done; the parent must hold the state in context; measured `cr/in` up to 64x | the measured failures come exactly from lost state, not from the chunk count |
| Store progress in a new board column | visible on the board | the board is a one-row-per-task table; per-chunk rows would break `plan-board` and the one-row contract | the board is a summary, not a ledger |
| Keep depth 2 and only shrink chunks | smallest change; no config change | the split decision stays with the same session that is already over budget; a chunk that still overflows has no way down | the architect and UX stages exceed a single session even when split once |
| Depth 4 or unbounded | handles any size | each level re-reads the brief and the upstream context; coordination cost grows faster than the chunk shrinks; harder to audit | three levels cover the measured stage sizes; the ceiling is a budget in itself |
| Script-only enforcement: kill the session at `context_stop_pct` | no process change; hard limit | a killed session leaves a half-written artifact and no return contract; the role learns nothing about planning | detection is not decomposition; `chunk-budget` needs a ledger to compare against |
| Run each chunk as a separate CLI process or an external scheduler | true isolation, no depth config | outside the harness: no role prompt, no checkpoints, no evidence ledger, no board integration | the harness must stay inside opencode sessions |
| Parallel children per chunk | wall-clock reduction | shared files and a single Ollama host; the harness already forbids parallel task execution | the measured bottleneck is context, not latency |

## Consequences

- `process.md` section 0 gains the three-level same-role chain and keeps the
  `ux-designer -> harness-coder` exception at depth 2; section 11.1 replaces the
  depth-2 rule with the chunk contract, the budget object, and the brief and
  return contracts; section 13 narrows the prohibition from "depth 3" to "depth
  4 and parallel children".
- `harness-coder` and `harness-architect` are the pilot roles: their first action
  on a stage becomes writing the chunk plan, not writing the artifact. The other
  five roles follow in a second step so that the pilot measures the model before
  it is generalized.
- New scripts: `chunk.ps1` (init, plan, claim, complete, fail, list, show) and
  `chunk-validate.py` (schema, ownership, coverage, state). `stage-done.ps1`
  gains `-Chunk` and refuses to close a checkpoint while a chunk of that stage is
  not `done`. `measure-tokens.ps1` attributes usage by chunk id in the session
  title.
- New template `harness/templates/chunk-ledger.md`; the card templates reference
  the ledger instead of a free-text `chunks` field.
- New checks `chunk-ownership-no-overlap`, `chunk-coverage`, `chunk-budget` in
  `feature.json` and `bugfix.json`, mapped to the artifact-producing stages.
  Legacy tasks without a ledger are `NOT_APPLICABLE`.
- `subagent_depth` becomes 3 in `install.ps1`; `doctor.ps1` reports the resolved
  depth, warns below 3, and warns that depth 3 multiplies sessions.
- `init.ps1` creates `docs/chunks/` in a new project.
- Cost: one more config value, one ledger per decomposed task, one brief per
  chunk. Benefit: a cold session resumes from the ledger and the brief instead of
  re-reading the corpus, which is the measured source of the 10x-64x cache-read
  amplification.
- Risk: a role may write the ledger by hand and diverge from the produced files.
  Mitigation: `produced` hashes are machine-written and `chunk-coverage` fails a
  chunk whose declared output is outside `owns`.
- Risk: the orchestrator becomes a bottleneck because it owns the ledger. The
  ledger is only touched at plan time and at chunk completion, so the load stays
  one write per chunk, not one per turn.
- Version 3.0.0: the depth value, the role prompts, the process rules, the
  scripts, the checks, the templates, and the documentation change together.

## Contracts and diagrams

- Ledger: `docs/chunks/T-XXX.json`; briefs: `docs/chunks/T-XXX/<id>.brief.md`.
- Schema and example: `harness/templates/chunk-ledger.md`.
- Scripts: `harness/scripts/chunk.ps1`, `harness/scripts/chunk-validate.py`,
  `harness/scripts/stage-done.ps1`, `harness/scripts/measure-tokens.ps1`.
- Checks: `harness/checks/feature.json`, `harness/checks/bugfix.json`
  (`chunk-ownership-no-overlap`, `chunk-coverage`, `chunk-budget`).
- Rules: `harness/process.md` sections 0, 11.1, 13;
  `harness/workflows/feature.md`.
- Roles: `harness/agents/harness-coder.md`, `harness/agents/harness-architect.md`,
  then the remaining five roles.
- Diagrams: `docs/architecture/decomposition-flow.puml/.svg` (chunk lifecycle
  and depth decision) and `docs/architecture/decomposition-artifacts.puml/.svg`
  (artifacts and their writers).
- Config: `subagent_depth: 3` in `~/.config/opencode/opencode.jsonc`, set by
  `harness/scripts/install.ps1`.
