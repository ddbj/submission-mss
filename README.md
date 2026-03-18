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

Build and push the Garage image before deploying:

```sh
docker build -t w3const/mssform-garage docker/garage/
docker push w3const/mssform-garage
```

```sh
bin/kamal deploy -d staging
bin/kamal deploy -d production
```
