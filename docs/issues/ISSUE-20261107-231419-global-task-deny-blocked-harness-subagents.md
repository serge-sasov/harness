# ISSUE-20261107-231419: Global task deny blocked harness subagents

| Field | Value |
|---|---|
| id | ISSUE-20261107-231419 |
| status | resolved |
| severity | blocker |
| type | permission |
| detected_at | 2026-11-07T23:14:19.1723574+03:00 |
| source | global harness |
| role | build |
| location | C:/Users/sergey/.config/opencode/opencode.jsonc: permission.task |
| environment | OS: Microsoft Windows NT 10.0.26300.0; cwd: C:\study\ai\research\analytic |

## Symptoms

build could not call harness-analyst or harness-orchestrator; task permission denied

## Reproduction

1. Open a harness project in the primary agent `build`.
2. Call `task` with `subagent_type: harness-analyst` (or `harness-orchestrator`).
3. Get `task` permission denied.

## Expected / actual behavior

- Expected: `build` can explicitly call a harness role for T-001.
- Actual: global `permission.task` deny blocked all harness roles.

## Cause

install.ps1 added a global permission.task deny for harness roles; agent-specific allow existed only in harness lead

## Solution / workaround

migrate permission.task to allow for harness-* roles; install/doctor updated

## Verification

opencode debug agent build shows allow for all harness roles; doctor passes

## Prevention / follow-up

any primary may explicitly call harness roles; keep marker and explicit /harness-* activation; roles keep task deny

Harness 2.2.1: `install.ps1` now adds missing harness allow entries to an
existing `permission.task` block (not only deny -> allow), validates the JSON,
and restores the backup on failure.

## Links

commit 6d547b0; docs/guides/harness-global.md

## Timeline

- 2026-11-07T23:14:19.1723574+03:00: detected
- 2026-11-07T23:15:00+03:00: cause - global deny in permission.task
- 2026-11-07T23:25:00+03:00: deny replaced with allow; install/doctor updated
- 2026-11-07T23:26:00+03:00: verified via `opencode debug agent build`
