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

| Variable                     | Default                 | Notes                                                                                                                              |
| ---------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `KEYCLOAK_URL`               | `http://localhost:8080` | Base URL of the Keycloak instance                                                                                                  |
| `KEYCLOAK_CLIENT_SECRET`     | —                       | Secret of the `mssform` client                                                                                                     |
| `KEYCLOAK_BEARER_CLIENT_IDS` | — (empty: off)          | Comma-separated client IDs whose access tokens may call the API (see [Bearer tokens](#bearer-tokens-nucleotide-submission-portal)) |
| `SEAWEEDFS_ACCESS_KEY`       | —                       | Access key of the `mssform` identity                                                                                               |
| `SEAWEEDFS_SECRET_KEY`       | —                       | Secret key of the `mssform` identity                                                                                               |
| `APP_URL`                    | `http://localhost:3000` | Origin of the Rails API                                                                                                            |
| `WEB_URL`                    | `http://localhost:4200` | Origin of the Ember SPA                                                                                                            |

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

## Bearer tokens (Nucleotide submission portal)

Another client of the same Keycloak realm -- the Nucleotide submission portal (GGS) -- may
call a few endpoints on a signed-in user's behalf, with the access token the
realm issued to it in `Authorization: Bearer <token>`. Such a request is
authenticated by the token alone: no session cookie is read or issued, and no
`X-CSRF-Token` is needed.

**Only the actions that opt in accept a token** (`allow_bearer only: ...` in the
controller). Any other action answers a request carrying a token with 401, even
when a valid session cookie comes with it. Today these are:

| Endpoint                                 | Controller                              |
| ---------------------------------------- | --------------------------------------- |
| `GET /api/me`                            | `MesController#show`                    |
| `POST /api/ggs_extractions`              | `GgsExtractionsController#create`       |
| `GET /api/ggs_extractions/:id`           | `GgsExtractionsController#show`         |
| `POST /api/submissions`                  | `SubmissionsController#create`          |
| `GET /api/submissions/:mass_id`          | `SubmissionsController#show`            |
| `POST /api/submissions/:mass_id/uploads` | `Submissions::UploadsController#create` |
| `POST /api/direct_uploads`               | `DirectUploadsController#create`        |

A token is accepted only if it is signed (RS256) by a key the realm publishes,
and its `iss` is `issuer`, its `aud` contains `client_id` (`mssform`), its `typ`
is `Bearer`, its `azp` is one of `bearer_client_ids`, its space-separated
`scope` contains `bearer_scope` (`mss-submission`), it carries a `sid` (tokens
of service accounts have none and are refused) and a non-blank
`preferred_username`, and it has not expired (30 seconds of leeway). The
settings live in `config/keycloak.yml`; in production and staging,
`bearer_client_ids` comes from the credentials as a list
(`keycloak.bearer_client_ids: [ggs-portal]`). The realm's keys are cached in
`Rails.cache` for an hour, and the realm is asked for them at most once a minute.

### User identity

As with the session login (`SessionsController#create`), the user is identified
by the token's `preferred_username`. A user MSS has not seen yet is created
with the token's `email` (a token without one is refused); an existing user's
address is never changed by a token -- only their own sign-in to MSS updates it.

`preferred_username` in the portal's tokens therefore has to be the realm
username and nothing else:

- It comes from an explicit mapper in the `mss-submission` client scope (below),
  not from whatever mappers the portal client happens to have.
- The portal client, its scopes and their mappers are administered by the DDBJ
  Keycloak administrators, like MSS's own `mssform` client.
- The realm has **Edit username** OFF (Realm settings → Login), so users cannot
  change their username.

### Keycloak setup

1. **Client scope** `mss-submission` (Client scopes → Create client scope):
   - Protocol: OpenID Connect.
   - **Include in token scope: ON.** Without it the scope's name does not appear
     in the token's `scope` claim, and MSS refuses every token.
   - Mappers (Add mapper → By configuration):
     - **Audience**: Included Client Audience `mssform` (MSS's client), Add to
       access token ON. This puts `mssform` in `aud`.
     - **User Attribute** (User Property in older Keycloak) for `username`:
       Token Claim Name `preferred_username`, Claim JSON Type String, Add to
       access token ON.
2. **Portal client**: add `mss-submission` to its client scopes (Optional, and
   requested by the portal as `scope=openid mss-submission`, or Default). Keep
   the realm's `basic` scope assigned so that access tokens carry `sid`.
3. **MSS**: add the portal client's ID to `bearer_client_ids`
   (`KEYCLOAK_BEARER_CLIENT_IDS` in development, the credentials elsewhere).

## GGS job ownership

A GGS import reads the job's files from `ggs_jobs_dir_template` in
`config/app.yml`. GGS also leaves the uid of the user who ran the job in a
`.ggs-owner` file next to `output/` (`ggs_owner_template`). Whenever that file
exists, the import is accepted only if its content is the importing user's uid,
however they signed in; otherwise the extraction is rejected with `not_owner`.

**Transitional:** a job without `.ggs-owner` is still imported. GGS currently
writes the file only for jobs created through the Nucleotide submission portal; once it
writes it for every job run by a logged-in user, a follow-up change will remove
this allowance and refuse jobs without the file (tracked in an issue).

## Deployment

Deployed with [Kamal](https://kamal-deploy.org/). See `config/deploy*.yml` for configuration.

## License

[Apache License 2.0](LICENSE)
