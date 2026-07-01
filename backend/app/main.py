from fastapi import FastAPI

app = FastAPI(
    title="SafeChat AI Backend",
    description="Backend API for Hebrew cyberbullying detection system",
    version="1.0.0"
)


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