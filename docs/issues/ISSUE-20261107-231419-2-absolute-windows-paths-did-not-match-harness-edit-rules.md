# ISSUE-20261107-231419-2: Absolute Windows paths did not match harness edit rules

| Поле | Значение |
|---|---|
| id | ISSUE-20261107-231419-2 |
| status | resolved |
| severity | major |
| type | path |
| detected_at | 2026-11-07T23:14:19.4276040+03:00 |
| source | global harness |
| role | build |
| location | C:/study/ai/research/analytic/harness/agents/harness-*.md; opencode permission edit |
| environment | OS: Microsoft Windows NT 10.0.26300.0; cwd: C:\study\ai\research\analytic |

## Симптомы

edit docs/plan.md and .gitignore was blocked; relative docs/** did not match C:/...; .gitignore had no allow

## Воспроизведение

1. Открыть проект с абсолютным путём `C:\study\...\Qwen 3.8 27B Q4_K_M`.
2. Роль с зоной `docs/**` пытается редактировать `docs/plan.md`.
3. Относительный шаблон `docs/**` не совпадает; срабатывает blanket deny. Для `.gitignore` allow отсутствует.

## Ожидаемое / фактическое поведение

- Ожидалось: роль редактирует файлы своей зоны по абсолютному пути.
- Фактически: edit/write заблокированы, включая `.gitignore`.

## Причина

opencode matches edit/write against absolute path; relative docs/** did not match; .gitignore was outside role zones

## Решение / workaround

added **/docs/**, **/README.md, **/.gitignore and role-specific **/... allows; .gitignore allowed for orchestrator/coder

## Проверка

opencode debug agent shows allow; doctor passes; docs/plan.md edit path resolved

## Предупреждение / follow-up

keep absolute **/... variants in role permissions; use absolute location in issue records

## Ссылки

commits e943761, 6d547b0; docs/guides/harness-global.md

## Timeline

- 2026-11-07T23:14:19.4276040+03:00: обнаружено
- 2026-11-07T23:18:00+03:00: причина — сопоставление с абсолютным путём
- 2026-11-07T23:20:00+03:00: добавлены `**/...` allow-паттерны и `.gitignore`
- 2026-11-07T23:26:00+03:00: проверено через `opencode debug agent`
