# ISSUE-20261108-170347-qa-subagent-incomplete-report: harness-qa returns an incomplete report instead of an accept/reject verdict

| Field | Value |
|---|---|
| id | ISSUE-20261108-170347 |
| status | resolved |
| severity | minor |
| type | model |
| detected_at | 2026-11-08T14:03:47Z |
| resolved_at | 2026-11-08T20:16:03+03:00 |
| source | primary (harness lead) |
| role | harness (lead) |
| location | C:/study/ai/research/Qwen 3.8 27B Q4_K_M; C:/Users/sergey/.config/opencode/agents/harness-qa.md; C:/Users/sergey/.config/opencode/opencode.jsonc |
| environment | opencode 1.18.33; QA model `qwen3.8:27b-64k` (vision, 64K); tiel-coder vision - actual `num_ctx 32768` |

## Symptoms

Calling harness-qa (tiel-coder vision) for T-004 acceptance twice returns an
incomplete/empty result instead of a structured accept/reject verdict:

- `ses_e44984bbeffewKshJm8moo5jN3` - `finish=length`, total 32767, output 588;
- `ses_e449259a4ffe7eJGQCoCbuhds4` - `finish=length`, total 32767, output 70.

## Reproduction

1. Run `harness-qa` for T-004 (Vue.js web frontend).
2. QA reads sources and runs tests/build; context reaches ~32K.
3. The model returns `finish=length` before the final verdict.
4. A repeat run on the same model gives the same result.

## Expected / actual behavior

- Expected: a structured accept/reject verdict against 6 acceptance criteria.
- Actual: generation cut off by the context limit; no verdict formed.

## Cause

The cause is not subagent depth and not a timeout. For model
`tiel-coder:35b-a3b-mtp-128k-vision`, the actual `num_ctx` is **32768**
(`ollama show`), while `~/.config/opencode/opencode.jsonc` specified
`limit.context: 128000` (both in `ollama` and `ollama-metrics`). Opencode
believed the context was 128K and did not run compaction; the QA session read
~56-60K characters of tool output and hit the real 32K limit. Both runs ended
with `finish=length` at 32767 tokens with small output (588 and 70 tokens).

For comparison: `qwen3.8:27b-64k` has actual `num_ctx 65536` and supports
vision/tools; `tiel-coder:...-text` has actual 131072.

## Solution

1. The harness QA model was switched from `tiel-coder:35b-a3b-mtp-128k-vision`
   to `qwen3.8:27b-64k` (vision, 64K):
   - `harness/agents/harness-qa.md` (source) and the global installation;
   - `harness/process.md` section 2, `README.md`, `docs/description/README.md`;
   - harness version 1.0.1 -> 1.0.2; `install.ps1` was run.
2. A context rule was added to the QA role: read selectively (card acceptance,
   API contract, target files/patterns), do not read all of `src`; tests/build
   with brief output; keep the verdict short.
3. In `~/.config/opencode/opencode.jsonc`, `limit.context` was fixed for
   `tiel-coder:35b-a3b-mtp-128k-vision` and `tiel-coder:35b-a3b-mtp-64k`
   (both providers): 128000/65536 -> 32768, matching the actual `num_ctx`.
4. T-004 remains accepted by primary as a temporary workaround until a working
   QA is available; the QA role is now operational for T-006.

## Verification

- `opencode debug agent harness-qa` shows `modelID: qwen3.8:27b-64k`.
- QA run `ses_e43e52504ffev0LbLrSkUDutZz` (qwen3.8:27b-64k):
  - read the T-004 card, API contract, views/stores/api/tests;
  - `npm run test -- --run` -> 10/10 passed;
  - `npm run build` -> success, 104 modules, `dist/` created;
  - 38,837 tokens total, no `finish=length`.
- QA model qwen3.8 turned out to be slow: the process was cut by a 15-minute
  timeout before the final text. Resuming the same session (qwen3.8 model; the
  CLI used the build agent on the same context) produced the full verdict:
  **REJECT**.
- Side finding for T-004 (medium): `RunButton.vue` does not show 409/500 launch
  errors to the user (criterion 3 partially met); this is a separate T-004
  problem, not a QA role problem. T-004 was previously accepted by primary; a
  decision is needed - return T-004 for fixes or create a separate issue.

## Prevention

- Compare actual `num_ctx` (`ollama show`) with `limit.context` in
  `opencode.jsonc`; on divergence, fix the config or the model.
- Keep the QA context small: targeted reads, `rg`, brief output.
- Account for qwen3.8 latency: give QA a sufficient timeout or split QA into
  text acceptance and vision review.
- Do not move an issue to `resolved` without a real QA run; record session ID,
  model, tokens, and `finish`.

Implemented in harness 2.2.1: `/harness-doctor` compares the actual `num_ctx`
from `ollama show` with `limit.context` and warns on overflow; `process.md`
section 11 treats a client timeout with a written artifact as resumable, not as
a failed attempt.

## References

- QA sessions: `ses_e44984bbeffewKshJm8moo5jN3`, `ses_e449259a4ffe7eJGQCoCbuhds4`,
  `ses_e43e52504ffev0LbLrSkUDutZz`.
- `C:/Users/sergey/.config/opencode/agents/harness-qa.md`.
- `C:/Users/sergey/.config/opencode/opencode.jsonc` (model limits).
- `harness/process.md` section 2, `harness/agents/harness-qa.md`.
- `docs/tasks/T-004-web-vue.md` (Acceptance, Log).
- `docs/issues/README.md`.

## Timeline

- 2026-11-08T14:03:47Z: detected; two runs cut off at 32767 tokens.
- 2026-11-08T19:53:31+03:00: QA model switched to qwen3.8:27b-64k,
  `install.ps1` run.
- 2026-11-08T19:54:00+03:00: `limit.context` fixed for vision/64k models.
- 2026-11-08T20:00:39+03:00: qwen3.8 QA run read artifacts, tests 10/10,
  build success; 38,837 tokens, no `finish=length`.
- 2026-11-08T20:16:03+03:00: full REJECT verdict received (criterion 3 partial);
  issue closed, T-004 finding recorded separately.
