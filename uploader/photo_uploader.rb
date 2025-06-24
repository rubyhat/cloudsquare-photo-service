# frozen_string_literal: true

# PhotoUploader — сервис для публикации задачи в очередь Redis (Sidekiq).
# Используется для асинхронного создания записей в основном Rails API.
#
# Пример использования:
# PhotoUploader.enqueue({
#   property_id: "...",
#   agency_id: "...",
#   user_id: "...",
#   file_url: "...",
#   is_main: true,
#   position: 1,
#   access: "public"
# })

require 'redis'
require 'json'

class PhotoUploader
  QUEUE_NAME = 'photo_worker' # имя Sidekiq queue в Rails

  class << self
    def enqueue(payload)
      redis.lpush("queue:#{QUEUE_NAME}", JSON.dump(payload))
    rescue => e
      raise StandardError, "Redis push failed: #{e.message}"
    end

    private

    def redis
      @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
    end
  end
end
