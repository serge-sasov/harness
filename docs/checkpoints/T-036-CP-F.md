# T-036 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-036 |
| checkpoint | CP-F |
| stage | final acceptance |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | architect |
| checks | n/a (harness core; product stage registry not applicable) |

## Scope

Final acceptance of release 2.8.0: all card acceptance items, the changelog
entry, the documentation rebuild, and the closed working tree.

## Artifacts

- `harness/agents/harness-architect.md`, `harness/process.md`,
  `harness/workflows/feature.md`, `harness/skills/harness/SKILL.md`,
  `harness/templates/architecture-description.md`,
  `harness/checks/feature.json`, `harness/scripts/verify-artifacts.ps1`.
- `docs/architecture/adr-005-responsibility-zones.md`.
- `harness/version.json` (`2.8.0`), `CHANGELOG.md`, `README.md`,
  `docs/description/`, `docs/manual/`.
- Global installation at `~/.config/opencode/` and `/harness-doctor` run.

## Verification

- Every acceptance item in `docs/tasks/T-036-responsibility-zones.md` is
  checked.
- The rule is stated identically in the role prompt and in `harness/process.md`;
  the waiver wording is identical in the template, the workflow, and the role.
- The check registry, the engine, and the self-test agree on the check type
  name `zones-unique`.
- The changelog records 2.8.0 with the changed files.
- The working tree is clean after the commit and the board row for T-036 is
  `done`.

## User decision

- approved: T-036 is done.
