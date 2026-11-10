# Plan (board)

Process rules: `harness/process.md`. Diagram: `docs/activity.puml`.
Updated after every task (process section 5).

## Status legend

| Status | Diagram color | Meaning |
|---|---|---|
| `pending` | gray `#D3D3D3` | not started |
| `in_progress` | yellow `#FFE082` | in progress |
| `done` | green `#90EE90` | completed |
| `failed` | red `#FF9090` | error, fix required |
| `blocked` | orange `#FFB347` | external blocker |

## Board

| ID | Task | Role | Dependencies | Status | Artifacts | Commit |
|---|---|---|---|---|---|---|
| T-001 | Git bootstrap: `git init`, `.gitignore`, README | orchestrator | - | done | `.gitignore`, `README.md` | 2a19b33 |
| T-002 | Unified process rules | orchestrator | T-001 | done | `harness/process.md` | 9d713d8 |
| T-003 | Board + task cards | orchestrator | T-002 | done | `docs/plan.md`, `docs/tasks/` | c621012 |
| T-004 | Activity diagram + SVG render | orchestrator | T-003 | done | `docs/activity.puml`, `docs/activity.svg` | 1ede40d |
| T-005 | Artifact templates | orchestrator | T-002 | done | `harness/templates/` | see T-006 |
| T-006 | Sub-agent `analyst` | analyst | T-005 | done | `harness/agents/analyst.md` | 9ad3ec9 |
| T-007 | Sub-agent `architect` | architect | T-005 | done | `harness/agents/architect.md` | 061f8e5 |
| T-008 | Sub-agent `coder` | coder | T-005 | done | `harness/agents/coder.md` | e4a4686 |
| T-009 | Sub-agent `qa` | qa | T-005 | done | `harness/agents/qa.md` | 95b3949 |
| T-010 | Sub-agent `doc-writer` | doc-writer | T-005 | done | `harness/agents/doc-writer.md` | 876e943 |
| T-011 | Sub-agent `orchestrator` | orchestrator | T-005 | done | `harness/agents/orchestrator.md` | e021349 |
| T-012 | opencode commands | orchestrator | T-006..T-011 | done | `harness/commands/harness-*.md` | cbf393f |
| T-013 | Full-cycle smoke test | qa | T-012 | done | `docs/analysis/`, `docs/architecture/`, `docs/qa/` | fb145b6 |

## Board rules

1. Only the orchestrator changes status (or the role performing the task, on acceptance).
2. `done` only after all `acceptance` items in the card are met.
3. Record the commit hash after the task commit.
4. On `failed`, dependent tasks stay `pending`; record the cause in the card.
5. At most one task is `in_progress`; parallel task execution is forbidden.
