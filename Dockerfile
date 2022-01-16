FROM node:16 AS frontend

ARG OPENID_CLIENT_ID
ARG OPENID_CONFIGURATION_ENDPOINT

ENV OPENID_CLIENT_ID=${OPENID_CLIENT_ID:?}

WORKDIR /app/frontend

COPY ./config /app/config
COPY ./frontend /app/frontend
RUN curl ${OPENID_CONFIGURATION_ENDPOINT:?} > /app/config/openid-configuration.json
RUN --mount=type=cache,target=/tmp/node_modules yarn install --frozen-lockfile --modules-folder /tmp/node_modules && cp --recursive --no-target-directory /tmp/node_modules ./node_modules
RUN yarn build

###

FROM ruby:3.1

ENV BUNDLE_CLEAN=true
ENV BUNDLE_DEPLOYMENT=true
ENV BUNDLE_JOBS=4
ENV BUNDLE_PATH=/app/backend/vendor/bundle
ENV BUNDLE_WITHOUT=development:test
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true
ENV SUBMISSIONS_DIR=/app/submissions
ENV TZ=Japan

EXPOSE 3000

RUN gem install bundler:2.3.4

WORKDIR /app/backend

COPY ./config /app/config
COPY ./backend /app/backend
RUN --mount=type=cache,target=/tmp/bundle BUNDLE_PATH=/tmp/bundle bundle install && cp --recursive --no-target-directory /tmp/bundle ./vendor/bundle
COPY --from=frontend /app/frontend/dist/ ./public/

CMD ["bin/rails", "server", "--binding", "0.0.0.0"]
