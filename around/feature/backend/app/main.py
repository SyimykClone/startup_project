from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.poi import router as poi_router
from app.api.route import router as route_router


def create_app() -> FastAPI:
    app = FastAPI(title="ARound API", version="1.0.0")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_list() if settings.cors_list() else ["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health")
    def health():
        return {"status": "ok"}

    app.include_router(poi_router)
    app.include_router(route_router)

    return app


app = create_app()
