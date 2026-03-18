# MSS Form

A submission management system for [DDBJ Mass Submission System (MSS)](https://www.ddbj.nig.ac.jp/ddbj/mss.html).

## Tech Stack

- **Backend:** Ruby on Rails, Puma, Solid Queue
- **Frontend:** Ember.js, TypeScript, Vite
- **Database:** PostgreSQL
- **Object Storage:** Garage (S3-compatible)
- **Deployment:** Kamal

## Development

### Prerequisites

- Ruby (see `.ruby-version`)
- Node.js + pnpm
- PostgreSQL
- Docker

### Setup

```sh
bin/setup
```

### Running

```sh
docker build -t mssform-garage docker/garage/
bin/dev
```

### Deployment

The Garage image is automatically built and pushed by the pre-deploy hook.

```sh
bin/kamal deploy -d staging
bin/kamal deploy -d production
```
