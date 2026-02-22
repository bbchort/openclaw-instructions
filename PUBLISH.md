# Как опубликовать эту инструкцию на GitHub

Локальный репозиторий уже готов. Чтобы появился репозиторий на GitHub:

## Вариант 1: Вручную на GitHub

1. Открой https://github.com/new
2. Repository name: **openclaw-instructions**
3. Public, без README/.gitignore (всё уже есть локально).
4. Create repository.
5. В терминале:

```bash
cd /root/.cursor/openclaw-instructions
git push -u origin main
```

## Вариант 2: Через GitHub CLI

```bash
gh auth login
cd /root/.cursor/openclaw-instructions
gh repo create openclaw-instructions --public --source=. --remote=origin --push
```

## Вариант 3: Токен + скрипт

Положи Personal Access Token (scope: repo) в `~/.cursor/secrets/github-token` или задай `GH_TOKEN`, затем:

```bash
./scripts/create-repo-and-push.sh
```

Скрипт создаст репозиторий на GitHub и выполнит push.

Remote уже настроен: `git@github.com:bbchort/openclaw-instructions.git` (замени bbchort на свой логин, если нужно).
