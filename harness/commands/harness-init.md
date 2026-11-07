---
description: "Инициализация harness в текущем проекте (глобальная установка уже выполнена)"
agent: build
---

Инициализируй harness в текущем проекте.

1. Проверь, что глобальная установка существует:
   `~/.config/opencode/agents/harness.md` и
   `~/.config/opencode/harness/scripts/init.ps1`.
   Если их нет — остановись и сообщи, что сначала нужно выполнить глобальную
   установку harness (`harness/scripts/install.ps1`).
2. Запусти через bash-инструмент (с подтверждением пользователя):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/harness/scripts/init.ps1"
   ```

3. Покажи вывод скрипта и следующие шаги: заполнить `docs/plan.md`, создать
   карточку задачи по `harness/templates/task-card.md`, запустить
   `/harness-run T-XXX`.
4. Не используй harness-агента и не создавай board вручную.
