# T-008: Sub-agent coder

| Поле | Значение |
|---|---|
| id | T-008 |
| title | Ролевой sub-agent `coder` (реализация, тесты, CI/CD) |
| role | coder |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/coder.md` |
| commit | записан в T-009 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/tiel-coder:35b-a3b-mtp-128k-text`, `temperature: 0.1`.
- [x] Permission: по образцу `local-coder.md` (whitelist build/test/lint, deny push/commit/rm), edit только `src/`, `tests/`, `scripts/`, `Dockerfile`, `Makefile`, `docs/tasks/**`.
- [x] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [x] Определены вход (ADR/контракты) и выход (код, тесты, отчёт).

## Log

- 2026-11-07: создан `harness/agents/coder.md` (whitelist bash, зона записи, правила тестов/CI, запреты).
