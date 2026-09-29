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


from services.docker_service import get_container_status


@app.get("/api/container")
def container_status():
    return get_container_status()


from services.incident_service import (
    get_latest_incident,
    get_latest_ai_analysis,
)
from services.system_service import get_system_metrics


@app.get("/api/dashboard")
def dashboard():
    return {
        "application": {
            "name": "CloudForge",
            "environment": "staging",
            "version": os.getenv("APP_VERSION", "1.0.0"),
        },
        "container": get_container_status(),
        "system": get_system_metrics(),
        "latest_incident": get_latest_incident(),
        "latest_ai_analysis": get_latest_ai_analysis(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


from fastapi.staticfiles import StaticFiles

app.mount("/dashboard", StaticFiles(directory="/app/static", html=True), name="dashboard")
