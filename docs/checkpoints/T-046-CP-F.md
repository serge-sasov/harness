# T-046 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-046 |
| checkpoint | CP-F |
| stage | implementation |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | orchestrator |
| checks | n/a (harness core; product stage registry not applicable) |

## Acceptance closure

| Criterion | Evidence |
|---|---|
| `T-009.json`, `T-010.json`, `T-011.json` exist and validate | all three VALID with 7/3/4 chunks |
| I-02 split | runner skeleton, dataset validator, three UC batches, fixtures/cleanup, full run |
| Q-01 split by UC batch plus execution approach | two matrix batches and one execution chunk |
| Q-02 split | code/artifact review, three evidence files, findings/verdict, vision review |
| Chunks never read the whole `src` | T-011 acceptance states targeted reads; the review chunk owns one report |
| Cards reference their ledgers; board reflects the plan | three new cards with a `chunks` field pointing at the ledger; board rows unchanged and now backed by cards |
| Rollout closure note | `docs/metrics/T-046-rollout.md` with the coverage table and deviations |
| Version 3.0.0 in both repositories | harness `harness/version.json` 3.0.0; ai-task-tracker 3.0.0 (doctor: project version matches global) |

## Rollout summary

| Stage | Ledger |
|---|---|
| R-01 | T-006 (8 chunks) |
| R-02 | T-007 (13 chunks) |
| I-01 | T-008 (7 chunks, 2 done) |
| I-02 | T-009 (7 chunks) |
| Q-01 | T-010 (3 chunks) |
| Q-02 | T-011 (4 chunks) |

Legacy without a ledger: A-01, A-02, U-01, U-02, P-00; they remain
`NOT_APPLICABLE` for the chunk checks.

## Residual

- Execution of the planned chunks is normal task work, not rollout work.
- `BUG-001` remains open.

## User decision

- approved: accept T-046.
