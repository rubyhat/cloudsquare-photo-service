# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class PhotoUploader
  PHOTO_JOB_URL = ENV.fetch("PHOTO_JOB_URL", "http://cloudsquares-api:3000/api/internal/photo_jobs")
  AUTH_HEADER = ENV.fetch("PHOTO_JOB_SECRET")

  class << self
    ##
    # Отправляет POST-запрос в основной Rails API
    #
    # @param payload [Hash] данные о фото
    # @raise [StandardError] если запрос завершился с ошибкой
    def enqueue(payload)
      uri = URI.parse(PHOTO_JOB_URL)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path, {
        "Content-Type" => "application/json",
        "X-Auth-Token" => AUTH_HEADER
      })
      request.body = payload.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise StandardError, "Photo job POST failed: #{response.code} #{response.body}"
      end
    rescue => e
      raise StandardError, "Photo job request error: #{e.message}"
    end
  end
end
