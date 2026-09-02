from fastapi import FastAPI
from datetime import datetime, timezone
import os
import socket
import psutil

app = FastAPI(
    title="CloudForge Demo API",
    version="1.0.0"
)

START_TIME = datetime.now(timezone.utc)


@app.get("/")
def root():
    return {
        "application": "CloudForge Demo API",
        "status": "running",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "hostname": socket.gethostname(),
        "started_at": START_TIME.isoformat()
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "version": os.getenv("APP_VERSION", "1.0.0")
    }


@app.get("/version")
def version():
    return {
        "version": os.getenv("APP_VERSION", "1.0.0")
    }


@app.get("/metrics")
def metrics():
    return {
        "cpu_percent": psutil.cpu_percent(interval=0.2),
        "memory_percent": psutil.virtual_memory().percent,
        "hostname": socket.gethostname(),
        "timestamp": datetime.now(timezone.utc).isoformat()
    }