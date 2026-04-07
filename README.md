# MSS Form

Web portal for submitting nucleotide sequences to [DDBJ](https://www.ddbj.nig.ac.jp/) via the Mass Submission System (MSS). Monorepo containing a Rails API backend and an Ember.js SPA frontend.

## Tech Stack

- **Backend**: Ruby 4.0 / Rails 8.1 (API only) / PostgreSQL
- **Frontend**: Ember.js 6 / TypeScript / GTS (`.gts`) / Bootstrap 5 / Vite
- **Job Queue / Cache**: Solid Queue / Solid Cache
- **Storage**: SeaweedFS (S3-compatible) + Active Storage
- **Auth**: OpenID Connect (Keycloak)
- **API Schema**: OpenAPI (`schema/openapi.yml`)

## Requirements

- Ruby (see `.ruby-version`)
- Node.js (see `.node-version`)
- pnpm (see `packageManager` in `web/package.json`)
- PostgreSQL
- Docker (for SeaweedFS and Keycloak in development)

## Setup

```bash
bin/setup
cd web && pnpm install
```

## Development

Start all services (Rails, Ember, SeaweedFS, Keycloak):

```bash
bin/dev
```

| Service   | URL                          |
| --------- | ---------------------------- |
| Rails API | http://mssform.localhost:3000 |
| Ember SPA | http://mssform.localhost:4200 |
| Keycloak  | http://localhost:8080         |

## Testing

```bash
# Rails
bin/rails test
bin/rails test test/integration/submissions_test.rb  # single file

# Ember
cd web && pnpm test:ember
```

## Linting

```bash
bin/rubocop -A          # Ruby
cd web && pnpm lint:fix # JS/TS/CSS/HBS + Prettier
```

## Project Structure

```
/                          Rails application (API)
├── app/controllers/       API endpoints
├── app/models/            ActiveRecord models
├── app/jobs/              Solid Queue jobs
├── app/views/             jb templates (JSON responses)
├── config/app.yml         App-specific config (URLs, paths)
├── config/enums.yml       Enumerize enum definitions
├── test/                  Minitest tests
├── schema/openapi.yml     OpenAPI schema
│
web/                       Ember.js frontend
├── app/components/        GTS components
├── app/models/            Frontend models
├── app/request-handlers/  @ember-data/request handlers
├── app/services/          Ember services
├── public/workers/        Web Workers (file parsers)
└── tests/                 QUnit + MSW tests
```

## Deployment

Deployed with [Kamal](https://kamal-deploy.org/). See `config/deploy*.yml` for configuration.

## License

[Apache License 2.0](LICENSE)
