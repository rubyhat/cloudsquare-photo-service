# frozen_string_literal: true

module FileHelpers
  # Считает общий размер всех файлов в байтах
  #
  # @param files [Array<Hash>] массив с ключом :tempfile
  # @return [Integer] размер в байтах
  def total_file_size(files)
    Array(files).sum { |f| f[:tempfile].size }
  end
end
