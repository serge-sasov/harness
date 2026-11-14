# T-040 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-040 |
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
| Section 0 permits three same-role levels, UX exception at 2 | rewritten bullet, `subagent_depth` must be 3 |
| Section 11.1 replaces the depth-2 rule with the d1/d2/d3 contract | new ten-bullet chunk contract |
| Section 13 keeps only prohibitions that still apply | depth 4, parallel children, cross-role, plan-skipping, machine-field edits |
| Coder's first action is the chunk plan, not code | `## Chunks` item 1 |
| Coder brief, `owns`, d3 condition, handoff instead of compaction | `## Chunks` items 2-4 and the budget rule |
| Architect carries the same contract with its own granularity | `## Chunks` in `harness-architect.md` |
| Workflow and skill describe the chunk plan and d3 | P-00 row, task-graph rules, skill artifacts and budget paragraph |
| Wording is consistent across all six files | shared names verified; doctor green |

## Residual risk

- The analyst, UX, QA, doc-writer, and orchestrator prompts still describe the
  depth-2 model; they are intentionally deferred to T-042 so the pilot measures
  the model before it is generalized. Until then those roles cannot self-delegate
  at depth 3 even though the config allows it.
- The running opencode process still enforces depth 2 until restart
  (ISSUE-20261114-193500); a fresh process is required for the pilot.

## User decision

- approved: accept T-040.
