---
description: "Синхронизация board harness (только для harness-проекта)"
agent: harness
---

Обнови артефакты планирования по регламенту `harness/process.md` п. 5.

Сначала проверь наличие `harness/process.md` и `docs/plan.md`. Если их нет —
остановись и предложи выполнить `/harness-init`.

Вход: `$ARGUMENTS` — ID задачи (например, `T-007`) или `all` для полной сверки.

1. Передай `harness-orchestrator` задание:
   - прочитать `docs/plan.md`, карточки `docs/tasks/T-*.md`, `docs/activity.puml`;
   - привести статусы к фактическому состоянию (истина — карточка);
   - заполнить колонку `Коммит` фактическими хэшами из `git log --oneline`;
   - обновить цвета `docs/activity.puml` и перерендерить `docs/activity.svg`
     через MCP `plantuml-render`;
   - сделать коммит `chore: board update ($ARGUMENTS)`.
2. Не редактируй файлы сам — это работа orchestrator.
3. Отчёт: какие статусы изменены, какие коммиты записаны, путь к SVG.
