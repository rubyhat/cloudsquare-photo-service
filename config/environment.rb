require 'bundler/setup'
Bundler.require(:default)

Dotenv.load

require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*' # Или конкретные домены: 'https://admin.cloudsquares.kz'
    resource '*',
             headers: :any,
             methods: [:get, :post, :options],
             expose: ['Authorization']
  end
end

require_relative '../services/jwt_decoder'
require_relative '../services/image_processor'
require_relative '../services/s3_uploader'
require_relative '../uploader/photo_uploader'

