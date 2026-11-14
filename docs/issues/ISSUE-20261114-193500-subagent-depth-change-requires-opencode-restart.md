# ISSUE-20261114-193500: subagent_depth change requires an opencode restart

| Field | Value |
|---|---|
| id | ISSUE-20261114-193500 |
| status | workaround |
| severity | minor |
| type | process |
| detected_at | 2026-11-14T19:35:00+03:00 |
| source | T-039 depth-3 enablement |
| role | orchestrator |
| location | `C:/Users/sergey/.config/opencode/opencode.jsonc`: `subagent_depth` |
| environment | opencode 1.18.33, Windows 10, qwen3.8:27b-64k / tiel-coder:35b-a3b-mtp-128k-text |

## Symptoms

`install.ps1` set the top-level `subagent_depth` to `3` and a fresh
`opencode debug config` reported `"subagent_depth": 3`, but a depth-3 chain in
the already-running session failed:

```
Subagent depth limit reached (2). Increase "subagent_depth" to allow nested subagents.
```

## Reproduction

1. Start an opencode session with `subagent_depth: 2`.
2. Change the value to `3` in `opencode.jsonc` (for example via `install.ps1`).
3. In the same session, call a role whose child calls the same role again.
4. The second nesting level fails with the depth-limit error.

## Expected / actual behavior

- Expected: the resolved config is re-read for every subagent call, so the new
  depth applies immediately.
- Actual: the depth limit is captured when the opencode process starts; the
  running process keeps enforcing the old value.

## Cause

The configuration is loaded at process start and the resolved `subagent_depth`
is held for the lifetime of the process. `opencode debug config` spawns a new
process, so it shows the new value while the host session still enforces 2.

## Solution / workaround

- Confirm the value in a fresh process: `opencode debug config | findstr
  subagent_depth` -> `3`.
- Verify the runtime in a fresh process, not in the session that changed the
  config:

  ```
  opencode run "<prompt that nests harness-coder three levels>"
  ```

  Recorded result: the chain returned `DEPTH3_OK`, so depth 3 is honored after
  a restart.
- Restart the opencode session (or start a new one) before relying on depth 3.

## Verification

- `opencode debug config` (fresh process): `"subagent_depth": 3`.
- `opencode run` smoke chain (fresh process): `DEPTH3_OK` returned from the
  third level; no depth-limit error.
- `doctor.ps1`: `[ok] subagent_depth is 3 (d1 -> d2 -> d3 same-role chains enabled)`.

## Prevention / follow-up

- `/harness-doctor` reports the resolved depth, so a mismatch is visible.
- Record in the runbook: after any `subagent_depth` change, restart before
  relying on it; verify with a fresh `opencode run` smoke chain, not in the
  current session.
- Doctor could compare the resolved config with the running session's behavior
  in a future revision (not implemented; no API for the host process limit).

## Links

- ADR-006 decision 6 (depth policy) and T-039.
- `harness/scripts/install.ps1` (`Set-SubagentDepth -Minimum 3`).
- `harness/scripts/doctor.ps1` (depth report).

## Timeline

- 2026-11-14T19:35:00+03:00: detected during the T-039 smoke test in the running session.
- 2026-11-14T19:37:00+03:00: confirmed in a fresh `opencode run` process (`DEPTH3_OK`).
