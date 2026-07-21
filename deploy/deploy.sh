#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
git fetch origin main
git reset --hard origin/main
docker compose up -d --build --remove-orphans
docker image prune -f >/dev/null 2>&1 || true
echo "СВОИ обновлён и запущен."
