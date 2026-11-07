# T-009: Sub-agent qa

| Поле | Значение |
|---|---|
| id | T-009 |
| title | Ролевой sub-agent `qa` (ревью кода/схем, тесты) |
| role | qa |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/qa.md` |
| commit | записан в T-010 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/tiel-coder:35b-a3b-mtp-128k-vision`, `temperature: 0.1`.
- [x] Permission: edit только `docs/qa/**` и `docs/tasks/**`; read — весь проект; bash read-only (git status/diff/log, test-раннеры); `task: deny`.
- [x] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [x] Vision-сценарий: чтение PlantUML/SVG/скриншотов для проверки схем.
- [x] Право вердикта: `accept` / `reject` с обязательным списком замечаний.

## Log

- 2026-11-07: создан `harness/agents/qa.md` (ревью, vision-проверка схем, вердикт accept/reject, severity).
