# Based on https://github.com/ledermann/docker-rails/blob/develop/Dockerfile
ARG RUBY_VERSION
# NOTE FROM clears all ARGs
FROM ruby:$RUBY_VERSION-alpine

ARG BUNDLER_VERSION

ENV RAILS_ENV ${RAILS_ENV}
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ENV RAILS_LOG_TO_STDOUT=true \
  RAILS_SERVE_STATIC_FILES=true \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US.UTF-8 \
  # Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
  GROVER_NO_SANDBOX=true \
  CHROMIUM_PATH=/usr/bin/chromium-browser

LABEL maintainer="elliot@greenriver.com"

RUN apk add --no-cache \
  nodejs yarn npm \
  tzdata \
  git \
  bash \
  freetds-dev \
  openssh ctags zsh \
  icu icu-dev \
  curl libcurl curl-dev \
  imagemagick \
  libmagic file-dev file \
  build-base libxml2-dev libxslt-dev postgresql-dev \
  wkhtmltopdf libgcc libstdc++ libx11 glib libxrender libxext libintl ttf-dejavu ttf-droid ttf-freefont ttf-liberation \
  chromium nss freetype freetype-dev harfbuzz ca-certificates ttf-freefont \
  lftp postgresql tmux postgis geos geos-dev proj proj-dev \
  shared-mime-info \
  vim less

RUN mkdir /app
WORKDIR /app

# Upgrade RubyGems and install required Bundler version
RUN gem update --system \
    && gem install bundler:$BUNDLER_VERSION

# Install gems
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

ENV BUNDLE_PATH=/bundle
ENV PATH=$PATH:/app/bin
COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
