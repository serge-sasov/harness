# Локальный harness: архитектура + реализация

Локальный harness для разработки архитектуры решений и ПО с последующей реализацией.
Весь процесс выполняется ролями-под-агентами на базе локальных моделей Ollama.

## Состав

- `harness/process.md` — единые требования к производственному процессу (регламент)
- `harness/agents/` — ролевые sub-agent'ы (orchestrator, analyst, architect, coder, qa, doc-writer)
- `harness/commands/` — команды opencode (role-run, board-update, board-report)
- `harness/templates/` — шаблоны артефактов (task-card, adr, plan-row)
- `docs/plan.md` — общий план (board задач: статус, роль, зависимости)
- `docs/tasks/` — карточки задач (по одной MD-файлу на задачу)
- `docs/activity.puml` / `activity.svg` — диаграмма активности (зелёный — done, серый — pending, красный — failed)
- `requirements/` — исходные требования

## Модели ролей

| Роль | Модель (Ollama) |
|---|---|
| orchestrator | qwen3.8:27b-64k (thinking: xhigh) |
| analyst | qwen3.8:27b-64k (thinking: medium) |
| architect | qwen3.8:27b-64k (thinking: xhigh) |
| coder | tiel-coder:35b-a3b-mtp-128k-text |
| qa | tiel-coder:35b-a3b-mtp-128k-vision |
| doc-writer | qwen3.8:27b-64k (thinking: low) |

## Жизненный цикл задачи

1. Проверка `depends_on` (все предшествующие — `done`)
2. Выполнение ролью-под-агентом
3. Приёмка по `acceptance`
4. Обновление: `docs/plan.md` → карточка задачи → `docs/activity.puml` → рендер SVG
5. `git commit`

Подробнее — в `harness/process.md` (обязателен для всех ролей).
