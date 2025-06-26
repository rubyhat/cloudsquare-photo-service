# frozen_string_literal: true

require "net/http"
require "json"

# PhotoUploader — отправляет задачи на Rails API, который принимает job'ы на создание PropertyPhoto.
# Все фотографии отправляются в виде массива даже если 1 штука, чтобы избежать ошибок в контроллере.

module PhotoUploader
  class << self
    # Отправка задач на сервер
    #
    # @param [Array<Hash>] photo_jobs массив задач на загрузку фотографий
    # @raise [StandardError] если ответ от API неуспешный
    def enqueue(photo_jobs)
      # Убедимся, что мы отправляем массив
      job_array = photo_jobs.is_a?(Array) ? photo_jobs : [photo_jobs]

      uri = URI.join(ENV["PHOTO_JOB_URL"], "/api/internal/photo_jobs")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path, {
        "Content-Type" => "application/json",
        "X-Auth-Token" => ENV["PHOTO_JOB_SECRET"]
      })

      request.body = { photo_job: job_array }.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise StandardError, "[PhotoUploader] Failed to enqueue photo jobs: #{response.code} - #{response.body}"
      end

      puts "[PhotoUploader] Successfully sent #{job_array.size} photo job(s) to Rails API"
    end
  end
end
