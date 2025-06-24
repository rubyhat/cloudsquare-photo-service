# frozen_string_literal: true

# Подключает вспомогательные методы для возврата JSON-ответов
require 'sinatra/json'

# Подключает сервис для декодирования JWT access токенов
require_relative '../services/jwt_decoder'

##
# Модуль AuthHelpers предоставляет методы для проверки JWT access токенов
# и извлечения полезной нагрузки (payload) из них.
#
# Используется как `helpers AuthHelpers` внутри Sinatra-приложений или маршрутов.
#
module AuthHelpers
  ##
  # Проверяет наличие и корректность JWT access токена в заголовке запроса `Authorization`.
  #
  # @return [Hash] полезная нагрузка (payload), включая `sub`, `agency_id`, `role`, и другие поля
  #
  # @raise [Sinatra::Halt] 401, если заголовок отсутствует, токен невалиден или истёк
  #
  def parse_token
    header = request.env['HTTP_AUTHORIZATION']
    halt 401, json(error: 'Missing Authorization header') unless header

    token = header.split(' ').last
    payload = JwtDecoder.decode(token)

    # Проверка, что токен валиден и является access-токеном
    halt 401, json(error: 'Invalid or expired token') unless payload && payload[:type] == 'access'

    payload
  rescue JWT::DecodeError => e
    logger.error "JWT Decode Error: #{e.message}"
    halt 401, json(error: 'Invalid token')
  end
end
