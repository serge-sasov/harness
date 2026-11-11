# T-XXX CP-N: Checkpoint title

| Field | Value |
|---|---|
| task | T-XXX |
| workflow | feature / bugfix |
| bug | BUG-XXX or - |
| checkpoint | CP-N |
| role | analyst / ux-designer / architect / coder / qa / doc-writer / orchestrator |
| stage | feature stage ID (P-00..F-01) or bugfix stage ID (B-00..B-05) |
| artifacts | comma-separated artifact paths |
| status | awaiting_review |
| requested_at | YYYY-MM-DDTHH:MM:SS |
| reviewed_at | - |
| reviewer | user |
| decision | - (approved / changes_requested) |
| snapshot_commit | - |

## Review scope

- What the user should verify.
- Acceptance points for this checkpoint.

## User remarks

- (user fills; may be empty if artifacts were edited directly)

## User edits

- path: summary of the user's change.

## Role response

- (orchestrator records from the role report: how remarks were addressed, conflicts, remaining issues)

## Next action

- continue / return to this checkpoint / accept task
