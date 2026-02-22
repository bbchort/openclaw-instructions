# Быстрый старт (после прочтения README)

1. **Установка:** `curl -fsSL https://openclaw.ai/install.sh | bash`
2. **Codex:** `openclaw onboard --auth-choice openai-codex` (в TTY, войти в OpenAI в браузере).
3. **Gateway:** `openclaw gateway` → открыть http://127.0.0.1:18789/?token=$(openclaw config get gateway.auth.token)
4. **Telegram:** `openclaw channels add --channel telegram --token 'BOT_TOKEN'`  
   Чтобы все могли писать: `openclaw config set channels.telegram.allowFrom '["*"]'` и `openclaw config set channels.telegram.dmPolicy open` → перезапуск gateway.
5. **Перезапуск gateway:** `openclaw gateway --force` или Ctrl+C и снова `openclaw gateway`.

Подробности и нюансы — в [README.md](README.md).
