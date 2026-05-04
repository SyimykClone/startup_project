from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path
from typing import List

BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://postgres:123456@127.0.0.1:5433/around"
    REDIS_URL: str = "redis://localhost:6379/0"
    AUTH_SESSION_TTL_SECONDS: int = 60 * 60 * 24 * 7
    AUTH_SECRET_KEY: str = "change-me"

    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        extra="ignore",
    )

    APP_ENV: str = "dev"
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    CORS_ORIGINS: str = "http://localhost:*"

    MAPBOX_TOKEN: str = ""
    GOOGLE_WEB_CLIENT_ID: str = ""
    GOOGLE_SERVER_API_KEY: str = ""

    def cors_list(self) -> List[str]:
        return [x.strip() for x in self.CORS_ORIGINS.split(",") if x.strip()]


settings = Settings()
