# Based on https://github.com/ledermann/docker-rails/blob/develop/Dockerfile
ARG RUBY_VERSION
# NOTE FROM clears all ARGs
FROM ruby:$RUBY_VERSION-alpine3.18

ARG BUNDLER_VERSION
ARG USER_ID=1001
ARG GROUP_ID=1001

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
  build-base libxml2-dev libxslt-dev postgresql-dev gcompat \
  libgcc libstdc++ libx11 glib libxrender libxext libintl \
  ttf-dejavu ttf-droid ttf-freefont ttf-liberation \
  chromium nss freetype freetype-dev harfbuzz ca-certificates \
  lftp postgresql tmux postgis geos geos-dev proj proj-dev proj-util zip expect \
  shared-mime-info docker \
  vim less \
  tar xz p7zip \
  python3 py3-pip \
  && git config --global --add safe.directory /app

RUN pip3 install awscliv2 awscli

RUN mkdir /app
WORKDIR /app

# Upgrade RubyGems and install required Bundler version
RUN gem update --system \
    && gem install bundler:$BUNDLER_VERSION

RUN addgroup -g ${GROUP_ID} app \
  && adduser -u ${USER_ID} -G app -h /home/app -D app

# Install gems
COPY --chown=app:app Gemfile /app/Gemfile
COPY --chown=app:app Gemfile.lock /app/Gemfile.lock

ENV BUNDLE_PATH=/bundle
ENV GEM_HOME=/bundle
ENV BUNDLE_JOBS=4
ENV BUNDLE_RETRY=3
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH
ENV BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH=$BUNDLE_BIN:$PATH:/app/bin
COPY docker/entrypoint.sh /usr/bin/
COPY docker/spec.entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/spec.entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# We should do this, but I don't want to break anything for anybody
# USER app
