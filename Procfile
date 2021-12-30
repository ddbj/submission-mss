ember: yarn --cwd frontend start --port ${EMBER_PORT:-4200} --proxy http://${HOST:-localhost}:${RAILS_PORT:-3000}
rails: cd backend && bin/rails server --port ${RAILS_PORT:-3000}
sidekiq: cd backend && bundle exec sidekiq
