# T-XXX: Short feature task title

| Field | Value |
|---|---|
| id | T-XXX |
| title | Full task title |
| workflow | feature |
| stage | P-00 / A-01 / A-02 / U-01 / U-02 / R-01 / R-02 / I-01 / I-02 / Q-01 / Q-02 / D-01 / F-01 |
| role | orchestrator / analyst / ux-designer / architect / coder / qa / doc-writer |
| status | pending |
| hold | false (true forces human review at every checkpoint) |
| depends_on | T-YYY, T-ZZZ |
| inputs | comma-separated input artifact paths |
| artifacts | comma-separated output artifact paths |
| e2e | required / not applicable (reason) |
| ux | required / not applicable (reason) |
| chunks | planned chunks and ownership (e.g., A-02a: UC-001..003; A-02b: UC-004..008) |
| budget | max_write_kb / max_session_kb / context_stop_pct (defaults: 8/20/60, YAML 6/15/60, code 12/40/65) |
| base_commit | commit hash the first checkpoint diff is measured from |
| usage | measured token usage (filled by stage-done; e.g. in=0 out=0 cr=0 ratio=0x min=0) |
| issues | ISSUE-... (links to docs/issues/ if problems occurred) |
| commit | latest commit hash (snapshot or closure) |

For R-01/R-02, `inputs` must list the current requirements, e2e use cases (when
in scope), UX specs, and the architecture description; trace checks read
`card.inputs`.

## Acceptance

- [ ] Criterion 1 (verifiable).
- [ ] Criterion 2.
- [ ] Criterion 3.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | stage-specific | `docs/...` | - | pending | `docs/checkpoints/T-XXX-CP-1.md` |
| CP-F | final acceptance | all task artifacts | - | pending | `docs/checkpoints/T-XXX-CP-F.md` |

Statuses: `pending`, `awaiting_review`, `approved`, `changes_requested`.
`Checks` is a machine summary `nP/nF/nM` written by `stage-done.ps1`.

## Blockers

- (filled on status=failed|blocked: cause, output, what is needed to unblock)

## Log

- YYYY-MM-DD: what was done, files, commands, results; checkpoint commits and user decisions.
