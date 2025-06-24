up-dev:
	bundle exec rerun --pattern '**/*.rb' -- falcon serve --bind http://localhost:9292
up-prod:
	 bundle exec rerun --pattern '**/*.rb' -- falcon serve
