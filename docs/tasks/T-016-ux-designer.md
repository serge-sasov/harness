# T-016: UX-Designer role and artifacts

| Field | Value |
|---|---|
| id | T-016 |
| title | Add ux-designer role with flows, wireframes, and HTML prototype |
| role | ux-designer |
| status | done |
| depends_on | T-014 |
| inputs | `docs/architecture/contracts-e2e-ux-checkpoints.md`, requirements |
| artifacts | `harness/agents/harness-ux-designer.md`, `harness/templates/ux-spec.md`, `docs/ux/` |
| e2e | linked (screen IDs traceable to `UC-E2E`) |
| ux | required |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Agent prompt defines responsibilities, write area, checkpoints, and prohibitions.
- [x] Artifacts: `user-flows`, `screens`, `wireframes` (`.puml`/`.svg`), `ui-spec`, `prototype/<slug>/index.html`.
- [x] Wireframes must pass `check_syntax` and render before handoff.
- [x] Prototype is static, offline, uses relative links, and contains no secrets.
- [x] Lead and commands can call `harness-ux-designer`; install/doctor include it.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | UX flows + wireframes | `docs/ux/` | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | all artifacts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: created the role, template, and integration points for version 2.1.0.
