# CloudForge Self-Healing Guide

This document explains how CloudForge detects application failures, collects evidence, automatically attempts recovery, and records the incident.

---

# 1. Purpose

CloudForge includes a self-healing mechanism for the application container.

The primary goal is to automatically recover from failures where restarting the application container can restore service.

The recovery lifecycle is:

```text
Application Failure
       ↓
Health Check Fails
       ↓
Failure Detected
       ↓
Evidence Collected
       ↓
Container Restart
       ↓
Health Check
       ↓
Recovered?
    /       \
  Yes        No
   |          |
Incident     Recovery
Recorded     Failed
   |
AI Analysis
````

---

# 2. Current Self-Healing Boundary

CloudForge currently focuses on application/container-level failures.

It can automatically recover failures such as:

```text
Container stopped
Container forcefully terminated
Application becomes unavailable because the container stopped
```

It does not automatically solve every infrastructure failure.

For example, if a firewall blocks port `8000`, restarting the container does not remove the firewall rule.

Therefore:

```text
Container Failure
       ↓
Restart Container
       ↓
Possible Recovery
```

but:

```text
Network / Firewall Failure
       ↓
Restart Container
       ↓
Network still blocked
       ↓
Recovery fails
```

This boundary is intentionally documented because it represents an area for future policy-engine and AI-driven improvements.

---

# 3. Main Components

CloudForge self-healing consists of several components.

```text
/opt/cloudforge/scripts/
├── health-check.sh
├── monitor.sh
└── self-heal.sh
```

The main responsibilities are:

| Component                    | Responsibility                                  |
| ---------------------------- | ----------------------------------------------- |
| `health-check.sh`            | Checks application health                       |
| `monitor.sh`                 | Continuously monitors the application           |
| `self-heal.sh`               | Performs recovery and creates incident evidence |
| `status-publisher.sh`        | Publishes container runtime state               |
| `cloudforge-monitor.service` | Runs monitoring continuously                    |

---

# 4. Health Check

The health-check script is:

```text
/opt/cloudforge/scripts/health-check.sh
```

Its purpose is to determine whether the CloudForge API is responding.

The health endpoint is:

```text
http://127.0.0.1:8000/health
```

The script uses:

```bash
curl -fsS
```

to verify the endpoint.

A successful request produces:

```text
CloudForge health check: HEALTHY
```

and the API response.

---

# 5. Run the Health Check Manually

Connect to the staging EC2 instance through SSM.

Then:

```bash
sudo su - ssm-user
```

Go to the project:

```bash
cd /opt/cloudforge
```

Run:

```bash
/opt/cloudforge/scripts/health-check.sh
```

Expected:

```text
CloudForge health check: HEALTHY
{"status":"healthy","version":"1.0.0"}
```

---

# 6. Monitoring Loop

The monitoring script is:

```text
/opt/cloudforge/scripts/monitor.sh
```

The monitor continuously executes the health check.

The current monitoring interval is approximately:

```text
30 seconds
```

The simplified logic is:

```text
Start monitor
     ↓
Run health check
     ↓
Healthy?
   /     \
 Yes      No
  |        |
Wait      Start
30 sec    self-healing
  |        |
  +--------+
```

---

# 7. Monitoring Service

CloudForge runs the monitoring process using systemd.

Service:

```text
cloudforge-monitor.service
```

Check the service:

```bash
sudo systemctl status cloudforge-monitor.service
```

Expected:

```text
active (running)
```

---

# 8. Monitoring Logs

View recent service logs:

```bash
sudo journalctl -u cloudforge-monitor.service -n 50
```

Follow the logs:

```bash
sudo journalctl -u cloudforge-monitor.service -f
```

The monitor prints messages such as:

```text
Running health check...
Application is healthy.
Waiting 30 seconds...
```

When a failure occurs:

```text
Application is unhealthy.
Starting self-healing...
```

---

# 9. Self-Healing Script

The recovery script is:

```text
/opt/cloudforge/scripts/self-heal.sh
```

The script first checks whether the application is already healthy.

If the application is healthy, it exits without performing recovery.

If the health check fails, it starts collecting evidence.

---

# 10. Failure Detection

When the health check fails, CloudForge records the detection time.

The script then captures Docker state.

Important values include:

```text
Container status
Exit code
OOMKilled
Restart count
Container logs
Host kernel logs
```

This information helps determine what happened before recovery.

---

# 11. Docker Evidence

CloudForge collects:

```text
Status
ExitCode
OOMKilled
RestartCount
```

Example:

```text
Status: exited
ExitCode: 137
OOMKilled: false
RestartCount: 0
```

The exact values depend on the failure being tested.

---

# 12. Container Logs

The self-healing script captures the last 50 lines of Docker logs:

```bash
docker logs --tail 50 cloudforge-api
```

These logs are stored in the incident record.

This allows the incident to retain application-level evidence from before recovery.

---

# 13. Host Evidence

CloudForge also collects recent kernel messages:

```bash
sudo dmesg -T | tail -50
```

This provides additional host-level context.

For example, Docker networking events may appear in the kernel logs when a container is stopped or removed.

---

# 14. Recovery Action

The current recovery action is:

```text
docker start
```

If necessary, the script falls back to:

```text
docker restart
```

The recovery flow is:

```text
Health Check Failed
        ↓
Collect Evidence
        ↓
docker start cloudforge-api
        ↓
Wait
        ↓
Health Check
```

---

# 15. Recovery Verification

After restarting the container, CloudForge does not immediately assume that recovery succeeded.

It repeatedly checks:

```text
http://127.0.0.1:8000/health
```

for a limited period.

Once the API becomes healthy:

```text
Recovery successful
```

is recorded.

If the application never becomes healthy:

```text
Recovery FAILED
```

is reported.

---

# 16. Recovery Timing

The recovery script records:

```text
detected_at
recovered_at
recovery_duration_seconds
```

This allows CloudForge to measure how long recovery took.

Example:

```json
{
  "detected_at": "2026-09-28T06:17:31Z",
  "recovered_at": "2026-09-28T06:17:33Z",
  "recovery_duration_seconds": 2
}
```

The actual recovery time varies depending on the failure and environment.

---

# 17. Incident Records

Successful recovery creates a JSON incident record.

Location:

```text
/opt/cloudforge/incidents/
```

Example:

```text
incident-2026-09-28-061731.json
```

The incident contains information such as:

```text
Incident ID
Environment
Application
Version
Failure type
Detection time
Recovery action
Recovery time
Recovery duration
Recovery status
Health status
Docker evidence
Host evidence
```

---

# 18. Example Incident Structure

A simplified incident looks like:

```json
{
  "incident_id": "incident-YYYY-MM-DD-HHMMSS",
  "environment": "staging",
  "application": "cloudforge-api",
  "version": "1.0.0",
  "failure_type": "container_stopped",
  "detected_at": "...",
  "recovery_action": "docker_start",
  "recovered_at": "...",
  "recovery_duration_seconds": 2,
  "recovery_status": "successful",
  "health_status": "healthy"
}
```

The actual incident record also contains Docker and host evidence.

---

# 19. Runtime Status Publisher

CloudForge also has a runtime status publisher:

```text
/opt/cloudforge/scripts/status-publisher.sh
```

It continuously reads Docker container state and writes:

```text
/opt/cloudforge/runtime/status.json
```

The file contains information such as:

```text
Container name
Container status
Running state
Health status
Exit code
OOM status
Restart count
Image
Start time
```

---

# 20. Status Publisher Service

The publisher runs through:

```text
cloudforge-status-publisher.service
```

Check it:

```bash
sudo systemctl status cloudforge-status-publisher.service
```

Expected:

```text
active (running)
```

This allows other CloudForge components, especially the dashboard, to read current container state without directly controlling Docker.

---

# 21. Self-Healing Test — Container Stop

A controlled failure can be created with:

```bash
docker stop cloudforge-api
```

This intentionally stops the API container.

Immediately after the stop, the application health check should eventually fail.

The monitor detects the failure.

The recovery process then:

```text
Health check fails
      ↓
Evidence collected
      ↓
Container restarted
      ↓
Health verified
      ↓
Incident recorded
```

---

# 22. Expected Result

After the test:

```bash
docker ps
```

should show the container running again.

Then:

```bash
curl http://127.0.0.1:8000/health
```

should return:

```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

An incident JSON file should also appear in:

```text
/opt/cloudforge/incidents/
```

---

# 23. Self-Healing Test — Force Kill

A second controlled failure can be created with:

```bash
docker kill cloudforge-api
```

This forcefully terminates the container.

CloudForge should detect the failure and attempt recovery.

The expected flow is:

```text
docker kill
     ↓
Health check fails
     ↓
Monitor detects failure
     ↓
Evidence collected
     ↓
Container started
     ↓
Health check succeeds
     ↓
Incident created
```

---

# 24. Exit Code 137

A forcefully terminated container may produce:

```text
Exit code: 137
```

Exit code `137` commonly indicates termination by `SIGKILL`.

However, CloudForge should not automatically treat this as proof of an out-of-memory failure.

The incident record separately records:

```text
OOMKilled
```

For example:

```text
ExitCode: 137
OOMKilled: false
```

This means the evidence does not establish that the container was killed by the Linux OOM killer.

The AI analyzer should also state when the exact root cause cannot be determined from the available evidence.

---

# 25. Network Failure Test

CloudForge was also tested against a network-level failure.

The controlled failure was:

```bash
sudo iptables -I INPUT -p tcp --dport 8000 -j REJECT
```

This blocks incoming TCP connections to port `8000`.

The health check then fails.

CloudForge detects the failure and attempts its normal recovery action.

---

# 26. Network Failure Limitation

Restarting the container does not remove the firewall rule.

Therefore:

```text
Health Check Failed
       ↓
Restart Container
       ↓
Health Check Failed
       ↓
Firewall still blocking port 8000
```

The container itself may be healthy while the health check remains inaccessible.

This demonstrates an important limitation of the current recovery policy.

---

# 27. Restore the Network

After completing the controlled firewall test, remove the rule:

```bash
sudo iptables -D INPUT -p tcp --dport 8000 -j REJECT
```

Then verify:

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

---

# 28. What CloudForge Currently Handles

### Container-level failure

```text
Container stops
       ↓
Detected
       ↓
Restart
       ↓
Recovered
```

### Forceful container termination

```text
Container killed
       ↓
Detected
       ↓
Evidence collected
       ↓
Restart
       ↓
Recovered
```

---

# 29. What CloudForge Does Not Yet Automatically Handle

Examples include:

```text
Firewall failures
Network routing failures
Subnet failures
Security group configuration problems
EC2 instance failure
AWS service outages
Persistent application bugs
Bad application deployments
Database failures
```

These require different detection and recovery strategies.

---

# 30. Recovery Boundary

The current system can be represented as:

```text
                 CloudForge
                     |
               Health Check
                     |
              Failure detected
                     |
             Collect evidence
                     |
             Restart container
                     |
             Health verification
                 /         \
              Healthy      Failed
                |             |
             Incident       Recovery
             recorded        failure
```

The important point is that CloudForge currently uses a relatively simple recovery policy:

```text
If application health fails → restart the container
```

---

# 31. Why Evidence Collection Matters

Simply restarting the container would recover the service but could destroy useful information about the failure.

CloudForge therefore collects evidence before recovery.

The sequence is:

```text
Failure
  ↓
Evidence
  ↓
Recovery
  ↓
Verification
  ↓
Incident Record
  ↓
AI Analysis
```

This makes the system more useful for troubleshooting and learning.

---

# 32. AI Incident Analysis

After a successful recovery, CloudForge runs:

```text
/opt/cloudforge/analyzer/run_analyzer.sh
```

The analyzer reads the latest incident JSON and generates an AI-assisted report.

The report covers:

```text
What happened
Likely cause
Impact
Recovery performed
Recovery assessment
Recommended next actions
```

The AI analyzer must distinguish between:

```text
Known evidence
```

and:

```text
Possible explanation
```

It should not claim an exact root cause when the incident data cannot establish one.

Detailed instructions are documented in:

```text
docs/ai-incident-analyzer.md
```

---

# 33. Dashboard Integration

The dashboard reads CloudForge runtime and incident information.

It can display:

```text
Application status
Container status
Docker health
CPU usage
Memory usage
Latest incident
Recovery information
AI analysis
```

The dashboard does not own the recovery process.

The architecture is:

```text
                 Dashboard
                     |
                     | Read
                     v
               FastAPI API
                     |
             +-------+-------+
             |               |
             v               v
       Runtime Status    Incident Files
             |               |
             |               |
             +-------+-------+
                     |
                     v
              Display State
```

The monitoring/self-healing system remains responsible for recovery.

---

# 34. Testing the Self-Healing System

Self-healing should be tested using controlled failures.

Recommended tests:

```text
Test 1
Container stop

Test 2
Container force kill

Test 3
Network/firewall failure
```

Each test should verify:

```text
[ ] Failure created
[ ] Failure detected
[ ] Evidence collected
[ ] Recovery attempted
[ ] Health checked
[ ] Recovery result recorded
[ ] Incident JSON created
[ ] AI analysis generated where applicable
```

Detailed test results are documented in:

```text
docs/chaos-testing.md
```

---

# 35. Current Test Results

CloudForge successfully demonstrated automatic recovery for:

```text
Container stop
Container force kill
```

The network/firewall test demonstrated:

```text
Failure detection
+
Recovery limitation
```

The network failure was not automatically repaired because the current recovery action only restarts the application container.

---

# 36. Future Self-Healing Improvements

The current implementation provides the foundation for a more advanced policy engine.

Future recovery policies could distinguish between:

```text
Application failure
        ↓
Restart container

Container repeatedly failing
        ↓
Rollback deployment

Memory pressure
        ↓
Investigate resource usage

Network failure
        ↓
Validate networking/security configuration

EC2 failure
        ↓
Replace/recover instance

Repeated incidents
        ↓
Escalate / notify
```

The planned AI incident analyzer can eventually help classify incidents, but AI recommendations should remain separate from deterministic recovery controls unless explicitly validated by a policy engine.

---

# 37. Important Safety Rule

Do not expose destructive chaos or recovery operations as unauthenticated public endpoints.

For example, an endpoint that executes:

```text
docker kill
docker stop
docker restart
```

should not be publicly accessible without authentication and authorization.

The current design keeps recovery logic on the EC2 host.

---

# 38. Troubleshooting

## Monitor is not running

Check:

```bash
sudo systemctl status cloudforge-monitor.service
```

View logs:

```bash
sudo journalctl -u cloudforge-monitor.service -n 100
```

---

## Self-healing script fails

Run manually:

```bash
/opt/cloudforge/scripts/self-heal.sh
```

Then inspect the output.

Check Docker:

```bash
docker ps -a
```

Check logs:

```bash
docker logs --tail 100 cloudforge-api
```

---

## Incident was not created

Check:

```bash
ls -la /opt/cloudforge/incidents
```

Check permissions:

```bash
ls -ld /opt/cloudforge/incidents
```

Check the monitoring logs:

```bash
sudo journalctl -u cloudforge-monitor.service -n 100
```

---

## API remains unhealthy after recovery

Check:

```bash
docker ps -a
```

Then:

```bash
docker logs --tail 100 cloudforge-api
```

Check the health endpoint:

```bash
curl -v http://127.0.0.1:8000/health
```

Check whether port `8000` is blocked:

```bash
sudo iptables -L INPUT -n --line-numbers
```

---

# 39. Final Self-Healing Architecture

```text
                  CloudForge API
                       |
                       v
                 Health Check
                       |
              +--------+--------+
              |                 |
           Healthy           Failure
              |                 |
            Wait          Collect Evidence
              |                 |
              |          Restart Container
              |                 |
              |          Health Verification
              |                 |
              |          +------+------+
              |          |             |
              |       Recovered       Failed
              |          |             |
              |      Incident       Recovery
              |       Record         Failure
              |          |
              |          v
              |     AI Analyzer
              |          |
              +----------+
                       |
                   Dashboard
```

---

# 40. Summary

CloudForge's current self-healing mechanism provides:

```text
Health monitoring
        +
Failure detection
        +
Docker evidence collection
        +
Host evidence collection
        +
Automatic container recovery
        +
Recovery verification
        +
Incident recording
        +
AI-assisted incident analysis
```

The system is intentionally designed with a clear recovery boundary.

The current policy is strongest for failures that can be resolved by restarting the application container. Network and infrastructure failures require additional recovery policies.

This provides the foundation for the future CloudForge policy engine and more advanced automated remediation.

```
```
