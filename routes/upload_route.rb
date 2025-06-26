# frozen_string_literal: true

# Sinatra::Base используется для создания изолированного модуля загрузки изображений
require 'sinatra/base'
require 'sinatra/json'
require 'securerandom'

# Хелперы: авторизация по JWT, проверка размера файлов
require_relative '../helpers/auth_helpers'
require_relative '../helpers/file_helpers'

# Сервисы: обработка изображений, загрузка в S3, постановка задач в Redis
require_relative '../services/image_processor'
require_relative '../services/s3_uploader'
require_relative '../uploader/photo_uploader'

##
# UploadRoute — модуль Sinatra, реализующий маршрут POST /upload.
#
# Предназначен для загрузки изображений, конвертации в `.webp`,
# загрузки в S3 и регистрации асинхронной задачи в Redis.
#
# Требуется авторизация по JWT и роль `agent`, `agent_manager` или `agent_admin`.
#
class UploadRoute < Sinatra::Base
  # Подключаем хелперы Sinatra и пользовательские
  helpers Sinatra::JSON
  helpers AuthHelpers
  helpers FileHelpers

  ##
  # POST /upload
  #
  # Загружает 1–30 изображений (JPG, PNG, HEIC), конвертирует в WebP,
  # сохраняет в S3, и отправляет задачу в Redis (Sidekiq).
  #
  # @header Authorization [String] JWT access_token
  #
  # @form_param entity_type [String] Тип сущности (например: property)
  # @form_param entity_id [UUID] ID сущности
  # @form_param images [Array<File>] Массив файлов (1–30)
  # @form_param access [String] public/private
  # @form_param main_photo_index [Integer] Индекс главного фото (0-основанный)
  #
  # @return [JSON] Результат загрузки по каждому файлу
  #
  post '/upload' do
    # Авторизация
    payload = parse_token
    user_id = payload[:sub]
    agency_id = payload[:agency_id]

    # Только агенты могут загружать изображения
    unless %w[agent agent_manager agent_admin].include?(payload[:role])
      halt 403, json(error: 'You do not have permission to upload photos')
    end

    # Получение параметров
    files = params["images"]
    entity_type = params["entity_type"]&.downcase
    entity_id = params["entity_id"]
    access = params["access"] || 'public'
    main_photo_index = params[:main_photo_index]&.to_i

    # Проверка наличия обязательных данных
    halt 400, json(error: 'No files provided') unless files
    halt 400, json(error: 'Missing entity_type') unless entity_type
    halt 400, json(error: 'Missing entity_id') unless entity_id

    # Упрощаем валидацию — всегда работаем с массивом
    files = [files] unless files.is_a?(Array)

    # Лимиты по количеству и объему
    halt 400, json(error: 'Too many files (max 30)') if files.size > 30
    halt 400, json(error: 'Total size exceeds 100MB') if total_file_size(files) > 100 * 1024 * 1024

    # Обработка и загрузка всех файлов
    photo_jobs = []
    uploads = []

    files.each_with_index do |file, index|
      tempfile = file[:tempfile]
      filename = file[:filename]

      begin
        # Обработка изображения: ресайз + WebP
        processed_file = ImageProcessor.process(tempfile.path)

        # Формируем путь в S3
        s3_path =
          if agency_id && !agency_id.empty?
            "agency_#{agency_id}/#{entity_type}_#{entity_id}/#{access}/#{SecureRandom.uuid}.webp"
          else
            "undefined_agency/#{entity_type}_#{entity_id}/#{access}/#{SecureRandom.uuid}.webp"
          end

        # Загрузка в S3
        url = S3Uploader.upload(processed_file.path, s3_path, access)

        # Подготовка задачи
        photo_jobs << {
          entity_type: entity_type,
          entity_id: entity_id,
          agency_id: agency_id,
          user_id: user_id,
          file_url: url,
          is_main: index == main_photo_index,
          position: index + 1,
          access: access
        }

        # Удаляем временный файл
        processed_file.unlink

        # Успешный результат
        uploads << { status: 'ok', url: url }
      rescue => e
        logger.error "File upload failed: #{filename}, error: #{e.message}"
        uploads << { status: 'error', error: e.message, file: filename }
      end
    end

    # Отправляем все задачи одной пачкой
    begin
      PhotoUploader.enqueue(photo_jobs)
    rescue => e
      logger.error "PhotoUploader error: #{e.message}"
      halt 502, json(error: 'Failed to enqueue photo jobs', details: e.message)
    end

    json results: uploads
  end
end