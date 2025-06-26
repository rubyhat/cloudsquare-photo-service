# Makefile — команды для запуска микросервиса изображений

# Переменные окружения по умолчанию
ENV_FILE_TEST=.env.test
ENV_FILE_DEV=.env.development
ENV_FILE_PROD=.env.production

# 🔧 Устанавливает зависимости из Gemfile
install:
	bundle install

# 🚀 Запуск сервиса в режиме разработки (с автоперезапуском при изменениях .rb-файлов)
up-dev-local:
	bundle exec rerun --pattern '**/*.rb' -- falcon serve --bind http://localhost:9292

## 🚀 Запустить dev-среду (локально с volumes и портами)
up-dev:
	docker compose --env-file $(ENV_FILE_DEV) up --build

# 🚀 Запуск сервиса в продакшн режиме (без автоперезапуска)
up-prod:
	bundle exec falcon serve
