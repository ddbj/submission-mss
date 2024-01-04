ARG NODE_VERSION
ARG RUBY_VERSION

FROM curlimages/curl:8.5.0 AS openid-configuration

ARG OPENID_CONFIGURATION_ENDPOINT

WORKDIR /app/config/
RUN curl ${OPENID_CONFIGURATION_ENDPOINT:?} > ./openid-configuration.json

###

FROM node:${NODE_VERSION:?} AS frontend

ARG MASS_DIR_PATH_TEMPLATE
ARG OPENID_CLIENT_ID

ENV MASS_DIR_PATH_TEMPLATE=${MASS_DIR_PATH_TEMPLATE:?}
ENV OPENID_CLIENT_ID=${OPENID_CLIENT_ID:?}

RUN corepack enable
RUN corepack prepare pnpm@latest-8 --activate

WORKDIR /app/config/
COPY ./config/ ./
COPY --from=openid-configuration /app/config/openid-configuration.json ./

WORKDIR /app/frontend/
COPY ./frontend/ ./
RUN --mount=type=cache,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile
RUN pnpm build

###

FROM ruby:${RUBY_VERSION:?}

ARG APP_GID
ARG APP_UID

ENV BUNDLE_CLEAN=true
ENV BUNDLE_DEPLOYMENT=true
ENV BUNDLE_JOBS=4
ENV BUNDLE_PATH=/app/backend/vendor/bundle/
ENV BUNDLE_WITHOUT=development:test
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true
ENV TZ=Japan

EXPOSE 3000

COPY ./docker/rails/irbrc /.irbrc

RUN apt-get update && apt-get install --assume-yes \
  unzip \
  gzip \
  ncompress \
  bzip2 \
  lzip \
  lzma \
  lzop \
  postgresql-client \
  xz-utils \
  zstd \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN gem update --system

WORKDIR /app/config/
COPY ./config/ ./
COPY --from=openid-configuration /app/config/openid-configuration.json ./

WORKDIR /app/backend/
COPY ./backend/ ./
RUN --mount=type=cache,target=/tmp/bundle/ BUNDLE_PATH=/tmp/bundle/ bundle install && cp --recursive --no-target-directory /tmp/bundle/ ./vendor/bundle/
COPY --from=frontend /app/frontend/dist/ ./public/
RUN install --directory --owner=${APP_UID:?} --group=${APP_GID:?} ./tmp/

USER ${APP_UID:?}:${APP_GID:?}
CMD rm -f ./tmp/pids/server.pid && bin/rails db:prepare && exec bin/rails server --binding 0.0.0.0
