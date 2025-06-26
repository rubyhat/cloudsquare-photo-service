# frozen_string_literal: true

# S3Uploader — сервис для загрузки и доступа к изображениям через S3-совместимое хранилище (например, DigitalOcean Spaces, AWS S3).
#
# Поддерживает:
# - загрузку файлов с уровнем доступа public/private;
# - генерацию временных ссылок (presigned URLs) для приватных объектов;
# - удаление файлов по ключу;
# - возврат публичного URL сразу после загрузки.
#
# Ожидаемые переменные окружения:
# - S3_ACCESS_KEY — ключ доступа
# - S3_SECRET_KEY — секретный ключ
# - S3_REGION — регион (например, 'us-east-1')
# - S3_BUCKET — имя бакета
# - S3_ENDPOINT — URL-ендпоинт, например: https://s3.ps.kz

require 'aws-sdk-s3'
require 'securerandom'

class S3Uploader
  class << self
    ##
    # Загружает файл в S3
    #
    # @param path [String] Абсолютный путь к локальному файлу
    # @param key [String] Ключ (путь) в бакете, например: agency_123/property_456/public/file.webp
    # @param access [String] Уровень доступа: 'public' или 'private' (по умолчанию 'public')
    #
    # @return [String] Если public — возвращает полный публичный URL, если private — возвращает только ключ
    #
    # @raise [StandardError] при ошибке загрузки
    def upload(path, key, access = 'public')
      acl = access == 'public' ? 'public-read' : 'private'

      client.put_object(
        bucket: bucket,
        key: key,
        body: File.open(path, 'rb'),
        acl: acl
      )

      access == 'public' ? public_url(key) : key
    rescue => e
      raise StandardError, "S3 upload failed: #{e.message}"
    end

    ##
    # Генерирует временную (presigned) ссылку для приватного объекта
    #
    # @param key [String] Ключ файла в бакете
    # @param expires_in [Integer] Срок действия ссылки в секундах (по умолчанию 3600 секунд = 1 час)
    #
    # @return [String] Ссылка для временного доступа
    def presigned_url(key, expires_in: 3600)
      signer = Aws::S3::Presigner.new(client: client)
      signer.presigned_url(:get_object, bucket: bucket, key: key, expires_in: expires_in)
    end

    ##
    # Удаляет файл из S3 по ключу
    #
    # @param key [String] Ключ файла (например, path/to/file.webp)
    #
    # @return [Boolean] true если удаление прошло успешно или файл уже был удалён, false если файл не найден
    #
    # @raise [StandardError] при других ошибках удаления
    def delete(key)
      client.delete_object(bucket: bucket, key: key)
      true
    rescue Aws::S3::Errors::NoSuchKey
      # Файл уже удалён — это не ошибка, возвращаем false
      puts "[S3Uploader] File not found for deletion: #{key}"
      false
    rescue => e
      # WARNING: Не ловим конкретные ошибки кроме NoSuchKey — при необходимости добавить retry или логику повторов
      raise StandardError, "[S3Uploader] Delete failed for #{key}: #{e.class.name} - #{e.message}"
    end

    private

    ##
    # Возвращает настроенного клиента AWS S3
    #
    # @return [Aws::S3::Client]
    def client
      @client ||= Aws::S3::Client.new(
        access_key_id:     ENV['S3_ACCESS_KEY'],
        secret_access_key: ENV['S3_SECRET_KEY'],
        region:            ENV['S3_REGION'],
        endpoint:          ENV['S3_ENDPOINT'],
        force_path_style:  true
      )
    end

    ##
    # Возвращает имя бакета
    #
    # @return [String]
    def bucket
      ENV['S3_BUCKET']
    end

    ##
    # Возвращает публичный URL к файлу
    #
    # @param key [String] путь внутри бакета
    # @return [String] абсолютный публичный URL
    def public_url(key)
      "#{ENV['S3_ENDPOINT']}/#{bucket}/#{key}"
    end
  end
end
