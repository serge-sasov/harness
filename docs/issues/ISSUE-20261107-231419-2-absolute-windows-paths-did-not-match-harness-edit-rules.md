# ISSUE-20261107-231419-2: Absolute Windows paths did not match harness edit rules

| Field | Value |
|---|---|
| id | ISSUE-20261107-231419-2 |
| status | resolved |
| severity | major |
| type | path |
| detected_at | 2026-11-07T23:14:19.4276040+03:00 |
| source | global harness |
| role | build |
| location | C:/study/ai/research/analytic/harness/agents/harness-*.md; opencode permission edit |
| environment | OS: Microsoft Windows NT 10.0.26300.0; cwd: C:\study\ai\research\analytic |

## Symptoms

edit docs/plan.md and .gitignore was blocked; relative docs/** did not match C:/...; .gitignore had no allow

## Reproduction

1. Open a project with an absolute path `C:\study\...\Qwen 3.8 27B Q4_K_M`.
2. A role with write area `docs/**` tries to edit `docs/plan.md`.
3. The relative pattern `docs/**` does not match; a blanket deny applies. There is no allow for `.gitignore`.

## Expected / actual behavior

- Expected: the role edits files in its area by absolute path.
- Actual: edit/write blocked, including `.gitignore`.

## Cause

opencode matches edit/write against absolute path; relative docs/** did not match; .gitignore was outside role zones

## Solution / workaround

added **/docs/**, **/README.md, **/.gitignore and role-specific **/... allows; .gitignore allowed for orchestrator/coder

## Verification

opencode debug agent shows allow; doctor passes; docs/plan.md edit path resolved

## Prevention / follow-up

keep absolute **/... variants in role permissions; use absolute location in issue records

Harness 2.2.1: `/harness-doctor` verifies that edit/read allow paths in the
global harness agents have `**/` counterparts.

## Links

commits e943761, 6d547b0; docs/guides/harness-global.md

## Timeline

- 2026-11-07T23:14:19.4276040+03:00: detected
- 2026-11-07T23:18:00+03:00: cause - absolute path matching
- 2026-11-07T23:20:00+03:00: added `**/...` allow patterns and `.gitignore`
- 2026-11-07T23:26:00+03:00: verified via `opencode debug agent`
