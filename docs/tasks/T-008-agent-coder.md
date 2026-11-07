# T-008: Sub-agent coder

| Поле | Значение |
|---|---|
| id | T-008 |
| title | Ролевой sub-agent `coder` (реализация, тесты, CI/CD) |
| role | coder |
| status | pending |
| depends_on | T-005 |
| artifacts | `harness/agents/coder.md` |
| commit | — |

## Acceptance

- [ ] Frontmatter: `mode: subagent`, `model: ollama-metrics/tiel-coder:35b-a3b-mtp-128k-text`, `temperature: 0.1`.
- [ ] Permission: по образцу `local-coder.md` (whitelist build/test/lint, deny push/commit/rm), edit только `src/`, `tests/`, `scripts/`, `Dockerfile`, `Makefile`, `docs/tasks/**`.
- [ ] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [ ] Определены вход (ADR/контракты) и выход (код, тесты, отчёт).

## Log

- 2026-11-07: задача создана.
