# Общий план (board)

Источник правил процесса: `harness/process.md`. Диаграмма: `docs/activity.puml`.
Обновляется после каждой задачи (регламент, п. 5).

## Легенда статусов

| Статус | Цвет в диаграмме | Значение |
|---|---|---|
| `pending` | серый `#D3D3D3` | не начата |
| `in_progress` | жёлтый `#FFE082` | в работе |
| `done` | зелёный `#90EE90` | выполнена |
| `failed` | красный `#FF9090` | ошибка, требуется исправление |
| `blocked` | оранжевый `#FFB347` | внешняя блокировка |

## Board

| ID | Задача | Роль | Зависимости | Статус | Артефакты | Коммит |
|---|---|---|---|---|---|---|
| T-001 | Git bootstrap: `git init`, `.gitignore`, README | orchestrator | — | done | `.gitignore`, `README.md` | 2a19b33 |
| T-002 | Единый регламент процесса | orchestrator | T-001 | done | `harness/process.md` | 9d713d8 |
| T-003 | Board + карточки задач | orchestrator | T-002 | done | `docs/plan.md`, `docs/tasks/` | c621012 |
| T-004 | Диаграмма активности + рендер SVG | orchestrator | T-003 | done | `docs/activity.puml`, `docs/activity.svg` | 1ede40d |
| T-005 | Шаблоны артефактов | orchestrator | T-002 | done | `harness/templates/` | см. T-006 |
| T-006 | Sub-agent `analyst` | analyst | T-005 | done | `harness/agents/analyst.md` | 9ad3ec9 |
| T-007 | Sub-agent `architect` | architect | T-005 | done | `harness/agents/architect.md` | 061f8e5 |
| T-008 | Sub-agent `coder` | coder | T-005 | done | `harness/agents/coder.md` | e4a4686 |
| T-009 | Sub-agent `qa` | qa | T-005 | done | `harness/agents/qa.md` | см. T-010 |
| T-010 | Sub-agent `doc-writer` | doc-writer | T-005 | pending | `harness/agents/doc-writer.md` | — |
| T-011 | Sub-agent `orchestrator` | orchestrator | T-005 | pending | `harness/agents/orchestrator.md` | — |
| T-012 | Команды opencode | orchestrator | T-006..T-011 | pending | `harness/commands/` | — |
| T-013 | Smoke-test полного цикла | qa | T-012 | pending | `docs/qa/`, пилотные артефакты | — |

## Правила ведения board

1. Статус меняет только orchestrator (или роль, выполняющая задачу, — по факту приёмки).
2. Переход в `done` — только после выполнения всех пунктов `acceptance` в карточке.
3. Хэш коммита записывается после коммита задачи.
4. При `failed` — зависимые задачи остаются `pending`, причина фиксируется в карточке.
