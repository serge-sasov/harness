# T-039: Depth-3 enablement and doctor checks

| Field | Value |
|---|---|
| id | T-039 |
| title | subagent_depth 3: install, doctor, uninstall, and config verification |
| workflow | feature |
| stage | implementation |
| role | orchestrator |
| status | done |
| hold | false |
| depends_on | T-037 |
| inputs | `docs/architecture/adr-006-recursive-decomposition.md`, `harness/scripts/install.ps1`, `harness/scripts/doctor.ps1`, `harness/scripts/uninstall.ps1`, `C:/Users/sergey/.config/opencode/opencode.jsonc` |
| artifacts | `harness/scripts/install.ps1`, `harness/scripts/doctor.ps1`, `harness/scripts/uninstall.ps1`, global install |
| e2e | not applicable (harness tooling) |
| ux | not applicable |
| chunks | A: install/uninstall depth and backup/validation; B: doctor depth + per-role self-allow + depth-3 cost warning; C: global install and doctor run with evidence |
| budget | 12/40/65 (code); 8/20/60 (Markdown) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] `install.ps1` sets top-level `subagent_depth` to 3 (not 2) with a config backup and a JSON validation step that restores the backup on failure.
- [ ] `uninstall.ps1` prints the correct removal instruction for `subagent_depth: 3`.
- [ ] `doctor.ps1` reads the effective resolved depth, reports it, warns when it is below 3, and warns that depth-3 calls multiply session count and wall-clock time.
- [ ] `doctor.ps1` verifies that every generator role (`harness-analyst`, `harness-architect`, `harness-coder`) declares `task` self-allow and that `harness-ux-designer` declares the `harness-coder` allow and no self-allow.
- [ ] `doctor.ps1` warns when a role declares a depth-3-unreachable configuration (for example a self-allow on a role that is only ever called at depth 2 by `ux-designer`).
- [ ] The global installation is updated and `opencode debug config` reports `subagent_depth: 3`; the evidence is quoted in the card log.
- [ ] A runtime smoke test is recorded: one same-role chain of three levels (`harness-coder` -> `harness-coder` -> `harness-coder`) replies `DEPTH3_OK` at the deepest level and reports no grandchildren attempt.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | depth tooling | install/doctor/uninstall | n/a | approved | `docs/checkpoints/T-039-CP-1.md` |
| CP-F | final acceptance | all task artifacts + smoke evidence | n/a | approved | `docs/checkpoints/T-039-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-039 (phase A, step 3). Verified before starting: opencode 1.18.33 resolves the top-level `subagent_depth` key (`opencode debug config` reports `"subagent_depth": 2` and no `experimental` block), so the depth change is a value change, not a schema move.
- 2026-11-14: install/doctor/uninstall updated to depth 3; global install refreshed; resolved config reports 3; runtime smoke test passed in a fresh opencode run process (DEPTH3_OK), in-session failure recorded as ISSUE-20261114-193500; CP-1 and CP-F approved (harness-core task: machine checks n/a).
