# frozen_string_literal: true

# PhotoUploader — сервис для постановки задач на создание фотографий в очередь Redis.
#
# Используется в микросервисе обработки изображений для передачи информации
# об успешно загруженных изображениях в основной Rails API, который читает задачи через Sidekiq.
#
# Каждая задача помещается в Redis-очередь `queue:photo_worker` в формате JSON.
# Формат задачи соответствует параметрам, нужным основному приложению:
# - entity_type: тип сущности (`property`, `sell_request`, и т.д.)
# - entity_id: UUID сущности
# - agency_id: UUID агентства недвижимости
# - user_id: UUID пользователя, загрузившего файл
# - file_url: полный URL до изображения в S3
# - is_main: является ли изображение главным (true/false)
# - position: порядковый номер изображения
# - access: уровень доступа — `public` или `private`
#
# Пример использования:
#
#   PhotoUploader.enqueue({
#     entity_type: "property",
#     entity_id: "d04a...",
#     agency_id: "a81b...",
#     user_id: "5c7f...",
#     file_url: "https://s3.ps.kz/bucket/.../photo.webp",
#     is_main: true,
#     position: 1,
#     access: "public"
#   })

require 'redis'
require 'json'

class PhotoUploader
  # Имя очереди Sidekiq, в которую будут помещаться задачи
  QUEUE_NAME = 'photo_worker'

  class << self
    ##
    # Помещает задачу в Redis-очередь в формате JSON
    #
    # @param payload [Hash] данные о фото, передаваемые в основной Rails API
    # @option payload [String] :entity_type тип сущности, например: "property"
    # @option payload [String] :entity_id UUID сущности
    # @option payload [String] :agency_id UUID агентства
    # @option payload [String] :user_id UUID пользователя
    # @option payload [String] :file_url полный URL до файла
    # @option payload [Boolean] :is_main является ли фото главным
    # @option payload [Integer] :position порядковый номер фото
    # @option payload [String] :access "public" или "private"
    #
    # @raise [StandardError] при ошибке записи в Redis
    def enqueue(payload)
      redis.lpush("queue:#{QUEUE_NAME}", JSON.dump(payload))
    rescue => e
      raise StandardError, "Redis push failed: #{e.message}"
    end

    private

    ##
    # Возвращает подключение к Redis (лениво инициализируемое)
    #
    # @return [Redis] экземпляр клиента Redis
    def redis
      @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
    end
  end
end
