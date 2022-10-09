ARG NODE_VERSION
ARG RUBY_VERSION

# >=curl-7.85 resolves *.localhost to 127.0.0.1
# https://github.com/curl/curl/pull/9296
FROM curlimages/curl:7.84.0 AS openid-configuration

ARG OPENID_CONFIGURATION_ENDPOINT

WORKDIR /app/config/
RUN curl ${OPENID_CONFIGURATION_ENDPOINT:?} > ./openid-configuration.json

###

FROM node:${NODE_VERSION:?} AS frontend

ARG OPENID_CLIENT_ID

ENV OPENID_CLIENT_ID=${OPENID_CLIENT_ID:?}

WORKDIR /app/config/
COPY ./config/ ./
COPY --from=openid-configuration /app/config/openid-configuration.json ./

WORKDIR /app/frontend/
COPY ./frontend/ ./
RUN --mount=type=cache,target=/tmp/node_modules yarn install --frozen-lockfile --modules-folder /tmp/node_modules/ && cp --recursive --no-target-directory /tmp/node_modules/ ./node_modules/
RUN yarn build

###

FROM ruby:${RUBY_VERSION:?}

ARG APP_GID
ARG APP_UID
ARG BUNDLER_VERSION

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

RUN gem install bundler --version ${BUNDLER_VERSION:?} --no-document

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
