# 🖼️ CloudSquares Photo Service

Микросервис для обработки и загрузки изображений недвижимости (и других сущностей) с автоматической конвертацией в `.webp` и последующей загрузкой в S3-совместимое хранилище. Поддерживает авторизацию через JWT, лимиты, приватные и публичные фотографии, очереди через Redis для интеграции с основным Rails API.

---

## 🚀 Возможности

- ✅ Конвертация изображений (.jpg, .png, .heic) в `.webp`
- ✅ Сжатие и ресайз до 1920px
- ✅ Поддержка HEIC/HEIF (iOS)
- ✅ Загрузка в S3
- ✅ Разделение доступа: public / private
- ✅ Асинхронная публикация задач в Redis (для основного API)
- ✅ JWT аутентификация (access token)
- ✅ Запуск на Falcon (async server)
- ✅ REST эндпоинты через Sinatra-модули
- ✅ Разделение кода на helpers / routes / services

---

## 📦 Стек

- Ruby 3.4.2
- Sinatra (API-only)
- Falcon (async web server)
- MiniMagick (ImageMagick)
- AWS S3 SDK
- Redis
- Dotenv
- Sidekiq-compatible queue

---

## 🔧 Установка

```bash
git clone https://your-repo-url
cd cloudsquares-photo-service

bundle install
cp .env.example .env
# Заполни .env своими переменными
```

---

## 📂 Структура

```text
.
├── app.rb                         # Точка входа Sinatra
├── config.ru                      # Запуск Falcon
├── .env.example                   # Пример конфигурации
├── config/
│   └── environment.rb             # dotenv + CORS + middleware
├── routes/
│   ├── upload_route.rb           # POST /upload
│   └── presigned_url_route.rb    # GET /presigned-url
├── helpers/
│   ├── auth_helpers.rb           # JWT аутентификация
│   └── file_helpers.rb           # Подсчёт размера файлов
├── services/
│   ├── jwt_decoder.rb            # Расшифровка access_token
│   ├── image_processor.rb        # Конвертация и сжатие
│   └── s3_uploader.rb            # Работа с S3
├── uploader/
│   └── photo_uploader.rb         # Публикация задач в Redis
```

---

## 🧪 Тестирование через Postman

### 📤 Запрос: `POST /upload`

**URL:**  
`http://localhost:9292/upload`

**Headers:**
```http
Authorization: Bearer <access_token>
```

**Body → form-data:**

| Ключ         | Тип   | Описание                                     |
|--------------|--------|----------------------------------------------|
| entity_type  | Text   | Тип сущности, например: property             |
| entity_id    | Text   | UUID сущности                                |
| access       | Text   | public / private (по умолчанию public)       |
| is_main      | Text   | true / false (первая — главная)              |
| images       | File   | файлы: .jpg, .png, .heic (1–30 файлов)        |

**Пример ответа:**

```json
{
  "results": [
    {
      "status": "ok",
      "url": "https://s3.ps.kz/bucket/agency_123/property_456/public/photo1.webp"
    }
  ]
}
```

---

### 🔒 Запрос: `GET /presigned-url?key=...`

**Только для доступа к приватным файлам:**

**Headers:**
```http
Authorization: Bearer <access_token>
```

**Пример запроса:**
```
GET /presigned-url?key=agency_.../property_.../private/uuid.webp
```

**Ответ:**
```json
{ "url": "https://s3.ps.kz/..." }
```

---

## 🔐 Переменные окружения

Смотри [.env.example](./.env.example)

```env
JWT_SECRET=...
S3_ACCESS_KEY=...
S3_SECRET_KEY=...
S3_REGION=...
S3_BUCKET=...
S3_ENDPOINT=https://s3.ps.kz
REDIS_URL=redis://localhost:6379/0
```

---

## 🧩 Что происходит при загрузке

1. JWT access_token декодируется и валидируется
2. Изображения проходят:
    - валидацию формата и размера
    - ресайз + преобразование в .webp
    - загрузку в S3 с нужным уровнем доступа
3. В Redis (queue:photo_worker) отправляется задача для Rails API

---

## 🤝 Интеграция с Rails backend

Rails API забирает задачи из Redis через Sidekiq:
- Создаёт `PropertyPhoto` или другую модель
- Присваивает флаг `is_main`, `position`, `access`
- Сохраняет URL в базе и отображает на клиенте

---

## 🐳 Запуск через Falcon

```bash
bundle exec falcon serve
```

По умолчанию работает на `http://localhost:9292`