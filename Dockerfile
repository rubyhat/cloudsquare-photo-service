FROM ruby:3.4.2-slim

WORKDIR /app
COPY . .

RUN apt-get update -qq && apt-get install --no-install-recommends -y \
  build-essential \
  libvips \
  libpq-dev \
  libyaml-dev \
  imagemagick \
  && gem install bundler \
  && bundle install

CMD ["bundle", "exec", "falcon", "serve", "--bind", "http://0.0.0.0:9292"]
