# znuny-docker

Docker setup for Znuny ITSM including MariaDB.

## Start

```bash
docker compose up --build -d
```

The initial database configuration runs automatically when the `znuny` container starts.

## Access

After startup, Znuny is available at <http://localhost:8123>.

## Configuration

Secrets and database credentials are stored in `.env` and can be adjusted there.
