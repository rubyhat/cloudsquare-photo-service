# frozen_string_literal: true

# S3Uploader — сервис для загрузки файлов в S3-совместимое хранилище.
# Поддерживает public/private доступ, отдельные пути, и возвращает URL.
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
    # @param path [String] путь к файлу
    # @param key [String] путь в бакете, например: agency_1/property_2/public/photo.webp
    # @param access [String] "public" или "private"
    # @return [String] публичный URL или путь
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

    private

    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: ENV['S3_ACCESS_KEY'],
        secret_access_key: ENV['S3_SECRET_KEY'],
        region: ENV['S3_REGION'],
        endpoint: ENV['S3_ENDPOINT'], # обязательно для ps.kz
        force_path_style: true
      )
    end

    def bucket
      ENV['S3_BUCKET']
    end

    def public_url(key)
      "#{ENV['S3_ENDPOINT']}/#{bucket}/#{key}"
    end
  end
end
