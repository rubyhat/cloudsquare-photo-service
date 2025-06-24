# frozen_string_literal: true

# JwtDecoder — сервис для валидации и декодирования JWT access токена.
#
# Используется для аутентификации пользователей по access_token, передаваемому в заголовке.
# Алгоритм подписи — HS256. Секретный ключ должен быть определён в переменной окружения `JWT_SECRET`.
#
# Пример использования:
#
#   token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
#   payload = JwtDecoder.decode(token)
#   if payload
#     puts payload[:sub] # => UUID пользователя
#   else
#     puts 'Invalid or expired token'
#   end
#
# Возвращаемый payload всегда содержит символизированные ключи: `:sub`, `:role`, `:agency_id`, и т.д.

require 'jwt'

class JwtDecoder
  class << self
    ##
    # Декодирует JWT access токен и возвращает payload
    #
    # @param token [String] access token из заголовка Authorization
    # @return [Hash, nil] Расшифрованный payload с символизированными ключами или nil, если токен невалидный или истёк
    def decode(token)
      # JWT.decode возвращает массив [payload, header]
      payload, = JWT.decode(
        token,
        ENV['JWT_SECRET'],
        true, # проверка подписи
        algorithm: 'HS256'
      )

      # Преобразуем ключи в символы для единообразия
      symbolize_keys(payload)
    rescue JWT::DecodeError, JWT::ExpiredSignature
      # Вернём nil в случае невалидного токена или истечения срока действия
      nil
    end

    private

    ##
    # Преобразует все string-ключи в symbol-ключи
    #
    # @param hash [Hash{String => Object}] исходный хэш
    # @return [Hash{Symbol => Object}] хэш с символизированными ключами
    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
