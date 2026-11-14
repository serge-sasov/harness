# T-039 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-039 |
| checkpoint | CP-F |
| stage | implementation |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | orchestrator |
| checks | n/a (harness core; product stage registry not applicable) |

## Acceptance closure

| Criterion | Evidence |
|---|---|
| `install.ps1` sets top-level depth 3 with backup and validation | `Set-SubagentDepth -Minimum 3`, `.before-depth` backup, `ConvertFrom-Json` validation with restore on failure |
| `uninstall.ps1` removal instruction | shows `"subagent_depth": 3` |
| `doctor.ps1` reports the depth, warns below 3, warns about cost | `[ok] ... d1 -> d2 -> d3 same-role chains enabled`; `[warn]` at 2; `[warn]` above 3; `[info]` cost note |
| `doctor.ps1` verifies generator self-allow | analyst, architect, coder checked; architect warning expected until T-040 |
| `doctor.ps1` warns about a depth-3-unreachable self allow | `$noSelfRoles` check for harness, orchestrator, ux-designer, qa-vision |
| Global install and resolved config | install run recorded; `opencode debug config` reports 3 |
| Runtime smoke test | `DEPTH3_OK` in a fresh `opencode run` process; the in-session failure and its cause recorded as ISSUE-20261114-193500 |

## Residual risk

- The running session still enforces depth 2 until restart; this is a config
  lifecycle property, not a harness defect. The workaround is documented.
- `harness-architect` has no self task allow yet; the doctor warning is the
  intended signal and disappears after T-040.

## User decision

- approved: accept T-039.
