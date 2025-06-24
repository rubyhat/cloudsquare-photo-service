require 'sinatra/base'
require 'sinatra/json'
require_relative '../helpers/auth_helpers'
require_relative '../services/s3_uploader'

class PresignedUrlRoute < Sinatra::Base
  helpers Sinatra::JSON
  helpers AuthHelpers

  get '/presigned-url' do
    payload = parse_token

    unless %w[agent agent_manager agent_admin].include?(payload[:role])
      halt 403, json(error: 'You do not have permission to view private files')
    end

    key = params['key']
    halt 400, json(error: 'Missing key parameter') unless key

    begin
      url = S3Uploader.presigned_url(key)
      json(url: url)
    rescue => e
      logger.error "Failed to generate presigned URL: #{e.message}"
      halt 500, json(error: 'Could not generate presigned URL')
    end
  end
end