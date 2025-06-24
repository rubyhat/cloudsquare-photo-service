# frozen_string_literal: true

require 'sinatra/json'
require_relative '../services/jwt_decoder'

module AuthHelpers
  def parse_token
    header = request.env['HTTP_AUTHORIZATION']
    halt 401, json(error: 'Missing Authorization header') unless header

    token = header.split(' ').last
    payload = JwtDecoder.decode(token)
    halt 401, json(error: 'Invalid or expired token') unless payload && payload[:type] == 'access'

    payload
  rescue JWT::DecodeError => e
    logger.error "JWT Decode Error: #{e.message}"
    halt 401, json(error: 'Invalid token')
  end
end
