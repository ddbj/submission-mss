# CLAUDE.md

DDBJ MSS (Mass Submission System) — monorepo with a Rails API and an Ember.js SPA.

## Tech Stack

- **Backend**: Ruby 4.0.2 / Rails 8.1 (API only) / PostgreSQL / Solid Queue / Solid Cache
- **Frontend**: Ember.js 6 / TypeScript / GTS (`.gts`) / Bootstrap 5 / Vite
- **Storage**: SeaweedFS (S3-compatible) + Active Storage direct upload
- **Auth**: OpenID Connect (Keycloak)
- **Schema**: `schema/openapi.yml` is the single source of truth for the API. Types are generated to `schema/openapi.d.ts`

## Commands

```bash
# Start all dev services (Rails + Ember + SeaweedFS + Keycloak)
bin/dev

# Rails tests
bundle exec rspec
bundle exec rspec spec/requests/submissions_spec.rb

# Ember tests (build + test)
cd web && pnpm test:ember

# Lint
bin/rubocop -A                    # Ruby
cd web && pnpm lint:fix           # JS/TS/CSS/HBS + Prettier
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
├── config/deploy*.yml     Kamal deployment config
├── spec/                  RSpec tests
│   ├── requests/          Request specs (OpenAPI validation via skooma)
│   └── factories/         FactoryBot factories
├── schema/openapi.yml     OpenAPI schema
│
web/                       Ember.js frontend
├── app/components/        GTS components
├── app/models/            Frontend models
├── app/request-handlers/  @ember-data/request handlers
├── app/services/          Ember services
├── public/workers/        Web Workers (file parsers, etc.)
└── tests/                 QUnit + MSW tests
```

## Conventions

### RSpec

- `describe` takes a resource path, `example` takes an action name
- Validate OpenAPI conformance with `conform_schema(status_code)`

```ruby
RSpec.describe '/api/submissions', type: :request do
  example 'index' do
    get '/api/submissions', headers: default_headers
    expect(response).to conform_schema(200)
  end
end
```

### Ember / TypeScript

- GTS template tag format (`<template>` block)
- API calls go through the RequestManager handler chain (`@ember-data/request`)
- Reference OpenAPI types as `paths['/endpoint']['method']['responses']['200']['content']['application/json']`
- Tests use MSW + openapi-msw for mocking

### API Responses

- Use `head :no_content` (204) for bodiless success responses. `head :ok` causes JSON parse errors on the client
- Return JSON via jb templates
