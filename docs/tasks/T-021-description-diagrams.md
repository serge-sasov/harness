# T-021: Description, diagrams, HTML, and activity rebuild

| Field | Value |
|---|---|
| id | T-021 |
| title | Reconcile solution description and diagrams with version 2.1.0 |
| role | architect |
| status | done |
| depends_on | T-020 |
| inputs | updated process, agents, ADR-002, contracts |
| artifacts | `docs/description/README.md`, `docs/description/diagrams/*`, `docs/description/index.html`, `docs/activity.puml/.svg` |
| e2e | linked (S-05/S-06 diagrams) |
| ux | linked (S-12 diagram) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Component and class diagrams include UX, e2e, and checkpoints.
- [x] Scenario map includes S-12 and S-13.
- [x] Sequence diagrams for task cycle, analyst, coder, and QA show checkpoints/e2e.
- [x] New `seq-12-ux-designer` and `seq-13-checkpoints` sources render to SVG.
- [x] Every changed `.puml` passes `check_syntax`; SVG is regenerated.
- [x] `index.html` rebuild embeds all diagrams and opens offline.
- [x] Activity diagram shows T-001..T-022 with `awaiting_review` legend.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | description + diagrams | README, `.puml`/`.svg` | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | HTML + activity | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: updated diagrams and description; rendered all changed SVGs; rebuilt HTML and activity.
