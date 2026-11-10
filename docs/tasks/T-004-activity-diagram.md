# T-004: Activity diagram

| Field | Value |
|---|---|
| id | T-004 |
| title | PlantUML activity diagram of tasks with dependencies and status colors |
| role | orchestrator |
| status | done |
| depends_on | T-003 |
| artifacts | `docs/activity.puml`, `docs/activity.svg` |
| commit | 1ede40d |

## Acceptance

- [x] `docs/activity.puml` is valid PlantUML (`check_syntax` with no errors).
- [x] The diagram shows all tasks T-001..T-013, sequence, and dependencies (fork/branches for independent tasks).
- [x] Colors: done `#90EE90`, pending `#D3D3D3`, in_progress `#FFE082`, failed `#FF9090`, blocked `#FFB347`.
- [x] `docs/activity.svg` rendered via MCP `plantuml-render`.

## Log

- 2026-11-07: created `docs/activity.puml` (all 13 tasks, fork branches T-003/T-004 and T-005->T-006..T-011, color legend); `check_syntax` valid; rendered `docs/activity.svg` (19740 bytes).
- 2026-11-07 (fix, T-013): the `#COLOR:activity;` syntax is deprecated in PlantUML 1.2026.6 (a deprecation banner appeared in the SVG); switched to `:activity; <<#COLOR>>`; re-rendered without warnings, colors applied.
