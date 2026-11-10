# T-001: Git bootstrap

| Field | Value |
|---|---|
| id | T-001 |
| title | Git bootstrap: `git init`, `.gitignore`, README |
| role | orchestrator |
| status | done |
| depends_on | - |
| artifacts | `.gitignore`, `README.md` |
| commit | 2a19b33 |

## Acceptance

- [x] `git init` completed; branch `master`.
- [x] `.gitignore` excludes secrets (`.env`, `*.pem`, `*.key`) and OS junk.
- [x] `README.md` describes the harness layout, role models, and task lifecycle.
- [x] First commit `chore: bootstrap repo (T-001)`.

## Log

- 2026-11-07: created `.gitignore`, `README.md`; `git init`; commit `2a19b33`.
