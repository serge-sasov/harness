# ISSUE-20261111-100017: local-rag sync timed out and left a stale lock

| Field | Value |
|---|---|
| id | ISSUE-20261111-100017 |
| status | workaround |
| severity | minor |
| type | rag |
| detected_at | 2026-11-11T10:00:17.8524821+03:00 |
| source | T-022 |
| role | harness lead |
| location | local-rag_rag_sync (MCP), collection harness |
| environment | OS: Microsoft Windows NT 10.0.26300.0; cwd: C:\study\ai\research\harness |

## Symptoms

rag_sync timed out after 120s; a retry returned 'Sync already running; skipped.' Search still returns new ADR content, but status metadata remains at the previous sync time.

## Reproduction

1. Update many Markdown/HTML files in the `harness` collection.
2. Call `local-rag_rag_sync` for `harness`.
3. The request times out; a second call returns `Sync already running; skipped.`
4. `local-rag_rag_status` still shows the previous `Last sync` timestamp.

## Expected / actual behavior

- Expected: sync completes and updates the file/chunk/metadata state.
- Actual: the client times out and the background run keeps the lock; new content is searchable but status metadata is stale.

## Cause

Embedding/indexing of changed Markdown/HTML exceeds the MCP request timeout; the background run keeps the sync lock after the client times out.

## Solution / workaround

Do not block the task: verify changed content with rag_search, leave the background sync running, and retry rag_sync after it releases the lock.

## Verification

rag_search found docs/architecture/adr-002-harness-e2e-ux-checkpoints.md and contracts; doctor and task verification are unaffected. Sync lock still present at the time of recording.

## Prevention / follow-up

Raise the MCP sync timeout or make rag_sync return a job ID and expose progress; add a smoke-test check for stale sync locks.

## Links

docs/description/README.md, docs/architecture/adr-002-harness-e2e-ux-checkpoints.md, T-022

## Timeline

- 2026-11-11T10:00:17.8524821+03:00: detected
- 2026-11-11T10:58:00+03:00: reproduced after the 2.2.0 docs/diagram update; MCP sync timed out again, status still shows the previous sync.
