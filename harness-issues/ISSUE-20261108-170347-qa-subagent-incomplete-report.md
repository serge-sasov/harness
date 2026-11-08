# ISSUE-20261108-170347-qa-subagent-incomplete-report: harness-qa возвращает незавершённый отчёт вместо вердикта accept/reject

| Поле | Значение |
|---|---|
| id | ISSUE-20261108-170347 |
| status | resolved |
| severity | low |
| type | tooling / subagent |
| detected_at | 2026-11-08T14:03:47Z |
| resolved_at | 2026-11-08T20:16:03+03:00 |
| source | primary (harness lead) |
| role | harness (lead) |
| location | C:/study/ai/research/Qwen 3.8 27B Q4_K_M; C:/Users/sergey/.config/opencode/agents/harness-qa.md; C:/Users/sergey/.config/opencode/opencode.jsonc |
| environment | opencode 1.18.33; QA-модель `qwen3.8:27b-64k` (vision, 64K); tiel-coder vision — фактический `num_ctx 32768` |

## Симптомы

Вызов harness-qa (tiel-coder vision) для приёмки T-004 дважды возвращает
незавершённый/пустой результат вместо структурированного вердикта accept/reject:

- `ses_e44984bbeffewKshJm8moo5jN3` — `finish=length`, total 32767, output 588;
- `ses_e449259a4ffe7eJGQCoCbuhds4` — `finish=length`, total 32767, output 70.

## Воспроизведение

1. Запустить `harness-qa` для T-004 (web-фронтенд Vue.js).
2. QA читает исходники и запускает тесты/build; контекст доходит до ~32K.
3. Модель возвращает `finish=length` до финального вердикта.
4. Повторный прогон на той же модели даёт тот же результат.

## Ожидаемое / фактическое поведение

- Ожидалось: структурированный вердикт accept/reject по 6 acceptance-критериям.
- Фактически: обрыв генерации по лимиту контекста; вердикт не сформирован.

## Причина

Причина не в глубине subagent и не в таймауте. У модели
`tiel-coder:35b-a3b-mtp-128k-vision` фактический `num_ctx` равен **32768**
(`ollama show`), а в `~/.config/opencode/opencode.jsonc` было указано
`limit.context: 128000` (и в `ollama`, и в `ollama-metrics`). Opencode считал,
что контекст 128K, и не запускал compaction; QA-сессия читала ~56–60K
символов tool-output и упиралась в реальные 32K. Оба прогона завершились
`finish=length` на 32767 токенах с малым output (588 и 70 токенов).

Для сравнения: `qwen3.8:27b-64k` имеет фактический `num_ctx 65536` и поддержку
vision/tools; `tiel-coder:...-text` — фактический 131072.

## Решение

1. QA-модель harness переключена с `tiel-coder:35b-a3b-mtp-128k-vision` на
   `qwen3.8:27b-64k` (vision, 64K):
   - `harness/agents/harness-qa.md` (источник) и глобальная установка;
   - `harness/process.md` §2, `README.md`, `docs/description/README.md`;
   - версия harness 1.0.1 → 1.0.2; выполнен `install.ps1`.
2. В роль QA добавлено правило контекста: читать точечно (карточка acceptance,
   API-контракт, целевые файлы/паттерны), не читать весь `src`, тесты/build —
   с кратким выводом, вердикт — короткий.
3. В `~/.config/opencode/opencode.jsonc` исправлен `limit.context` для
   `tiel-coder:35b-a3b-mtp-128k-vision` и `tiel-coder:35b-a3b-mtp-64k`
   (оба провайдера): 128000/65536 → 32768, по фактическому `num_ctx`.
4. T-004 остаётся принятым primary как временный workaround до появления
   рабочего QA; QA-роль теперь работоспособна для T-006.

## Проверка

- `opencode debug agent harness-qa` показывает `modelID: qwen3.8:27b-64k`.
- QA-прогон `ses_e43e52504ffev0LbLrSkUDutZz` (qwen3.8:27b-64k):
  - прочитаны карточка T-004, API-контракт, views/stores/api/tests;
  - `npm run test -- --run` → 10/10 passed;
  - `npm run build` → success, 104 modules, dist/ создан;
  - суммарно 38 837 токенов, `finish=length` отсутствует.
- QA-модель qwen3.8 оказалась медленной: процесс был срезан 15-минутным
  таймаутом до финального текста. Возобновление той же сессии (модель qwen3.8;
  CLI использовал агента build на том же контексте) дало полный вердикт:
  **REJECT**.
- Побочная находка T-004 (medium): `RunButton.vue` не показывает
  пользователю ошибки запуска 409/500 (критерий 3 выполнен частично);
  это отдельная проблема T-004, не проблема QA-роли. T-004 ранее принят
  primary; требуется решение — вернуть T-004 на исправление или завести
  отдельный issue.

## Prevention

- Сверять фактический `num_ctx` (`ollama show`) с `limit.context` в
  `opencode.jsonc`; при расхождении — исправлять конфиг или модель.
- Держать QA-контекст небольшим: точечные чтения, `rg`, краткий вывод.
- Учитывать latency qwen3.8: для QA задавать достаточный таймаут или
  разделять QA на text-приёмку и vision-проверку.
- Не переводить issue в `resolved` без реального QA-прогона; фиксировать
  session ID, модель, токены и `finish`.

## Ссылки

- QA-сессии: `ses_e44984bbeffewKshJm8moo5jN3`, `ses_e449259a4ffe7eJGQCoCbuhds4`,
  `ses_e43e52504ffev0LbLrSkUDutZz`.
- `C:/Users/sergey/.config/opencode/agents/harness-qa.md`.
- `C:/Users/sergey/.config/opencode/opencode.jsonc` (лимиты моделей).
- `harness/process.md` §2, `harness/agents/harness-qa.md`.
- `docs/tasks/T-004-web-vue.md` (Acceptance, Log).
- `docs/issues/README.md`.

## Timeline

- 2026-11-08T14:03:47Z: обнаружено; два прогона оборвались по 32767 токенов.
- 2026-11-08T19:53:31+03:00: QA-модель переключена на qwen3.8:27b-64k,
  выполнен install.ps1.
- 2026-11-08T19:54:00+03:00: исправлены limit.context для vision/64k моделей.
- 2026-11-08T20:00:39+03:00: QA-прогон qwen3.8 прочитал артефакты, тесты 10/10,
  build success; 38 837 токенов, без finish=length.
- 2026-11-08T20:16:03+03:00: получен полный вердикт REJECT (критерий 3 частично);
  issue закрыт, T-004-находка зафиксирована отдельно.
