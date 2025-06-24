# frozen_string_literal: true

# ImageProcessor — сервис обработки изображений для микросервиса загрузки фотографий.
#
# Возможности:
# - Конвертация любых форматов (JPG, PNG, HEIC и др.) в `.webp`
# - Пропорциональное уменьшение до размера 1920x1920 по большей стороне
# - Использует MiniMagick (обёртка над ImageMagick)
# - Возвращает временный файл в формате `.webp`
#
# Требует установленного ImageMagick с поддержкой формата HEIF (для HEIC-файлов с iOS).
# Используется в UploadRoute перед загрузкой в S3.
#
# Пример:
#   webp_tempfile = ImageProcessor.process('/tmp/input.jpg')
#   File.exist?(webp_tempfile.path) #=> true

require 'mini_magick'
require 'securerandom'
require 'tempfile'

class ImageProcessor
  # Максимальный размер по ширине/высоте (в пикселях)
  MAX_DIMENSION = 1920

  # Качество выходного .webp изображения (0–100)
  QUALITY = 85

  class << self
    ##
    # Обрабатывает изображение:
    # - открывает файл по указанному пути
    # - автоматически поворачивает (если требуется)
    # - уменьшает размер до MAX_DIMENSION по большей стороне
    # - конвертирует в формат WebP
    # - сохраняет во временный файл
    #
    # @param path [String] путь к входному изображению (jpg, png, heic и т.д.)
    # @return [Tempfile] временный файл с .webp изображением
    # @raise [StandardError] в случае ошибки обработки
    def process(path)
      # Открываем изображение с помощью MiniMagick
      image = MiniMagick::Image.open(path)

      # Исправляем ориентацию (важно для iPhone/HEIC и др.)
      image.auto_orient

      # Пропорционально уменьшаем, если превышает MAX_DIMENSION
      image.resize "#{MAX_DIMENSION}x#{MAX_DIMENSION}>"

      # Создаём временный файл для .webp (с бинарным режимом)
      temp = Tempfile.new(%w[processed_ .webp], binmode: true)

      # Устанавливаем формат и качество
      image.format 'webp'
      image.quality QUALITY.to_s

      # Сохраняем изображение в temp
      image.write(temp.path)

      # Возвращаем Tempfile (обработчик должен вызвать unlink при завершении)
      temp
    rescue => e
      # Преобразуем любую ошибку в понятное исключение
      raise StandardError, "Image processing failed: #{e.message}"
    end
  end
end
