# T-044 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-044 |
| checkpoint | CP-F |
| stage | D-01 |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | doc-writer |
| checks | n/a (harness core; product stage registry not applicable) |

## Acceptance closure

| Criterion | Evidence |
|---|---|
| Card templates reference the ledger and the extended budget | `task-card-feature.md`, `task-card-bugfix.md` |
| `chunk-ledger.md` matches the validator | same field set; `baseline` and `notes` documented |
| `plan-row.md` states that chunk progress is not a board column | added rule |
| README and guide describe the model, depth, resume, and pilot | README versions/limitations; guide 4.2a |
| `CHANGELOG.md` has 3.0.0 with the full change list | new top row |
| `harness/version.json` is 3.0.0 | verified |
| description and manual updated, HTML rebuilt | sections added; both builds ran |
| Global install matches 3.0.0 and doctor is clean | `install.ps1` run; `doctor.ps1`: project version matches global; no critical problems |

## Residual risk

- The description and manual gained a section but their scenario and artifact
  maps still describe the 2.x flow in places; a follow-up doc pass should fold
  the chunk ledger into the scenario map and the artifact map diagrams.

## User decision

- approved: accept T-044.
