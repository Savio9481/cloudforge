# CloudForge Self-Healing System

CloudForge includes a runtime self-healing mechanism designed to detect application failures, collect evidence, restart the affected container, verify recovery, create an incident record, and trigger AI-based incident analysis.

The current implementation focuses on failures that can be recovered by restarting the application container.

---

# 1. Self-Healing Overview

The self-healing workflow is:

```text
Application
     |
     v
Health Check
     |
     +---- Healthy ----> Continue Monitoring
     |
     +---- Failed
            |
            v
      Failure Detection
            |
            v
      Evidence Collection
            |
            v
      Container Recovery
            |
            v
      Health Verification
            |
       +----+----+
       |         |
    Healthy    Failed
       |         |
       v         v
   Incident    Recovery
    Record     Failed
       |
       v
  AI Analysis
````

The objective is to reduce the time between failure detection and recovery while preserving evidence about what happened.

---

# 2. Current Self-Healing Scope

CloudForge currently handles application failures where restarting the Docker container can restore service.

Examples tested successfully include:

```text
docker stop cloudforge-api
docker kill cloudforge-api
```

CloudForge detects the failed health check and attempts to restart the container.

---

# 3. Important Limitation

Self-healing does not currently recover every possible infrastructure failure.

For example, a firewall rule blocking port `8000` can cause the application health check to fail even when the Docker container itself is running correctly.

In that situation:

```text
Health Check
     |
     v
Failure
     |
     v
Container Restart
     |
     v
Health Check
     |
     v
Still Failed
```

The container restart does not remove the external firewall problem.

This was intentionally tested as part of CloudForge chaos testing.

The limitation is documented rather than presenting the system as capable of recovering every failure type.

---

# 4. Components

The self-healing system consists of:

```text
health-check.sh
monitor.sh
self-heal.sh
cloudforge-monitor.service
cloudforge-status-publisher.service
incident JSON records
AI incident analyzer
```

---

# 5. Health Check

The health check script is:

```text
scripts/health-check.sh
```

Its purpose is to determine whether the CloudForge API is responding correctly.

The endpoint checked is:

```text
http://127.0.0.1:8000/health
```

The script uses:

```bash
curl -fsS
```

A successful response means the application is considered healthy.

---

# 6. Health Check Script

The current implementation is:

```bash
#!/bin/bash

URL="http://127.0.0.1:8000/health"

if curl -fsS "$URL" > /tmp/cloudforge-health.json; then
    echo "CloudForge health check: HEALTHY"
    cat /tmp/cloudforge-health.json
    exit 0
else
    echo "CloudForge health check: FAILED"
    exit 1
fi
```

The important design decision is that the script returns:

```text
0 = healthy
1 = unhealthy
```

This allows the monitoring process to make a simple decision.

---

# 7. Monitoring Loop

The monitoring script is:

```text
scripts/monitor.sh
```

It continuously checks the application.

The current monitoring interval is:

```text
30 seconds
```

The workflow is:

```text
Run Health Check
       |
       +---- Success
       |       |
       |       v
       |   Wait 30 seconds
       |
       +---- Failure
               |
               v
          Start Self-Healing
               |
               v
          Wait 30 seconds
```

---

# 8. Monitor Script

The current implementation is:

```bash
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
```

---

# 9. Systemd Monitoring Service

The monitoring process runs as a systemd service:

```text
cloudforge-monitor.service
```

This makes the monitoring process independent from the interactive terminal session.

The service can be inspected using:

```bash
sudo systemctl status cloudforge-monitor.service
```

View recent logs:

```bash
sudo journalctl -u cloudforge-monitor.service -n 100
```

Follow logs live:

```bash
sudo journalctl -u cloudforge-monitor.service -f
```

---

# 10. Why Systemd Is Used

Running the monitoring script directly inside a terminal would mean that the monitoring process could stop when the terminal session ends.

Systemd provides:

```text
Service management
Automatic restart
Boot-time startup
Centralized logs
Operational status
```

The monitoring service therefore continues independently of an SSM shell session.

---

# 11. Self-Healing Workflow

The self-healing script is:

```text
scripts/self-heal.sh
```

Its workflow is:

```text
Health Check Failed
       |
       v
Record Detection Time
       |
       v
Inspect Docker Container
       |
       v
Collect Container Logs
       |
       v
Collect Host Kernel Evidence
       |
       v
Attempt Container Recovery
       |
       v
Wait for Health
       |
       +---- Healthy
       |       |
       |       v
       |   Create Incident
       |       |
       |       v
       |   Run AI Analyzer
       |
       +---- Still Unhealthy
               |
               v
         Recovery Failed
```

---

# 12. Failure Detection

When the health check fails, CloudForge records:

```text
Detection timestamp
Container status
Exit code
OOMKilled state
Restart count
Container logs
Host kernel logs
```

This information is preserved before the recovery attempt.

This is important because recovery can change the runtime state.

---

# 13. Docker Evidence

CloudForge collects:

```text
Container status
Exit code
OOMKilled
Restart count
Container logs
```

The information is obtained using Docker inspection and logs.

For example:

```bash
docker inspect cloudforge-api
```

and:

```bash
docker logs --tail 50 cloudforge-api
```

---

# 14. Host Evidence

CloudForge also captures recent kernel logs:

```bash
sudo dmesg -T | tail -50
```

This can provide additional context around:

```text
Docker networking
Process termination
Kernel events
Container lifecycle events
Other host-level activity
```

Host evidence does not automatically prove the exact root cause.

It is supporting evidence.

---

# 15. Container Recovery

The primary recovery action is:

```text
docker start cloudforge-api
```

If required, the script falls back to:

```text
docker restart cloudforge-api
```

The purpose is to restore the existing application container rather than rebuild or redeploy the application.

---

# 16. Recovery Verification

Starting the container is not considered successful recovery by itself.

CloudForge repeatedly checks:

```text
http://127.0.0.1:8000/health
```

The current recovery loop checks the application for up to approximately:

```text
60 seconds
```

using repeated checks.

The recovery process exits successfully only after the application becomes healthy.

---

# 17. Recovery Duration

When recovery succeeds, CloudForge calculates:

```text
recovery_duration_seconds
```

This value is stored in the incident record.

Example:

```json
{
  "recovery_duration_seconds": 2
}
```

This provides measurable evidence of recovery performance.

---

# 18. Incident Records

After successful recovery, CloudForge creates a JSON incident file under:

```text
/opt/cloudforge/incidents/
```

Example:

```text
incident-2026-09-28-061731.json
```

The incident record contains:

```text
Incident ID
Environment
Application
Version
Failure type
Detection time
Recovery action
Recovery time
Recovery status
Health status
Docker evidence
Host evidence
```

---

# 19. Incident Structure

A simplified incident record looks like:

```json
{
  "incident_id": "incident-YYYY-MM-DD-HHMMSS",
  "environment": "staging",
  "application": "cloudforge-api",
  "version": "1.0.0",
  "failure_type": "container_stopped",
  "detected_at": "timestamp",
  "recovery_action": "docker_start",
  "recovered_at": "timestamp",
  "recovery_duration_seconds": 2,
  "recovery_status": "successful",
  "health_status": "healthy",
  "docker_evidence": {},
  "host_evidence": {}
}
```

The actual record contains the captured evidence.

---

# 20. AI Incident Analysis

After an incident record is created, CloudForge invokes:

```text
analyzer/run_analyzer.sh
```

The analyzer reads the latest incident JSON.

The AI analyzer uses Google Gemini.

The current working model used during development is:

```text
gemini-3.6-flash
```

The API key is stored as an environment variable and is not committed to GitHub.

---

# 21. AI Analysis Workflow

The workflow is:

```text
Incident JSON
      |
      v
AI Analyzer
      |
      v
Gemini
      |
      v
Structured Analysis
      |
      v
AI Report
```

The generated report contains:

```text
What happened
Likely cause
Impact
Recovery performed
Recovery assessment
Recommended next actions
```

---

# 22. AI Evidence Policy

The analyzer is instructed to use the incident evidence.

It should distinguish between:

```text
Confirmed evidence
Possible explanation
Unknown information
```

For example, an exit code may indicate how a process terminated, but it may not identify exactly who or what caused the termination.

Therefore:

```text
Observed evidence != guaranteed root cause
```

This distinction is important for responsible incident analysis.

---

# 23. Example Exit Code 137 Analysis

One tested incident contained:

```text
Exit code: 137
OOMKilled: false
```

Exit code `137` corresponds to a process receiving `SIGKILL`.

However, because:

```text
OOMKilled = false
```

the incident evidence did not conclusively establish that the Linux OOM killer caused the termination.

The AI analysis therefore identified the exact root cause as undetermined and recommended checking:

```text
Docker events
Deployment activity
Host activity
Maintenance activity
External stop/kill actions
```

This demonstrates why CloudForge preserves both Docker and host evidence.

---

# 24. Graceful Container Stop Test

CloudForge was intentionally tested with:

```bash
docker stop cloudforge-api
```

The expected sequence was:

```text
Container running
       |
       v
docker stop
       |
       v
Health check fails
       |
       v
Self-healing detects failure
       |
       v
docker start
       |
       v
Health restored
       |
       v
Incident created
       |
       v
AI analysis
```

The test succeeded.

---

# 25. Force Kill Test

CloudForge was also tested using:

```bash
docker kill cloudforge-api
```

This forces the container to terminate.

The self-healing system detected the failure and restarted the container.

The tested incident:

```text
incident-2026-09-23-075737
```

recovered in approximately:

```text
2 seconds
```

The application became healthy again.

---

# 26. Network Failure Test

A controlled firewall failure was tested using:

```bash
sudo iptables -I INPUT -p tcp --dport 8000 -j REJECT
```

This caused the health check to fail.

CloudForge attempted container recovery.

However, the firewall continued blocking the application port.

Therefore:

```text
Container restart
        |
        v
Port still blocked
        |
        v
Health check still fails
```

This test demonstrated a boundary of the current recovery mechanism.

---

# 27. Firewall Rule Removal

The test firewall rule was removed using:

```bash
sudo iptables -D INPUT -p tcp --dport 8000 -j REJECT
```

Once the firewall restriction was removed, application health could be restored.

This demonstrates that some failures require infrastructure-level remediation rather than simply restarting the application.

---

# 28. Self-Healing Boundary

Current capability:

```text
Application/container failure
        |
        v
Container restart
        |
        v
Health verification
```

Current limitation:

```text
Network failure
Infrastructure failure
Incorrect configuration
Host failure
Dependency failure
        |
        v
May require additional remediation
```

CloudForge does not currently claim automatic recovery for all of these categories.

---

# 29. Runtime Status Publisher

CloudForge also includes:

```text
cloudforge-status-publisher.service
```

Its purpose is to continuously publish the current Docker runtime state.

The status is written to:

```text
/opt/cloudforge/runtime/status.json
```

The dashboard reads this information.

---

# 30. Runtime Status Architecture

```text
Docker
   |
   v
Status Publisher
   |
   v
runtime/status.json
   |
   v
Dashboard
```

The dashboard therefore provides visibility into the runtime state without owning the recovery logic.

---

# 31. Self-Healing and Dashboard Separation

The responsibilities are intentionally separated.

### Self-Healing

```text
Detect
Collect evidence
Recover
Verify
Record incident
Trigger AI analysis
```

### Dashboard

```text
Read status
Display container state
Display incidents
Display AI analysis
Display system metrics
```

The dashboard does not replace the self-healing engine.

---

# 32. Self-Healing and Jenkins Separation

Jenkins handles deployment.

Self-healing handles runtime failures.

```text
Jenkins
   |
   +--> Build
   +--> Test
   +--> Deploy
   +--> Verify
```

while:

```text
Self-Healing
   |
   +--> Monitor
   +--> Detect
   +--> Recover
   +--> Analyze
```

This separation prevents a runtime failure from being treated as a new application deployment.

---

# 33. Monitoring Logs

Check the monitoring service:

```bash
sudo systemctl status cloudforge-monitor.service
```

View logs:

```bash
sudo journalctl -u cloudforge-monitor.service -n 100
```

Follow logs:

```bash
sudo journalctl -u cloudforge-monitor.service -f
```

---

# 34. Status Publisher Logs

Check:

```bash
sudo systemctl status cloudforge-status-publisher.service
```

View:

```bash
sudo journalctl -u cloudforge-status-publisher.service -n 100
```

---

# 35. Check Current Runtime State

Run:

```bash
cat /opt/cloudforge/runtime/status.json
```

A healthy example contains information similar to:

```json
{
  "container": {
    "name": "cloudforge-api",
    "status": "running",
    "running": true,
    "health": "healthy",
    "exit_code": 0,
    "oom_killed": false,
    "restart_count": 0,
    "image": "..."
  }
}
```

---

# 36. Check Latest Incident

List incidents:

```bash
ls -lt /opt/cloudforge/incidents/
```

Read the latest incident:

```bash
LATEST=$(ls -t /opt/cloudforge/incidents/*.json | head -n 1)
cat "$LATEST"
```

---

# 37. Check Latest AI Analysis

List AI reports:

```bash
ls -lt /opt/cloudforge/incidents/*-ai.txt
```

Read the latest:

```bash
LATEST_AI=$(ls -t /opt/cloudforge/incidents/*-ai.txt | head -n 1)
cat "$LATEST_AI"
```

---

# 38. Manual Self-Healing Test

For controlled testing only:

```bash
docker stop cloudforge-api
```

Then monitor:

```bash
sudo journalctl -u cloudforge-monitor.service -f
```

The expected sequence is:

```text
Health check failed
       |
       v
Self-healing started
       |
       v
Docker evidence collected
       |
       v
Container restarted
       |
       v
Health restored
       |
       v
Incident created
       |
       v
AI analyzer executed
```

---

# 39. Manual Health Verification

After recovery:

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

Then:

```bash
docker ps --filter name=cloudforge-api
```

The container should be:

```text
Up
healthy
```

---

# 40. What Self-Healing Does Not Do

The current implementation does not automatically:

```text
Create a new EC2 instance
Replace the host
Modify security groups
Remove firewall rules
Modify Terraform
Automatically rollback deployments
Perform blue/green deployments
Perform canary deployments
Guarantee root-cause identification
```

These are future extension areas.

---

# 41. Future Self-Healing Architecture

A future policy-driven system could extend the current workflow:

```text
Failure
   |
   v
Evidence Collection
   |
   v
Failure Classification
   |
   v
Policy Engine
   |
   +---- Container Failure
   |        |
   |        v
   |     Restart
   |
   +---- Network Failure
   |        |
   |        v
   |     Network Remediation
   |
   +---- Deployment Failure
   |        |
   |        v
   |     Rollback
   |
   +---- Host Failure
            |
            v
       Infrastructure
         Recovery
```

This is a future architecture and is not currently implemented.

---

# 42. Future AI Integration

The current AI analyzer is primarily an incident analysis component.

A future implementation could use AI to assist with:

```text
Incident classification
Evidence correlation
Suggested remediation
Failure pattern detection
Operational recommendations
```

Any automated remediation should be controlled through explicit policies rather than allowing unrestricted AI actions.

---

# 43. Security Considerations

Self-healing scripts execute operational commands.

Therefore:

```text
Do not expose self-healing shell commands directly to the public internet.
Do not expose unrestricted docker commands through an API.
Do not commit AWS credentials.
Do not commit Gemini API keys.
Do not expose internal incident files unnecessarily.
```

The current dashboard is intended as a staging/learning environment.

A production implementation should add appropriate authentication and authorization before exposing operational actions.

---

# 44. Incident Evidence Retention

Incident files provide a local audit trail.

They can be used to review:

```text
When the failure occurred
What Docker reported
What the host reported
What recovery action was attempted
How long recovery took
Whether recovery succeeded
What AI analysis concluded
```

This makes the system useful not only for recovery but also for learning and debugging.

---

# 45. Chaos Testing Relationship

Self-healing capabilities are verified through controlled chaos tests.

The current documented tests include:

```text
Container Stop
Container Force Kill
Network/Firewall Failure
```

The results demonstrate:

```text
Detection
Recovery
Recovery measurement
Failure boundaries
```

See:

```text
docs/chaos-testing.md
```

for the detailed chaos-testing documentation.

---

# 46. Load Testing Relationship

Load testing is separate from self-healing testing.

Load testing verifies application performance under concurrent requests.

Self-healing testing verifies:

```text
Failure detection
Recovery
Incident creation
```

The load testing documentation is:

```text
docs/load-testing.md
```

---

# 47. Operational Metrics

Important self-healing metrics include:

```text
Failure detection time
Recovery duration
Recovery success/failure
Container restart count
Exit code
OOMKilled state
Incident count
```

The dashboard exposes several of these operational signals.

---

# 48. Example Successful Recovery

A typical successful recovery looks like:

```text
00:00  Application healthy
00:00  Container intentionally stopped
00:30  Health check detects failure
00:30  Evidence collected
00:30  Container restarted
00:32  Application healthy
00:32  Incident created
00:32  AI analysis started
```

The exact timing depends on the monitoring interval and application startup time.

---

# 49. Why the Detection Time Matters

The monitor checks every:

```text
30 seconds
```

Therefore a failure may not be detected immediately.

For example:

```text
Failure at 10:00:05
       |
       v
Next health check
10:00:30
       |
       v
Detection
```

The actual recovery duration should therefore be interpreted separately from the monitoring detection interval.

The incident's `recovery_duration_seconds` measures the recorded recovery process from detection to successful recovery.

---

# 50. Self-Healing Verification Checklist

Before considering the self-healing system verified:

```text
[ ] health-check.sh works
[ ] monitor.sh runs
[ ] cloudforge-monitor.service is active
[ ] Health endpoint is healthy
[ ] Container stop test works
[ ] Container kill test works
[ ] Recovery is verified through /health
[ ] Incident JSON is created
[ ] Docker evidence is recorded
[ ] Host evidence is recorded
[ ] AI analysis is generated
[ ] Dashboard displays latest incident
[ ] Network failure limitation is documented
```

---

# 51. Current Verified Results

CloudForge has been tested with controlled failures.

### Container Stop

```text
Failure:
docker stop cloudforge-api

Result:
Automatic recovery successful.
```

### Container Force Kill

```text
Failure:
docker kill cloudforge-api

Result:
Automatic recovery successful.
```

### Network Failure

```text
Failure:
Firewall blocks TCP port 8000

Result:
Failure detected.
Container restart attempted.
Recovery remained blocked by the firewall.
```

The third test establishes an explicit boundary of the current self-healing implementation.

---

# 52. Overall Architecture

The complete runtime architecture is:

```text
                         +----------------------+
                         |    CloudForge API    |
                         |        :8000         |
                         +----------+-----------+
                                    |
                                    v
                              Health Check
                                    |
                                    v
                              Monitor Loop
                                    |
                         +----------+----------+
                         |                     |
                      Healthy                Failed
                         |                     |
                         v                     v
                     Continue             Self-Healing
                                               |
                         +---------------------+------------------+
                         |                     |                  |
                         v                     v                  v
                  Docker Evidence      Host Evidence       Recovery
                         |                     |                  |
                         +---------------------+------------------+
                                               |
                                               v
                                        Health Verification
                                               |
                                  +------------+------------+
                                  |                         |
                               Success                    Failure
                                  |                         |
                                  v                         v
                           Incident JSON              Recovery Failed
                                  |
                                  v
                            AI Analyzer
                                  |
                                  v
                            AI Report
                                  |
                                  v
                              Dashboard
```

---

# 53. Final Summary

CloudForge self-healing provides a complete runtime recovery loop for supported container-level failures:

```text
Detect
  ↓
Collect Evidence
  ↓
Recover
  ↓
Verify
  ↓
Record
  ↓
Analyze
```

The current system successfully demonstrates:

```text
Automated health monitoring
Container failure detection
Automatic container recovery
Recovery verification
Incident evidence collection
AI-assisted incident analysis
Operational dashboard visibility
Controlled chaos testing
```

At the same time, CloudForge explicitly documents its current boundaries.

The current implementation is focused on **container-level recovery**, while broader infrastructure remediation, automated rollback, advanced policy engines, and more sophisticated recovery strategies remain future extensions.

```
```
