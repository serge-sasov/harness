# T-041 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-041 |
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
| ai-task-tracker runs the 3.0.0-dev core | `harness/**` synced; `chunk.ps1`, `chunk-validate.py`, updated `stage-done.ps1` present; version `3.0.0-dev` |
| `docs/chunks/T-008.json` with C4fix..C6d, validator green | `VALID T-008 (7 chunks)` |
| Every chunk has a cold-start brief | seven briefs under `docs/chunks/T-008/` |
| Two chunks executed, one with stop/resume | C4fix (stop after) then C5a (cold session, brief only) |
| Metrics recorded per chunk with the baseline | `docs/metrics/T-041-pilot.md` |
| Verdict stated | `cr/in <= 15x` not met with a documented cause; compaction/attempts/wall/resume all met |
| Harness problems recorded in ai-task-tracker | `ISSUE-20261114-203800` (resolved) |

## Outcome

The model is viable. The measurable wins over the pre-ledger baseline are one
attempt instead of three, no compaction, and 2.8-3.5x lower wall time per chunk.
The `cr/in` target was wrong for this agent and is replaced by turns and
cache-read per turn in T-042.

## Residual work

- C5b, C6a..C6d and CP-F of T-008 remain; they are T-008's own work, not T-041.
- The pilot ran at depth 1 because the host process had not restarted; T-045
  (architect replay) will exercise the depth-3 path in a fresh process.

## User decision

- approved: accept T-041.
