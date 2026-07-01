from fastapi import FastAPI

from app.routers.analyze import router as analyze_router


app = FastAPI(
    title="SafeChat AI Backend",
    description="Backend API for Hebrew cyberbullying detection system",
    version="1.0.0"
)


app.include_router(analyze_router)


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
