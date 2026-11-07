---
description: "Проверка глобальной установки harness и текущего проекта"
agent: build
---

Проверь состояние harness.

1. Убедись, что существует глобальная установка:
   `~/.config/opencode/agents/harness.md`,
   `~/.config/opencode/commands/harness-run.md`,
   `~/.config/opencode/skills/harness/SKILL.md`,
   `~/.config/opencode/harness/scripts/doctor.ps1`.
   Если чего-то нет — сообщи, что нужна глобальная установка.
2. Запусти через bash-инструмент (с подтверждением пользователя):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/harness/scripts/doctor.ps1"
   ```

3. Покажи вывод и перечисли действия для исправления предупреждений.
