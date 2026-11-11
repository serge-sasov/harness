---
description: "Initialize harness in the current project (global installation must already exist)"
agent: build
---

Initialize harness in the current project.

1. Verify that the global installation exists: `~/.config/opencode/agents/harness.md` and `~/.config/opencode/harness/scripts/init.ps1`. If not, stop and report that the global harness installation must be performed first (`harness/scripts/install.ps1`).
2. Run via the bash tool (with user confirmation):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/harness/scripts/init.ps1"
   ```

3. Show the script output and the next steps:
   - start a feature with `/harness-feature <slug> [e2e] [ux]`;
   - register a bug with `/harness-bug <report or BUG-XXX>`;
   - run a task with `/harness-run T-XXX`, review its checkpoint, then resume.
   Cards use `harness/templates/task-card-feature.md` or
   `harness/templates/task-card-bugfix.md`; product bugs live in
   `docs/bugs/`, harness problems in `docs/issues/`.
4. Do not use the harness agent and do not create the board manually.
