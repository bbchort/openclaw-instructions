#!/usr/bin/env bash
# Создаёт репозиторий openclaw-instructions на GitHub и пушит. Использует GH_TOKEN, GITHUB_TOKEN или ~/.cursor/secrets/github-token.
set -e
REPO_NAME="openclaw-instructions"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GITHUB_USER="${GITHUB_USER:-bbchort}"

TOKEN="${GH_TOKEN:-$GITHUB_TOKEN}"
[ -z "$TOKEN" ] && [ -f ~/.cursor/secrets/github-token ] && TOKEN=$(head -1 ~/.cursor/secrets/github-token | tr -d '\r\n ')
[ -z "$TOKEN" ] && { echo "No token. Set GH_TOKEN or add to ~/.cursor/secrets/github-token"; exit 1; }

HTTP=$(curl -sS -w "%{http_code}" -o /tmp/repo-create.json -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO_NAME\",\"private\":false}")
[ "$HTTP" = "201" ] && echo "Repo $REPO_NAME created."
[ "$HTTP" = "422" ] && echo "Repo $REPO_NAME already exists."
[ "$HTTP" != "201" ] && [ "$HTTP" != "422" ] && { cat /tmp/repo-create.json; exit 1; }

cd "$REPO_DIR"
git remote remove origin 2>/dev/null || true
git remote add origin "git@github.com:$GITHUB_USER/$REPO_NAME.git"
git push -u origin main
echo "Pushed to origin main."
