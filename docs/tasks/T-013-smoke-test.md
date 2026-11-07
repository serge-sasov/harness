# T-013: Smoke-test полного цикла

| Поле | Значение |
|---|---|
| id | T-013 |
| title | Прогон полного цикла на пилотной задаче |
| role | qa |
| status | pending |
| depends_on | T-012 |
| artifacts | `docs/analysis/`, `docs/architecture/`, `docs/qa/` (пилот) |
| commit | — |

## Acceptance

- [ ] Аналитик формирует `docs/analysis/pilot-requirements.md` по пилотной задаче («Мини-CRUD сервис»).
- [ ] Архитектор формирует `docs/architecture/pilot-adr.md` + `docs/architecture/pilot-components.puml` (валидный, рендерится).
- [ ] QA оформляет `docs/qa/pilot-review.md` с вердиктом accept/reject.
- [ ] Board и activity-диаграмма обновлены по итогам цикла; коммит сделан.
- [ ] Проверено, что ролевые промпты достаточно детерминированы (результат соответствует acceptance).

## Log

- 2026-11-07: задача создана.
