# T-036: Responsibility zones for components, modules, and classes

| Field | Value |
|---|---|
| id | T-036 |
| title | Version 2.8.0: architect responsibility zones (component -> module -> class) with exclusive zones per level |
| workflow | feature |
| stage | R-01 / R-02 |
| role | architect |
| status | done |
| hold | false |
| depends_on | T-035 |
| inputs | `harness/agents/harness-architect.md`, `harness/process.md`, `harness/workflows/feature.md`, `harness/templates/architecture-description.md`, `harness/checks/feature.json`, `harness/scripts/verify-artifacts.ps1` |
| artifacts | `harness/agents/harness-architect.md`, `harness/process.md`, `harness/workflows/feature.md`, `harness/skills/harness/SKILL.md`, `harness/templates/architecture-description.md`, `harness/checks/feature.json`, `harness/scripts/verify-artifacts.ps1`, `docs/architecture/adr-005-responsibility-zones.md`, `docs/description/`, `docs/manual/`, `CHANGELOG.md`, `harness/version.json`, global install |
| e2e | not applicable (harness rule and checks update) |
| ux | not applicable |
| chunks | A: role and process rules; B: template and checks registry; C: verification engine + self-test; D: ADR, card, version, docs; E: global install and doctor |
| budget | 8/20/60 (Markdown); 12/40/65 (code) |
| base_commit | d5fd4e9 docs: add CHANGELOG with version history |
| usage | n/a |
| issues | - |
| commit | pending |

## Acceptance

- [x] Architect role states the rule: hierarchy `component -> module (optional) -> class`, `Owns`/`Does not own` per element, exclusivity per level, resolution of overlaps, `MOD-NNN`/`CLS-NNN` IDs, explicit waivers.
- [x] `harness/process.md` carries the same mandatory rule for all roles.
- [x] `harness/templates/architecture-description.md` has the `## Responsibility zones` section with the Components/Modules/Classes tables and scope lines.
- [x] New check type `zones-unique` in `harness/scripts/verify-artifacts.ps1` with 9 self-test cases (all green).
- [x] Checks registry: `responsibility-zones` (R-01, R-02), `module-ids` (R-01), `class-ids` (R-02), `zones-overlap-review` (manual, R-01, R-02).
- [x] `harness/workflows/feature.md` and `harness/skills/harness/SKILL.md` synced with the new sections, IDs, and check ids.
- [x] ADR-005 accepted; version 2.8.0; CHANGELOG updated.
- [x] `docs/description/` and `docs/manual/` updated and rebuilt to HTML.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | solution design | architect role, process, template, checks registry | n/a | approved | `docs/checkpoints/T-036-CP-1.md` |
| CP-2 | interfaces/data model | engine `zones-unique`, ADR-005, version, docs | n/a | approved | `docs/checkpoints/T-036-CP-2.md` |
| CP-F | final acceptance | all task artifacts | n/a | approved | `docs/checkpoints/T-036-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: architect rule added (hierarchy, zone format, exclusivity per level, overlap resolution, `MOD-NNN`/`CLS-NNN`, waivers); process.md rule; architecture-description template section `## Responsibility zones` with Components/Modules/Classes tables; new check type `zones-unique` (section presence, Owns/Does not own columns, per-level and per-parent zone uniqueness, contradiction detection, parent resolution, Components table cross-check) with 9 self-test cases (PASSED); checks registry R-01/R-02 (`responsibility-zones`, `module-ids`, `class-ids`, `zones-overlap-review` manual); workflow and skill synced; ADR-005 accepted; version 2.8.0; global install and doctor passed.
- 2026-11-14: CP-1, CP-2 and CP-F approved (harness-core task: the product stage registry does not apply, machine checks recorded as `n/a`); checkpoints written to `docs/checkpoints/T-036-CP-1.md`, `docs/checkpoints/T-036-CP-2.md`, `docs/checkpoints/T-036-CP-F.md`; card and board set to `done`.
