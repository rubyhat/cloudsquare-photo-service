# frozen_string_literal: true

# ImageProcessor — сервис для обработки изображений:
# - конвертация любых форматов в `.webp`
# - ресайз до 1920x1920 (по большей стороне)
# - сохранение во временный файл
#
# Использует MiniMagick и ImageMagick с поддержкой libheif

require 'mini_magick'
require 'securerandom'
require 'tempfile'

class ImageProcessor
  MAX_DIMENSION = 1920
  QUALITY = 85

  class << self
    # Обрабатывает изображение: ресайз + webp
    # @param path [String] путь к исходному файлу
    # @return [Tempfile] временный файл .webp
    def process(path)
      image = MiniMagick::Image.open(path)

      # Принудительно декодируем HEIC (если ImageMagick поддерживает)
      image.auto_orient
      image.resize "#{MAX_DIMENSION}x#{MAX_DIMENSION}>"

      temp = Tempfile.new(%w[processed_ .webp], binmode: true)
      image.format 'webp'
      image.quality QUALITY.to_s
      image.write(temp.path)

      temp
    rescue => e
      raise StandardError, "Image processing failed: #{e.message}"
    end
  end
end
