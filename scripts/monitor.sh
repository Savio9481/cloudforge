#!/bin/bash

HEALTH_CHECK="/opt/cloudforge/scripts/health-check.sh"
SELF_HEAL="/opt/cloudforge/scripts/self-heal.sh"

echo "CloudForge monitor started..."
echo "Checking application every 30 seconds..."

while true; do

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running health check..."

    if "$HEALTH_CHECK"; then
        echo "Application is healthy."
    else
        echo "Application is unhealthy."
        echo "Starting self-healing..."

        if "$SELF_HEAL"; then
            echo "Self-healing completed successfully."
        else
            echo "Self-healing FAILED."
        fi
    fi

    echo "Waiting 30 seconds..."
    sleep 30

done
