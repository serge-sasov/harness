# T-029: Bugfix/feature diagrams, activity, and HTML rebuild

| Field | Value |
|---|---|
| id | T-029 |
| title | Reflect both workflows in diagrams, activity, and the solution HTML |
| workflow | feature |
| stage | R-02 / D-01 |
| role | architect |
| status | done |
| depends_on | T-028 |
| inputs | ADR-003, contracts, updated description, workflow files |
| artifacts | `docs/description/diagrams/*`, `docs/description/index.html`, `docs/activity.puml/.svg`, `docs/qa/vision-review-T-029.md` |
| e2e | not applicable (documentation) |
| ux | not applicable (documentation) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Component and class diagrams show workflows and the bug registry.
- [x] Scenario map includes feature and bugfix paths.
- [x] New bugfix sequence diagram uses `BUG-XXX`, failing regression, fix, and QA verification.
- [x] Existing sequence diagrams that mention commands include `/harness-feature` and `/harness-bug`.
- [x] Every changed `.puml` passes `check_syntax` and is rendered to SVG.
- [x] `index.html` embeds all diagrams and opens offline.
- [x] Activity diagram shows T-001..T-029 and T-022 pending.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | diagrams | `.puml` + `.svg` | n/a (direct update) | `docs/qa/vision-review-T-029.md` |
| CP-F | final acceptance | HTML + activity | n/a (direct update) | validated by T-022 |

## Blockers

- (none)

## Log

- 2026-11-11: card created; awaits T-028.
- 2026-11-11: scenario map, component/class, sequences, activity, and HTML updated; PlantUML check and render passed; vision QA returned PASS.
