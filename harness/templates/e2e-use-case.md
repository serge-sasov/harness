# E2E use cases: <scope>

| Field | Value |
|---|---|
| Task | T-XXX |
| Role | analyst |
| Source requirements | `docs/analysis/requirements-<slug>.md` |
| Test data | `docs/analysis/e2e-test-data-<slug>.yaml` |
| Environment | local/staging; base URL from an environment variable |
| Status | draft |

## Coverage summary

| Requirement | Use cases | Covered |
|---|---|---|
| R-001 | UC-E2E-001 | yes |
| R-002 | UC-E2E-002 | yes |
| R-00N | - | out_of_scope (Q-NNN) |

## UC-E2E-001: <title>

| Field | Value |
|---|---|
| ID | UC-E2E-001 |
| Actor | <user/service> |
| Priority | P0 / P1 / P2 |
| Source requirements | R-001, R-002 |
| Preconditions | <state and seed data> |
| Trigger | <action> |
| Test data reference | `e2e-test-data-<slug>.yaml#UC-E2E-001` |
| Main flow | 1. <step> -> <expected>; 2. <step> -> <expected> |
| Alternate flows | A1: <condition> -> <result> |
| Error flows | E1: <invalid data> -> <error and state> |
| Postconditions | <state after success> |
| Expected result | <observable outcome and evidence> |
| Cleanup | <how test data is removed> |
| Traceability | <requirement -> use case -> test id> |

## Out of scope and open questions

| ID | Item | Reason / question |
|---|---|---|
| Q-NNN | <requirement or scenario> | <why excluded or what must be clarified> |

## Validation rules

- Every functional requirement is covered by a use case or has an explicit `out_of_scope` entry.
- Every use case has test data, expected results, and cleanup.
- Use-case IDs are stable and are referenced by QA and coder artifacts.
