---
description: "Check the global harness installation and the current project"
agent: build
---

Check the harness state.

1. Verify that the global installation exists: `~/.config/opencode/agents/harness.md`, `~/.config/opencode/commands/harness-run.md`, `~/.config/opencode/skills/harness/SKILL.md`, `~/.config/opencode/harness/scripts/doctor.ps1`. If anything is missing, report that a global installation is required.
2. Run via the bash tool (with user confirmation):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/harness/scripts/doctor.ps1"
   ```

3. Show the output and list actions to fix warnings.
