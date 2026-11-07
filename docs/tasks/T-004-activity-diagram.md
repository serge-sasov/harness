# T-004: Диаграмма активности

| Поле | Значение |
|---|---|
| id | T-004 |
| title | PlantUML activity-диаграмма задач с зависимостями и цветовыми статусами |
| role | orchestrator |
| status | pending |
| depends_on | T-003 |
| artifacts | `docs/activity.puml`, `docs/activity.svg` |
| commit | — |

## Acceptance

- [ ] `docs/activity.puml` — валидный PlantUML (`check_syntax` без ошибок).
- [ ] На диаграмме все задачи T-001..T-013, отражены последовательность и зависимости (fork/ветвления для независимых задач).
- [ ] Цвета: done `#90EE90`, pending `#D3D3D3`, in_progress `#FFE082`, failed `#FF9090`, blocked `#FFB347`.
- [ ] `docs/activity.svg` отрендерен через MCP `plantuml-render`.

## Log

- 2026-11-07: задача создана.
