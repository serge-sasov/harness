# T-045 pilot: architect stages under the UoW model

Measured on 2026-11-14 in `C:/study/ai/research/ai-task-tracker`, harness
`3.0.0-dev` / source `3.0.0`.

## Retrospective chunk plans

The architect stages were already accepted, so the plans were reconstructed from
the delivered artifacts and each chunk was recorded as `done` with its sha256:

| Ledger | Stage | Chunks | Granularity |
|---|---|---|---|
| `docs/chunks/T-006.json` | R-01 | 8 | one ADR, one contracts file, one architecture description, one OpenAPI spec per `API-NNN`, plus the replay child |
| `docs/chunks/T-007.json` | R-02 | 13 | component, data model, class, one sequence diagram per `SCN-NNN` (8), one render/link verification chunk with no `owns`, plus the replay child |

Both ledgers validate (`VALID T-006 (8 chunks)`, `VALID T-007 (13 chunks)`): no
`owns` overlap, produced files inside `owns`, role write area, and full coverage
of every existing file under the card artifacts.

Budget note: the retrospective ledgers use the observed artifact sizes
(`max_write_kb` 30 for T-006 and 90 for T-007) because ADR-005 contracts are
24.6 KB and rendered class SVGs reach 80 KB. Under the 3.0.0 defaults these
artifacts would have been split, which is exactly what the model changes; the
plan itself is still the granularity the model prescribes.

## Replays

Two chunks were regenerated from the accepted inputs in cold sessions and
compared with the accepted artifacts:

| Chunk | Artifact | Produced | Wall | Input | Output | Cache read | cr/in | Verdict |
|---|---|---|---|---|---|---|---|---|
| T-006.R1 | API-004 OpenAPI spec | 2.3 KB | 27 min | 29858 | 26019 | 350413 | 11.7x | differs (accepted spec is wrong) |
| T-007.R2 | SCN-001 sequence + SVG | 1.8 KB + 24.8 KB | 44 min | 100525 | 38098 | 1080010 | 10.7x | identical |

Both are within the replacement criteria (turns <= 40, cache read per turn
<= 150K, one attempt, no compaction) and within the 15x ratio target.

## Baseline (pre-ledger)

| Unit | Wall | Input | Cache read | Notes |
|---|---|---|---|---|
| R-01 chunk b | 68.7 min | 202573 | 1467126 | one 22.9 KB contract over the 8 KB write limit (`ISSUE-20261113-115617`) |
| R-01 in 2.6.0 | 123.5 min | 402036 | 1641389 | whole stage in one session |
| R-02 | 129.2 min | 471089 | 2395332 | whole stage in one session |
| T-006 task total | 211 min | 452356 | 4372564 | 9.7x, five checkpoints of work |
| T-007 task total | 182 min | 570819 | 3311589 | 5.8x, whole diagram set |

Per artifact, the replays are 2.5-4.8x faster than the stage-level baseline and
stay inside the budget. The task-level `cr/in` of the baseline is lower only
because it aggregates a much larger input; the per-chunk figures are the
comparable numbers.

## Finding: accepted API-004 spec contradicts the contracts

The R1 replay regenerated `GET /api/health` from `contracts` section 4.1 and
section 5 and found that the accepted
`docs/architecture/openapi-api-004-ai-task-tracker.yaml` does not match them:

1. the accepted response uses flat `backend` / `database` / `ollama` fields
   instead of `checks.*` plus `source_status`, `ollama_status`, `last_ingest_at`;
2. `status` is an enum `[ok, degraded]` instead of the contract's `ok` string;
3. `required` lists the wrong fields;
4. the contract's 503 `SERVICE_UNAVAILABLE` response is missing;
5. the shared `Error` envelope schema is missing.

Recorded as a product bug in `docs/bugs/BUG-001-api-004-spec-diverges.md`
(ai-task-tracker). The accepted file was not modified.

## Verdict

- Chunk granularity for the architect is correct: 8 chunks at R-01 and 13 at R-02
  cover the delivered artifacts with no overlap and no omission.
- Both replays are cheap, correct, and resumable; one of them caught a real
  contract defect that the stage-level process missed.
- No adjustment to the ADR-006 per-role granularity is required.
