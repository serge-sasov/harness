# Локальный harness: архитектура + реализация

Локальный harness для разработки архитектуры решений и ПО с последующей
реализацией. Весь процесс выполняется ролями-под-агентами на базе локальных
моделей Ollama. Harness устанавливается глобально для текущего пользователя,
но активируется в проекте только явно через `/harness-*`.

Подробный гайд: [`docs/guides/harness-global.md`](docs/guides/harness-global.md).

## Состав

- `harness/process.md` — единые требования к производственному процессу (регламент)
- `harness/agents/` — primary-агент `harness` и ролевые sub-agent'ы
  (`harness-orchestrator`, `harness-analyst`, `harness-architect`,
  `harness-coder`, `harness-qa`, `harness-doc-writer`)
- `harness/commands/` — команды opencode: `/harness-run`,
  `/harness-board-update`, `/harness-board-report`, `/harness-init`,
  `/harness-doctor`
- `harness/skills/harness/SKILL.md` — глобальный skill с кратким workflow
- `harness/templates/` — шаблоны артефактов (task-card, adr, plan-row)
- `harness/scripts/` — `install.ps1`, `init.ps1`, `doctor.ps1`, `uninstall.ps1`
- `harness/version.json` — версия установки
- `docs/plan.md` — общий план (board задач: статус, роль, зависимости)
- `docs/tasks/` — карточки задач (по одной MD-файлу на задачу)
- `docs/activity.puml` / `activity.svg` — диаграмма активности
- `requirements/` — исходные требования

## Модели ролей

| Роль | Агент | Модель (Ollama) |
|---|---|---|
| harness lead | `harness` | qwen3.8:27b-64k (thinking: xhigh) |
| orchestrator | `harness-orchestrator` | qwen3.8:27b-64k (thinking: xhigh) |
| analyst | `harness-analyst` | qwen3.8:27b-64k (thinking: medium) |
| architect | `harness-architect` | qwen3.8:27b-64k (thinking: xhigh) |
| coder | `harness-coder` | tiel-coder:35b-a3b-mtp-128k-text |
| qa | `harness-qa` | tiel-coder:35b-a3b-mtp-128k-vision |
| doc-writer | `harness-doc-writer` | qwen3.8:27b-64k (thinking: low) |

## Глобальная установка (один раз)

Из корня репозитория:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1
```

Скрипт:

1. копирует агентов, команды, skill, шаблоны и скрипты в
   `~/.config/opencode/`;
2. делает backup изменяемых файлов в `~/.config/opencode/backups/`;
3. добавляет или обновляет в `opencode.jsonc` разрешение
   `permission.task` для `harness-*` ролей.

После установки перезапустите opencode. Проверка:

```text
/harness-doctor
```

## Активация в проекте

Harness не включается автоматически: `default_agent` остаётся обычным.
В проекте выполните:

1. `/harness-init` — создаёт `harness/process.md`, `harness/version.json`,
   `harness/templates/`, `docs/plan.md`, `docs/activity.puml` и каркас
   каталогов.
2. Заполните `docs/plan.md`, создайте карточку по
   `harness/templates/task-card.md`.
3. `/harness-run T-XXX` — выполнение задачи.
4. `/harness-board-update all` — синхронизация board и activity.
5. `/harness-board-report` — сводка без изменений.

Если `harness/process.md` или `docs/plan.md` отсутствуют, `harness`-агент
останавливается и предлагает `/harness-init`.

## Жизненный цикл задачи

1. Harness lead проверяет marker проекта и `depends_on` (все — `done`).
2. `harness-orchestrator` переводит задачу в `in_progress` и обновляет board.
3. Роль выполняет задачу строго по `acceptance` из карточки.
4. `harness-orchestrator` принимает результат.
5. При успехе — `done`, обновление board/карточки/activity/SVG и коммит;
   при провале — `failed`, до 3 попыток, затем `blocked` и эскалация.

## Версии

- Глобальная версия хранится в `~/.config/opencode/harness/version.json`.
- Проект фиксирует версию в `harness/version.json` при `/harness-init`.
- `/harness-doctor` предупреждает о расхождении версий.
- Глобальное обновление действует на все проекты. Для «заморозки» версии
  в отдельном проекте можно позже включить vendor-копию агентов и команд
  в `.opencode/`.

## Ограничения

- Установка только для текущего пользователя (`~/.config/opencode`).
- Harness не используется в обычных задачах: активация только через
  `/harness-run` и сервисные команды.
- `git push`, `git tag`, правка истории и prod-деплой запрещены.
- Модели и MCP (`plantuml-render`, `local-rag`) должны быть доступны локально.
