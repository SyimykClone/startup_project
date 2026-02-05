from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.poi import router as poi_router
from app.api.route import router as route_router
from app.core.db import close_db, connect_db
from app.core.redis import connect_redis, close_redis

from app.api.auth import router as auth_router

def create_app() -> FastAPI:
    app = FastAPI(title="ARound API", version="1.0.0")

    app.include_router(auth_router)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost:3000",
            "http://localhost:8000",
            "http://localhost:5173",
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health")
    def health():
        return {"status": "ok"}

    @app.on_event("startup")
    async def startup():
        await connect_db()
        await connect_redis()

    @app.on_event("shutdown")
    async def shutdown():
        await close_redis()
        await close_db()

    app.include_router(poi_router)
    app.include_router(route_router)

    return app


app = create_app()
