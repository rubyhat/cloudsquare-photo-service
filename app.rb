# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/base'
require 'dotenv/load'
require 'securerandom'
require 'mini_magick'
require 'aws-sdk-s3'
require 'sidekiq'
require 'redis'
require 'tempfile'
require_relative './config/environment'
require_relative './services/jwt_decoder'
require_relative './services/image_processor'
require_relative './services/s3_uploader'
require_relative './uploader/photo_uploader'


class ImageService < Sinatra::Base
  configure do
    enable :logging
    set :allow_origin, :any
    set :max_request_size, 50 * 1024 * 1024 # 50MB max upload
  end

  before do
    content_type :json
  end

  helpers do
    def parse_token
      header = request.env['HTTP_AUTHORIZATION']
      halt 401, json(error: 'Missing Authorization header') unless header

      token = header.split(' ').last
      payload = JwtDecoder.decode(token)
      halt 401, json(error: 'Invalid or expired token') unless payload && payload['type'] == 'access'

      payload
    rescue JWT::DecodeError => e
      logger.error "JWT Decode Error: #{e.message}"
      halt 401, json(error: 'Invalid token')
    end
  end

  post '/upload' do
    payload = parse_token
    user_id = payload['sub']
    agency_id = payload['agency_id']

    unless ['agent', 'agent_manager', 'agent_admin'].include?(payload['role'])
      halt 403, json(error: 'You do not have permission to upload photos')
    end

    files = params['images']
    property_id = params['property_id']
    access = params['access'] || 'public'
    is_main = params['is_main'] == 'true'

    halt 400, json(error: 'No files provided') unless files
    files = [files] unless files.is_a?(Array)

    halt 400, json(error: 'Too many files (max 30)') if files.size > 30

    uploads = files.each_with_index.map do |file, index|
      tempfile = file[:tempfile]
      filename = file[:filename]

      begin
        processed_file = ImageProcessor.process(tempfile.path)

        s3_path = "agency_#{agency_id}/property_#{property_id}/#{access}/#{SecureRandom.uuid}.webp"
        url = S3Uploader.upload(processed_file.path, s3_path, access)

        PhotoUploader.enqueue({
                                property_id: property_id,
                                agency_id: agency_id,
                                user_id: user_id,
                                file_url: url,
                                is_main: is_main && index.zero?,
                                position: index + 1,
                                access: access
                              })

        processed_file.unlink
        { status: 'ok', url: url }
      rescue => e
        logger.error "File upload failed: #{filename}, error: #{e.message}"
        { status: 'error', error: e.message, file: filename }
      end
    end

    json results: uploads
  end

  # run! is handled by config.ru + falcon
end
