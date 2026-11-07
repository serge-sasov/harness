# T-001: Git bootstrap

| Поле | Значение |
|---|---|
| id | T-001 |
| title | Git bootstrap: `git init`, `.gitignore`, README |
| role | orchestrator |
| status | done |
| depends_on | — |
| artifacts | `.gitignore`, `README.md` |
| commit | 2a19b33 |

## Acceptance

- [x] `git init` выполнен, ветка `master`.
- [x] `.gitignore` исключает секреты (`.env`, `*.pem`, `*.key`) и мусор ОС.
- [x] `README.md` описывает состав harness, модели ролей и жизненный цикл задачи.
- [x] Первый коммит `chore: bootstrap repo (T-001)`.

## Log

- 2026-11-07: созданы `.gitignore`, `README.md`; `git init`; коммит `2a19b33`.
