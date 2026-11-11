# T-XXX: Short feature task title

| Field | Value |
|---|---|
| id | T-XXX |
| title | Full task title |
| workflow | feature |
| stage | P-00 / A-01 / A-02 / U-01 / U-02 / R-01 / R-02 / I-01 / I-02 / Q-01 / Q-02 / D-01 / F-01 |
| role | orchestrator / analyst / ux-designer / architect / coder / qa / doc-writer |
| status | pending |
| depends_on | T-YYY, T-ZZZ |
| inputs | comma-separated input artifact paths |
| artifacts | comma-separated output artifact paths |
| e2e | required / not applicable (reason) |
| ux | required / not applicable (reason) |
| issues | ISSUE-... (links to docs/issues/ if problems occurred) |
| commit | commit hash after completion |

## Acceptance

- [ ] Criterion 1 (verifiable).
- [ ] Criterion 2.
- [ ] Criterion 3.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | stage-specific | `docs/...` | pending | `docs/checkpoints/T-XXX-CP-1.md` |
| CP-F | final acceptance | all task artifacts | pending | `docs/checkpoints/T-XXX-CP-F.md` |

Statuses: `pending`, `awaiting_review`, `approved`, `changes_requested`.

## Blockers

- (filled on status=failed|blocked: cause, output, what is needed to unblock)

## Log

- YYYY-MM-DD: what was done, files, commands, results; checkpoint commits and user decisions.
