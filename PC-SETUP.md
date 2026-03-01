# Подключение ПК к OpenClaw на сервере (управление браузером с VPS)

Серверная часть уже настроена. Инструкция для шагов **на твоём ПК**.

**Полная инструкция с токеном** лежит на сервере (после настройки можно открыть и копировать оттуда):
```bash
cat ~/.openclaw/workspace/OPENCLAW-PC-SETUP.md
```
Токен также можно взять на сервере: `openclaw config get gateway.auth.token`.

---

## Кратко: что сделать на ПК

1. **Установить OpenClaw CLI:** `curl -fsSL https://openclaw.ai/install.sh | bash`

2. **SSH-туннель** (порт 18790 если 18789 занят):
   ```bash
   ssh -N -L 18790:127.0.0.1:18789 USER@VPS_IP
   ```

3. **Node host** (в новом терминале):
   ```bash
   export OPENCLAW_GATEWAY_TOKEN="<токен с сервера>"
   openclaw node run --host 127.0.0.1 --port 18790
   ```

4. **На сервере один раз:** `openclaw devices list` → `openclaw devices approve <request_id>`

5. **Chrome-расширение:** `openclaw browser extension install`, загрузить в Chrome, в Options указать токен и Port (18793 при туннеле на 18790).

Подробные шаги и точные команды — в файле на сервере `~/.openclaw/workspace/OPENCLAW-PC-SETUP.md`.
