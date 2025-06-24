# frozen_string_literal: true

# JwtDecoder — сервис для валидации и декодирования JWT access токена.
# Использует HS256 и секрет, заданный в ENV["JWT_SECRET"].
#
# Пример:
#   payload = JwtDecoder.decode(token)
#   payload["sub"] #=> user_id

require 'jwt'

class JwtDecoder
  class << self
    # @param token [String] JWT access token
    # @return [Hash, nil] payload or nil if invalid
    def decode(token)
      payload, = JWT.decode(token, ENV['JWT_SECRET'], true, algorithm: 'HS256')
      symbolize_keys(payload)
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    private

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
