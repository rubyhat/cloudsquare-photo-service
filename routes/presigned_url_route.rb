# frozen_string_literal: true

# Sinatra::Base — модуль для создания изолированных маршрутов
require 'sinatra/base'

# Подключает хелпер для JSON-ответов (метод `json(...)`)
require 'sinatra/json'

# Вспомогательный модуль авторизации, содержит метод `parse_token`
require_relative '../helpers/auth_helpers'

# Сервис для работы с S3: загрузка и генерация временных ссылок
require_relative '../services/s3_uploader'

##
# Класс PresignedUrlRoute отвечает за маршрут `GET /presigned-url`,
# который генерирует временные (presigned) ссылки для приватных файлов в S3-хранилище.
#
# Используется для безопасного доступа к приватным фотографиям и другим медиа.
#
# Требуется access-токен с ролью agent/agent_manager/agent_admin.
#
class PresignedUrlRoute < Sinatra::Base
  # Подключаем JSON-хелпер от Sinatra
  helpers Sinatra::JSON

  # Подключаем парсинг JWT-токена из заголовка
  helpers AuthHelpers

  ##
  # GET /presigned-url
  #
  # Генерирует временную ссылку на приватный объект в S3.
  # Проверяет наличие токена и наличие прав у пользователя.
  #
  # @query_param key [String] ключ (путь) файла в S3-бакете
  #
  # @return [JSON] { url: "https://..." }
  #
  # @raise [Sinatra::Halt] 401, 403, 400, 500 в зависимости от ошибки
  #
  get '/presigned-url' do
    # Извлекаем и валидируем JWT токен
    payload = parse_token

    # Разрешаем доступ только авторизованным агентам
    unless %w[agent agent_manager agent_admin].include?(payload[:role])
      halt 403, json(error: 'You do not have permission to view private files')
    end

    # Обязательный query-параметр — ключ файла в S3
    key = params['key']
    halt 400, json(error: 'Missing key parameter') unless key

    begin
      # Генерируем временную ссылку
      url = S3Uploader.presigned_url(key)

      # Отправляем успешный JSON-ответ
      json(url: url)
    rescue => e
      logger.error "Failed to generate presigned URL: #{e.message}"
      halt 500, json(error: 'Could not generate presigned URL')
    end
  end
end
