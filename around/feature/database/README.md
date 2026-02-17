# ARound Database (PostgreSQL)

## Files
- `feature/database/init.sql` - base `poi` schema
- `feature/database/seed.sql` - initial POI data
- `feature/database/users.sql` - users table
- `feature/database/visits.sql` - user-to-poi visits

## Local Run (Docker Compose)
From repository root:

```powershell
docker compose up -d postgres
```

Connection settings:
- host: `127.0.0.1`
- port: `5433`
- database: `around`
- user: `postgres`
- password: `123456`

## Migration Strategy
Init scripts from `/docker-entrypoint-initdb.d` run only when the Postgres data volume is created the first time.

For existing volumes, apply schema changes manually:

```powershell
docker exec -i around-postgres psql -U postgres -d around < feature/database/users.sql
docker exec -i around-postgres psql -U postgres -d around < feature/database/visits.sql
```

Recommended next step for team workflow:
- introduce explicit migrations (for example, Alembic), and stop relying on one-time init scripts for schema evolution.
