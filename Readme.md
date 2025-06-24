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
- ✅ Запуск на Falcon
- ✅ Аутентификация по JWT access token

---

## 📦 Стек

- Ruby 3.4.2
- Sinatra (API-only)
- Falcon (async web server)
- MiniMagick (ImageMagick)
- AWS S3 SDK
- Redis
- Sidekiq-compatible job push
- Dotenv

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
├── app.rb                   # Sinatra-приложение
├── config.ru                # Точка входа для Falcon
├── .env.example             # Пример конфигурации
├── services/
│   ├── jwt_decoder.rb       # Проверка access_token
│   ├── image_processor.rb   # Обработка изображений
│   ├── s3_uploader.rb       # Загрузка в S3
├── uploader/
│   └── photo_uploader.rb    # Публикация задач в Redis
├── config/
│   └── environment.rb       # CORS + dotenv + rack middlewares
```

---

## 🧪 Тестирование через Postman

### 📤 Запрос: `POST /upload`

**URL:**  
`https://localhost:9292/upload` *(или http://localhost:9292, если отключён TLS)*

**Headers:**
```http
Authorization: Bearer <access_token>
```

**Body → form-data:**

| Ключ         | Тип   | Описание                                     |
|--------------|--------|----------------------------------------------|
| property_id  | Text   | UUID объекта недвижимости                    |
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

## 🐳 Запуск через Falcon

```bash
bundle exec falcon serve
```

По умолчанию доступно на:  
`https://localhost:9292`

---

## 🔐 Переменные окружения

Смотри [.env.example](./.env.example)

---

## 📬 Что происходит при загрузке

1. Авторизация через access_token
2. Каждое изображение:
   - Проверяется
   - Конвертируется в `.webp`
   - Загружается в S3 по пути:
     ```
     agency_<agency_id>/property_<property_id>/<access>/<uuid>.webp
     ```
   - Отправляется задача в Redis `queue:photo_worker` для основного Rails API
3. Возвращается список URL и статусов

---

## 🧩 Связь с Rails backend

Rails API забирает задачи из Redis через `Sidekiq` с queue `photo_worker` и:
- Создаёт `PropertyPhoto` (или другую сущность)
- Обрабатывает права, лимиты, и отображение