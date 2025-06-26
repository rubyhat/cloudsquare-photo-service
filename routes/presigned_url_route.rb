# frozen_string_literal: true

# Sinatra::Base — модуль для создания изолированных маршрутов
require 'sinatra/base'
require 'sinatra/json'

# JWT авторизация и S3-загрузки
require_relative '../helpers/auth_helpers'
require_relative '../services/s3_uploader'

##
# PresignedUrlRoute — модуль Sinatra для генерации временных ссылок (presigned URLs)
# на приватные объекты в S3-хранилище.
#
# Используется агентами и сотрудниками агентств для безопасного просмотра приватных медиафайлов.
#
# Требует авторизации с ролями: agent, agent_manager, agent_admin.
#
class PresignedUrlRoute < Sinatra::Base
  helpers Sinatra::JSON
  helpers AuthHelpers

  # Перед выполнением каждого запроса — проверка авторизации и прав
  before do
    @payload = parse_token

    unless %w[agent agent_manager agent_admin].include?(@payload[:role])
      halt 403, json(error: 'You do not have permission to view private files')
    end
  end

  ##
  # GET /presigned-url
  #
  # Генерирует временную ссылку на один файл.
  #
  # @query_param key [String] Ключ файла в S3 (например: agency_xx/property_yy/private/abc.webp)
  # @return [JSON] { url: "https://..." }
  #
  # @response 400 Если отсутствует параметр key
  # @response 403 Если нет доступа по роли
  # @response 500 Если не удалось сгенерировать ссылку
  #
  get '/presigned-url' do
    key = params['key']
    halt 400, json(error: 'Missing key parameter') unless key

    begin
      url = S3Uploader.presigned_url(key)
      json(url: url)
    rescue => e
      logger.error "Failed to generate presigned URL: #{e.message}"
      halt 500, json(error: 'Could not generate presigned URL')
    end
  end

  ##
  # POST /presigned-urls
  #
  # Принимает массив ключей и возвращает массив временных ссылок.
  #
  # @body_param keys [Array<String>] Ключи файлов в S3
  # @return [JSON] { results: [{ key: ..., url: ..., status: "ok" }, { key: ..., error: ..., status: "error" }, ...] }
  #
  # @response 400 Если тело запроса невалидно или не массив строк
  # @response 403 Если нет доступа по роли
  #
  post '/presigned-urls' do
    request.body.rewind

    begin
      body = JSON.parse(request.body.read)
      keys = body['keys']
    rescue JSON::ParserError
      halt 400, json(error: 'Invalid JSON in request body')
    end

    unless keys.is_a?(Array) && keys.all? { |k| k.is_a?(String) }
      halt 400, json(error: 'Parameter "keys" must be an array of strings')
    end

    results = keys.map do |key|
      begin
        { key: key, url: S3Uploader.presigned_url(key), status: 'ok' }
      rescue => e
        logger.error "Presigned URL generation failed for key=#{key}: #{e.message}"
        { key: key, error: 'Could not generate URL', status: 'error' }
      end
    end

    json results: results
  end
end
