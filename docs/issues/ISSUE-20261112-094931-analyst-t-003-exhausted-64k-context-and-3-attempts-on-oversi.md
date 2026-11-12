# ISSUE-20261112-094931: Analyst T-003 exhausted 64K context and 3 attempts on oversized e2e artifacts

| Field | Value |
|---|---|
| id | ISSUE-20261112-094931 |
| status | Mitigated |
| severity | major |
| type | model |
| detected_at | 2026-11-12T09:49:31.3659966+03:00 |
| source | ai-task-tracker T-003 |
| role | harness-analyst |
| location | C:/study/ai/research/ai-task-tracker/docs/analysis/e2e-use-cases-ai-task-tracker.md; session ses_e349e85afffepgtl3SJOIZMdPi |
| environment | OS: Microsoft Windows NT 10.0.26300.0; cwd: C:\study\ai\research\harness |

## Symptoms

The analyst role session for T-003 (A-02 e2e use cases and YAML dataset) ran for
4 h 08 min and failed three times before producing the artifacts:

- `19:34:08` - `SSE read timed out` (`ProviderResponseStreamError`) after ~50 min
  of a single generation; no artifact written.
- `20:25:33` - `finish=length` with output exactly 16 384 tokens; the attempted
  single `write` of the whole Markdown catalog produced no file.
- `21:02:49` - a second `SSE read timed out` after ~58 min; no artifact written.
- The fourth attempt (`22:01`-`23:07`) succeeded only after switching to a
  skeleton plus one `edit` per use case and writing the YAML in three parts.
- At `23:08` the context reached 63 901 / 65 536 tokens (97.5%) and a second
  compaction ran; the session was aborted at `23:20`.

Session totals: input 136 497, output 70 443, cache read 910 312, 43 assistant
messages, 2 compactions. Artifacts: 40 331 B Markdown (223 lines) and 28 751 B
YAML (646 lines). The 3-attempt limit was exhausted; the next failure would have
forced `blocked`.

## Reproduction

1. Give one analyst role call a stage that produces eight use cases plus the
   YAML dataset (T-003 A-02) with no chunk budget.
2. Let the role read all inputs and attempt to author the catalog in a single
   `write`/few large `edit` calls on `ollama-metrics/qwen3.8:27b-64k`
   (`limit.context=65536`, `limit.output=16384`).
3. Observe `finish=length`, SSE stream timeouts, context growth to ~98%, and
   compaction loops; the same oversized call is retried instead of split.

## Expected / actual behavior

- Expected: the role writes large artifacts incrementally, stops before the
  context limit, and splits the stage into smaller chunks with a handoff.
- Actual: the role attempted oversized single-shot writes, exhausted the output
  budget and context, burned all three attempts, and required manual recovery.

## Cause

1. No generation budget: one `write` carried 17-21.5 KB, `edit` calls 8-14.5 KB;
   with reasoning, a single response hit the 16 384-token output cap.
2. No decomposition: eight use cases plus a 28 KB YAML dataset were treated as
   one role run; every write payload stays in the session history.
3. Roles could not delegate: `task: deny` and default `subagent_depth=1` blocked
   self-sub-sessions; process section 13 forbade nested calls.
4. Compaction was used instead of a curated handoff; after each compaction the
   role re-read the inputs and re-derived token arithmetic.
5. No planning-time size estimate and no stop rule at 60% of context.
6. The card log recorded "3 attempts" but omitted the `finish=length` attempt and
   token metrics, weakening the 3-attempt rule.

## Solution / workaround

Harness 2.3.0 introduces generation budgets, mandatory chunk decomposition,
self-sub-session rights for generator roles, and installer/doctor checks. See
"Prevention / follow-up" for the implemented files.

## Verification

Implemented and installed globally; ai-task-tracker synced to 2.3.0. Static
checks pass: `doctor.ps1` confirms `subagent_depth: 2`, self-allows, no cross-role
allows; `opencode debug agent harness-analyst` shows the self-allow in the
resolved task permissions; `validate-e2e-data.py` reports 8 use cases, 24 links,
0 errors on the T-003 dataset. Runtime confirmed after restart: a `task`
self-sub-session of `harness-analyst` (depth 2) spawned one child
(`harness-analyst`) that replied `CHILD_OK` — no grandchildren or other roles.
Root cause mitigated. Pending: lead approves `T-030-CP-F.md`.

## Prevention / follow-up

- `harness/process.md`: generation/context budget table, chunking rules,
  self-sub-session exception, per-chunk attempts, compaction handoff rule.
- `harness/templates/task-card-feature.md` and `task-card-bugfix.md`: `chunks`
  and `budget` fields.
- `harness/agents/harness-analyst.md`, `harness-coder.md`: self-sub-session
  permission (`task` self-allow) and chunk authoring rules.
- `harness/scripts/install.ps1`: top-level `subagent_depth: 2` with backup and
  validation; `harness/scripts/doctor.ps1`: depth and self-delegation checks.
- `harness/scripts/check-budget.ps1` and `harness/scripts/validate-e2e-data.py`
  to catch oversized artifacts and broken anchors before a checkpoint.

## Links

- Session: `ses_e349e85afffepgtl3SJOIZMdPi` (ai-task-tracker, 2026-11-11).
- Task card: `C:/study/ai/research/ai-task-tracker/docs/tasks/T-003-e2e-use-cases.md`.
- Checkpoint: `C:/study/ai/research/ai-task-tracker/docs/checkpoints/T-003-CP-2.md`.
- Harness board: T-030 (`docs/tasks/T-030-context-budget-self-sessions.md`).

## Timeline

- 2026-11-11T19:34:08+03:00: first SSE timeout.
- 2026-11-11T20:25:33+03:00: `finish=length`, no artifact.
- 2026-11-11T21:02:49+03:00: second SSE timeout.
- 2026-11-11T23:07:00+03:00: artifacts completed incrementally.
- 2026-11-11T23:08:06+03:00: context 63 901 / 65 536; second compaction.
- 2026-11-11T23:20:09+03:00: session aborted.
- 2026-11-12T09:49:31+03:00: issue recorded; fix started.
- 2026-11-12T09:57:50+03:00: harness 2.3.0 installed; `subagent_depth: 2` set.
- 2026-11-12T09:58:04+03:00: ai-task-tracker synced to 2.3.0.
- 2026-11-12T09:59:00+03:00: doctor and validators pass; runtime smoke pending restart.
