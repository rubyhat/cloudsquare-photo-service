# Makefile — команды для запуска микросервиса изображений

# 🔧 Устанавливает зависимости из Gemfile
install:
	bundle install

# 🚀 Запуск сервиса в режиме разработки (с автоперезапуском при изменениях .rb-файлов)
up-dev:
	bundle exec rerun --pattern '**/*.rb' -- falcon serve --bind http://localhost:9292

# 🚀 Запуск сервиса в продакшн режиме (без автоперезапуска)
up-prod:
	bundle exec falcon serve
