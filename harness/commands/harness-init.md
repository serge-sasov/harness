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

3. Show the script output and the next steps: fill `docs/plan.md`, create a task card from `harness/templates/task-card.md`, run `/harness-run T-XXX`.
4. Do not use the harness agent and do not create the board manually.
