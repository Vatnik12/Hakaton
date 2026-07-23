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

### Офлайн-запуск в один клик на Windows

Скачайте архив репозитория в папку `C:\Users\main\Downloads`, затем дважды нажмите `START_GNEZDO.bat`. Подключение к GitHub и установленный Git не требуются. Лаунчер автоматически:

1. найдёт самый свежий архив `Hakaton-main.zip`, `Hakaton-main (1).zip`, `Hakaton-main (2).zip` и так далее;
2. проверит ZIP и дождётся окончания его загрузки;
3. обновит проект в `C:\Users\main\Desktop\Hakaton`, сохранив локальный `.env`;
4. не станет повторно копировать уже установленный архив;
5. запустит сайт напрямую на Windows и откроет `http://localhost:8080`.

Docker Desktop, Java, PostgreSQL и Git для локального MVP не требуются. Данные интерфейса сохраняются в браузере.

### Полный стек с backend через Docker — необязательно

Docker нужен только разработчикам, которым отдельно требуется Spring Boot API и PostgreSQL.

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
POST /api/v1/chats/person
POST /api/v1/chats/listing
GET  /api/v1/chats/{roomId}/messages
POST /api/v1/chats/{roomId}/messages
```

Диалог с потенциальным соседом создаётся через Spring Boot API, а нажатие «Я готов — добавить в гнездо» сохраняет подтверждённый мэтч в PostgreSQL.


## Быстрый деплой на новый сервер `31.77.241.39`

Ниже команды именно для Windows CMD. Первая команда настраивает удобный вход `ssh gnezdo` на вашем компьютере, вторая запускается уже на сервере и поднимает сайт.

### 1. На своём компьютере в Windows CMD

```bat
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
if not exist "%USERPROFILE%\.ssh\gnezdo_admin" ssh-keygen -t ed25519 -N "" -C "gnezdo-admin" -f "%USERPROFILE%\.ssh\gnezdo_admin"
(
  echo Host gnezdo
  echo   HostName 31.77.241.39
  echo   User root
  echo   IdentityFile %USERPROFILE%\.ssh\gnezdo_admin
  echo   IdentitiesOnly yes
) >> "%USERPROFILE%\.ssh\config"
ssh root@31.77.241.39 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" < "%USERPROFILE%\.ssh\gnezdo_admin.pub"
ssh gnezdo
```

Во время команды `ssh root@31.77.241.39 ...` Windows попросит пароль от сервера, если ключ ещё не добавлен. Если провайдер отключил вход по паролю, добавьте содержимое файла `%USERPROFILE%\.ssh\gnezdo_admin.pub` в `/root/.ssh/authorized_keys` через панель провайдера, затем выполните `ssh gnezdo`.

### 2. На сервере после входа по `ssh gnezdo`

```bash
set -e
apt-get update && apt-get install -y git ca-certificates curl
rm -rf /tmp/gnezdo-bootstrap
git clone https://github.com/Vatnik12/Hakaton.git /tmp/gnezdo-bootstrap
bash /tmp/gnezdo-bootstrap/deploy/setup-server.sh
```

После завершения сайт будет доступен по адресу `http://31.77.241.39`, а проверка API — `http://31.77.241.39/api/v1/health`. Скрипт в конце выведет значения для GitHub Secrets:

```text
SERVER_HOST=31.77.241.39
SERVER_USER=deploy
SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY----- ...
```

Добавьте эти три секрета в GitHub: `Settings → Secrets and variables → Actions → New repository secret`. Это и есть deploy key для автодеплоя: workflow будет заходить на сервер пользователем `deploy` и запускать `/usr/local/bin/deploy-gnezdo`.

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
