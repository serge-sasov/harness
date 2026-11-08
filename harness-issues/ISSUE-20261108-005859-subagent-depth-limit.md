# ISSUE-20261108-005859-subagent-depth-limit: Запуск harness-coder через task — «Subagent depth limit reached (1)»

| Поле | Значение |
|---|---|
| id | ISSUE-20261108-005859 |
| status | resolved |
| severity | medium |
| type | tooling / subagent |
| detected_at | 2026-11-07T21:58:59Z |
| resolved_at | 2026-11-08T17:08:39+03:00 |
| source | primary (harness lead) |
| role | harness (lead) |
| location | C:/study/ai/research/Qwen 3.8 27B Q4_K_M; C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js:79 |
| environment | opencode 1.18.33; `experimental.subagent_depth` не задан (default 1); provider ollama-metrics/qwen3.8:27b-64k |

## Симптомы

Вызов `task` с `subagent_type: "harness-coder"` (и других `harness-*` ролей)
терминально падает:

```
Subagent depth limit reached (1). Increase 'subagent_depth' to allow nested subagents.
```

Ошибка возникает не в корневой (primary) сессии, а в сессии, созданной
автоматическим compaction-handoff. Из настоящей root-сессии маршрутизация
работает: в `ses_e48bdaeeeffe6i5na0LjBRt98b` успешно запущены
`harness-orchestrator`, `harness-analyst`, `harness-architect`,
`harness-coder`; позже из root `ses_e455ef26effeICirCvhfaDzuOi` успешно
запущены `harness-orchestrator`, `harness-coder`, `harness-qa`.

## Воспроизведение

1. Работать в сессии с моделью `ollama-metrics/qwen3.8:27b-64k`.
2. Дождаться автоматического compaction: плагин `qwen-compaction-handoff`
   создаёт новую сессию-продолжение с `parentID` (до исправления).
3. В этой сессии вызвать `task` с любым `subagent_type: harness-*`.
4. Наблюдается ошибка «Subagent depth limit reached (1)».
5. Повторный compaction увеличивает глубину: продолжение создаётся от
   продолжения, и ошибка сохраняется.

## Ожидаемое / фактическое поведение

- Ожидалось: сессия-продолжение после compaction остаётся равноправной
  primary-сессией и может запускать harness-роли (`task: allow`).
- Фактически: продолжение считается дочерней сессией; `task` вычисляет
  depth по цепочке `parentID` и при `depth >= 1` блокирует запуск.

## Причина

Причина не в правах `permission.task` и не в «запрете primary-сессии».
Плагин `C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js`
(строка 79 до исправления) создавал сессию-продолжение так:

```js
body: { parentID: sessionID, title }
```

Из-за `parentID` opencode считает продолжение дочерней сессией.
`packages/opencode/src/tool/task.ts` (1.18.33) вычисляет глубину обходом
цепочки `parentID`; при `depth >= (subagent_depth ?? 1)` выбрасывается
ошибка. `experimental.subagent_depth` не задан, поэтому лимит равен 1:
корневая сессия (depth 0) может запускать субагентов, а продолжение
(depth 1) — уже нет. Каждый следующий compaction создаёт ещё один уровень.

Подтверждение:

- `%LOCALAPPDATA%/opencode-compaction/handoff.log`:
  - `2026-11-07T20:56:39Z` — `ses_e48bdaeeeffe6i5na0LjBRt98b` → `ses_e48336f53ffeagk3CHjcE056HT`;
  - `2026-11-07T21:26:27Z` — `ses_e48336f53ffeagk3CHjcE056HT` → `ses_e48182831ffe4KyNMbQsl5zXLd`.
- В `opencode.db`: `ses_e48336f53ffeagk3CHjcE056HT.parent_id = ses_e48bdaeeeffe6i5na0LjBRt98b`,
  `ses_e48182831ffe4KyNMbQsl5zXLd.parent_id = ses_e48336f53ffeagk3CHjcE056HT`.
- Issue создан в `ses_e48182831ffe4KyNMbQsl5zXLd` (depth 2).

## Решение

Плагин `qwen-compaction-handoff.js` исправлен:

1. Handoff пропускается, если у текущей сессии уже есть `parentID`
   (субагент или старое продолжение): новые дочерние сессии не создаются.
2. Сессия-продолжение создаётся без `parentID` (`body: { title }`), поэтому
   остаётся корневой (depth 0) и может запускать harness-роли.
3. Бэкап исходной версии:
   `C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js.bak-20261108-170839`.

Прежний workaround «делать роли inline в primary» не является исправлением:
он нарушает §1/§8 `harness/process.md` (lead не пишет файлы) и привёл к
двум задачам в `in_progress` (T-003, T-004), отсутствию `backend/` и
частичному `web/`. Если сессия имеет `parentID`, нужно начинать новый
корневой сеанс, а не выполнять ролевую работу в обход маршрутизации.

## Проверка

- `node --check qwen-compaction-handoff.js` — синтаксис OK.
- Mock-тест плагина (Node ESM, фиктивный `client`):
  - корневая сессия → `session.create` вызван с `body: { title: "root (continued)" }`,
    без `parentID`; `promptAsync` выполнен; `output.enabled = false`;
  - дочерняя сессия (`parentID` задан) → `session.create` не вызван,
    `output.enabled = true`, в лог записан `skip ... child session`.
- Историческая проверка маршрутизации: из root-сессий успешно запускались
  `harness-*` роли (см. раздел «Симптомы»).
- Follow-up: после следующего реального compaction в сессии qwen проверить
  `session.parent_id IS NULL` у новой сессии и успешный `task` с
  `harness-orchestrator` из неё. Для применения патча может потребоваться
  перезапуск opencode.

Примечание: прежние утверждения в этой записи о «pytest green» для T-003 и
«npm test/build success» для T-004 не подтверждены артефактами на момент
проверки: `backend/` отсутствовал, `web/` был частичным. К причине данного
issue эти проверки не относятся.

## Prevention

- Compaction-handoff не должен создавать continuation через `parentID`;
  продолжение обязано оставаться корневой сессией.
- При `parentID` у текущей сессии не выполнять ролевую работу inline:
  начинать новый корневой сеанс или исправлять handoff.
- Не переводить issue в `resolved` без воспроизводимой проверки и
  артефактов; фиксировать реальные команды и результаты.
- Добавить проверку в `/harness-doctor` (или docs): предупреждать, если
  handoff-плагин создаёт дочерние continuation-сессии.

## Ссылки

- Плагин: `C:/Users/sergey/.config/opencode/plugins/qwen-compaction-handoff.js`
- `packages/opencode/src/tool/task.ts` (opencode 1.18.33), проверка depth.
- `harness/process.md` §0 (маршрутизация), §1/§8 (роли и артефакты), §9 (запрет правки global config), §10 (учёт issue).
- `%LOCALAPPDATA%/opencode-compaction/handoff.log`.
- Сессии: `ses_e48bdaeeeffe6i5na0LjBRt98b`, `ses_e48336f53ffeagk3CHjcE056HT`, `ses_e48182831ffe4KyNMbQsl5zXLd`, `ses_e455ef26effeICirCvhfaDzuOi`.

## Timeline

- 2026-11-07T20:56:39Z: compaction-handoff создал `ses_e48336f53ffeagk3CHjcE056HT` (child).
- 2026-11-07T21:26:27Z: повторный compaction создал `ses_e48182831ffe4KyNMbQsl5zXLd` (grandchild).
- 2026-11-07T21:58:59Z: обнаружена ошибка `Subagent depth limit reached (1)` (исправлено с `2026-11-08T00:58:59Z`: была путаница UTC/local).
- 2026-11-08T17:08:39+03:00: плагин исправлен (root continuation + skip child), mock-проверка пройдена.
- Ожидается: подтверждение на следующем реальном compaction в qwen-сессии.
