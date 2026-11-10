# ADR-001: Stack and structure of the pilot "Mini-CRUD service"

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-11-07 |
| Task | T-013 |
| Related ADRs | - |

## Context

Requirements in `docs/analysis/pilot-requirements.md` (R-001..R-006, NFR-1..3):
REST CRUD for notes, SQLite, local Docker run, deterministic tests. One service,
no auth, no external integrations.

## Decision

Python 3.12 + FastAPI + SQLAlchemy 2.x (SQLite) + Pydantic v2.
Structure: thin API layer -> service layer (domain) -> repository (SQLite).
Tests: pytest + httpx (ASGI transport). Container: python:3.12-slim,
docker compose with a volume for the DB file.

## Alternatives

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Flask + SQLite | simpler, lightweight | manual validation, less typing | FastAPI provides validation out of the box |
| Node/Express + better-sqlite3 | fast start | second stack in the environment | Python stack is already used locally |
| Django + DRF | batteries included | overkill for one CRUD | exceeds pilot requirements |

## Consequences

- Positive: minimal code, OpenAPI autodoc, typed contracts.
- Negative/risks: SQLite is not for concurrent writes - accepted for the pilot.
- Changes: `src/`, `tests/`, `Dockerfile`, `docker-compose.yml`.

## Contracts and diagrams

- Component diagram: `docs/architecture/pilot-components.puml` (SVG next to it).
- REST contract:

| Method | Path | Body | Response |
|---|---|---|---|
| POST | `/notes` | `{title, body}` | 201 `{id, title, body, created_at}` |
| GET | `/notes` | - | 200 `[...]` |
| GET | `/notes/{id}` | - | 200 / 404 |
| PUT | `/notes/{id}` | `{title, body}` | 200 / 404 |
| DELETE | `/notes/{id}` | - | 204 / 404 |

- Errors: `{"detail": "..."}`; validation - 422 (Pydantic).
