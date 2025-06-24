# frozen_string_literal: true

require_relative './config/environment'
require_relative './routes/upload_route'
require_relative './routes/presigned_url_route'

class ImageService < Sinatra::Base
  configure do
    enable :logging
    set :allow_origin, :any
    set :max_request_size, 100 * 1024 * 1024 # 100MB общий размер загрузки
  end

  before do
    content_type :json
  end

  use UploadRoute
  use PresignedUrlRoute
end
