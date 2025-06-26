# frozen_string_literal: true

# Основной Sinatra-приложение для микросервиса загрузки изображений.
#
# Объединяет маршруты загрузки файлов и генерации временных ссылок.
# Поддерживает предварительную инициализацию окружения, CORS, логирование, лимит размера запроса.
#
# Загружаемые маршруты:
# - POST /upload — загрузка изображений с конвертацией и отправкой задач в Redis
# - GET /presigned-url — получение временной ссылки для доступа к приватным файлам
#
# Конфигурация:
# - `set :max_request_size` ограничивает общий объём загружаемых данных (100 МБ)
# - `before` блок устанавливает `Content-Type` в `application/json` для всех ответов

require_relative './config/environment'
require_relative './routes/upload_route'
require_relative './routes/presigned_url_route'
require_relative './routes/delete_photos_route'

class ImageService < Sinatra::Base
  configure do
    # Включает логирование HTTP-запросов
    enable :logging

    # Разрешает любые источники (для CORS), либо указывается конкретный домен в environment.rb
    set :allow_origin, :any

    # Максимальный размер тела запроса — 100 мегабайт (в байтах)
    set :max_request_size, 100 * 1024 * 1024
  end

  # Устанавливает заголовок Content-Type как JSON для всех ответов
  before do
    content_type :json
  end

  # Подключение маршрутов
  use UploadRoute        # POST /upload
  use PresignedUrlRoute  # GET /presigned-url
  use DeletePhotosRoute  # DEL /delete-photos
end
