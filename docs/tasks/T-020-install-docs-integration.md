# T-020: Install, version, and documentation integration

| Field | Value |
|---|---|
| id | T-020 |
| title | Ship harness 2.1.0 with UX, e2e, and checkpoint support |
| role | orchestrator |
| status | done |
| depends_on | T-016, T-017 |
| inputs | updated agents/templates/commands/skills/scripts |
| artifacts | `harness/version.json`, `install.ps1`, `init.ps1`, `doctor.ps1`, `README.md`, `docs/guides/harness-global.md` |
| e2e | required (doctor/install checks) |
| ux | required (role installation) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] `version.json` is `2.1.0` and lists `harness-ux-designer`.
- [x] `install.ps1` copies/checks the UX agent and new templates, and allows the UX role.
- [x] `init.ps1` creates `docs/ux/` and `docs/checkpoints/`, copies new templates, and adds `awaiting_review` to legends.
- [x] `doctor.ps1` verifies the UX agent, templates, directories, and allow rules.
- [x] `uninstall.ps1` reminder includes the UX role.
- [x] README and global guide document e2e, UX, checkpoints, and version 2.1.0.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | installation + docs | scripts, README, guide | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | all artifacts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: updated version and installation/docs integration; existing `source` path change included.
