#!/bin/bash

CONTAINER="cloudforge-api"
URL="http://127.0.0.1:8000/health"
INCIDENT_DIR="/opt/cloudforge/incidents"

echo "CloudForge self-healing started..."

if curl -fsS "$URL" > /tmp/cloudforge-health.json; then
    echo "CloudForge is healthy."
    cat /tmp/cloudforge-health.json
    exit 0
fi

DETECTED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

echo "CloudForge health check FAILED."
echo "Attempting container restart..."

docker start "$CONTAINER" 2>/dev/null || docker restart "$CONTAINER"

echo "Waiting for application to become healthy..."

for i in $(seq 1 30); do

    if curl -fsS "$URL" > /tmp/cloudforge-health.json; then

        RECOVERED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
	RECOVERY_DURATION=$(python3 -c "from datetime import datetime; print(int((datetime.fromisoformat('$RECOVERED_AT'.replace('Z','+00:00')) - datetime.fromisoformat('$DETECTED_AT'.replace('Z','+00:00'))).total_seconds()))")
        INCIDENT_ID="incident-$(date -u '+%Y-%m-%d-%H%M%S')"
        INCIDENT_FILE="$INCIDENT_DIR/$INCIDENT_ID.json"

        cat > "$INCIDENT_FILE" <<EOF2
{
  "incident_id": "$INCIDENT_ID",
  "environment": "staging",
  "application": "cloudforge-api",
  "version": "1.0.0",
  "failure_type": "container_stopped",
  "detected_at": "$DETECTED_AT",
  "recovery_action": "docker_start",
  "recovered_at": "$RECOVERED_AT",
"recovery_duration_seconds": $RECOVERY_DURATION,
  "recovery_status": "successful",
  "health_status": "healthy"
}
EOF2

        echo "CloudForge recovery successful."
        cat /tmp/cloudforge-health.json
        echo "Incident record created: $INCIDENT_FILE"
        /opt/cloudforge/analyzer/run_analyzer.sh

        exit 0
    fi

    echo "Attempt $i/30 - application not ready"
    sleep 2

done

echo "CloudForge recovery FAILED."
exit 1
