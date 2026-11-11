# UX specification: <scope>

| Field | Value |
|---|---|
| Task | T-XXX |
| Role | ux-designer |
| Source requirements | `docs/analysis/requirements-<slug>.md` |
| Source use cases | `docs/analysis/e2e-use-cases-<slug>.md` |
| Prototype | `docs/ux/prototype/<slug>/index.html` |
| Wireframes | `docs/ux/wireframes-<slug>.puml`, `.svg` |
| Status | draft |

## 1. Personas and goals

| Persona | Goal | Key scenarios |
|---|---|---|
| <persona> | <goal> | UC-E2E-001 |

## 2. User flows

| Flow | Steps | Screens | Use cases |
|---|---|---|---|
| UF-01 | <step> -> <step> | SCR-01, SCR-02 | UC-E2E-001 |

## 3. Screen inventory

| Screen | Purpose | Entry points | States |
|---|---|---|---|
| SCR-01 | <purpose> | <navigation> | empty / loading / success / error |

## 4. Wireframes

- PlantUML Salt source: `docs/ux/wireframes-<slug>.puml`.
- Rendered SVG: `docs/ux/wireframes-<slug>.svg`.
- Every screen in the inventory has a wireframe; states that affect layout are shown.

## 5. Interaction specification

| Component | Behavior | Validation | Error / empty state |
|---|---|---|---|
| <component> | <interaction> | <rules> | <message> |

## 6. Accessibility and UI copy

- Semantic structure, labels, focus order, keyboard access.
- Contrast and text alternatives for non-text content.
- UI copy: titles, buttons, validation and error messages.

## 7. Design tokens and responsive rules

| Token | Value | Usage |
|---|---|---|
| <token> | <value> | <usage> |

- Breakpoints: <list>.
- Layout constraints: <list>.

## 8. Traceability

| Use case | Screens | Components | Prototype route |
|---|---|---|---|
| UC-E2E-001 | SCR-01 | <component> | `index.html#scr-01` |

## 9. Open questions

| ID | Question | Assumption |
|---|---|---|
| Q-UX-001 | <question> | <assumption> |
