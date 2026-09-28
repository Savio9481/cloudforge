#!/bin/bash

CONTAINER="cloudforge-api"
STATUS_FILE="/opt/cloudforge/runtime/status.json"

while true; do

    if docker inspect "$CONTAINER" >/dev/null 2>&1; then

        STATUS=$(docker inspect "$CONTAINER" --format '{{.State.Status}}')
        RUNNING=$(docker inspect "$CONTAINER" --format '{{.State.Running}}')
        HEALTH=$(docker inspect "$CONTAINER" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}')
        EXIT_CODE=$(docker inspect "$CONTAINER" --format '{{.State.ExitCode}}')
        OOM_KILLED=$(docker inspect "$CONTAINER" --format '{{.State.OOMKilled}}')
        RESTART_COUNT=$(docker inspect "$CONTAINER" --format '{{.RestartCount}}')
        IMAGE=$(docker inspect "$CONTAINER" --format '{{.Config.Image}}')
        STARTED_AT=$(docker inspect "$CONTAINER" --format '{{.State.StartedAt}}')

        cat > "$STATUS_FILE" <<EOF2
{
  "container": {
    "name": "$CONTAINER",
    "status": "$STATUS",
    "running": $RUNNING,
    "health": "$HEALTH",
    "exit_code": $EXIT_CODE,
    "oom_killed": $OOM_KILLED,
    "restart_count": $RESTART_COUNT,
    "image": "$IMAGE",
    "started_at": "$STARTED_AT"
  },
  "updated_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF2

    else

        cat > "$STATUS_FILE" <<EOF2
{
  "container": {
    "name": "$CONTAINER",
    "status": "not_found",
    "running": false,
    "health": "unknown",
    "exit_code": null,
    "oom_killed": false,
    "restart_count": 0,
    "image": null,
    "started_at": null
  },
  "updated_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF2

    fi

    sleep 5
done
