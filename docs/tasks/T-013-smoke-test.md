# T-013: Smoke-test полного цикла

| Поле | Значение |
|---|---|
| id | T-013 |
| title | Прогон полного цикла на пилотной задаче |
| role | qa |
| status | done |
| depends_on | T-012 |
| artifacts | `docs/analysis/`, `docs/architecture/`, `docs/qa/` (пилот) |
| commit | fb145b6 |

## Acceptance

- [x] Аналитик формирует `docs/analysis/pilot-requirements.md` по пилотной задаче («Мини-CRUD сервис»).
- [x] Архитектор формирует `docs/architecture/pilot-adr.md` + `docs/architecture/pilot-components.puml` (валидный, рендерится).
- [x] QA оформляет `docs/qa/pilot-review.md` с вердиктом accept/reject.
- [x] Board и activity-диаграмма обновлены по итогам цикла; коммит сделан.
- [x] Проверено, что ролевые промпты достаточно детерминированы (результат соответствует acceptance).

## Log

- 2026-11-07: роли исполнены по промптам `harness/agents/*.md`; созданы требования (R-001..R-006, NFR-1..3), ADR-001 с альтернативами, компонентная схема (SVG отрендерен), QA-ревью с вердиктом `accept` (2 minor-замечания).
- 2026-11-07: агенты зарегистрированы проектно в `.opencode/agents/` (копии из `harness/agents/`); фактический вызов sub-agent'ов доступен после рестарта opencode — в текущей сессии роли исполнены по тем же промптам.
- 2026-11-07 (global harness): роли перенесены в глобальную установку `harness-*`; проектные копии `.opencode/agents/` удалены, чтобы не дублировать ID и не обходить permission-gating.
