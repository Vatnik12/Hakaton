# Гнездо — совместная аренда жилья

Рабочий hackathon MVP для поиска квартиры, совместимых соседей и формирования общего «гнезда» арендаторов.

## Стек

- Frontend: HTML, CSS, JavaScript, Nginx;
- Backend: Java 21 (соответствует требованию Java 17+), Spring Boot 3.5;
- Database: PostgreSQL 17;
- Миграции: Flyway;
- Доступ к данным: Spring JDBC `JdbcClient`;
- Инфраструктура: Docker Compose, Nginx reverse proxy, GitHub Actions auto-deploy.

## Что хранится на сервере

- объявления о квартирах;
- профили потенциальных соседей;
- комнаты чатов;
- сообщения;
- созданные мэтчи и чаты по объявлениям.

При первом запуске backend автоматически создаёт 128 объявлений и 50 профилей в PostgreSQL.

## Архитектура

```text
Browser
  └── Nginx :80
      ├── /              -> frontend
      └── /api/*         -> Spring Boot :8080
                              └── PostgreSQL 17 :5432
```

## Локальный запуск всего проекта

Требуются Docker Desktop и Docker Compose.

```bash
cp .env.example .env
docker compose up -d --build
```

Открыть:

- сайт: `http://localhost`;
- API: `http://localhost/api/v1/health`.

Проверка данных:

```bash
curl http://localhost/api/v1/meta
curl http://localhost/api/v1/listings?limit=5
curl http://localhost/api/v1/profiles?limit=5
```

Остановка:

```bash
docker compose down
```

Удаление базы вместе с данными:

```bash
docker compose down -v
```

## Запуск backend без Docker

Нужны Java 17+ и Maven 3.9+, а также запущенный PostgreSQL 17.

```bash
cd backend
mvn spring-boot:run
```

Переменные подключения:

```text
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/gnezdo
SPRING_DATASOURCE_USERNAME=gnezdo
SPRING_DATASOURCE_PASSWORD=gnezdo
```

## API MVP

```text
GET  /api/v1/health
GET  /api/v1/meta
GET  /api/v1/listings
POST /api/v1/listings
GET  /api/v1/profiles
POST /api/v1/matches
POST /api/v1/chats/listing
GET  /api/v1/chats/{roomId}/messages
POST /api/v1/chats/{roomId}/messages
```

Форма арендодателя на сайте уже сохраняет новое объявление через Spring Boot API в PostgreSQL.

## Мгновенный запуск на Ubuntu-сервере

```bash
sudo apt-get update && sudo apt-get install -y git ca-certificates curl && \
rm -rf /tmp/gnezdo-bootstrap && \
git clone https://github.com/Vatnik12/Hakaton.git /tmp/gnezdo-bootstrap && \
cd /tmp/gnezdo-bootstrap && \
sudo bash deploy/setup-server.sh
```

Скрипт:

1. устанавливает Docker;
2. создаёт безопасный пароль PostgreSQL в `/opt/svoi/.env`;
3. запускает PostgreSQL 17, Spring Boot и Nginx;
4. выводит ссылку на сайт и health endpoint;
5. создаёт ключ для GitHub Actions.

Ручное обновление:

```bash
sudo -u deploy /usr/local/bin/deploy-gnezdo
```

## Автодеплой

В GitHub добавьте Secrets:

```text
SERVER_HOST
SERVER_USER
SSH_PRIVATE_KEY
```

После каждого push в `main` workflow обновляет код и выполняет:

```bash
docker compose up -d --build --remove-orphans
```

## Production-заметки

Для полноценного production нужны авторизация, роли, WebSocket/STOMP для realtime-чатов, object storage для фотографий, rate limiting, резервные копии PostgreSQL и реальные интеграции верификации.
