# T-042 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-042 |
| checkpoint | CP-F |
| stage | implementation |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | architect |
| checks | n/a (harness core; product stage registry not applicable) |

## Acceptance closure

| Criterion | Evidence |
|---|---|
| Each role states its granularity | `## Chunks` in all five prompts; table in `process.md` 11.1 |
| Each role states whether it may delegate | analyst `d2/d3`; ux none (coder `d2` only); qa `d2`; doc-writer `d2`; orchestrator none |
| Orchestrator owns the ledger and never delegates | `## Chunk ledger ownership`; `task: deny` |
| Lead prompt routes a resumed chunk | step 7a uses `chunk.ps1 status` and passes `next` plus the brief |
| Uniform rule set, no duplication | process 11.1 table is the single source; prompts reference the granularity |
| Skill matches the process and prompts | depth matrix paragraph updated |
| Pilot metrics cited where the default changed | ADR-006 `Amendment 1` |

## Residual risk

- Five prompts gained a section; their length grew by roughly 1 KB each. The
  generation budget for prompts is not enforced by a check, only by review.
- QA and doc-writer self-delegation is capped at `d2` by prompt and process text,
  not by a machine check (the config only exposes a global depth).

## User decision

- approved: accept T-042.
