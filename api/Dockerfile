# syntax = docker/dockerfile:1

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t my-app .
# docker run -d -p 80:80 -p 443:443 --name my-app -e RAILS_MASTER_KEY=<value from config/master.key> my-app

ARG NODE_VERSION
ARG RUBY_VERSION

FROM node:${NODE_VERSION:?} AS web

ARG MASS_DIR_PATH_TEMPLATE

ENV MASS_DIR_PATH_TEMPLATE=${MASS_DIR_PATH_TEMPLATE:?}

RUN corepack enable pnpm

WORKDIR /app/web/
COPY ./web/ ./
RUN --mount=type=cache,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile
RUN pnpm build

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /app/api

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    TZ=Japan

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY api/Gemfile api/Gemfile.lock api/.ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY api/ .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/




# Final stage for app image
FROM base

ARG APP_GID
ARG APP_UID

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y unzip gzip ncompress bzip2 lzip lzma lzop xz-utils zstd && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /app/api /app/api
COPY --from=web /app/web/dist/ /app/api/public

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid ${APP_GID:?} rails && \
    useradd rails --uid ${APP_UID:?} --gid ${APP_GID:?} --create-home --shell /bin/bash && \
    chown -R rails:rails log tmp
USER ${APP_UID:?}:${APP_GID:?}

# Entrypoint prepares the database.
ENTRYPOINT ["/app/api/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
