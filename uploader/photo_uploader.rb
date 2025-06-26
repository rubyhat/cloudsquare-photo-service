# frozen_string_literal: true

require "net/http"
require "json"

# PhotoUploader — отправляет задачи на Rails API:
# - загрузка фотографий (POST /api/internal/photo_jobs)
# - удаление фотографий (DELETE /api/internal/photo_jobs/delete)
#
# Все данные передаются в виде JSON.
#
module PhotoUploader
  class << self
    ##
    # Отправка задач на добавление фото
    #
    # @param [Array<Hash>] photo_jobs массив задач на загрузку
    # @raise [StandardError] при неуспешном ответе
    def enqueue(photo_jobs)
      job_array = photo_jobs.is_a?(Array) ? photo_jobs : [photo_jobs]
      uri = URI.join(ENV["PHOTO_JOB_URL"], "/api/internal/photo_jobs")

      send_request(:post, uri, { photo_job: job_array })

      puts "[PhotoUploader] Successfully sent #{job_array.size} photo job(s) to Rails API"
    end


    ##
    # Удаление одного или нескольких фото
    #
    # @param [String] entity_type тип сущности, например "property"
    # @param [String] entity_id UUID сущности
    # @param [Array<String>] file_urls список путей к файлам (ключи в S3)
    # @raise [StandardError] при ошибке
    def delete_photos(entity_type:, entity_id:, file_urls:)
      raise ArgumentError, "file_urls must be an array" unless file_urls.is_a?(Array)

      uri = URI.join(ENV["PHOTO_JOB_URL"], "/api/internal/photo_jobs/delete")

      send_request(:delete, uri, {
        entity_type: entity_type,
        entity_id: entity_id,
        file_urls: file_urls
      })

      puts "[PhotoUploader] Successfully deleted #{file_urls.size} photo(s) for #{entity_type} #{entity_id}"
    end

    private

    ##
    # Вспомогательный метод для отправки POST/DELETE запросов
    #
    # @param [Symbol] method :post или :delete
    # @param [URI] uri URL запроса
    # @param [Hash] body тело запроса
    # @return [Net::HTTPResponse] объект ответа
    # @raise [StandardError] если ответ неуспешный
    def send_request(method, uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request_class = method == :post ? Net::HTTP::Post : Net::HTTP::Delete
      request = request_class.new(uri.path, {
        "Content-Type" => "application/json",
        "X-Auth-Token" => ENV["PHOTO_JOB_SECRET"]
      })

      request.body = body.to_json
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise StandardError, "[PhotoUploader] #{method.upcase} failed: #{response.code} - #{response.body}"
      end

      response
    end
  end
end
