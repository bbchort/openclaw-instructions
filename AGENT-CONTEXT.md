# Контекст для нового агента: что уже сделано с OpenClaw и окружением

**Прочитай этот файл в новом чате**, чтобы быть в курсе всей настройки, репозиториев, правил и типичных починок.

---

## 1. Репозитории и правила (обязательно)

### openclaw-instructions (главный репо с инструкциями)
- **URL:** https://github.com/bbchort/openclaw-instructions  
- **Локально:** `~/.cursor/openclaw-instructions` (или `/root/.cursor/openclaw-instructions`)
- **Правило:** при любой **настройке или починке** OpenClaw — коммитить и пушить изменения в этот репо и **обновлять README** (и при необходимости QUICK.md). Не коммитить секреты, только описание шагов.
- **Правило лежит в:** `.cursor/rules/openclaw-instructions-sync.mdc` (alwaysApply: true)

### openclaw-project (приватный проект)
- **Локально:** `~/.cursor/openclaw-project`  
- **Remote:** `git@github.com:bbchort/openclaw-project.git`  
- Используется для скриптов создания репо и прочего кода проекта; основной источник правды по «как настроить и чинить» — **openclaw-instructions**.

### GitHub: создание репозиториев
- **Правило:** создавать репо **только программно**, не просить пользователя идти на github.com/new.
- **Как:** если `gh auth status` успешен (пользователь bbchort) — `gh repo create <name> --public|--private --source=<path> --remote=origin --push`. Иначе — токен из `GH_TOKEN` / `GITHUB_TOKEN` или `~/.cursor/secrets/github-token`.
- **Правило в:** `.cursor/rules/github-repo-create.mdc`

---

## 2. OpenClaw: что установлено и как устроено

- **Установка:** через `curl -fsSL https://openclaw.ai/install.sh | bash` (ставит Node.js при необходимости и пакет OpenClaw).
- **Конфиг:** `~/.openclaw/openclaw.json`  
  Ключевые места: `gateway` (port 18789, auth token), `agents.defaults` (model, workspace, contextTokens), `channels.telegram`, `auth.profiles`, `models.providers`.
- **Gateway:** запускается как **systemd user service** `openclaw-gateway.service`. Перезапуск: `systemctl --user restart openclaw-gateway.service` или `openclaw gateway --force`.
- **Dashboard:** http://127.0.0.1:18789/ — для входа подставлять токен в URL: `?token=<gateway.auth.token>` (значение: `openclaw config get gateway.auth.token`).

### Модели и авторизация
- **Codex (OpenAI):** подключён через OAuth. Важно: команда `openclaw models auth login --provider openai-codex` даёт «No provider plugins found» — Codex подключается только через **`openclaw onboard --auth-choice openai-codex`** (в TTY).
- В конфиге есть провайдеры: **openai-codex** (модели gpt-5.3-codex, o4-mini и др.), **minimax**, **kimi-coding**. Основная модель по умолчанию — **openai-codex/gpt-5.3-codex**; фоллбэки заданы в `agents.defaults.model` (primary + fallbacks). Смена модели: правка `agents.defaults.model.primary` в `~/.openclaw/openclaw.json` и добавление новой модели в `models.providers.openai-codex.models` при необходимости, затем перезапуск gateway.
- Для кастомного провайдера в `models.providers.<id>.api` допустимы только: `openai-completions`, `openai-responses`, `anthropic-messages`, `google-generative-ai`, `github-copilot`, `bedrock-converse-stream`, `ollama`. **Не** `chat_completions` — из‑за этого конфиг становился невалидным и gateway падал.

### Удалённый браузер (OpenClaw на VPS + браузер на ПК пользователя)
- На ПК пользователя: SSH-туннель `-L 18789:127.0.0.1:18789` до VPS, затем `openclaw node run --host 127.0.0.1 --port 18789` и переменная `OPENCLAW_GATEWAY_TOKEN`. Chrome с расширением OpenClaw (relay порт 18792). Подробно: раздел 8 в README openclaw-instructions.

### Telegram
- Один бот (аккаунт default), токен в `channels.telegram.botToken`.
- Чтобы бот отвечал всем в личку: `dmPolicy: "open"` и `allowFrom: ["*"]`. Иначе при `pairing` нужно одобрять отправителей.
- Смена бота: `openclaw channels remove --channel telegram --delete`, затем `openclaw channels add --channel telegram --token 'NEW_TOKEN'`, перезапуск gateway.

---

## 3. Что уже чинили и как

1. **«No provider plugins found»** при `openclaw models auth login --provider openai-codex`  
   Решение: использовать **`openclaw onboard --auth-choice openai-codex`**, не `models auth login`.

2. **Бот в Telegram не отвечает**  
   Решение: выставить `dmPolicy: "open"` и `allowFrom: ["*"]` (и перезапустить gateway). Либо одобрить отправителя через pairing.

3. **«gateway token missing» в браузере**  
   Решение: открывать Dashboard с токеном в URL: `http://127.0.0.1:18789/?token=<gateway.auth.token>`.

4. **Пишет, пишет — ответы не приходят или пропадают**  
   Причина: переполнен контекст сессии (в `openclaw status` видно высокий % токенов). Решение: в Telegram отправить боту **`/new`** или **`/reset`**; в Dashboard — «New session». Дополнительно выставляли `agents.defaults.contextTokens: 200000`.

5. **Конфиг невалидный: `models.providers.openai-codex.api: Invalid input`**  
   Причина: в конфиге было `"api": "chat_completions"`. Решение: заменить на **`"api": "openai-completions"`** в `~/.openclaw/openclaw.json`, перезапустить gateway.

6. **Gateway не поднимается / unreachable**  
   Проверить валидность конфига (`openclaw doctor`), при необходимости исправить `api` и другие поля по схеме. Перезапустить: `systemctl --user restart openclaw-gateway.service`.

7. **Переключить ассистента на GPT-5.3 Codex вместо o4-mini**  
   В `~/.openclaw/openclaw.json`: добавить модель `gpt-5.3-codex` в `models.providers.openai-codex.models` (по образцу o4-mini), выставить `agents.defaults.model.primary` в `openai-codex/gpt-5.3-codex`, при желании добавить o4-mini в `fallbacks`. Перезапустить gateway.

---

## 4. Полезные команды

| Действие | Команда |
|----------|--------|
| Статус | `openclaw status` |
| Модели/авторизация | `openclaw models status` |
| Каналы | `openclaw channels status` |
| Токен gateway | `openclaw config get gateway.auth.token` |
| Перезапуск gateway | `systemctl --user restart openclaw-gateway.service` или `openclaw gateway --force` |
| Проверка конфига | `openclaw doctor` |
| Логи | `openclaw logs --follow` |

---

## 5. Где что лежит

- **Полная инструкция по установке и починке:** репозиторий **openclaw-instructions**, файл **README.md** (и QUICK.md).
- **Правила для агента:** `.cursor/rules/` — в т.ч. `openclaw-instructions-sync.mdc`, `github-repo-create.mdc`.
- **Конфиг OpenClaw:** `~/.openclaw/openclaw.json`; учётные данные агента — `~/.openclaw/agents/main/agent/auth-profiles.json`; сессии — `~/.openclaw/agents/main/sessions/`.

---

## 6. Что делать в новом чате

1. Прочитать этот файл (или вставить его содержимое в чат).
2. При любых настройках/починках OpenClaw — обновлять **openclaw-instructions** (README и при необходимости другие файлы) и пушить.
3. Репозитории создавать программно через `gh` (или токен), не просить пользователя создавать репо вручную.
4. При проблемах с конфигом проверять допустимые значения `api` и другие поля по документации/схеме OpenClaw; при переполнении контекста напоминать про `/new` и при необходимости лимит `contextTokens`.
