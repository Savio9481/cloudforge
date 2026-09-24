#!/bin/bash

INCIDENT_DIR="/opt/cloudforge/incidents"
ANALYZER="/opt/cloudforge/analyzer/analyze.py"

LATEST_INCIDENT=$(ls -t "$INCIDENT_DIR"/*.json 2>/dev/null | head -n 1)

if [ -z "$LATEST_INCIDENT" ]; then
    echo "No incident files found."
    exit 1
fi

echo "Latest incident:"
echo "$LATEST_INCIDENT"
echo

python3 "$ANALYZER" "$LATEST_INCIDENT"
