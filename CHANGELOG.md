# Changelog

Version history of the local harness, newest first. Source of truth:
`harness/version.json` in the git history (the repository has no tags).

| Version | Date | Task | Changes |
|---|---|---|---|
| 2.7.0 | 2026-11-14 | T-035 | Architect stage split: R-01 Solution design (ADR, architecture description core, component and per-`SCN` sequence diagrams, `SCN`/`SVC` IDs) and R-02 Interfaces and data model (contracts, `API-NNN` IDs, OpenAPI 3.x specs, data/class models, per-service swimlanes, full traceability); new `contracts-requirement-trace`; ADR-004; checks, workflow, role, templates, process, and docs synced. |
| 2.6.0 | 2026-11-13 | - | Architecture design package: overall architecture description, component/per-scenario sequence/data/class/per-service swimlane diagrams, OpenAPI 3.x validation, coverage and link checks; Russian manual with offline HTML. |
| 2.5.0 | 2026-11-13 | T-031, T-032, T-033, T-034 | Deterministic verification engine and checks registry, P2 checkpoint approval, SHA256 evidence ledger, token usage metrics; install/init/doctor; global install and pilot sync. |
| 2.4.0 | 2026-11-12 | T-028, T-029 | Per-scenario UX HTML pages; derived activity diagram marked informational only; diagrams, wireframes, and description updated. |
| 2.3.0 | 2026-11-12 | T-030 | Generation and context budgets, chunking for A-02 and code work, self-sub-sessions (depth 2), per-chunk attempts, compaction handoff. |
| 2.2.1 | 2026-11-11 | - | Reliability checks and harness issue registry (`harness-issues` skill); 2.2.1 smoke test registered. |
| 2.2.0 | 2026-11-11 | T-023, T-024, T-025, T-026, T-027 | Separate feature and bugfix workflows (ADR-003), bug registry, `/harness-feature` and `/harness-bug`, workflow templates, 9-column board; init/install/doctor. |
| 2.0.0 | 2026-11-10 | - | English release of the harness core: agents, commands, templates, and documentation translated. |
| 1.0.4 | 2026-11-10 | - | QA report incremental write and output budget. |
| 1.0.3 | 2026-11-09 | - | Coder output and permissions hardening. |
| 1.0.2 | 2026-11-08 | - | `harness-qa` switched to qwen3.8:27b-64k (64K context, vision). |
| 1.0.1 | 2026-11-08 | - | Parallel harness task execution forbidden. |
| 1.0.0 | 2026-11-07 | - | Initial harness: global install and explicit `/harness-*` activation. |

Note: 2.1.0 (UX, e2e, and checkpoint support; T-014..T-021) is documented in
ADR-002 and T-020, but it was never released as a separate commit:
`version.json` went from 2.0.0 straight to 2.2.0.
