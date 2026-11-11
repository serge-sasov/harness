# Contracts: E2E data, UX artifacts, and checkpoints

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-11-11 |
| Task | T-014 |
| Related ADRs | ADR-002 |

## 1. E2E use-case contract

### 1.1 Markdown use cases

Path: `docs/analysis/e2e-use-cases-<slug>.md` (template
`harness/templates/e2e-use-case.md`).

Required per use case:

| Field | Rule |
|---|---|
| `ID` | `UC-E2E-NNN`, stable, never reused |
| `Actor` | user or external system |
| `Priority` | `P0`, `P1`, `P2` |
| `Source requirements` | at least one requirement ID |
| `Preconditions` | state and seed data |
| `Main flow` | numbered action -> expected result |
| `Alternate/Error flows` | explicit conditions and outcomes |
| `Postconditions` | observable state after success |
| `Expected result` | evidence the test must produce |
| `Cleanup` | how test data is removed |
| `Traceability` | requirement -> use case -> test ID |

Coverage rule: every functional requirement is covered by a use case or listed
as `out_of_scope` with a reason or open question.

### 1.2 YAML test data

Path: `docs/analysis/e2e-test-data-<slug>.yaml` (template
`harness/templates/e2e-test-data.yaml`).

Top-level schema:

| Key | Type | Rule |
|---|---|---|
| `schema` | string | exactly `harness-e2e/1` |
| `scope` | string | matches the requirements scope |
| `environment.base_url` | string | environment placeholder only, for example `${E2E_BASE_URL}` |
| `environment.timeout_seconds` | integer | > 0 |
| `environment.seed_profile` | string | deterministic seed profile |
| `use_cases` | list | non-empty; IDs unique and matching the Markdown file |

Per use case: `id`, `title`, `requirements[]`, `actor`, `priority`,
`preconditions[]`, `steps[]`, `cleanup[]`, `expected_postcondition`,
`traceability.test_ids[]`.

Per step: `id` (`S1`, `S2`, ...), `action`, optional `data`, `expected`.
`expected.status` is an HTTP status when applicable; `expected.json_paths` is a
list of JSONPath expressions that must exist.

Rules:

- no secrets, tokens, passwords, or real personal data; use environment
  placeholders;
- every `UC-E2E-NNN` in Markdown appears exactly once in YAML and vice versa;
- every step is deterministic and repeatable;
- cleanup runs even after a failed step.

## 2. UX artifact contract

Root: `docs/ux/`.

| Artifact | Path | Required content |
|---|---|---|
| User flows | `user-flows-<slug>.md` | actors, entry points, main/alternate/error paths, screen IDs |
| Screen inventory | `screens-<slug>.md` | screen ID, purpose, states, navigation, data |
| Wireframes | `wireframes-<slug>.puml` + `.svg` | one diagram per key flow or screen set |
| UI specification | `ui-spec-<slug>.md` | layout, components, validation, empty/loading/error states, accessibility |
| Prototype | `prototype/<slug>/index.html` | static, offline, no external CDNs or secrets; links screens and states |
| Screenshots (optional) | `prototype/<slug>/screenshots/` | PNG for QA vision |

Rules:

- screen IDs are stable and referenced by architecture contracts and e2e use
  cases;
- the prototype is a design artifact, not production code;
- no real user data, credentials, or tracking scripts;
- all links are relative.

## 3. Checkpoint contract

Path: `docs/checkpoints/T-XXX-CP-N.md` (template
`harness/templates/checkpoint.md`).

Required fields: `task`, `checkpoint`, `role`, `stage`, `artifacts`, `status`,
`requested_at`, `reviewed_at`, `reviewer`, `decision`, `snapshot_commit`.

Statuses: `awaiting_review`, `approved`, `changes_requested`.

Rules:

- every checkpoint listed in the card has exactly one file;
- `CP-F` is mandatory for every task;
- `decision` is written only by the user or by the orchestrator on the user's
  explicit instruction;
- `snapshot_commit` is the commit that freezes the reviewed artifact state;
- the role reads the checkpoint file and `git diff <snapshot_commit>..HEAD`
  before continuing and preserves user edits;
- a task cannot be `done` without `CP-F = approved`.

Task status transitions:

```text
pending -> in_progress -> awaiting_review -> in_progress -> ... -> done
                              |                    |
                              +-> failed           +-> awaiting_review
                              +-> done (CP-F approved)
```

At most one task may be `in_progress` or `awaiting_review`.

## 4. E2E automation contract

| Artifact | Path | Rule |
|---|---|---|
| Tests | `tests/e2e/` | deterministic, tagged e2e, map to `UC-E2E-NNN` |
| Runner | `scripts/e2e.ps1` or `make e2e` | isolated local/staging only, seed + cleanup, machine-readable result |
| Validator | `scripts/validate-e2e-data.py` | validates schema, IDs, coverage, placeholders |

The runner must fail on invalid/missing data, leave no test data behind, and
never target production. QA runs only these entry points and records evidence in
`docs/qa/e2e-report-<slug>.md`.
