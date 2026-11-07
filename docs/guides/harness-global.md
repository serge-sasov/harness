# Глобальный harness: установка и использование

Документ описывает, как один раз установить harness для текущего пользователя
и включать его в проектах только по явной команде.

## 1. Что глобально, а что в проекте

| Часть | Расположение | Содержимое |
|---|---|---|
| Инструменты harness | `~/.config/opencode/` | агенты `harness-*`, команды `/harness-*`, skill `harness`, шаблоны, скрипты |
| Состояние проекта | `<проект>/` | `harness/process.md`, `harness/version.json`, `docs/plan.md`, `docs/tasks/`, артефакты, git |

Board, карточки задач и артефакты не могут быть глобальными: это состояние
конкретного проекта. Глобальными являются только определения ролей, команды,
шаблоны и скрипты.

## 2. Глобальная установка

Из корня репозитория с исходниками harness:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1
```

Скрипт:

1. копирует агентов, команды, skill, шаблоны и скрипты в
   `~/.config/opencode/`;
2. делает backup изменяемых файлов в
   `~/.config/opencode/backups/harness-install-<timestamp>/`;
3. добавляет или обновляет в `opencode.jsonc` разрешения:

```jsonc
"permission": {
  "task": {
    "harness-orchestrator": "allow",
    "harness-analyst": "allow",
    "harness-architect": "allow",
    "harness-coder": "allow",
    "harness-qa": "allow",
    "harness-doc-writer": "allow"
  }
}
```

Эти правила разрешают любому primary-агенту явно вызывать harness-роли.
Роли не вызывают друг друга: у них остаётся `task: deny`. Primary-агент
`harness` сохраняет собственные allow-правила.

Если в `opencode.jsonc` есть комментарии, скрипт не правит файл автоматически,
а печатает готовый сниппет для ручного добавления.

После установки **перезапустите opencode**: агенты и конфигурация читаются при
старте. Проверка:

```text
/harness-doctor
```

Установка выполняется только для текущего пользователя. System-wide вариант
(`%ProgramData%\opencode`) не используется.

## 3. Инициализация проекта

В проекте:

```text
/harness-init
```

Создаются:

```text
harness/
  process.md
  version.json
  templates/
    task-card.md
    adr.md
    plan-row.md
docs/
  plan.md
  activity.puml
  tasks/
  analysis/
  architecture/
  qa/
  guides/
```

`/harness-init` не копирует глобальных агентов и команд: используется
глобальная установка. Повторный запуск без `-Force` останавливается; с `-Force`
делает backup в `.harness-backup-<timestamp>/`.

`harness/process.md` и `docs/plan.md` — marker-файлы. Без них `harness`-агент
останавливается, даже если его выбрали вручную.

## 4. Активация только по явной команде

`default_agent` не переключается на harness. Основные команды:

| Команда | Назначение |
|---|---|
| `/harness-init` | инициализация проекта |
| `/harness-run T-XXX` | выполнение задачи, приёмка, board, коммит |
| `/harness-board-update all / T-XXX` | синхронизация board, карточек, activity и SVG |
| `/harness-board-report` | read-only сводка по board |
| `/harness-doctor` | проверка установки и проекта |

Схема запуска:

```text
/harness-run T-XXX
  → primary-агент harness (проверка marker и depends_on)
  → harness-orchestrator (in_progress, board, activity, SVG)
  → harness-analyst | harness-architect | harness-coder |
    harness-qa | harness-doc-writer
  → harness-orchestrator (приёмка, done/failed, коммит)
```

Lead не редактирует файлы сам; board и коммиты выполняет orchestrator.

## 5. Защита от случайного запуска

1. Явные команды `/harness-*`; harness не является агентом по умолчанию.
2. Глобальный `permission.task` разрешает любому primary-агенту явно вызывать
   `harness-*`; роли не вызывают друг друга (`task: deny`).
3. Marker-файлы `harness/process.md` и `docs/plan.md` обязательны.
4. Harness-инструкции не добавляются в глобальный `AGENTS.md`.
5. Skill `harness` имеет явное описание и не предназначен для авто-применения.

Дополнительно можно временно отключить harness в конкретном проекте (V1):

```jsonc
{
  "agent": {
    "harness": { "disable": true }
  }
}
```

## 5.1. Права и абсолютные пути

opencode сопоставляет `edit`/`write` с абсолютным путём (Windows-разделители
нормализуются в `/`). Поэтому относительного шаблона `docs/**` недостаточно:
он соответствует `docs/plan.md`, но не `C:/project/docs/plan.md`.

В ролях harness поэтому продублированы оба варианта:

```yaml
edit:
  "*": "deny"
  "docs/**": "allow"
  "**/docs/**": "allow"
  ".gitignore": "allow"
  "**/.gitignore": "allow"
```

`**/docs/**` и `**/.gitignore` матчатся на абсолютный путь при любом
расположении проекта и при workspace root `/`. Не удаляйте абсолютные
варианты: blanket deny `"*": "deny"` остаётся, а конкретные allow-правила
должны совпасть с полным путём.

`.gitignore` разрешён ролям `harness-orchestrator` и `harness-coder`.
Остальные роли его не правят — это осознанное ограничение.

Если opencode показывает workspace root `/`, запускайте его из каталога
проекта и проверьте `git rev-parse --show-toplevel`: корень должен совпадать
с проектом. Абсолютные варианты паттернов защищают от этой проблемы, но
корректный workspace root всё равно предпочтителен.

## 6. Версии и pin-версии

- Глобальная версия: `~/.config/opencode/harness/version.json`.
- Версия проекта: `harness/version.json`, создаётся при `/harness-init`.
- `/harness-doctor` предупреждает, если версии различаются.

**Version record** (используется сейчас) фиксирует версию, но проект продолжает
использовать глобальные файлы. Это удобно при одном пользователе и частых
обновлениях.

**Vendor pin** — если проект нужно «заморозить»:

1. скопировать `harness-*` агентов и команды в `.opencode/agents/` и
   `.opencode/commands/` проекта;
2. зафиксировать версию в `harness/version.json`;
3. обновлять копии только вручную.

Project-файлы имеют приоритет над глобальными, поэтому vendor-копии перекрывают
глобальную установку. Полноценный vendor-режим в `harness-init` пока не включён;
его можно добавить отдельным флагом, если появится потребность.

## 7. Обновление и удаление

Обновление глобальной установки:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1
```

Скрипт делает backup и перезаписывает глобальные файлы. После обновления
перезапустите opencode.

Удаление:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/uninstall.ps1
```

Скрипт удаляет только глобальные `harness-*` файлы, skill и каталог
`~/.config/opencode/harness`; проектные `harness/` и `docs/` не затрагиваются.
Правила `permission.task` в `opencode.jsonc` нужно удалить вручную (скрипт
печатает напоминание).

## 8. Диагностика

| Симптом | Причина | Действие |
|---|---|---|
| команда `/harness-*` не видна | opencode не перезапущен после установки | перезапустить opencode |
| harness-агент не виден | файлы не попали в `~/.config/opencode/agents/` | проверить `/harness-doctor`, повторить install |
| `build` может вызвать роли | `permission.task` содержит allow | штатное поведение; иначе запустить install и перезапустить opencode |
| `build` не может вызвать роли | остался старый `deny`-блок | выполнить install.ps1, перезапустить opencode; проверить `opencode debug agent build` |
| harness не вызывает роли | нет allow-правил у агента `harness` | проверить `opencode debug agent harness` |
| проект не запускается | нет `harness/process.md` или `docs/plan.md` | выполнить `/harness-init` |
| edit `docs/plan.md` заблокирован, хотя есть `docs/**` allow | путь абсолютный, относительный шаблон не совпал | обновить harness, перезапустить opencode; в ролях должны быть `**/docs/**` |
| write `.gitignore` заблокирован | `.gitignore` не входит в зону роли | использовать `harness-orchestrator` или `harness-coder` |
| workspace root `/` | opencode запущен не из корня проекта / неверный cwd | запустить из проекта, проверить `git rev-parse --show-toplevel` |
| старые агенты обходят gating | остались `.opencode/agents/analyst.md` и т.п. | удалить старые копии или переименовать в `harness-*` |
| конфиг не пропатчился | в `opencode.jsonc` есть комментарии | добавить `permission.task` с allow вручную |
| версия отличается | проект инициализирован старой версией | обновить проект осознанно; см. pin |

## 9. Переход на opencode V2

Текущая установка — opencode 1.18.33 и V1-поля. При переходе на V2:

- `permission` → `permissions` (упорядоченный массив правил);
- `task` → `subagent`;
- `disable` → `disabled`;
- `agent` map → `agents`;
- `temperature`/`options` у агента переносятся в model variant.

Файловые расположения `.opencode/agents`, `.opencode/commands`,
`.opencode/skills` сохраняются. Не смешивайте V1- и V2-поля в одном файле
агента.
