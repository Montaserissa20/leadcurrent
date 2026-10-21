#!/usr/bin/env bash
set -o errexit
bundle config set --local without 'development test'
bundle install
npm ci --ignore-scripts
npm run build
bundle exec rails assets:precompile
bundle exec rails db:migrate
if [ "${DEMO_SEED_ENABLED:-false}" = "true" ]; then
  bundle exec rails db:seed
fi
