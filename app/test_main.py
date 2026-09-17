from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200


def test_health():
    response = client.get("/health")
    assert response.status_code == 200

    data = response.json()

    assert data["status"] == "healthy"
    assert "version" in data


def test_version():
    response = client.get("/version")
    assert response.status_code == 200

    data = response.json()

    assert "version" in data


def test_metrics():
    response = client.get("/metrics")
    assert response.status_code == 200

    data = response.json()

    assert "cpu_percent" in data
    assert "memory_percent" in data
    assert "hostname" in data
    assert "timestamp" in data
