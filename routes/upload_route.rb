# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'securerandom'

require_relative '../helpers/auth_helpers'
require_relative '../helpers/file_helpers'
require_relative '../services/image_processor'
require_relative '../services/s3_uploader'
require_relative '../uploader/photo_uploader'

class UploadRoute < Sinatra::Base
  helpers Sinatra::JSON
  helpers AuthHelpers
  helpers FileHelpers

  post '/upload' do
    payload = parse_token
    user_id = payload[:sub]
    agency_id = payload[:agency_id]

    unless %w[agent agent_manager agent_admin].include?(payload[:role])
      halt 403, json(error: 'You do not have permission to upload photos')
    end

    files = params['images']
    entity_type = params['entity_type']&.downcase
    entity_id = params['entity_id']
    access = params['access'] || 'public'
    is_main = params['is_main'] == 'true'

    halt 400, json(error: 'No files provided') unless files
    halt 400, json(error: 'Missing entity_type') unless entity_type
    halt 400, json(error: 'Missing entity_id') unless entity_id

    files = [files] unless files.is_a?(Array)
    halt 400, json(error: 'Too many files (max 30)') if files.size > 30
    halt 400, json(error: 'Total size exceeds 100MB') if total_file_size(files) > 100 * 1024 * 1024

    uploads = files.each_with_index.map do |file, index|
      tempfile = file[:tempfile]
      filename = file[:filename]

      begin
        processed_file = ImageProcessor.process(tempfile.path)

        s3_path = if agency_id && !agency_id.empty?
                    "agency_#{agency_id}/#{entity_type}_#{entity_id}/#{access}/#{SecureRandom.uuid}.webp"
                  else
                    "undefined_agency/#{entity_type}_#{entity_id}/#{access}/#{SecureRandom.uuid}.webp"
                  end

        url = S3Uploader.upload(processed_file.path, s3_path, access)

        PhotoUploader.enqueue({
                                entity_type: entity_type,
                                entity_id: entity_id,
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
end
