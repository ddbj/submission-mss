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
- A SeaweedFS instance — in development we point at one running on the host, shared with the other projects
- A Keycloak instance — in development we point at the one from [cloakman](https://github.com/ddbj/cloakman)

## Setup

Neither SeaweedFS nor Keycloak is started by `bin/dev` — the application talks
to instances running outside it (in development, the host's SeaweedFS and
cloakman's Keycloak). Point it at them through the environment:

| Variable                 | Default                 | Notes                                  |
| ------------------------ | ----------------------- | -------------------------------------- |
| `KEYCLOAK_URL`           | `http://localhost:8080` | Base URL of the Keycloak instance      |
| `KEYCLOAK_CLIENT_SECRET` | —                       | Secret of the `mssform` client         |
| `SEAWEEDFS_ACCESS_KEY`   | —                       | Access key of the `mssform` identity   |
| `SEAWEEDFS_SECRET_KEY`   | —                       | Secret key of the `mssform` identity   |
| `APP_URL`                | `http://localhost:3000` | Origin of the Rails API                |
| `WEB_URL`                | `http://localhost:4200` | Origin of the Ember SPA                |

### SeaweedFS

The development instance is shared with the other projects, so this application
is given a bucket of its own and an identity that reaches no further. Create
both once, on the machine the instance runs on:

```bash
echo 's3.bucket.create -name mssform' | weed shell

echo 's3.configure -user=mssform -buckets=mssform -actions=Read,Write,List -access_key=<access key> -secret_key=<secret key> -apply' | weed shell
```

The browser uploads files to the instance directly, so it answers the preflight
requests itself: start it with `-s3.allowedOrigins=http://localhost:4200`, the
origin the SPA is served from. The endpoint and the bucket name live in
`config/seaweedfs.yml`.

Without the keys the AWS SDK works its way down to the EC2 metadata service, so
a timeout against 169.254.169.254 is the environment talking, not the instance.

### Application

`bin/setup` starts the application when it is done, so leave it until the
storage is in place:

```bash
bin/setup
cd web && pnpm install
```

## Development

Start Rails and Ember:

```bash
bin/dev
```

| Service   | URL                     |
| --------- | ----------------------- |
| Rails API | http://localhost:3000   |
| Ember SPA | http://localhost:4200   |

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
├── workers/               Web Workers (file parsers), bundled by Vite
└── tests/                 QUnit + MSW tests
```

## Deployment

Deployed with [Kamal](https://kamal-deploy.org/). See `config/deploy*.yml` for configuration.

## License

[Apache License 2.0](LICENSE)
