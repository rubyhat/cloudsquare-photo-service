# frozen_string_literal: true

# S3Uploader — сервис для загрузки и получения доступа к файлам в S3-совместимом хранилище.
# Поддерживает загрузку public/private файлов и генерацию временных ссылок для приватных объектов.
#
# Требует настройки ENV:
# - S3_ACCESS_KEY
# - S3_SECRET_KEY
# - S3_REGION
# - S3_BUCKET
# - S3_ENDPOINT (например: https://s3.ps.kz)

require 'aws-sdk-s3'
require 'securerandom'

class S3Uploader
  class << self
    # Загружает файл в S3
    #
    # @param path [String] локальный путь к файлу
    # @param key [String] путь в бакете, например: agency_1/property_2/public/photo.webp
    # @param access [String] "public" или "private"
    # @return [String] полный URL (для public) или ключ (для private)
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

    # Генерирует временную ссылку на приватный объект
    #
    # @param key [String] путь в бакете
    # @param expires_in [Integer] срок жизни ссылки в секундах (по умолчанию 3600 секунд = 1 час)
    # @return [String] presigned URL
    def presigned_url(key, expires_in: 3600)
      signer = Aws::S3::Presigner.new(client: client)
      signer.presigned_url(:get_object, bucket: bucket, key: key, expires_in: expires_in)
    end

    private

    # Возвращает экземпляр клиента S3
    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: ENV['S3_ACCESS_KEY'],
        secret_access_key: ENV['S3_SECRET_KEY'],
        region: ENV['S3_REGION'],
        endpoint: ENV['S3_ENDPOINT'],
        force_path_style: true
      )
    end

    # Возвращает имя бакета
    def bucket
      ENV['S3_BUCKET']
    end

    # Возвращает полный публичный URL
    #
    # @param key [String]
    # @return [String]
    def public_url(key)
      "#{ENV['S3_ENDPOINT']}/#{bucket}/#{key}"
    end
  end
end
