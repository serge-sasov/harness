# Локальный harness: описание решения

| Поле | Значение |
|---|---|
| Статус | актуально |
| Дата | 2026-11-07 |
| Область | локальный multi-agent harness + пилотный «Мини-CRUD сервис» |
| Источник требований | [`requirements/initial.txt`](../../requirements/initial.txt) |
| Регламент процесса | [`harness/process.md`](../../harness/process.md) |
| Board | [`docs/plan.md`](../plan.md) |
| HTML-версия | [`index.html`](index.html) |

Документ описывает решение целиком: назначение, архитектуру, карту сценариев,
sequence-диаграммы каждого сценария, концептуальную модель классов и пилотный
кейс, подтвердивший полный цикл. Все схемы встроены в текст; рядом с каждой
указан исходник PlantUML.

---

## 1. Назначение и область

Нужен локальный harness для проектирования архитектуры решений и ПО с
последующей реализацией. Процесс выполняется разными ролями в рамках отдельных
задач и общего плана: у задач есть зависимости, статусы, ответственная роль и
критерии приёмки. Каждая роль — отдельный sub-agent, работающий на локальной
модели Ollama; внешние API не используются.

В область решения входят:

- harness: роли, board, карточки задач, регламент, команды, артефакты;
- локальные модели и инструменты: Ollama, `local-rag`, MCP `plantuml-render`, Git;
- пилотный «Мини-CRUD сервис» как сквозной пример: требования → ADR → схемы →
  QA-приёмка.

Вне области: аутентификация, внешние интеграции, production-деплой,
многопользовательская работа, пагинация и поиск по заметкам.

### Ключевые принципы

1. **Единый board** — `docs/plan.md` единственный источник истины по составу работ.
2. **Единый регламент** — `harness/process.md` задаёт жизненный цикл, статусы,
   порядок обновления артефактов и git-дисциплину.
3. **Изоляция ролей** — каждая роль пишет только в свою зону и не выходит за
   границы задачи; вложенные вызовы sub-agent'ов запрещены.
4. **Детерминированная приёмка** — задача закрывается только по критериям
   `acceptance` из карточки; провал фиксируется в `Blockers`.
5. **Локальность** — модели, эмбеддинги, рендер схем и тесты выполняются локально.
6. **Прослеживаемость** — решение, схемы, контракты, ревью и коммиты связаны
   через ID задач.

---

## 2. Архитектура

### 2.1 Компонентная схема

![Компонентная схема harness](diagrams/components-harness.svg)

Исходник: [`diagrams/components-harness.puml`](diagrams/components-harness.puml).

Слои решения:

| Слой | Компоненты | Назначение |
|---|---|---|
| Управление | opencode, primary-агент `harness`, команды `/harness-*`, глобальная установка | явный запуск, маршрутизация ролей, синхронизация артефактов |
| Роли | `harness-orchestrator`, `harness-analyst`, `harness-architect`, `harness-coder`, `harness-qa`, `harness-doc-writer` | выполнение работ по зонам ответственности |
| Модели | `qwen3.8:27b-64k`, `tiel-coder:35b-a3b-mtp-128k` (text/vision) | локальный инференс без внешних API |
| Источники истины | `docs/plan.md`, `docs/tasks/*.md` | состав работ, статусы, зависимости, acceptance |
| Артефакты | `docs/analysis`, `docs/architecture`, `docs/qa`, `docs/guides`, `docs/issues`, `src`, `tests` | результаты ролей |
| Инструменты | MCP `plantuml-render`, `local-rag`, Git | проверка/рендер схем, поиск по источникам, версионирование |
| Пилот | FastAPI REST API, NoteService, NoteRepository, SQLite | сквозной пример реализации |

Поток управления: пользователь вызывает `/harness-run T-XXX` → команда
переключает сессию на primary-агента `harness` → lead проверяет marker и
`depends_on` → `harness-orchestrator` ведёт board и приёмку → профильная роль
пишет артефакты → orchestrator обновляет board/диаграмму и коммитит.

### 2.2 Роли и модели

| Роль | Модель Ollama | Thinking | Основная задача |
|---|---|---|---|
| harness lead | `qwen3.8:27b-64k` | xhigh | явный запуск, marker, маршрутизация, отчёт |
| orchestrator | `qwen3.8:27b-64k` | xhigh | board, зависимости, приёмка, коммиты |
| analyst | `qwen3.8:27b-64k` | medium | требования, RAG-анализ, вопросы, глоссарий |
| architect | `qwen3.8:27b-64k` | xhigh | ADR, схемы PlantUML, контракты |
| coder | `tiel-coder:35b-a3b-mtp-128k-text` | — | код, тесты, CI/CD, локальный деплой |
| qa | `tiel-coder:35b-a3b-mtp-128k-vision` | — | ревью, визуальная проверка схем, вердикт |
| doc-writer | `qwen3.8:27b-64k` | low | README, runbook, гайды, финализация ADR |

Агенты установлены глобально как `harness`, `harness-orchestrator`,
`harness-analyst`, `harness-architect`, `harness-coder`, `harness-qa`,
`harness-doc-writer`; lead вызывает их через `task`.

### 2.3 Права и зоны записи

| Роль | Зона записи | Запрещено |
|---|---|---|
| harness lead | не пишет файлы; только читает и делегирует | edit/write, git commit, вызов ролей вне harness |
| orchestrator | `docs/**`, `README.md`, `.gitignore` | работа других ролей, `git push/tag/reset/rebase` |
| analyst | `docs/analysis/**`, `docs/tasks/**` (свой статус/лог) | архитектура, код, тесты, коммиты |
| architect | `docs/architecture/**`, `docs/tasks/**` | код, тесты, правка `docs/analysis` |
| coder | `src/**`, `tests/**`, `scripts/**`, `Dockerfile`, `docker-compose*.yml`, `Makefile`, `.gitignore` | prod-действия, `git commit`, `docker push`, облачные CLI |
| qa | `docs/qa/**`, `docs/tasks/**` | исправление кода и артефактов, коммиты, деплой |
| doc-writer | `README.md`, `docs/guides/**`, `docs/architecture/adr-*.md` (редактура) | код, тесты, CI/CD, изменение смысла ADR |

Права содержат и относительные, и `**/...` варианты паттернов: opencode
сопоставляет edit/write с абсолютным путём, поэтому blanket deny `"*": "deny"`
перекрывается конкретным allow, совпадающим с полным путём. `.gitignore`
разрешён orchestrator и coder. Все роли могут создавать issue-файлы в
`docs/issues/**`; индекс ведёт orchestrator.

Общие запреты: правка `~/.config/opencode/**`, секреты в коде/логах/коммитах,
вложенный вызов sub-agent'ов, выход за пределы диска `C:`, prod-деплой.

### 2.4 Источники истины и артефакты

| Артефакт | Путь | Владелец |
|---|---|---|
| Board | `docs/plan.md` | orchestrator |
| Карточка задачи | `docs/tasks/T-XXX-*.md` | роль задачи + orchestrator |
| Требования | `docs/analysis/requirements-*.md` | analyst |
| Вопросы и допущения | `docs/analysis/questions-*.md` | analyst |
| Глоссарий | `docs/analysis/glossary.md` | analyst |
| ADR | `docs/architecture/adr-NNN-*.md` | architect (финализация — doc-writer) |
| Схемы | `docs/architecture/*.puml`, `*.svg` | architect |
| Контракты | `docs/architecture/contracts-*.md` | architect |
| Отчёт QA | `docs/qa/review-T-XXX.md` | qa |
| Код и тесты | `src/`, `tests/`, `scripts/`, `Dockerfile`, compose, `Makefile` | coder |
| Activity-диаграмма | `docs/activity.puml`, `docs/activity.svg` | orchestrator |
| Гайды | `docs/guides/**`, `README.md` | doc-writer |
| Журнал проблем | `docs/issues/ISSUE-*.md`, `docs/issues/README.md` | все роли; индекс — orchestrator |

---

## 3. Карта сценариев

![Карта сценариев](diagrams/scenario-map.svg)

Исходник: [`diagrams/scenario-map.puml`](diagrams/scenario-map.puml).

| ID | Сценарий | Триггер | Роли | Результат |
|---|---|---|---|---|
| S-01 | Установка и bootstrap | `install.ps1`, затем `/harness-init` | opencode, глобальный harness, Ollama | глобальные агенты установлены, проект инициализирован |
| S-02 | Полный цикл задачи | `/harness-run T-XXX` | harness lead + orchestrator + роль | задача `done`/`failed`, коммит, разблокировка зависимых |
| S-03 | Анализ требований | задача analyst | analyst, local-rag | требования, вопросы, глоссарий |
| S-04 | Архитектура и схемы | задача architect | architect, MCP PlantUML | ADR, `.puml`/`.svg`, контракты, декомпозиция |
| S-05 | Реализация и тесты | задача coder | coder, test runner, Docker | код, тесты, CI/CD, локальный запуск |
| S-06 | QA-приёмка | задача qa | qa, test runner, vision | отчёт ревью и вердикт `accept`/`reject` |
| S-07 | Документирование | задача doc-writer | doc-writer | README, runbook, гайды, финализация ADR |
| S-08 | Синхронизация board | `harness-board-update all / T-XXX` | orchestrator, MCP, Git | статусы, коммиты, SVG, chore-коммит |
| S-09 | Отчёт по board | `harness-board-report` | orchestrator | сводка и рекомендации (read-only) |
| S-10 | Ошибки и блокировки | провал приёмки | orchestrator, роль, пользователь | `failed` → retry ≤3 → `blocked`/`done` |
| S-11 | Пилотный end-to-end | задача T-013 | orchestrator, analyst, architect, qa | подтверждённый полный цикл на «Мини-CRUD» |

---

## 4. Сценарии

### S-01. Установка и bootstrap harness

**Цель:** один раз установить harness глобально и инициализировать его в проекте.
**Предусловия:** репозиторий с исходниками harness доступен, Ollama запущена,
модели загружены.

![S-01 Установка и bootstrap](diagrams/seq-01-bootstrap.svg)

Исходник: [`diagrams/seq-01-bootstrap.puml`](diagrams/seq-01-bootstrap.puml).

**Результат:** агенты, команды, skill, шаблоны и скрипты лежат в
`~/.config/opencode/`; в проекте созданы `harness/process.md`,
`harness/version.json` и `docs/plan.md`. **Особенность:** `default_agent` не
меняется; после установки агентов обязателен перезапуск opencode. Активация —
только явными `/harness-*`.

### S-02. Полный цикл задачи (`/harness-run`)

**Цель:** провести задачу от проверки зависимостей до приёмки и коммита.
**Предусловия:** проект инициализирован (`harness/process.md`), карточка
`docs/tasks/T-XXX-*.md` существует, все `depends_on` находятся в статусе `done`.

![S-02 Полный цикл задачи](diagrams/seq-02-harness-run.svg)

Исходник: [`diagrams/seq-02-harness-run.puml`](diagrams/seq-02-harness-run.puml).

**Результат:** задача переведена в `done`, обновлены board, карточка, activity-
диаграмма и SVG, сделан коммит `T-XXX: ...`; зависимые задачи разблокированы.
**Ошибки:** нет marker — стоп с предложением `/harness-init`; невыполненные
зависимости — стоп без запуска; провал `acceptance` — `failed` и причина в
`Blockers`.

### S-03. Анализ требований (analyst)

**Цель:** собрать и уточнить требования, проверить существующие материалы через
RAG. **Предусловия:** есть постановка и доступ к `local-rag` (при недоступности
Ollama RAG работает в режиме FTS5).

![S-03 Анализ требований](diagrams/seq-03-analyst.svg)

Исходник: [`diagrams/seq-03-analyst.puml`](diagrams/seq-03-analyst.puml).

**Результат:** `docs/analysis/requirements-*.md` с атомарными проверяемыми
требованиями `R-NNN`, `questions-*.md` с открытыми вопросами и допущениями,
`glossary.md`; отчёт orchestrator с рисками и блокерами. **Ошибки:** недостаток
данных оформляется как вопрос, а не как выдуманное требование.

### S-04. Архитектура и схемы (architect)

**Цель:** принять архитектурное решение с альтернативами, оформить схемы и
контракты. **Предусловия:** требования analyst приняты.

![S-04 Архитектура и схемы](diagrams/seq-04-architect.svg)

Исходник: [`diagrams/seq-04-architect.puml`](diagrams/seq-04-architect.puml).

**Результат:** ADR по шаблону, компонентные/sequence-схемы `.puml` + `.svg`,
контракты интерфейсов, декомпозиция для coder. **Обязательный контроль:** каждая
схема проходит `check_syntax`, затем `render_file`; ошибки синтаксиса устраняются
до передачи задачи. Решение без альтернатив недопустимо.

### S-05. Реализация и тесты (coder)

**Цель:** реализовать решение строго по ADR и контрактам. **Предусловия:** ADR и
контракты приняты, задача содержит target локального запуска.

![S-05 Реализация и тесты](diagrams/seq-05-coder.svg)

Исходник: [`diagrams/seq-05-coder.puml`](diagrams/seq-05-coder.puml).

**Результат:** код в `src/`, тесты в `tests/`, CI/CD-подготовка (`Dockerfile`,
compose, Makefile, скрипты), зелёные тесты и локально поднятый сервис. **Ошибки:**
падение тестов исправляется без ослабления assert'ов; при нехватке контекста —
стоп и блокер, а не частичная реализация.

### S-06. QA-приёмка (qa)

**Цель:** независимо проверить артефакты против `acceptance`. **Предусловия:**
результаты роли переданы orchestrator'ом.

![S-06 QA-приёмка](diagrams/seq-06-qa.svg)

Исходник: [`diagrams/seq-06-qa.puml`](diagrams/seq-06-qa.puml).

**Результат:** `docs/qa/review-T-XXX.md` с таблицей «критерий → pass/fail»,
замечаниями по severity и вердиктом `accept`/`reject`; независимый прогон тестов
(read-only) и визуальная проверка схем. **Ошибки:** `reject` возвращает задачу на
исправление; QA сам артефакты не правит.

### S-07. Документирование (doc-writer)

**Цель:** привести документацию к фактическому решению. **Предусловия:** ADR,
контракты и реализация доступны.

![S-07 Документирование](diagrams/seq-07-doc-writer.svg)

Исходник: [`diagrams/seq-07-doc-writer.puml`](diagrams/seq-07-doc-writer.puml).

**Результат:** README, runbook, гайды, финализация ADR по шаблону; ссылки
относительные, команды проверены. **Ограничение:** менять смысл ADR и контрактов
нельзя — только форму и полноту.

### S-08. Синхронизация board (`harness-board-update`)

**Цель:** привести план, карточки и activity-диаграмму к фактическому состоянию.
**Предусловия:** проект инициализирован; выполнены задачи или изменились статусы.

![S-08 Синхронизация board](diagrams/seq-08-harness-board-update.svg)

Исходник: [`diagrams/seq-08-harness-board-update.puml`](diagrams/seq-08-harness-board-update.puml).

**Результат:** `harness` lead делегирует `harness-orchestrator` обновление
`docs/plan.md`, карточек, цветов `docs/activity.puml`, перерендер
`docs/activity.svg`, запись хэшей коммитов и коммит `chore: board update (...)`.
**Правило:** при расхождении истиной считается карточка задачи.

### S-09. Отчёт по board (`harness-board-report`)

**Цель:** получить сводку без изменения артефактов. **Предусловия:** проект
инициализирован.

![S-09 Отчёт по board](diagrams/seq-09-harness-board-report.svg)

Исходник: [`diagrams/seq-09-harness-board-report.puml`](diagrams/seq-09-harness-board-report.puml).

**Результат:** `harness` lead делегирует `harness-orchestrator` read-only сводку:
таблица статусов, список готовых к старту задач, `failed`/`blocked` с причинами,
%done, проверка «висячих» зависимостей, 1–3 рекомендации. **Правило:** сценарий
строго read-only, ничего не коммитится.

### S-10. Ошибки, retry и блокировки

**Цель:** обработать провал приёмки предсказуемо и не потерять историю.
**Предусловия:** роль вернула результат, orchestrator выполнил приёмку.

![S-10 Ошибки и блокировки](diagrams/seq-10-errors.svg)

Исходник: [`diagrams/seq-10-errors.puml`](diagrams/seq-10-errors.puml).

**Результат:** при провале задача получает `failed`, причина и вывод пишутся в
карточку; выполняется до 3 попыток исправления; после исчерпания — `blocked` и
эскалация пользователю. История ошибок не удаляется при исправлении.

### S-11. Пилотный end-to-end цикл T-013

**Цель:** доказать работоспособность полного цикла на отдельной задаче.
**Предусловия:** harness собран (T-001..T-012), роли доступны.

![S-11 Пилотный end-to-end](diagrams/seq-11-pilot-e2e.svg)

Исходник: [`diagrams/seq-11-pilot-e2e.puml`](diagrams/seq-11-pilot-e2e.puml).

**Результат:** аналитик сформировал требования пилота, архитектор — ADR и
компонентную схему, QA — ревью с вердиктом `accept`; T-013 переведена в `done`,
сделан коммит. Пилот подтвердил, что ролевые промпты достаточно детерминированы.

---

## 5. Концептуальная модель классов

![Классы harness](diagrams/class-harness.svg)

Исходник: [`diagrams/class-harness.puml`](diagrams/class-harness.puml).

Модель концептуальная: она описывает домен harness (board, задачи, роли,
артефакты), а не классы конкретного приложения.

| Класс | Назначение |
|---|---|
| `PlanBoard` | board `docs/plan.md`: загрузка задач, смена статуса, запись коммита |
| `TaskCard` | карточка задачи: id, роль, зависимости, acceptance, артефакты, блокеры, лог |
| `TaskStatus` | статусы `pending`, `in_progress`, `done`, `failed`, `blocked` |
| `Role` | абстрактная роль: модель, права, зоны записи, выполнение задачи |
| `Orchestrator`, `Analyst`, `Architect`, `Coder`, `QA`, `DocWriter` | конкретные роли harness |
| `ModelProfile` | локальная модель, режим thinking, назначение |
| `Artifact` | артефакт роли с путём, типом и производителем |
| `Diagram` | PlantUML-исходник и SVG-рендер; проверка и рендер |
| `Review` | отчёт QA: вердикт и список замечаний |
| `Finding` | замечание с ID, severity и текстом |
| `Commit` | git-коммит задачи: хэш и сообщение |
| `Command` | команда opencode: `/harness-run`, `/harness-board-update`, `/harness-board-report` |
| `HarnessLead` | primary-агент `harness`: marker, маршрутизация, отчёт; не пишет файлы |
| `LogEntry` | запись в логе карточки |
| `RoleResult` | результат роли: статус, файлы, резюме |

Ключевые связи: `PlanBoard 1 *-- 0..* TaskCard`; `TaskCard` зависит от других
карточек (`dependsOn`), назначена одной роли и имеет один статус; роль produces
много артефактов; `Diagram` и `Review` наследуют `Artifact`; `HarnessLead`
выбирается командой, читает board/карточки и вызывает роли; orchestrator
обновляет board и создаёт коммиты.

---

## 6. Процесс, статусы и управление

### 6.1 Жизненный цикл задачи

1. `harness` lead проверяет marker проекта и `depends_on`: все — `done`.
2. `harness-orchestrator` переводит задачу в `in_progress` (plan, карточка,
   цвет диаграммы).
3. Роль выполняет задачу строго по `acceptance` из карточки.
4. `harness-orchestrator` принимает результат; при провале — `failed`.
5. Статус → `done`, запись в `log`, обновление board/activity/SVG и коммит.

### 6.2 Статусы

| Статус | Цвет | Значение |
|---|---|---|
| `pending` | `#D3D3D3` | не начата |
| `in_progress` | `#FFE082` | в работе |
| `done` | `#90EE90` | выполнена и принята |
| `failed` | `#FF9090` | ошибка, требуется исправление |
| `blocked` | `#FFB347` | внешняя блокировка |

Допустимые переходы: `pending → in_progress → done`; `in_progress → failed`;
`failed → in_progress` (после исправления); `* → blocked` при внешней блокировке.

### 6.3 Обязательный порядок обновления артефактов

1. `docs/plan.md` — статус, артефакты, хэш коммита.
2. `docs/tasks/T-XXX-*.md` — статус, лог, блокеры.
3. `docs/activity.puml` — цвет блока задачи.
4. Перерендер `docs/activity.svg` через MCP `plantuml-render`.
5. `git commit` с сообщением `T-XXX: ...`.

### 6.4 Git-дисциплина

- Репозиторий в корне проекта, ветка по умолчанию — `master`.
- Минимум один коммит на задачу; формат `T-XXX: краткое описание`.
- Запрещены `git push`, `git tag`, правка истории, коммит секретов и `.env`.
- В коммит включаются только файлы задачи.

### 6.5 Диаграмма выполнения плана

![Диаграмма активности T-001..T-013](../activity.svg)

Исходник: [`docs/activity.puml`](../activity.puml). Зелёный — `done`, серый —
`pending`, жёлтый — `in_progress`, красный — `failed`, оранжевый — `blocked`.

### 6.6 Журнал проблем

Проблемы harness фиксируются skill `harness-issues`:

- `docs/issues/ISSUE-YYYYMMDD-HHMMSS-<slug>.md` — одна проблема;
- [`docs/issues/README.md`](../issues/README.md) — индекс-перечень.

Запись содержит статус, severity, type, source, роль, абсолютный location,
симптомы, воспроизведение, причину, решение/workaround, проверку, prevention
и timeline. Все роли могут создавать issue-файлы; `harness-orchestrator`
сверяет индекс и включает их в коммит задачи. Секреты в issue не записываются.

---

## 7. Пилотный кейс «Мини-CRUD сервис» (T-013)

Пилот проверяет цикл analyst → architect → qa на отдельной задаче: REST CRUD для
заметок, SQLite, локальный Docker, детерминированные тесты. Один пользователь,
без auth и внешних интеграций.

### 7.1 Требования

| ID | Требование |
|---|---|
| R-001 | `POST /notes` с `title`, `body`; ответ 201 с `id`. |
| R-002 | `GET /notes` — массив заметок, сортировка по `created_at` убыв. |
| R-003 | `GET /notes/{id}`; 404 при отсутствии. |
| R-004 | `PUT /notes/{id}` с `title`, `body`; 404 при отсутствии. |
| R-005 | `DELETE /notes/{id}`; 204 при успехе, 404 при отсутствии. |
| R-006 | Валидация: `title` 1..200 символов, `body` до 10000; ошибка 422. |
| NFR-1 | `docker compose up` поднимает сервис на порту 8080. |
| NFR-2 | SQLite-файл в volume, переживает рестарт контейнера. |
| NFR-3 | Unit + API-тесты, детерминированные, без сети. |

Открытые вопросы пилота: пагинация не нужна (Q-001), поиск по тексту вне пилота
(Q-002). Риски: рост SQLite-файла (R1), отсутствие auth — только local/staging
(R2). Полные требования: [`docs/analysis/pilot-requirements.md`](../analysis/pilot-requirements.md).

### 7.2 Архитектурное решение (ADR-001)

Стек: Python 3.12 + FastAPI + SQLAlchemy 2.x (SQLite) + Pydantic v2. Структура:
тонкий API-слой → сервисный слой → репозиторий. Тесты: pytest + httpx (ASGI
transport). Контейнеризация: `python:3.12-slim`, docker compose с volume для БД.

| Альтернатива | Почему отклонена |
|---|---|
| Flask + SQLite | ручная валидация, меньше типизации |
| Node/Express + better-sqlite3 | второй стек в локальном окружении |
| Django + DRF | избыточен для одного CRUD |

Полный ADR: [`docs/architecture/pilot-adr.md`](../architecture/pilot-adr.md).

### 7.3 REST-контракт

| Метод | Путь | Тело | Ответ |
|---|---|---|---|
| POST | `/notes` | `{title, body}` | 201 `{id, title, body, created_at}` |
| GET | `/notes` | — | 200 `[...]` |
| GET | `/notes/{id}` | — | 200 / 404 |
| PUT | `/notes/{id}` | `{title, body}` | 200 / 404 |
| DELETE | `/notes/{id}` | — | 204 / 404 |

Ошибки: `{"detail": "..."}`; валидация — 422 (Pydantic).

### 7.4 Компонентная схема пилота

![Компоненты пилотного CRUD](../architecture/pilot-components.svg)

Исходник: [`docs/architecture/pilot-components.puml`](../architecture/pilot-components.puml).

### 7.5 Модель классов пилота

![Классы пилотного CRUD](diagrams/class-pilot.svg)

Исходник: [`diagrams/class-pilot.puml`](diagrams/class-pilot.puml).

`Note` — доменная сущность; `NoteCreate`/`NoteUpdate` — входные схемы;
`NoteRead` — выходная схема; `NoteService` — доменная логика; `NoteRepository` —
доступ к SQLite; `NoteNotFound` — ошибка 404.

### 7.6 Результат QA

Вердикт: **accept**. Замечания minor: N-001 — не зафиксирована версия
Python-образа (pin в Dockerfile на этапе coder); N-002 — не описан формат
`created_at` (ISO-8601 UTC). Полный отчёт:
[`docs/qa/pilot-review.md`](../qa/pilot-review.md).

---

## 8. Эксплуатация

### 8.1 Глобальная установка и быстрый старт

1. Из корня репозитория выполнить глобальную установку:
   `powershell -NoProfile -ExecutionPolicy Bypass -File harness/scripts/install.ps1`.
2. Перезапустить opencode; проверить установку командой `/harness-doctor`.
3. В проекте выполнить `/harness-init`; проверить `harness/process.md` и
   `docs/plan.md`.
4. Заполнить `docs/plan.md`, создать карточку по
   `harness/templates/task-card.md`.
5. Запустить задачу командой `/harness-run T-XXX`.
6. Сводка: `/harness-board-report`; синхронизация: `/harness-board-update all`.
7. Диаграмма: `docs/activity.puml`, рендер — `docs/activity.svg`.

`default_agent` не переключается на harness: активация только явными
`/harness-*`. Глобальная установка выполняется для текущего пользователя
(`~/.config/opencode`).

### 8.2 Команды

| Команда | Аргумент | Назначение |
|---|---|---|
| `/harness-init` | — | создать harness в текущем проекте и marker-файлы |
| `/harness-run` | `T-XXX` | проверка зависимостей, `in_progress`, вызов роли, приёмка, коммит |
| `/harness-board-update` | `T-XXX` или `all` | сверка статусов, коммитов, activity-диаграммы и SVG |
| `/harness-board-report` | — | read-only сводка: статусы, блокеры, готовые к старту, рекомендации |
| `/harness-doctor` | — | проверка глобальной установки и текущего проекта |

### 8.3 Как добавить задачу

1. Создать карточку по шаблону `harness/templates/task-card.md`.
2. Добавить строку в `docs/plan.md` по шаблону `harness/templates/plan-row.md`.
3. Указать роль, `depends_on`, `acceptance`, артефакты.
4. Запустить `harness-run T-XXX` после выполнения зависимостей.
5. После задачи обновить board/карточку/диаграмму и закоммитить.

### 8.4 Ограничения и риски

- SQLite не предназначен для конкурентной записи — принято для пилота.
- Нет auth — сервис только для local/staging.
- Модели локальные: качество и скорость зависят от железа; при недоступности
  Ollama RAG работает в режиме FTS5.
- Схемы и документация требуют периодической сверки с кодом.
- Ролевые промпты детерминированы, но не гарантируют идеальный результат с
  первого прохода — предусмотрены `failed` и retry ≤ 3.

### 8.5 Сборка HTML

HTML-версия генерируется из этого файла и не требует сети:

```powershell
python docs/description/build_html.py
```

Скрипт встраивает все SVG как `data:`-URI, оборачивает диаграммы в zoomable-
фигуры и собирает `docs/description/index.html`. Шаблон страницы и стили/JS
модалки — `docs/description/template.html`. Требуется Python 3.12 и пакет
`markdown`.

### 8.6 Диагностика

| Симптом | Причина | Действие |
|---|---|---|
| роль не видна в opencode | агенты добавлены после старта | перезапустить opencode |
| модель недоступна | Ollama не запущена / модель не загружена | запустить Ollama, `ollama pull` |
| RAG отвечает без эмбеддингов | Ollama недоступна | работа в режиме FTS5, не блокирует задачу |
| схема не рендерится | ошибка PlantUML | `check_syntax`, исправить `.puml`, повторить `render_file` |
| задача не стартует | зависимость не `done` | проверить `depends_on` и статусы карточек |

---

## 9. Трассируемость

| Сценарий | Артефакты | Источник |
|---|---|---|
| S-01 | глобальные агенты, project marker | [`harness/scripts/install.ps1`](../../harness/scripts/install.ps1), [`harness/commands/harness-init.md`](../../harness/commands/harness-init.md) |
| S-02 | план, карточка, activity, коммит | [`harness/commands/harness-run.md`](../../harness/commands/harness-run.md) |
| S-03 | требования, вопросы, глоссарий | [`harness/agents/harness-analyst.md`](../../harness/agents/harness-analyst.md) |
| S-04 | ADR, схемы, контракты | [`harness/agents/harness-architect.md`](../../harness/agents/harness-architect.md) |
| S-05 | код, тесты, CI/CD | [`harness/agents/harness-coder.md`](../../harness/agents/harness-coder.md) |
| S-06 | отчёт ревью | [`harness/agents/harness-qa.md`](../../harness/agents/harness-qa.md) |
| S-07 | README, гайды, ADR | [`harness/agents/harness-doc-writer.md`](../../harness/agents/harness-doc-writer.md) |
| S-08 | board, карточки, activity | [`harness/commands/harness-board-update.md`](../../harness/commands/harness-board-update.md) |
| S-09 | сводка board | [`harness/commands/harness-board-report.md`](../../harness/commands/harness-board-report.md) |
| S-10 | `failed`/`blocked`, лог | [`harness/process.md`](../../harness/process.md), п. 7 |
| S-11 | пилотные требования, ADR, QA | [`docs/tasks/T-013-smoke-test.md`](../tasks/T-013-smoke-test.md) |

---

## 10. Карта файлов

| Путь | Содержимое |
|---|---|
| `README.md` | краткое описание harness и быстрый старт |
| `requirements/initial.txt` | исходные требования |
| `harness/process.md` | регламент процесса |
| `harness/agents/*.md` | primary-агент `harness` и ролевые sub-agent'ы |
| `harness/commands/*.md` | команды `/harness-*` |
| `harness/skills/harness/SKILL.md` | глобальный skill harness |
| `harness/skills/harness-issues/SKILL.md` | skill учёта проблем и решений |
| `harness/templates/*.md` | шаблоны card, ADR, plan-row, issue |
| `harness/scripts/*.ps1` | install, init, doctor, uninstall, new-issue |
| `harness/version.json` | версия установки |
| `docs/plan.md` | board задач |
| `docs/tasks/*.md` | карточки задач |
| `docs/issues/` | журнал проблем и решений |
| `docs/analysis/` | требования пилота |
| `docs/architecture/` | ADR и схемы пилота |
| `docs/qa/` | отчёт ревью пилота |
| `docs/activity.puml/.svg` | activity-диаграмма плана |
| `docs/description/` | это описание, диаграммы и HTML |
| `docs/description/README.md` | исходное описание (Markdown) |
| `docs/description/diagrams/` | исходники `.puml` и рендеры `.svg` |
| `docs/description/build_html.py` | сборка самодостаточного HTML |
| `docs/description/template.html` | шаблон HTML, CSS и pan/zoom-модалка |
| `docs/description/index.html` | самодостаточная HTML-версия с zoom-модалкой |
| `docs/guides/harness-global.md` | глобальная установка, активация, pin и диагностика |

---

## Приложение. Глоссарий

| Термин | Значение |
|---|---|
| Harness | локальная система ролей-под-агентов с общим планом и регламентом |
| Sub-agent | роль, вызываемая primary-агентом через `task` |
| Board | `docs/plan.md` — таблица задач со статусами и зависимостями |
| Карточка задачи | MD-файл с id, ролью, `depends_on`, `acceptance`, логом |
| Acceptance | проверяемые критерии приёмки задачи |
| Артефакт | файл или набор файлов, созданный ролью |
| ADR | Architecture Decision Record — запись архитектурного решения |
| MCP | протокол инструментов; здесь — `plantuml-render` и `local-rag` |
| RAG | поиск по локальному индексу (FTS5 + LanceDB + Ollama) |
| SVG | векторный формат схем, масштабируется без потери качества |
| Pan/zoom | перетаскивание и масштабирование диаграммы в HTML-модалке |

---

## Источники

- [`requirements/initial.txt`](../../requirements/initial.txt) — исходные требования.
- [`README.md`](../../README.md) — состав репозитория и быстрый старт.
- [`docs/guides/harness-global.md`](../guides/harness-global.md) — глобальная установка и активация.
- [`harness/process.md`](../../harness/process.md) — регламент процесса.
- [`docs/plan.md`](../plan.md) — board задач T-001..T-013.
- [`docs/analysis/pilot-requirements.md`](../analysis/pilot-requirements.md) — требования пилота.
- [`docs/architecture/pilot-adr.md`](../architecture/pilot-adr.md) — ADR-001.
- [`docs/qa/pilot-review.md`](../qa/pilot-review.md) — QA-ревью пилота.
- [`docs/tasks/T-013-smoke-test.md`](../tasks/T-013-smoke-test.md) — карточка пилотного цикла.
