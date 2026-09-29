import json
import os

STATUS_FILE = "/opt/cloudforge/runtime/status.json"


def get_container_status():
    try:
        if not os.path.exists(STATUS_FILE):
            return {
                "available": False,
                "status": "status_unavailable",
            }

        with open(STATUS_FILE, "r") as file:
            data = json.load(file)

        container = data.get("container", {})

        return {
            "available": True,
            **container,
            "updated_at": data.get("updated_at"),
        }

    except Exception as exc:
        return {
            "available": False,
            "status": "error",
            "error": str(exc),
        }
