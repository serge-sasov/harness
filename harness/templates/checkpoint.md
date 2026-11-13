# T-XXX CP-N: Checkpoint title

> Rendered by `harness/scripts/stage-done.ps1` from machine data. The table
> fields `status`, `reviewed_at`, `reviewer`, `snapshot_commit`, `generated_by`,
> `checks_file` are machine-owned; do not hand-edit. A human reviewer fills
> `decision`, `user remarks`, and `user edits`.

| Field | Value |
|---|---|
| task | T-XXX |
| workflow | feature / bugfix |
| bug | BUG-XXX or - |
| checkpoint | CP-N |
| role | analyst / ux-designer / architect / coder / qa / doc-writer / orchestrator |
| stage | feature stage ID (P-00..F-01) or bugfix stage ID (B-00..B-05) |
| artifacts | comma-separated artifact paths |
| status | awaiting_review / approved |
| requested_at | YYYY-MM-DDTHH:MM:SS |
| reviewed_at | - |
| reviewer | user / auto (P2) |
| decision | - (approved / changes_requested) |
| snapshot_commit | - |
| generated_by | stage-done/1 |
| checks_file | docs/checkpoints/T-XXX-CP-N.checks.json |

## Review scope

- What the user should verify.
- Acceptance points for this checkpoint.

## Checks

| ID | Check | Result | Detail |
|---|---|---|---|
| check-id | check-type | PASS / FAIL / MANUAL / NOT_APPLICABLE | machine detail |

Summary: 0 PASS, 0 FAIL, 0 MANUAL, 0 N/A, 0 UNCHECKED.

## Manual review

- check-id: what the reviewer must confirm (only when MANUAL items exist).

## Usage

| Sessions | Input | Output | Reasoning | Cache read | Cache/Input | Minutes | Cost |
|---|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 0x | 0 | 0.00 |

## Diff stat

```
(filled from git diff --stat since base_commit)
```

## User remarks

- (user fills; may be empty if artifacts were edited directly)

## User edits

- path: summary of the user's change.

## Role response

- (orchestrator records from the role report: how remarks were addressed, conflicts, remaining issues)

## Next action

- continue / return to this checkpoint / accept task
