# frozen_string_literal: true

# Загружает зависимости, указанные в Gemfile
require 'bundler/setup'
Bundler.require(:default) # Загружает гемы из группы :default в Gemfile

# Загружает переменные окружения из файла .env (используется для конфиденциальной конфигурации)
Dotenv.load

# Подключает middleware Rack CORS для поддержки CORS-заголовков
require 'rack/cors'

# Настройка политики CORS
# Позволяет обрабатывать кросс-доменные запросы к API (например, с фронтенда)
# В данном случае разрешены все домены (`'*'`), но в продакшене лучше указать конкретные
use Rack::Cors do
  allow do
    # Указывает, какие источники могут обращаться к серверу
    origins '*' # В продакшене желательно заменить на конкретные домены: 'https://admin.cloudsquares.kz'

    # Указывает, какие ресурсы разрешены
    resource '*',
             headers: :any,               # Разрешены любые заголовки
             methods: [:get, :post, :options], # Разрешённые методы HTTP
             expose: ['Authorization']    # Разрешено клиенту видеть заголовок Authorization (важно для токенов)
  end
end

# Подключает собственные сервисы для JWT-декодирования, обработки изображений, загрузки в S3
require_relative '../services/jwt_decoder'     # Обработка и валидация JWT access токенов
require_relative '../services/image_processor' # Конвертация и ресайз изображений
require_relative '../services/s3_uploader'     # Работа с S3-хранилищем

# Подключает сервис для публикации задач в Redis-очередь (используется для интеграции с Rails API через Sidekiq)
require_relative '../uploader/photo_uploader'
