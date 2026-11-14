# T-043 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-043 |
| checkpoint | CP-F |
| stage | implementation |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | architect |
| checks | n/a (harness core; product stage registry not applicable) |

## Acceptance closure

| Criterion | Evidence |
|---|---|
| Engine gains a chunk check type with five self-test cases | `chunk-ledger` type; valid, missing, overlap, uncovered, budget cases all green |
| `chunk-ownership-no-overlap` mapped to artifact stages | present in feature A-01..D-01 and bugfix B-00..B-04 |
| `chunk-coverage` fails on an unowned existing file and on an own outside the card | self-test case `uncovered artifact` FAIL; codes `E_COVERAGE`, `E_OWN_OUTSIDE_CARD` |
| `chunk-budget` fails on per-file and per-chunk overrun | self-test case `budget overrun` FAIL; both limits implemented |
| A task without a ledger is NOT_APPLICABLE | T-007/R-02 and T-036/R-01 show three N/A rows |
| Checks documented for `verify-stage` and the roles | process 11.1, coder and architect verification sections |
| No new FAIL for tasks that predate the ledger | legacy regression run recorded in CP-1 |

## Residual risk

- `chunk-budget` measures produced file sizes only; it cannot see how much content
  was written and then deleted within a chunk. The role's own budget rule still
  applies.
- The check type shells out to Python; without Python it reports `NOT_APPLICABLE`
  rather than failing, which keeps legacy projects usable.

## User decision

- approved: accept T-043.
