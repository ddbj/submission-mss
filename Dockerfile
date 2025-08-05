# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t mssform .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name mssform mssform

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    TZ="Japan"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

FROM docker.io/library/node:24.5.0 AS web

ARG RAILS_ENV

ENV RAILS_ENV=${RAILS_ENV:?}

RUN corepack enable pnpm

WORKDIR /config
COPY config/app.yml config/enums.yml ./

WORKDIR /web
COPY web/ ./
RUN --mount=type=cache,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile
RUN pnpm build




# Final stage for app image
FROM base

ARG APP_UID
ARG APP_GID

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y unzip gzip ncompress bzip2 lzip lzma lzop xz-utils zstd && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails
COPY --from=web /web/dist/ /rails/public

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid ${APP_GID:?} rails && \
    useradd rails --uid ${APP_UID:?} --gid ${APP_GID:?} --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER ${APP_UID:?}:${APP_GID:?}

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
