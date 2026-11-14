# T-037 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-037 |
| checkpoint | CP-F |
| stage | R-01 |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | architect |
| checks | n/a (harness core; product stage registry not applicable) |

## Acceptance closure

| Criterion | Evidence |
|---|---|
| ADR-006 with Context/Decision/Alternatives/Consequences/Contracts | present |
| Unit-of-work model fully specified | decisions 1-5 and 9-12 (fields, states, ownership, brief, return, stop) |
| Depth policy and the d3 condition | decisions 6-7, ceiling 3, split only on budget overflow |
| Ledger schema field by field | decision 2-4 plus `harness/templates/chunk-ledger.md` (T-038) |
| Uniform rules and per-role granularity | decision 13 table covers all eight roles and eleven stages |
| Stop/resume contract | decision 11 |
| Alternatives compared | seven options with pros, cons, and rejection reasons |
| Two diagrams authored and rendered | `decomposition-flow`, `decomposition-artifacts`; syntax PASS, SVG rendered, vision ACCEPT |
| Required changes for T-038..T-040 stated | `Consequences` lists process sections 0/11.1/13, install/doctor, scripts, checks, templates, roles |

## Baseline captured

T-008 lead chain: 16 compaction handoffs. Coder chunk 3: `in=350592`,
`cr=11993356`, 73.6 min. Architect R-02: `in=471089`, `cr=2395332`, 129 min.
UX U-02: `in=1046186`. Contract write of 22.9 KB -> `ISSUE-20261113-115617`.

## User decision

- approved: accept T-037.
