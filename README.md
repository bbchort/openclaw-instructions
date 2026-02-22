# OpenClaw Agent: полная инструкция по установке и запуску

Документ описывает всё, что сделано при развёртывании персонального агента OpenClaw: установка, Codex OAuth, Telegram-бот, Gateway, тонкости и команды. Прочитав его, можно восстановить или повторить настройку с нуля или понять текущее состояние.

**Этот репозиторий — единый источник правды по настройке:** при любой настройке или починке OpenClaw инструкции здесь коммитятся и обновляются (в т.ч. README), чтобы актуальность сохранялась.

---

## 1. Что такое OpenClaw и зачем это

- **OpenClaw** — открытый персональный AI-агент: чат, навыки, каналы (Telegram, WhatsApp и др.), работа с моделями (Codex, Claude и т.д.).
- Сайт: https://openclaw.ai/
- Документация: https://docs.openclaw.ai/
- Агент запускается на твоей машине (или сервере), данные и конфиг хранятся локально (`~/.openclaw/`).

---

## 2. Установка OpenClaw

### 2.1 Требования

- **Node.js 22.12+** (установщик может поставить сам).
- **Git**, **curl** (обычно уже есть на Linux/macOS).

### 2.2 Однострочная установка

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

Скрипт ставит Node.js (если нет), затем пакет OpenClaw. В конце может быть интерактивный шаг — если терминал без TTY, он упадёт с ошибкой про `/dev/tty`; это нормально, CLI уже установлен.

### 2.3 Проверка

```bash
openclaw --version
node -v   # ожидается v22.x
```

---

## 3. Первичная настройка (onboard)

### 3.1 Базовая конфигурация без TTY

Если нет интерактивного терминала:

```bash
openclaw config set gateway.mode local
mkdir -p ~/.openclaw/agents/main/sessions ~/.openclaw/credentials
openclaw onboard --non-interactive --accept-risk --skip-channels --skip-skills --skip-daemon --skip-ui --flow quickstart
```

После этого в `~/.openclaw/openclaw.json` появятся `gateway`, `agents.defaults.workspace` и т.д.

### 3.2 Важно про Codex и `models auth login`

Команда **`openclaw models auth login --provider openai-codex`** в стандартной установке даёт ошибку **"No provider plugins found"**: провайдер Codex встроен в мастер onboard, а не в отдельный плагин.

**Подключать Codex нужно так:**

```bash
openclaw onboard --auth-choice openai-codex
```

- Нужен **терминал с TTY** (чтобы открыть браузер или вставить URL).
- Откроется браузер (или будет выдан URL) → вход в OpenAI/ChatGPT → при необходимости вставь **полный redirect URL** (с `code=` и `state=`) в терминал.
- После успеха профиль сохранится в `~/.openclaw/agents/main/agent/auth-profiles.json`, модель по умолчанию — `openai-codex/gpt-5.3-codex`.

Проверка:

```bash
openclaw models status
```

Должен быть провайдер `openai-codex` и строка про OAuth/профиль.

---

## 4. Gateway (веб-панель и API)

### 4.1 Запуск

```bash
openclaw gateway
```

Обычно слушает порт **18789**. Dashboard: **http://127.0.0.1:18789/** (или http://localhost:18789/).

### 4.2 Токен доступа к Dashboard

По умолчанию включена авторизация по токену. Токен хранится в конфиге:

```bash
openclaw config get gateway.auth.token
```

Чтобы открыть Dashboard **без ручного ввода токена**, открой в браузере:

```
http://127.0.0.1:18789/?token=<значение gateway.auth.token>
```

Токен сохранится в браузере (localStorage), дальше можно заходить по обычному URL.

Если видишь ошибку **"gateway token missing"** или **"unauthorized"** — подставь токен в URL выше или введите его в настройках подключения в интерфейсе (Settings / Connection / Auth).

### 4.3 Перезапуск gateway

- Если gateway запущен **вручную** в терминале: **Ctrl+C**, затем снова `openclaw gateway`.
- Из другого терминала (убить процесс на порту и запустить заново):

  ```bash
  openclaw gateway --force
  ```

- Если gateway установлен как **сервис** (systemd/launchd):

  ```bash
  openclaw gateway restart
  ```

После смены конфига (например, Telegram или Codex) gateway нужно перезапустить.

---

## 5. Telegram-бот

### 5.1 Добавление бота

Токен бота берётся у [@BotFather](https://t.me/BotFather). Затем:

```bash
openclaw channels add --channel telegram --token 'ТВОЙ_ТОКЕН_БОТА'
```

Аккаунт будет называться `default`, токен записывается в `~/.openclaw/openclaw.json` в `channels.telegram.botToken`.

### 5.2 Смена токена (новый бот)

Сначала удалить старый аккаунт, потом добавить новый:

```bash
openclaw channels remove --channel telegram --delete
openclaw channels add --channel telegram --token 'НОВЫЙ_ТОКЕН'
```

После этого перезапусти gateway.

### 5.3 Чтобы бот отвечал всем в личку (без pairing)

По умолчанию для личных сообщений включён **pairing**: первый отправитель должен быть одобрен (код в Telegram + `openclaw pairing approve telegram <CODE>`). Пока не одобрен — бот не обрабатывает сообщения.

Чтобы **все могли писать** без одобрения:

```bash
openclaw config set channels.telegram.allowFrom '["*"]'
openclaw config set channels.telegram.dmPolicy open
```

Для `dmPolicy: "open"` в конфиге **обязательно** наличие `"*"` в `allowFrom` (иначе конфиг невалидный). После смены — перезапуск gateway.

### 5.4 Проверка канала

```bash
openclaw channels status
```

Должно быть что-то вроде: `Telegram default: enabled, configured, mode:polling, token:config`.

Токен можно проверить отдельно:

```bash
curl -sS "https://api.telegram.org/bot<ТВОЙ_ТОКЕН>/getMe"
```

В ответе `"ok":true` и данные бота.

---

## 6. Конфиг: где что лежит

- **Главный конфиг:** `~/.openclaw/openclaw.json`
  - `gateway` — порт, режим, auth (token/password)
  - `agents.defaults` — модель по умолчанию, workspace
  - `channels.telegram` — включение, токен бота, `dmPolicy`, `allowFrom`
  - `auth.profiles` — привязка OAuth/API-ключей к провайдерам

- **Учётные данные агента:** `~/.openclaw/agents/main/agent/auth-profiles.json` (OAuth/токены моделей).

- **Сессии:** `~/.openclaw/agents/main/sessions/`

- **Credentials (OAuth и т.п.):** `~/.openclaw/credentials/`

Не коммить в git и не светить в открытом доступе: `openclaw.json` (там токены), `auth-profiles.json`, `credentials/`.

---

## 7. Полезные команды (шпаргалка)

| Задача | Команда |
|--------|--------|
| Версия | `openclaw --version` |
| Статус моделей / Codex | `openclaw models status` |
| Статус каналов | `openclaw channels status` |
| Запуск gateway | `openclaw gateway` |
| Перезапуск (убить порт + запуск) | `openclaw gateway --force` |
| Токен gateway | `openclaw config get gateway.auth.token` |
| Добавить Telegram | `openclaw channels add --channel telegram --token 'TOKEN'` |
| Удалить Telegram | `openclaw channels remove --channel telegram --delete` |
| Открыть Dashboard с токеном в URL | браузер: `http://127.0.0.1:18789/?token=<token>` |
| Проверка здоровья | `openclaw doctor` |
| Логи | `openclaw logs --follow` |

---

## 8. Тонкости и частые проблемы

1. **"No provider plugins found"** при `openclaw models auth login --provider openai-codex`  
   Codex подключается только через onboard: `openclaw onboard --auth-choice openai-codex`.

2. **Бот в Telegram не отвечает**  
   - Проверить: `channels.telegram.enabled: true`, токен верный, gateway запущен.  
   - Если стоит `dmPolicy: "pairing"` — нужно одобрить отправителя (`openclaw pairing approve telegram <CODE>`) или переключить на `dmPolicy: "open"` и `allowFrom: ["*"]`, затем перезапустить gateway.

3. **"gateway token missing" в браузере**  
   Открыть Dashboard с токеном в URL: `http://127.0.0.1:18789/?token=<gateway.auth.token>`.

4. **После смены конфига ничего не меняется**  
   Перезапустить gateway: `openclaw gateway --force` или Ctrl+C и снова `openclaw gateway`.

5. **Одна консоль, а нужны и gateway, и команды**  
   Запустить gateway в фоне: `openclaw gateway &` — затем в той же консоли можно вызывать `openclaw ...` (onboard, channels, config и т.д.).

---

## 9. Итоговая схема того, что у нас настроено

- **Установка:** OpenClaw через `install.sh`, при необходимости — донастройка через `onboard --non-interactive` и ручной `onboard --auth-choice openai-codex`.
- **Модель:** Codex по OAuth, модель по умолчанию `openai-codex/gpt-5.3-codex`.
- **Gateway:** local, порт 18789, авторизация по токену; Dashboard открывается по URL с `?token=...`.
- **Telegram:** один бот (аккаунт default), `dmPolicy: open`, `allowFrom: ["*"]` — все могут писать в личку; для смены бота — remove + add с новым токеном и перезапуск gateway.

Этого достаточно, чтобы из нового чата или с другой машины восстановить картину и повторить шаги до мелочей.

---

## 10. Публикация этой инструкции на GitHub

Готовый репозиторий лежит в `openclaw-instructions/`. Чтобы выложить его на GitHub, см. [PUBLISH.md](PUBLISH.md).
