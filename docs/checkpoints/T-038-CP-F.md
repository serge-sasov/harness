# T-038 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-038 |
| checkpoint | CP-F |
| stage | implementation |
| status | approved |
| date | 2026-11-14 |
| reviewer | user |
| role | coder |
| checks | n/a (harness core; product stage registry not applicable) |

## Scope

All task artifacts of T-038 (chunk ledger and tooling) against the card
acceptance list.

## Acceptance closure

| Criterion | Evidence |
|---|---|
| Validator rejects every listed defect | 12 self-test cases green; each error has a stable code and a precise message |
| Validator supports `--json` and `--self-test` | implemented; output verified in the sandbox run |
| `chunk.ps1` implements all actions | `init`, `add`, `plan`, `claim`, `complete`, `fail`, `list`, `show`, `status`, `usage`, `verify` verified |
| Ledger schema documented in a template | `harness/templates/chunk-ledger.md` with field tables, state machine, example, brief |
| `stage-done.ps1 -Chunk` | gate verified (refused `C1=failed`), produced files hashed, `## Chunks` recorded |
| `measure-tokens.ps1` per-chunk attribution | `-ByChunk` verified against the live opencode database |
| `init.ps1` creates `docs/chunks/` | directory list extended; verified by reading the script |
| Self-tests / executable examples green | 12/12 validator cases, sandbox end-to-end runs, parser check |

## Residual risk

- `owns` overlap uses a witness-based glob intersection. It is exact for the
  nested-prefix patterns the harness uses and may be conservative for unusual
  patterns such as `**/x/*.py` against `a/*/x/**`; the validator reports them as
  overlapping, which fails safe.
- Permission wiring for the pilot roles is handled in T-040; until then the roles
  see a bash `ask` prompt for the new scripts.

## User decision

- approved: accept T-038.
