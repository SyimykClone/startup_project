# ARound Backend

Серверная часть мобильного приложения ARound.

## Стек

- FastAPI
- Uvicorn
- Supabase PostgreSQL через `asyncpg`
- Upstash Redis

## Требования

- Python 3.11+
- Проект Supabase с доступом к PostgreSQL
- Экземпляр Upstash Redis

## Установка и запуск

```powershell
cd feature/backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Переменные окружения

Файл: `feature/backend/.env`

```env
DATABASE_URL=postgresql://<user>:<password>@<host>:5432/<database>
REDIS_URL=rediss://default:<password>@<host>:<port>
AUTH_SESSION_TTL_SECONDS=604800
AUTH_SECRET_KEY=change-me
APP_ENV=dev
HOST=0.0.0.0
PORT=8000
CORS_ORIGINS=http://localhost:3000,http://localhost:8000,http://localhost:5173,http://localhost:*
MAPBOX_TOKEN=<token>
GOOGLE_WEB_CLIENT_ID=<client_id>
GOOGLE_SERVER_API_KEY=<api_key>
```

## Проверка работоспособности

- `GET /health`
- `GET /docs`

Пример:

```powershell
curl http://127.0.0.1:8000/health
```

## Структура backend

- `app/main.py` - запуск приложения, middleware, роутеры
- `app/api` - REST-эндпоинты
- `app/services` - бизнес-логика и интеграции
- `app/core` - конфиг, база данных, Redis, безопасность
- `app/models` - Pydantic-схемы
