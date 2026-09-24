import json
import sys
from pathlib import Path


def analyze_incident(file_path):
    with open(file_path, "r") as file:
        incident = json.load(file)

    print("CloudForge Incident Analysis")
    print("=" * 30)

    print(f"Incident: {incident['incident_id']}")
    print(f"Environment: {incident['environment']}")
    print()

    print("What happened?")

    if incident["failure_type"] == "container_stopped":
        print("The cloudforge-api container stopped unexpectedly.")
    elif incident["failure_type"] == "network_failure":
        print("The cloudforge-api application became unreachable due to a network-related failure.")
    else:
        print(f"Failure type: {incident['failure_type']}")

    print()
    print("Recovery action:")
    print(f"The self-healing system performed: {incident['recovery_action']}")

    print()
    print("Recovery time:")
    print(f"{incident['recovery_duration_seconds']} seconds")

    print()
    print("Recovery status:")
    print(incident["recovery_status"].upper())

    print()
    print("Final health:")
    print(incident["health_status"].upper())

    print()
    print("Recommendation:")

    if incident["recovery_status"] == "successful":
        if incident["failure_type"] == "container_stopped":
            print("Review Docker and application logs to determine why the container stopped.")
        elif incident["failure_type"] == "network_failure":
            print("Check firewall rules, network connectivity, and application port 8000.")
        else:
            print("Review logs related to the detected failure type.")
    else:
        print("Immediate investigation required because automatic recovery failed.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 analyze.py <incident.json>")
        sys.exit(1)

    analyze_incident(Path(sys.argv[1]))
