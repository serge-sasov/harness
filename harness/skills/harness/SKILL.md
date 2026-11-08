---
name: Local Harness
description: "Локальный multi-agent harness: роли, board, задачи, приёмка, артефакты. Использовать только по явному запросу пользователя и только в проекте с harness/process.md. Не применять к обычным задачам кодинга."
metadata:
  opencode/autoinvoke: false
---

# Local Harness

## Когда использовать

Только если пользователь явно просит запустить harness или выполнить
`/harness-run`, `/harness-board-update`, `/harness-board-report` в проекте,
где есть `harness/process.md` и `docs/plan.md`.

Не использовать для обычных задач разработки, анализа или документации.

## Проверка проекта

Перед любым действием:

1. Убедись, что существуют `harness/process.md` и `docs/plan.md`.
2. Если их нет — остановись и предложи `/harness-init`.
3. Прочитай `harness/process.md`: это источник правил процесса.
4. Прочитай `docs/plan.md` и карточку задачи `docs/tasks/T-XXX-*.md`.

## Команды

| Команда | Назначение |
|---|---|
| `/harness-init` | создать в проекте `harness/`, `docs/plan.md`, каркас каталогов |
| `/harness-run T-XXX` | выполнить задачу по регламенту, с приёмкой и коммитом |
| `/harness-board-update all / T-XXX` | синхронизировать board, карточки, activity и SVG |
| `/harness-board-report` | read-only сводка по board |
| `/harness-doctor` | проверить глобальную установку и текущий проект |

Все команды запускаются только явно. `default_agent` не переключается на harness.

## Роли

| Агент | Роль |
|---|---|
| `harness` | primary lead: маршрутизация, проверка marker, отчёт |
| `harness-orchestrator` | board, зависимости, приёмка, activity, коммиты |
| `harness-analyst` | требования, RAG, вопросы, глоссарий |
| `harness-architect` | ADR, PlantUML, контракты |
| `harness-coder` | код, тесты, CI/CD, локальный запуск |
| `harness-qa` | ревью, vision, вердикт accept/reject |
| `harness-doc-writer` | README, runbook, гайды, финализация ADR |

Lead не редактирует файлы сам: board и коммиты делает orchestrator.

## Артефакты

- `docs/plan.md` — board, единственный источник истины по составу работ;
- `docs/tasks/T-XXX-*.md` — карточки задач;
- `docs/activity.puml` / `.svg` — статусы задач;
- `docs/analysis/`, `docs/architecture/`, `docs/qa/`, `docs/guides/` — артефакты ролей;
- `docs/issues/` — журнал проблем и решений (skill `harness-issues`);
- `src/`, `tests/`, `scripts/`, `Dockerfile`, `docker-compose*.yml`, `Makefile` — код и CI/CD.

## Статусы и приёмка

`pending → in_progress → done`; `in_progress → failed`;
`failed → in_progress`; `* → blocked` при внешней блокировке.

Задачи выполняются строго последовательно: одновременно не более одной
`in_progress`; параллельный запуск нескольких задач запрещён. `/harness-run`
принимает ровно один ID задачи.

Задача закрывается только по критериям `acceptance` из карточки. При провале —
`failed` с причиной в `Blockers`, до 3 попыток, затем `blocked`.

При любой проблеме, блокировке или найденном workaround используй skill
`harness-issues` и создай запись в `docs/issues/`; orchestrator обновит индекс
и включит issue в коммит задачи.

## Глобальная установка и версии

- Агенты и команды установлены в `~/.config/opencode/`.
- Проект получает `harness/process.md`, шаблоны и `harness/version.json`
  через `/harness-init`.
- `harness/version.json` фиксирует версию, с которой инициализирован проект;
  `doctor` предупреждает о расхождении с глобальной версией.
- Глобальное обновление меняет harness во всех проектах. Для «заморозки»
  версии в конкретном проекте используйте отдельную vendor-копию агентов
  и команд в `.opencode/` (если такая практика включена).

## Безопасность

- Не добавляй harness-правила в глобальный `AGENTS.md`.
- Не работай вне текущего проекта (`external_directory` запрещён).
- Не делай `git push`, `git tag`, правку истории.
- Секреты — только через переменные окружения.
