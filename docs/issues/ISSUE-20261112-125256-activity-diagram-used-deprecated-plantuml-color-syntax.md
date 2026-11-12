# ISSUE-20261112-125256: Activity diagram used deprecated PlantUML color syntax

| Field | Value |
|---|---|
| id | ISSUE-20261112-125256 |
| status | resolved |
| severity | minor |
| type | process |
| detected_at | 2026-11-12T12:52:56.2108256+03:00 |
| source | T-004/T-013; ai-task-tracker T-001 |
| role | harness-orchestrator |
| location | C:\study\ai\research\ai-task-tracker\docs\activity.puml:10 |
| environment | OS: Microsoft Windows NT 10.0.26300.0; cwd: C:\study\ai\research\harness |

## Symptoms

PlantUML 1.2026.6 rendered a yellow deprecation banner at the top of
`docs/activity.svg` in `ai-task-tracker`:
`This syntax is deprecated, you must add <<#90EE90>> at the end of the line, after the ';'`.
The source used `#90EE90:...;` inside partitions. `check_syntax` returned
`valid=true` and MCP `render_file` returned `success=true`, so the warning was
not reported by the tooling.

## Reproduction

1. Create an activity diagram with `#90EE90:Action;`.
2. Render it to SVG with MCP `plantuml-render`.
3. Open the SVG: a yellow banner with the deprecation text is embedded; stderr is empty.

## Expected / actual behavior

- Expected: colored activity nodes with no warning banner.
- Actual: green nodes plus a deprecation banner; `check_syntax` and MCP success do not catch it.

## Cause

The `diagrams` skill had no rule for activity node colors, and
`harness/process.md` listed only color values without the PlantUML syntax.
The orchestrator therefore used the old prefix form. The lesson from harness
T-004/T-013 (switch to `:activity; <<#COLOR>>`) was recorded only in the task
card log and was not propagated to the skill or process.

## Solution / workaround

Replaced `#90EE90:...;` with `:...; <<#90EE90>>` in
`ai-task-tracker/docs/activity.puml` and re-rendered the SVG. Updated:

- `~/.config/opencode/skills/diagrams/SKILL.md`: canonical suffix syntax,
  pre-render lint regex, post-render SVG banner check;
- `~/.config/opencode/skills/plantuml-render/SKILL.md`: note that `check_syntax`
  and `success=true` do not report deprecation banners;
- harness `process.md` section 9.5, `init.ps1` activity template,
  `harness-orchestrator` step 7, `/harness-board-update`, harness `SKILL.md`;
- `ai-task-tracker` local `harness/process.md` section 9.5.

Global harness files were reinstalled from the repository source.

## Verification

- `check_syntax` on the updated `activity.puml`: `valid=true`, no errors.
- MCP `render_file`: `success=true`, 8958 bytes.
- Grep of the new SVG for `deprecated`: no matches; `fill="#90EE90"` present.
- Grep of `ai-task-tracker/**/*.puml` for `^\s*#[0-9A-Za-z]+\s*:`: no matches.

## Prevention / follow-up

- `diagrams` skill now requires `:text; <<#RRGGBB>>` and an SVG banner check.
- `plantuml-render` skill warns that `check_syntax` does not catch deprecation.
- Harness process/template/agent/command contain the correct syntax, so new
  projects and board updates generate the new form.
- Existing project copies of `process.md` need the same patch (`ai-task-tracker`
  is done).

## Links

- `C:\study\ai\research\ai-task-tracker\docs\activity.puml`
- `C:\study\ai\research\ai-task-tracker\docs\activity.svg`
- `C:\study\ai\research\harness\docs\tasks\T-004-activity-diagram.md`
- `C:\Users\sergey\.config\opencode\skills\diagrams\SKILL.md`
- `C:\Users\sergey\.config\opencode\skills\plantuml-render\SKILL.md`
- `C:\study\ai\research\harness\harness\process.md` section 9.5

## Timeline

- 2026-11-12T12:52:56+03:00: detected
- 2026-11-12T12:52:56+03:00: fixed in skills, harness process, and ai-task-tracker; verified
