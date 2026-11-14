# T-035 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-035 |
| checkpoint | CP-F |
| stage | final |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | architect |

## Scope

Final acceptance of the 2.7.0 architect stage split: R-01 Solution design and
R-02 Interfaces and data model.

## Artifacts

- `harness/checks/feature.json`: R-01/R-02 split, new `contracts-requirement-trace`.
- `harness/workflows/feature.md`: R-01/R-02 stage rows and default checkpoints.
- `harness/agents/harness-architect.md`: R-01/R-02 workflows, artifacts,
  checkpoints, verification.
- `harness/agents/harness-orchestrator.md`: card-artifacts/chunk note.
- `harness/skills/harness/SKILL.md`: architect role and artifacts.
- `harness/process.md`: architecture scope and default checkpoints.
- `harness/templates/architecture-description.md`, `adr.md`: R-01/R-02 ownership.
- `harness/templates/task-card-feature.md`: stage inputs.
- `docs/architecture/adr-004-architect-stage-split.md`.
- `docs/tasks/T-035-architect-stage-split.md`, `docs/plan.md`.
- `README.md`, `docs/guides/harness-global.md`, `docs/description/README.md`,
  `docs/manual/README.md`, `docs/description/index.html`, `docs/manual/index.html`.
- `harness/version.json`: 2.7.0.

## Verification

- `verify-artifacts.ps1 -SelfTest`: SELF-TEST PASSED (17 checks).
- `feature.json` parses; R-01 has 16 checks, R-02 has 17 checks; universal
  `artifacts-exist` and `artifact-hashes` unchanged.
- R-01/R-02 stage run on T-035: 4 PASS, 7 FAIL, 7 N/A — the FAILs are
  artifact-absence for a core-harness task (no pilot architecture/`.puml`
  files), not wiring errors; checks execute as designed.
- Docs and HTML regenerated via `build_html.py` for description and manual.
- Committed `e3aad34`, pushed to `origin/main`.

## User decision

- approved: user requested commit and push.
