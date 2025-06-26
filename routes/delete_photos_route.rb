# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'json'

require_relative '../helpers/auth_helpers'
require_relative '../services/s3_uploader'
require_relative '../uploader/photo_uploader'

##
# DeletePhotosRoute реализует маршрут DELETE /delete-photos.
# Удаляет указанные фото из S3 и уведомляет Rails API о необходимости удаления метаданных.
#
# Требует JWT с ролью agent_* или admin_* (включая superadmin).
#
class DeletePhotosRoute < Sinatra::Base
  helpers Sinatra::JSON
  helpers AuthHelpers

  ##
  # DELETE /delete-photos
  #
  # @header Authorization [String] JWT access_token
  # @body_param entity_type [String] — тип сущности, например "property"
  # @body_param entity_id [UUID] — ID сущности
  # @body_param file_urls [Array<String>] — список путей (ключей) файлов в бакете
  #
  # @return [JSON] { status: 'ok', deleted: [...], failed: [...] }
  #
  delete '/delete-photos' do
    # Авторизация пользователя через JWT
    payload = parse_token
    user_role = payload[:role]
    agency_id_from_token = payload[:agency_id]

    # Проверка доступа: только роли agent_* или admin_*
    unless user_role.start_with?('agent') || user_role.start_with?('admin')
      halt 403, json(error: 'Access denied: insufficient permissions')
    end

    # Чтение тела запроса
    request.body.rewind
    begin
      body = JSON.parse(request.body.read)
    rescue JSON::ParserError
      halt 400, json(error: 'Invalid JSON in request body')
    end

    entity_type = body["entity_type"]&.downcase
    entity_id   = body["entity_id"]
    file_urls   = body["file_urls"]

    unless entity_type && entity_id && file_urls.is_a?(Array)
      halt 400, json(error: 'Missing or invalid parameters')
    end

    deleted = []
    failed = []

    file_urls.each do |key|
      # Защита от удаления чужих файлов
      if user_role != 'admin' && !key.include?("agency_#{agency_id_from_token}")
        logger.warn "[DeletePhotosRoute] Blocked attempt to delete foreign file: #{key}"
        failed << key
        next
      end

      begin
        logger.info "[DeletePhotosRoute] Attempting to delete file: #{key}"
        result = S3Uploader.delete(key)

        # В случае отсутствия файла delete возвращает nil, не считаем это успехом
        if result
          deleted << key
        else
          failed << key
        end
      rescue => e
        logger.error "[DeletePhotosRoute] Failed to delete #{key}: #{e.class.name} - #{e.message}"
        failed << key
      end
    end

    # Уведомляем Rails API только если есть успешные удаления
    if deleted.any?
      begin
        PhotoUploader.delete_photos(
          entity_type: entity_type,
          entity_id: entity_id,
          file_urls: deleted
        )
      rescue => e
        logger.error "[DeletePhotosRoute] Rails sync failed: #{e.class.name} - #{e.message}"
        # TODO: Возможно стоит добавить retry/очередь на повторную синхронизацию
      end
    end

    json status: 'ok', deleted: deleted, failed: failed
  end
end
