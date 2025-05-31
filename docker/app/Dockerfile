# syntax = docker/dockerfile:1-experimental

###########################################
## Dependencies just needed during build ##
###########################################
ARG BUILD_TAG
FROM ruby:${BUILD_TAG} AS cert

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
  openssl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /

RUN openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
  -subj "/C=US/ST=Vermont/L=Brattleboro/O=greenriver/CN=www.example.com" \
  -keyout key.pem -out cert.pem


#########################
## global dependencies ##
#########################

ARG BUILD_TAG
FROM ruby:${BUILD_TAG} AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG USER_ID=10000
ARG GROUP_ID=10000
ARG BUNDLER_VERSION=2.6.3

LABEL "app"=open-path-warehouse
LABEL "ruby-version"=3.3.7

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV GEM_HOME=/bundle
ENV BUNDLE_JOBS=4
ENV BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH
ENV BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH /app/bin:$BUNDLE_BIN:$PATH
# https://github.com/sass/sassc-ruby/issues/146#issuecomment-542288556
# core dumps during precompile on github when using the pre-cache image pulled
# from ECR
ENV BUNDLE_BUILD__SASSC=--disable-march-tune-native
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true
# Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV GROVER_NO_SANDBOX=true
ENV CHROMIUM_PATH=/usr/bin/chromium

# Allow tls connection to database with verification
COPY docker/app/us-east-1-bundle.pem  /etc/ssl/certs/us-east-1-bundle.pem
# Deprecated and soon to expire
COPY docker/app/rds-combined-ca-bundle.pem /etc/ssl/certs/rds-combined-ca-bundle.pem

RUN groupadd -g ${GROUP_ID} app-user \
  && useradd -l -u ${USER_ID} -g app-user -s /bin/bash -d /home/app-user -m app-user \
  && mkdir /app /bundle \
  && chown app-user:app-user /bundle /app

# Add PostgreSQL official repository
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates lsb-release gnupg \
  && sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
  && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg \
  && apt-get update \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  locales-all \
  nodejs yarnpkg \
  awscli \
  tzdata \
  git \
  bash \
  build-essential \
  freetds-dev \
  libicu-dev \
  libcurl4 libcurl4-openssl-dev \
  imagemagick \
  libmagic1 libheif1 libmagic-dev file \
  libxml2-dev libxslt1-dev libpq-dev \
  libx11-6 libglib2.0-0 libxrender1 libxext6 \
  fonts-dejavu fonts-droid-fallback fonts-freefont-ttf fonts-liberation \
  chromium chromium-common libfreetype6 libfreetype-dev libharfbuzz-dev ca-certificates \
  lftp postgresql-16 postgresql-client-16 postgresql-17 postgresql-client-17 postgresql-17-postgis-3 \
  tmux libgeos-dev proj-bin libproj-dev zip expect \
  shared-mime-info libyaml-dev libffi-dev \
  tar p7zip-full vim gpg gnupg-agent poppler-utils \
  && rm -rf /var/lib/apt/lists/* \
  && if [ "$(uname -m)" = "aarch64" ]; then \
       ln -s /usr/lib/aarch64-linux-gnu/libproj.so /usr/lib/libproj.so.20; \
     else \
       ln -s /usr/lib/x86_64-linux-gnu/libproj.so /usr/lib/libproj.so.20; \
     fi \
  && ln -s /usr/bin/yarnpkg /usr/bin/yarn

WORKDIR /app

RUN gem update --system \
  && gem install bundler --version=${BUNDLER_VERSION} \
  && bundle config set --local path /bundle \
  && chown -R app-user:app-user /bundle \
  && echo 'America/New_York' > /etc/timezone \
  && chmod a+w /etc/timezone

USER ${USER_ID}

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

#########################################
## Stage/target for use in development ##
#########################################

FROM base AS dev-build

USER root

COPY docker/app/entrypoint.dev.sh /usr/bin/
COPY docker/app/entrypoint.spec.sh /usr/bin/
COPY docker/app/entrypoint.dj-eks-test.sh /usr/bin/
ENTRYPOINT ["/usr/bin/entrypoint.dev.sh"]

RUN git config --global --add safe.directory /app \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  neovim less docker.io python3 zsh openssh-client \
  && rm -rf /var/lib/apt/lists/*

USER ${USER_ID}

########################################
## Stage/target for use in production ##
########################################

FROM base AS prod-build

COPY docker/app/entrypoint.sh /usr/bin/
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

COPY --chown=app-user:app-user --from=cert /key.pem /cert.pem /app/config/
COPY --chown=app-user:app-user Gemfile Gemfile.lock ./

RUN bundle config without development test doc \
  && bundle install \
  && find /bundle -name "*.o" -exec rm {} \; \
  && find /bundle -name "*.c" -exec rm {} \;

COPY --chown=app-user:app-user package.json yarn.lock ./
RUN yarn install --frozen-lockfile \
  && yarn cache clean

COPY --chown=app-user:app-user . ./
COPY --chown=app-user:app-user sample.irbrc ./.irbrc
COPY --chown=app-user:app-user docker/app/REVISION ./
COPY --chown=app-user:app-user docker/app/GIT_BRANCH ./
COPY --chown=app-user:app-user docker/app/database.open-path-warehouse.yml ./config/database.yml

RUN rm -rf tmp/* \
  && mkdir -p tmp/pids public/assets var
