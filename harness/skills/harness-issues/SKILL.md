---
name: Harness Issues
description: "Учёт проблем и решений harness: фиксируй ошибки, блокировки, permission deny, сбои MCP/RAG/моделей, git/board и найденные workaround в docs/issues/*.md с индексом. Использовать при любой проблеме во время работы harness; не для обычных задач вне harness."
---

# Harness Issues

## Когда использовать

Загружай этот skill, если во время работы harness возникла проблема, которую
пришлось диагностировать, обходить или исправлять:

- permission denied, несовпадение абсолютных путей, `task: deny`;
- ошибка Ollama/модели, недоступность MCP `plantuml-render` или `local-rag`;
- сбой git, board, activity, шаблонов или агентов;
- неожиданное поведение ролей, команд или `/harness-*`;
- найден workaround или исправление, которое нужно сохранить для анализа.

Не создавай issue на каждый успешный шаг и не дублируй карточку задачи.
Issue — это журнал проблемы, её причины и решения.

## Жёсткая проверка

Перед записью убедись, что проект инициализирован:

- существуют `harness/process.md` и `docs/plan.md`;
- если их нет — остановись и предложи `/harness-init`.

## Где хранить

```
docs/issues/
  README.md                              # индекс-перечень
  ISSUE-YYYYMMDD-HHMMSS-<slug>.md        # одна проблема — один файл
```

Шаблон: `harness/templates/issue.md`.
Хелпер: `harness/scripts/new-issue.ps1` (копируется в проект через init).
При совпадении timestamp к ID добавляется `-2`, `-3`.

## Workflow

1. Зафиксируй контекст **до** исправления:
   - source: `S-xx`, `T-xxx`, `/harness-*`, `build`;
   - роль/агент и cwd;
   - абсолютный `location` (файл:строка, команда, конфиг);
   - текст ошибки и ожидаемое/фактическое поведение.
2. Создай запись:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/new-issue.ps1 `
     -Title "Краткое название" `
     -Severity major `
     -Status open `
     -Type permission `
     -Source "T-001" `
     -Role "harness-analyst" `
     -Location "C:\path\to\file:line"
   ```

   Если скрипта нет — создай файл вручную по `harness/templates/issue.md`.
3. Заполни разделы: симптомы, воспроизведение, причина, решение/workaround,
   проверка, prevention/follow-up, ссылки.
4. Если проблема решена — поставь `status: resolved` и заполни «Проверка».
   Если остался обходной путь — `status: workaround`.
5. Передай ID issue в `harness-orchestrator`: он сверяет индекс
   `docs/issues/README.md` и включает issue-файлы в коммит задачи.
6. Свяжи issue с карточкой задачи (`T-XXX`) и артефактами/коммитом.

## Статусы

| Статус | Значение |
|---|---|
| `open` | проблема зафиксирована, причина не найдена |
| `investigating` | идёт диагностика |
| `workaround` | есть обходной путь, корень не устранён |
| `resolved` | причина устранена, проверка пройдена |
| `wontfix` | решение не требуется/невозможно, причина указана |

`severity`: `blocker`, `major`, `minor`, `info`.
`type`: `permission`, `tool`, `model`, `mcp`, `rag`, `path`, `git`, `process`, `other`.

## Индекс

`docs/issues/README.md` — перечень всех проблем:

| ID | Кратко | Severity | Status | Location | Source | Updated |
|---|---|---|---|---|---|---|

Скрипт добавляет строку в индекс. Orchestrator проверяет консистентность и
исправляет расхождения. Не удаляй историю issue-файлов.

## Правила

- Один файл — одна проблема; не перезаписывай существующие issue.
- Не записывай секреты, токены, ключи и содержимое `.env`; редактируй значения.
- Указывай абсолютный путь: относительные пути часто не совпадают с правилами
  permission и затрудняют анализ.
- Issue фиксирует проблему и решение, но не заменяет задачу board.
- Если проблема требует изменения правил/процесса, добавь это в
  «Предупреждение / follow-up» и предложи отдельную задачу.
