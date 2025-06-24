# frozen_string_literal: true

# Источник для загрузки RubyGem-зависимостей
source 'https://rubygems.org'

# Используемая версия Ruby
ruby '3.4.2'

# --- Основные зависимости приложения ---

gem 'sinatra'                  # Минималистичный DSL для создания веб-приложений (используется как API framework)
gem 'sinatra-contrib'          # Расширения Sinatra: sinatra/json, sinatra/reloader, sinatra/cross_origin и др.
gem 'rack-cors'                # Middleware для настройки CORS (используется в config/environment.rb)
gem 'aws-sdk-s3'               # Работа с S3 и совместимыми хранилищами (DigitalOcean Spaces и др.)
gem 'mini_magick'              # Обёртка над ImageMagick для обработки изображений (.jpg, .png, .webp, .heic)
gem 'sidekiq'                  # Поддержка совместимости с очередями Sidekiq (используется в Rails API)
gem 'redis'                    # Подключение к Redis (используется для очередей задач)
gem 'dotenv'                   # Загрузка переменных окружения из `.env` файлов
gem 'jwt'                      # Работа с JWT-токенами (декодирование и валидация access_token)
gem 'falcon'                   # Асинхронный веб-сервер на базе Rack и Async (альтернатива Puma/Thin)
gem 'rexml'                    # Стандартный XML-парсер (необходим для MiniMagick в некоторых конфигурациях)

# --- Зависимости только для разработки ---
group :development do
  gem 'rerun'                  # Автоматический перезапуск сервера при изменении файлов (удобно для dev-среды)
end
