# ISSUE-20261107-231419: Global task deny blocked harness subagents

| Поле | Значение |
|---|---|
| id | ISSUE-20261107-231419 |
| status | resolved |
| severity | blocker |
| type | permission |
| detected_at | 2026-11-07T23:14:19.1723574+03:00 |
| source | global harness |
| role | build |
| location | C:/Users/sergey/.config/opencode/opencode.jsonc: permission.task |
| environment | OS: Microsoft Windows NT 10.0.26300.0; cwd: C:\study\ai\research\analytic |

## Симптомы

build could not call harness-analyst or harness-orchestrator; task permission denied

## Воспроизведение

1. Открыть harness-проект в primary-агенте `build`.
2. Вызвать `task` с `subagent_type: harness-analyst` (или `harness-orchestrator`).
3. Получить `task` permission denied.

## Ожидаемое / фактическое поведение

- Ожидалось: `build` может явно вызвать harness-роль для T-001.
- Фактически: глобальный `permission.task` deny блокировал все harness-роли.

## Причина

install.ps1 added a global permission.task deny for harness roles; agent-specific allow existed only in harness lead

## Решение / workaround

migrate permission.task to allow for harness-* roles; install/doctor updated

## Проверка

opencode debug agent build shows allow for all harness roles; doctor passes

## Предупреждение / follow-up

any primary may explicitly call harness roles; keep marker and explicit /harness-* activation; roles keep task deny

## Ссылки

commit 6d547b0; docs/guides/harness-global.md

## Timeline

- 2026-11-07T23:14:19.1723574+03:00: обнаружено
- 2026-11-07T23:15:00+03:00: причина — глобальный deny в permission.task
- 2026-11-07T23:25:00+03:00: deny заменён на allow, install/doctor обновлены
- 2026-11-07T23:26:00+03:00: проверено через `opencode debug agent build`
