# T-004: Диаграмма активности

| Поле | Значение |
|---|---|
| id | T-004 |
| title | PlantUML activity-диаграмма задач с зависимостями и цветовыми статусами |
| role | orchestrator |
| status | done |
| depends_on | T-003 |
| artifacts | `docs/activity.puml`, `docs/activity.svg` |
| commit | 1ede40d |

## Acceptance

- [x] `docs/activity.puml` — валидный PlantUML (`check_syntax` без ошибок).
- [x] На диаграмме все задачи T-001..T-013, отражены последовательность и зависимости (fork/ветвления для независимых задач).
- [x] Цвета: done `#90EE90`, pending `#D3D3D3`, in_progress `#FFE082`, failed `#FF9090`, blocked `#FFB347`.
- [x] `docs/activity.svg` отрендерен через MCP `plantuml-render`.

## Log

- 2026-11-07: создан `docs/activity.puml` (все 13 задач, fork-ветки T-003/T-004 и T-005→T-006..T-011, легенда цветов); `check_syntax` — valid; отрендерен `docs/activity.svg` (19740 байт).
