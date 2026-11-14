# T-041 pilot: unit-of-work model in ai-task-tracker

Measured on 2026-11-14, project `C:/study/ai/research/ai-task-tracker`, task T-008
(stage I-01), harness core `3.0.0-dev` (source 2.8.0 + ledger/depth-3 changes).

Harness was synced with `init.ps1 -Force`; the chunk plan is
`docs/chunks/T-008.json` with seven chunks and a 1135-path baseline snapshot.
Each chunk has a brief under `docs/chunks/T-008/`.

## Executed chunks

| Chunk | Scope | Attempts | Wall min | Messages | Input | Output | Cache read | cr/in | Compaction |
|---|---|---|---|---|---|---|---|---|---|
| C4fix | apply fix plan A/B/C + wiring test | 1 | 26 | 91 | 184650 | 49964 | 6596097 | 35.7x | none |
| C5a | API-002 calendar + tokens | 1 | 21 | 63 | 81527 | 47715 | 3992331 | 49.0x | none |

Verification: `mvn -f backend/pom.xml clean test` -> 98 tests green after C4fix;
112 tests green after C5a. Both verified independently by the parent role.

## Baseline (pre-ledger, same task)

| Unit | Attempts | Wall min | Input | Cache read | cr/in | Notes |
|---|---|---|---|---|---|---|
| T-008 chunk 3 (ingestion + tests) | 3 | 73.6 | 350592 | 11993356 | 34x | two sessions, 16 handoffs in the lead chain overall |
| T-008 chunk 1 (skeleton) | 3 | - | - | - | - | attempts 1-2 returned an empty result |
| T-008 total before the pilot | - | 1066 | 2071945 | 6476228 | 3.1x | task-level aggregate |

## Result against the pilot criteria

| Criterion | Target | C4fix | C5a | Verdict |
|---|---|---|---|---|
| `cr/in` per chunk | <= 15x | 35.7x | 49.0x | **not met** |
| No compaction inside a chunk | 0 | 0 | 0 | met |
| Attempts per chunk | 1 | 1 | 1 | met |
| Wall per chunk | <= 45 min | 26 | 21 | met |
| Cold resume without lost work | required | yes (C5a started from the brief and ledger only) | yes | met |
| Usage attributed per chunk | required | via session id | via title `T-008.C5a` | met |

## Why `cr/in` did not improve (and why it is the wrong primary metric)

`cr/in` is `sum(cache_read) / sum(input)` over the whole session tree. The cache
read grows with **turns x context per turn**, not with the size of the chunk:

- the coder session used 63-91 messages (roughly 31-45 turns);
- the per-turn context was about 130-146 KB, near the 128K window of
  `tiel-coder:35b-a3b-mtp-128k-text`;
- a smaller chunk lowers the *input* tokens, so the same number of turns produces
  a **higher** ratio. A ratio comparison across different input sizes is not
  meaningful.

Chunking did improve what it was designed to improve: no compaction, one attempt
instead of three, and wall time 2.8-3.5x lower than the 73.6 min baseline.

Proposed replacement criteria (to be recorded in ADR-006 when the model is
generalized in T-042):

- turns per chunk <= 40 (C4fix 45, C5a 31);
- cache read per turn <= 150K (C4fix 146K, C5a 129K);
- no compaction, one attempt, wall <= 45 min, cold resume works.

## Stop and resume evidence

1. C4fix completed and was recorded in the ledger with 8 sha256 hashes.
2. The run was stopped (no further chunk dispatched in that context).
3. C5a was dispatched as a cold session whose only context was
   `docs/chunks/T-008/C5a.brief.md` plus the owned paths; it needed no history
   from C4fix and produced 13 files.
4. `chunk.ps1 status` in a fresh process reports `2/7 done; next C5b`, and
   `chunk-validate.py` reports VALID, so the state is entirely in the ledger.

Caveat: a full root-session restart through `/harness-run T-008` was not
performed; the cold subagent session is the equivalent resume path for the role,
and the ledger was read from disk by a new process.

## Findings

1. `chunk-validate.py` originally compared the union of `owns` against coarse
   card globs (`src/**`), which fails for any fine-grained plan. Fixed during the
   pilot: coverage now walks the real files and requires a `baseline` snapshot for
   pre-ledger work.
2. Session titles must carry `T-XXX.<chunk>` (`T-008.C5a`); otherwise per-chunk
   usage cannot be attributed. The `usage -Session <id>` path covers the
   exceptions, and attribution must walk the nearest ancestor with a chunk id, not
   the root title, or one chunk inherits the whole root session.
3. The running opencode process still enforced depth 2 during the pilot
   (`ISSUE-20261114-193500` in the harness repo), so the chunks ran at depth 1
   with no children.
4. The pilot measures the model, not the prompts: the host process had loaded the
   role prompts from before T-040, so the coder did not read the ledger itself.
   The parent kept the ledger, which is the orchestrator's role in the final
   model anyway.
