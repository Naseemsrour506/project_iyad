from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import models
from app.database import Base, engine
from app.routers.alerts import router as alerts_router
from app.routers.analyze import router as analyze_router
from app.routers.auth import router as auth_router
from app.routers.children import router as children_router
from app.routers.dashboard import router as dashboard_router
from app.routers.messages import router as messages_router
from app.routers.reports import router as reports_router


Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="SafeChat AI Backend",
    description=(
        "Backend API for Hebrew "
        "cyberbullying detection system"
    ),
    version="1.0.0"
)


app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):\d+",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth_router)
app.include_router(children_router)
app.include_router(analyze_router)
app.include_router(messages_router)
app.include_router(dashboard_router)
app.include_router(alerts_router)
app.include_router(reports_router)


@app.get("/")
def root():
    return {
        "message": "SafeChat AI Backend is running"
    }


@app.get("/api/health")
def health_check():
    return {
        "status": "ok"
    }
