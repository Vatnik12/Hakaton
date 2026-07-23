# Гнездо

«Гнездо» — hackathon MVP для совместной аренды: пользователь подбирает квартиру, сравнивает анкеты будущих соседей, начинает диалог и собирает команду для совместного поиска.

## Онлайн-демо

После первого включения GitHub Pages сайт будет доступен по адресу:

**https://vatnik12.github.io/Hakaton/**

Для GitHub Pages используется статический demo-режим. Каталог, фильтры, избранное, анкеты, чаты и переключение темы работают в браузере; состояние сохраняется в `localStorage`.

> GitHub Pages публикует только статические файлы и не запускает Java/Spring Boot. Полный backend запускается локально или на отдельном сервере. Инструкция для обоих вариантов находится ниже.

## Стек

- frontend: HTML, CSS, JavaScript;
- backend: Java 21, Spring Boot 3.5;
- доступ к данным: Spring Data JPA;
- база данных: PostgreSQL 17;
- миграции: Flyway;
- локальная инфраструктура: Docker Compose и Nginx;
- публикация frontend: GitHub Actions и GitHub Pages.

## Как включить GitHub Pages — подробно

Репозиторий уже подготовлен: workflow находится в `.github/workflows/pages.yml`, а пути к CSS, JavaScript и изображениям сделаны относительными, поэтому проект корректно открывается из подпапки `/Hakaton/`.

### Шаг 1. Откройте настройки Pages

1. Откройте репозиторий `Vatnik12/Hakaton` на GitHub.
2. Нажмите вкладку **Settings**.
3. В левом меню найдите раздел **Code and automation**.
4. Откройте пункт **Pages**.

Если вкладка **Settings** не видна, у аккаунта нет прав администратора этого репозитория. Включить Pages должен владелец или администратор.

### Шаг 2. Выберите GitHub Actions как источник

1. В блоке **Build and deployment** найдите поле **Source**.
2. Выберите **GitHub Actions**.
3. Дополнительную ветку или папку указывать не нужно: публикацией управляет готовый workflow.

Не выбирайте вариант **Deploy from a branch**. Для этого проекта уже настроен более надёжный вариант через Actions, который собирает отдельный безопасный статический артефакт.

### Шаг 3. Запустите первую публикацию

Обычно workflow стартует автоматически после push в `main`. Чтобы запустить его вручную:

1. Откройте вкладку **Actions** в репозитории.
2. В списке слева выберите **Deploy frontend to GitHub Pages**.
3. Нажмите **Run workflow**.
4. В поле ветки оставьте `main`.
5. Ещё раз нажмите зелёную кнопку **Run workflow**.

### Шаг 4. Дождитесь завершения

В workflow последовательно выполняются две задачи:

1. **build** — копирует `index.html`, `product-v4.css`, `product-v4.js` и каталог `assets` в отдельный Pages-артефакт;
2. **deploy** — публикует этот артефакт в окружение `github-pages`.

Обе задачи должны стать зелёными. Первая публикация обычно занимает несколько минут, но GitHub предупреждает, что обновление сайта иногда может занять до 10 минут.

После успешного выполнения:

1. откройте завершившийся workflow;
2. нажмите ссылку **View deployment** в блоке `deploy`;
3. либо откройте **Settings → Pages** — там появится адрес опубликованного сайта.

### Шаг 5. Проверьте сайт

Откройте:

```text
https://vatnik12.github.io/Hakaton/
```

Проверьте:

- загружаются логотип и фотографии;
- работают вкладки «Квартиры», «Найти соседа», «Сообщения»;
- открываются карточки и модальные окна;
- переключение темы запускает сцену с солнцем, луной, домом и птицей;
- после обновления страницы сохраняются избранное, чаты и состав гнезда.

### Как публиковать следующие изменения

После включения Pages отдельные ручные действия больше не нужны. Любой push в `main`, который меняет frontend или Pages workflow, автоматически запускает публикацию:

```bash
git add index.html product-v4.css product-v4.js assets .github/workflows/pages.yml
git commit -m "Update frontend"
git push origin main
```

Следить за процессом можно во вкладке **Actions → Deploy frontend to GitHub Pages**.

## Если GitHub Pages не заработал

### Workflow не появился во вкладке Actions

Проверьте, что файл `.github/workflows/pages.yml` существует в ветке `main`. Затем откройте **Actions** и разрешите запуск workflows, если GitHub показывает кнопку **I understand my workflows, go ahead and enable them**.

### Ошибка `Get Pages site failed` или `Not Found`

Откройте **Settings → Pages** и убедитесь, что в поле **Source** выбран **GitHub Actions**. После этого заново запустите workflow вручную.

### Ошибка прав в задаче deploy

Откройте:

**Settings → Actions → General → Workflow permissions**

Для стандартного Pages workflow достаточно разрешить GitHub Actions выполняться в репозитории. Не удаляйте из `pages.yml` права:

```yaml
permissions:
  contents: read
  pages: write
  id-token: write
```

Они нужны официальному действию публикации Pages.

### Сайт открывается, но CSS или изображения не загружаются

1. Убедитесь, что открываете адрес с `/Hakaton/` в конце.
2. Выполните жёсткое обновление страницы: `Ctrl + F5` на Windows/Linux или `Cmd + Shift + R` на macOS.
3. Проверьте, что последний workflow завершился после ваших изменений.
4. Не заменяйте относительные пути `./product-v4.css`, `./product-v4.js` и `./assets/...` на пути, начинающиеся с `/`: абсолютный путь укажет на корень домена и сломает проектную страницу GitHub Pages.

### На Pages не отвечает `/api/v1/...`

Это ожидаемо: GitHub Pages не запускает Spring Boot и PostgreSQL. На домене `github.io` frontend автоматически работает в статическом demo-режиме и не обращается к отсутствующему API.

Чтобы подключить опубликованный frontend к отдельно развёрнутому backend, до `product-v4.js` нужно определить публичный HTTPS-адрес API:

```html
<script>
  window.GNEZDO_API_BASE = 'https://api.example.com/api/v1';
</script>
```

Backend при этом должен разрешать CORS для адреса GitHub Pages. Не добавляйте токены, пароли базы или приватные ключи в frontend: весь опубликованный JavaScript доступен посетителям.

## Быстрый локальный запуск frontend

Самый простой вариант без Docker и Java:

```bash
python -m http.server 4173
```

Откройте `http://localhost:4173`.

На Windows можно также дважды нажать `START_GNEZDO.bat`. Локальный demo-режим хранит состояние интерфейса в браузере.

## Запуск полного стека через Docker

Нужны Docker и Docker Compose.

### Linux/macOS

```bash
export POSTGRES_PASSWORD='replace-with-a-long-local-password'
docker compose up --build
```

### Windows PowerShell

```powershell
$env:POSTGRES_PASSWORD = 'replace-with-a-long-local-password'
docker compose up --build
```

После запуска:

- сайт: `http://localhost`;
- health-check API: `http://localhost/api/v1/health`;
- backend внутри Compose: Spring Boot на порту `8080`;
- база внутри Compose: PostgreSQL на порту `5432`.

Остановка контейнеров:

```bash
docker compose down
```

Удаление контейнеров вместе с локальными данными PostgreSQL:

```bash
docker compose down -v
```

## Запуск backend без Docker

Нужны Java 17+, Maven 3.9+ и запущенный PostgreSQL.

Задайте параметры подключения через переменные окружения:

```text
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/gnezdo
SPRING_DATASOURCE_USERNAME=gnezdo
SPRING_DATASOURCE_PASSWORD=your-local-password
```

Затем запустите:

```bash
cd backend
mvn spring-boot:run
```

## Архитектура backend

Backend разделён на отдельные слои и пакеты:

```text
ru.gnezdo.api
├── controller   HTTP-контроллеры и валидация входных запросов
├── service      бизнес-логика приложения
├── repository   Spring Data JPA репозитории
├── model        JPA-сущности и enum-типы
├── dto          DTO запросов/ответов и mapper
└── config       конфигурация и заполнение demo-данными
```

Поток обработки запроса:

```text
Controller → Service → Repository → PostgreSQL
                    ↘ DTO mapper → HTTP response
```

Основные endpoint'ы:

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

## Безопасность публикации

Pages workflow публикует только четыре части frontend:

- `index.html`;
- `product-v4.css`;
- `product-v4.js`;
- `assets/`.

Backend, Docker-конфигурация, миграции, `.env` и серверные настройки в Pages-артефакт не попадают. Секреты следует хранить только в переменных окружения или GitHub Actions Secrets; реальные пароли и приватные ключи нельзя коммитить в репозиторий.
