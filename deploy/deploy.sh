#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
git fetch origin main
git reset --hard origin/main
if [ ! -f .env ]; then
  cp .env.example .env
  sed -i "s/replace_with_a_strong_password/$(openssl rand -hex 24)/" .env
fi
docker compose up -d --build --remove-orphans
docker image prune -f >/dev/null 2>&1 || true
echo "Гнездо обновлено: frontend + Spring Boot API + PostgreSQL 17."
