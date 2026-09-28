import glob
import json
import os


INCIDENT_DIR = "/opt/cloudforge/incidents"


def get_latest_incident():
    files = glob.glob(os.path.join(INCIDENT_DIR, "*.json"))

    if not files:
        return None

    latest_file = max(files, key=os.path.getmtime)

    try:
        with open(latest_file, "r") as file:
            incident = json.load(file)

        return incident

    except Exception as exc:
        return {
            "error": str(exc)
        }


def get_latest_ai_analysis():
    files = glob.glob(os.path.join(INCIDENT_DIR, "*-ai.txt"))

    if not files:
        return None

    latest_file = max(files, key=os.path.getmtime)

    try:
        with open(latest_file, "r") as file:
            return file.read()

    except Exception as exc:
        return f"Unable to read AI analysis: {exc}"
