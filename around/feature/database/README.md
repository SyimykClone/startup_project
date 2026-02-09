# ARound Database (PostgreSQL)

## Local development (Docker)
Example container parameters used for development:
- DB: postgres
- User: postgres
- Password: 123456
- Port: 5432
- Image: postgres:18

### Run Postgres
powershell
docker run --name around-postgres `
  -e POSTGRES_DB=postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=123456 `
  -p 5432:5432 `
  -d postgres:18
