# Requirements: pilot "Mini-CRUD service" (T-013)

| Field | Value |
|---|---|
| Task | T-013 |
| Role | analyst |
| Status | accepted (pilot) |
| Source | `requirements/initial.txt` (pilot harness check) |

## Context

Pilot service for a full harness cycle: note management via REST API, local
storage, local Docker run. External integrations and authentication are out of scope.

## Functional requirements

| ID | Requirement |
|---|---|
| R-001 | Create a note: `POST /notes` with `title`, `body`; response 201 with `id`. |
| R-002 | List notes: `GET /notes` - array of notes, sorted by `created_at` descending. |
| R-003 | Read one: `GET /notes/{id}`; 404 if missing. |
| R-004 | Update: `PUT /notes/{id}` with `title`, `body`; 404 if missing. |
| R-005 | Delete: `DELETE /notes/{id}`; 204 on success, 404 if missing. |
| R-006 | Validation: `title` 1..200 characters, `body` up to 10000; error 422. |

## Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 | Local run: `docker compose up` starts the service on port 8080. |
| NFR-2 | Storage: SQLite file in a volume; survives container restart. |
| NFR-3 | Tests: unit + API tests, deterministic, no network. |

## Constraints and assumptions

- Single user, no auth (out of scope).
- The architect chooses the language/stack (ADR required with alternatives).

## Open questions

| ID | Question | Pilot assumption |
|---|---|---|
| Q-001 | Is list pagination needed? | No, up to 1000 notes |
| Q-002 | Is full-text search needed? | No, out of scope |

## Risks

- R1: SQLite file growth at large volumes - not critical for the pilot.
- R2: no auth - service is local/staging only.
