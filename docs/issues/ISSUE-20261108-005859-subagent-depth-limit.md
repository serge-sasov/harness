# ISSUE-20261108-005859-subagent-depth-limit: launching harness-coder via task - "Subagent depth limit reached (1)"

| Field | Value |
|---|---|
| id | ISSUE-20261108-005859 |
| status | resolved |
| severity | major |
| type | tool |
| detected_at | 2026-11-07T21:58:59Z |
| resolved_at | 2026-11-08T17:08:39+03:00 |
| source | primary (harness lead) |
| role | harness (lead) |
| location | C:/study/ai/research/Qwen 3.8 27B Q4_K_M; C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js:79 |
| environment | opencode 1.18.33; `experimental.subagent_depth` not set (default 1); provider ollama-metrics/qwen3.8:27b-64k |

## Symptoms

Calling `task` with `subagent_type: "harness-coder"` (and other `harness-*`
roles) fails terminally:

```
Subagent depth limit reached (1). Increase 'subagent_depth' to allow nested subagents.
```

The error occurs not in the root (primary) session but in a session created by
the automatic compaction handoff. From a real root session, routing works:
`harness-orchestrator`, `harness-analyst`, `harness-architect`, and
`harness-coder` were successfully launched in `ses_e48bdaeeeffe6i5na0LjBRt98b`;
later `harness-orchestrator`, `harness-coder`, and `harness-qa` were successfully
launched from root `ses_e455ef26effeICirCvhfaDzuOi`.

## Reproduction

1. Work in a session with model `ollama-metrics/qwen3.8:27b-64k`.
2. Wait for automatic compaction: the `qwen-compaction-handoff` plugin creates a
   continuation session with `parentID` (before the fix).
3. In that session, call `task` with any `subagent_type: harness-*`.
4. The error "Subagent depth limit reached (1)" appears.
5. Another compaction increases the depth: the continuation is created from the
   continuation, and the error persists.

## Expected / actual behavior

- Expected: the continuation session after compaction remains an equal primary
  session and can launch harness roles (`task: allow`).
- Actual: the continuation is treated as a child session; `task` computes depth
  along the `parentID` chain and blocks the launch when `depth >= 1`.

## Cause

The cause is not `permission.task` and not a "primary session ban". The plugin
`C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js` (line 79
before the fix) created the continuation session as follows:

```js
body: { parentID: sessionID, title }
```

Because of `parentID`, opencode treats the continuation as a child session.
`packages/opencode/src/tool/task.ts` (1.18.33) computes depth by traversing the
`parentID` chain; when `depth >= (subagent_depth ?? 1)`, it throws the error.
`experimental.subagent_depth` is not set, so the limit is 1: a root session
(depth 0) can launch subagents, but a continuation (depth 1) cannot. Each
subsequent compaction creates another level.

Confirmation:

- `%LOCALAPPDATA%/opencode-compaction/handoff.log`:
  - `2026-11-07T20:56:39Z` - `ses_e48bdaeeeffe6i5na0LjBRt98b` -> `ses_e48336f53ffeagk3CHjcE056HT`;
  - `2026-11-07T21:26:27Z` - `ses_e48336f53ffeagk3CHjcE056HT` -> `ses_e48182831ffe4KyNMbQsl5zXLd`.
- In `opencode.db`: `ses_e48336f53ffeagk3CHjcE056HT.parent_id = ses_e48bdaeeeffe6i5na0LjBRt98b`,
  `ses_e48182831ffe4KyNMbQsl5zXLd.parent_id = ses_e48336f53ffeagk3CHjcE056HT`.
- The issue was created in `ses_e48182831ffe4KyNMbQsl5zXLd` (depth 2).

## Solution

The `qwen-compaction-handoff.js` plugin was fixed:

1. Handoff is skipped when the current session already has a `parentID`
   (a subagent or an old continuation): no new child sessions are created.
2. The continuation session is created without `parentID` (`body: { title }`),
   so it remains a root session (depth 0) and can launch harness roles.
3. Backup of the original version:
   `C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js.bak-20261108-170839`.

The previous workaround "run roles inline in primary" is not a fix: it violates
sections 1 and 8 of `harness/process.md` (the lead writes no files) and led to
two tasks in `in_progress` (T-003, T-004), a missing `backend/`, and a partial
`web/`. If a session has `parentID`, start a new root session instead of doing
role work outside routing.

## Verification

- `node --check qwen-compaction-handoff.js` - syntax OK.
- Mock plugin test (Node ESM, fake `client`):
  - root session -> `session.create` called with `body: { title: "root (continued)" }`,
    without `parentID`; `promptAsync` executed; `output.enabled = false`;
  - child session (`parentID` set) -> `session.create` not called,
    `output.enabled = true`, `skip ... child session` written to the log.
- Historical routing check: `harness-*` roles were successfully launched from
  root sessions (see "Symptoms").
- Follow-up: after the next real compaction in a qwen session, check that the
  new session has `session.parent_id IS NULL` and that `task` with
  `harness-orchestrator` works from it. Applying the patch may require an
  opencode restart.

Note: earlier claims in this record about "pytest green" for T-003 and
"npm test/build success" for T-004 were not confirmed by artifacts at
verification time: `backend/` was missing, `web/` was partial. These checks are
not related to the cause of this issue.

## Prevention

- Compaction handoff must not create a continuation via `parentID`; the
  continuation must remain a root session.
- When the current session has `parentID`, do not perform role work inline:
  start a new root session or fix the handoff.
- Do not move an issue to `resolved` without a reproducible check and artifacts;
  record real commands and results.
- Add a check to `/harness-doctor` (or docs): warn when the handoff plugin
  creates child continuation sessions.

Implemented in harness 2.2.1: `/harness-doctor` warns when the compaction
handoff creates a continuation with `parentID`; `harness/process.md` section 11
forbids running role work inline on a depth/routing failure and requires a new
root session plus an issue record.

## References

- Plugin: `C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js`
- `packages/opencode/src/tool/task.ts` (opencode 1.18.33), depth check.
- `harness/process.md` section 0 (routing), sections 1/8 (roles and artifacts),
  section 9 (global config edit ban), section 10 (issue tracking).
- `%LOCALAPPDATA%/opencode-compaction/handoff.log`.
- Sessions: `ses_e48bdaeeeffe6i5na0LjBRt98b`, `ses_e48336f53ffeagk3CHjcE056HT`, `ses_e48182831ffe4KyNMbQsl5zXLd`, `ses_e455ef26effeICirCvhfaDzuOi`.

## Timeline

- 2026-11-07T20:56:39Z: compaction handoff created `ses_e48336f53ffeagk3CHjcE056HT` (child).
- 2026-11-07T21:26:27Z: another compaction created `ses_e48182831ffe4KyNMbQsl5zXLd` (grandchild).
- 2026-11-07T21:58:59Z: error `Subagent depth limit reached (1)` detected (corrected from `2026-11-08T00:58:59Z`: UTC/local confusion).
- 2026-11-08T17:08:39+03:00: plugin fixed (root continuation + skip child), mock check passed.
- Pending: confirmation on the next real compaction in a qwen session.
