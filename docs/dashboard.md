# CloudForge Dashboard Guide

This document describes the final CloudForge staging dashboard architecture, source structure, runtime data flow, deployment process, verification, security boundaries, and reproducible build process.

The dashboard is an operational visibility layer. It does not perform container recovery itself.

---

# 1. Purpose

The CloudForge dashboard provides a live operational view of the staging environment.

It brings together:

- Application status
- Docker container state
- Container health
- CPU usage
- Memory usage
- Runtime state
- Latest incident
- Recovery information
- AI incident analysis
- CloudForge environment information

The dashboard is designed as a monitoring and observability interface.

The recovery mechanism remains separate:

```text
Monitoring
    |
    v
Self-Healing
    |
    v
Recovery
    |
    v
Incident Evidence
    |
    v
Dashboard
```

This separation keeps recovery logic out of the dashboard.

---

# 2. Final Dashboard Architecture

CloudForge uses two separate application containers on the staging EC2 instance:

```text
                         Browser
                            |
                 +----------+----------+
                 |                     |
                 v                     v
              :8080                  :8000
                 |                     |
                 v                     v
      cloudforge-dashboard      cloudforge-api
             container             container
                 |
                 v
        Dashboard Backend
                 |
        +--------+---------+
        |        |         |
        v        v         v
     Runtime  Incidents  System
     Status      +       Metrics
               AI
             Analysis
```

The main API remains responsible for the application.

The dashboard provides the operational interface.

---

# 3. Container Separation

The dashboard runs independently from the main CloudForge API.

Dashboard:

```text
cloudforge-dashboard
```

API:

```text
cloudforge-api
```

This separation provides:

- Independent dashboard deployment
- Independent dashboard image builds
- Clear separation between application and observability
- A read-oriented dashboard design
- No requirement for the dashboard to control Docker directly

---

# 4. Dashboard Ports

The dashboard application listens on port:

```text
8000
```

inside its container.

Docker maps it to:

```text
8080
```

on the EC2 host.

The mapping is:

```text
EC2 :8080
     |
     v
Container :8000
```

The API uses:

```text
EC2 :8000
     |
     v
API container :8000
```

The dashboard URL is:

```text
http://<EC2-PUBLIC-IP>:8080/dashboard/
```

The EC2 public IP can change when the instance is stopped and started because the staging instance does not use an Elastic IP.

---

# 5. Final Repository Structure

The dashboard source is now part of the CloudForge Git repository.

The final structure is:

```text
dashboard/
├── Dockerfile
├── main.py
├── requirements.txt
├── services/
│   ├── docker_service.py
│   ├── incident_service.py
│   └── system_service.py
└── static/
    ├── index.html
    ├── style.css
    └── dashboard.js
```

This is important because the dashboard is now reproducible from the Git repository instead of depending on manually created files on the EC2 instance.

---

# 6. Dashboard Backend

The dashboard backend uses FastAPI.

Main file:

```text
dashboard/main.py
```

The backend provides:

```text
/
 /health
 /version
 /metrics
 /api/container
 /api/dashboard
```

The dashboard frontend is served under:

```text
/dashboard/
```

The dashboard backend does not contain the self-healing recovery logic.

---

# 7. Dashboard Frontend

The frontend is located under:

```text
dashboard/static/
```

Files:

```text
index.html
style.css
dashboard.js
```

## index.html

Defines the dashboard structure and operational UI.

## style.css

Provides:

- Dashboard layout
- Cards
- Status indicators
- Responsive design
- Operational panels
- Visual hierarchy

## dashboard.js

Provides:

- API polling
- Live data updates
- Container status rendering
- System metric rendering
- Incident rendering
- AI analysis rendering
- Dashboard state updates

---

# 8. Runtime Status Architecture

The dashboard does not need direct Docker control.

Instead, CloudForge publishes runtime information to:

```text
/opt/cloudforge/runtime/status.json
```

The flow is:

```text
Docker
   |
   v
Status Publisher
   |
   v
status.json
   |
   v
Dashboard Backend
   |
   v
Browser
```

The status publisher is managed by:

```text
cloudforge-status-publisher.service
```

This allows the dashboard to read container state without mounting the Docker socket.

---

# 9. Runtime Status Data

The runtime status file contains information such as:

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
    "image": "...",
    "started_at": "..."
  },
  "updated_at": "..."
}
```

The actual image name and timestamps depend on the current deployment.

The dashboard reads this information in read-only mode.

---

# 10. Docker Service

The dashboard uses:

```text
dashboard/services/docker_service.py
```

This service reads:

```text
/opt/cloudforge/runtime/status.json
```

It exposes information such as:

- Container name
- Container status
- Running state
- Health status
- Exit code
- OOM status
- Restart count
- Image
- Start time
- Last update

The dashboard therefore does not need unrestricted access to the Docker daemon.

---

# 11. Incident Service

Incident information is provided by:

```text
dashboard/services/incident_service.py
```

The service reads incident records from:

```text
/opt/cloudforge/incidents/
```

The latest incident JSON is selected from the available incident files.

AI reports are read from:

```text
/opt/cloudforge/incidents/*-ai.txt
```

The dashboard displays these generated records but does not create or modify them.

---

# 12. Incident Information

A typical incident record contains:

```text
Incident ID
Environment
Application
Version
Failure type
Detected time
Recovery action
Recovered time
Recovery duration
Recovery status
Health status
Docker evidence
Host evidence
```

This allows the dashboard to show the most recent recovery event.

---

# 13. AI Incident Analysis

The AI analyzer remains a separate CloudForge component.

The analyzer generates:

```text
*-ai.txt
```

inside:

```text
/opt/cloudforge/incidents/
```

The dashboard reads the latest generated report.

The dashboard does not call Gemini directly.

The separation is:

```text
Incident JSON
     |
     v
Gemini Analyzer
     |
     v
AI Report
     |
     v
Dashboard
```

The report can contain:

- What happened
- Likely cause
- Impact
- Recovery performed
- Recovery assessment
- Recommended next actions

The analyzer is responsible for generating the report; the dashboard is responsible for displaying it.

---

# 14. System Metrics

The dashboard uses:

```text
dashboard/services/system_service.py
```

and `psutil` to collect current host metrics.

The dashboard can display:

```text
CPU percentage
Memory percentage
Memory used
Memory total
Hostname
Timestamp
```

These are current host metrics rather than historical monitoring data.

---

# 15. Dashboard API

The main dashboard endpoint is:

```text
/api/dashboard
```

It combines:

```text
Application information
        +
Container information
        +
System metrics
        +
Latest incident
        +
Latest AI analysis
```

Example response structure:

```json
{
  "application": {
    "name": "CloudForge",
    "environment": "staging",
    "version": "1.0.0"
  },
  "container": {},
  "system": {},
  "latest_incident": {},
  "latest_ai_analysis": "...",
  "timestamp": "..."
}
```

This gives the frontend a single operational view of the current CloudForge state.

---

# 16. Container API

The dashboard backend also exposes:

```text
/api/container
```

This endpoint returns the current CloudForge API container state obtained from the runtime status data.

---

# 17. Dashboard Health Check

The dashboard Docker image includes a health check.

It checks:

```text
http://127.0.0.1:8000/health
```

The Docker container should eventually show:

```text
healthy
```

Verify with:

```bash
docker ps --filter name=cloudforge-dashboard
```

---

# 18. Dashboard Dockerfile

The final dashboard Dockerfile is:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .
COPY services/ ./services/
COPY static/ ./static/

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

The Dockerfile is stored at:

```text
dashboard/Dockerfile
```

---

# 19. Dashboard Dependencies

The dashboard has its own requirements file:

```text
dashboard/requirements.txt
```

It contains the dashboard runtime dependencies:

```text
fastapi
uvicorn[standard]
psutil
pytest
httpx
```

The Gemini SDK is intentionally not part of the dashboard image.

Gemini dependencies belong to the separate incident analyzer environment.

---

# 20. Build the Dashboard Image

From the CloudForge repository root:

```bash
cd /opt/cloudforge
```

Build the dashboard:

```bash
docker build -t cloudforge-dashboard:1.0.5 ./dashboard
```

Verify:

```bash
docker images | grep cloudforge-dashboard
```

The image tag can be incremented when dashboard source changes.

---

# 21. Start the Dashboard Container

The dashboard requires read-only access to runtime and incident information.

The final deployment pattern is:

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.5
```

The volumes are read-only:

```text
/opt/cloudforge/runtime → /opt/cloudforge/runtime:ro
/opt/cloudforge/incidents → /opt/cloudforge/incidents:ro
```

This prevents the dashboard from modifying operational evidence.

---

# 22. Verify the Dashboard Container

Run:

```bash
docker ps --filter name=cloudforge-dashboard
```

Expected mapping:

```text
0.0.0.0:8080->8000/tcp
```

Expected health:

```text
healthy
```

---

# 23. Verify Dashboard HTTP Response

From the EC2 instance:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

Expected:

```text
HTTP/1.1 200 OK
```

This verifies that the dashboard is being served by the container.

---

# 24. Verify Dashboard API

Run:

```bash
curl -s http://127.0.0.1:8080/api/dashboard
```

The response should contain:

```text
application
container
system
latest_incident
latest_ai_analysis
timestamp
```

This verifies that the dashboard is not just serving static HTML; it is reading live CloudForge operational data.

---

# 25. Open the Live Dashboard

Find the current EC2 public IP:

```powershell
aws ec2 describe-instances `
  --instance-ids <instance-id> `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text
```

Then open:

```text
http://<EC2-PUBLIC-IP>:8080/dashboard/
```

The public IP can change after the EC2 instance is stopped and started.

---

# 26. AWS Security Group

The staging security group must allow the dashboard port according to the intended access policy.

Dashboard:

```text
8080/TCP
```

API:

```text
8000/TCP
```

Terraform manages the staging security group configuration.

If the dashboard works locally on EC2 but cannot be opened from a browser, check the security group before changing the container configuration.

---

# 27. Dashboard Data Flow

The final data flow is:

```text
                         Staging EC2
                              |
          +-------------------+-------------------+
          |                                       |
          v                                       v
   cloudforge-api                         Status Publisher
          |                                       |
          |                                       v
          |                                  status.json
          |                                       |
          +-------------------+-------------------+
                              |
                              v
                       Dashboard Backend
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
       Container State   Incident Data    System Metrics
             |                |
             |                v
             |           AI Analysis
             |                |
             +----------------+----------------+
                              |
                              v
                         Browser UI
```

---

# 28. Live Polling

The dashboard frontend periodically requests updated information from the dashboard API.

The live view can update:

```text
Container state
Health state
CPU
Memory
Incident information
AI analysis
Runtime information
```

This allows the dashboard to act as an operational monitoring interface instead of a static status page.

---

# 29. Dashboard Operational States

The dashboard can represent states such as:

```text
HEALTHY
INCIDENT DETECTED
SELF-HEALING
RECOVERED
UNAVAILABLE
```

These states are based on the operational information available to the dashboard.

The dashboard itself does not perform the recovery transition.

---

# 30. Dashboard and Self-Healing Relationship

The dashboard is not the self-healing engine.

The correct architecture is:

```text
Health Monitoring
       |
       v
Self-Healing
       |
       v
Container Recovery
       |
       v
Incident JSON
       |
       v
AI Analysis
       |
       v
Dashboard Visibility
```

Not:

```text
Dashboard
    |
    v
Docker restart
```

This separation is important because the dashboard should not become a privileged recovery control surface.

---

# 31. Read-Only Dashboard Design

The dashboard primarily reads:

```text
Runtime status
Incident records
AI reports
System metrics
```

It does not require:

```text
/var/run/docker.sock
```

inside the dashboard container.

Avoid mounting the Docker socket into the dashboard unless a future requirement specifically justifies it and the access is properly secured.

The current design is intentionally read-oriented.

---

# 32. Testing Live Dashboard Updates

A controlled test can be performed from the EC2 instance.

First verify the API:

```bash
curl http://127.0.0.1:8000/health
```

Then intentionally stop the API:

```bash
docker stop cloudforge-api
```

The monitoring service should detect the failed health check.

The self-healing process should attempt recovery.

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

The dashboard should eventually reflect the recovered state.

This test demonstrates the relationship between:

```text
Failure
  ↓
Detection
  ↓
Self-Healing
  ↓
Recovery
  ↓
Incident Evidence
  ↓
Dashboard Visibility
```

---

# 33. Dashboard Incident Test

After a controlled chaos test:

```bash
ls -lt /opt/cloudforge/incidents/
```

You should see incident records such as:

```text
incident-<timestamp>.json
```

and, when the analyzer has completed:

```text
incident-<timestamp>-ai.txt
```

Refresh the dashboard.

The latest incident and AI analysis should become available through:

```text
/api/dashboard
```

---

# 34. Troubleshooting — Dashboard Does Not Open

Check the container:

```bash
docker ps -a --filter name=cloudforge-dashboard
```

Check logs:

```bash
docker logs --tail 100 cloudforge-dashboard
```

Check locally:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

If local access works but browser access fails, check the AWS Security Group.

---

# 35. Troubleshooting — Dashboard Connection Refused

Check port 8080:

```bash
sudo ss -lntp | grep :8080
```

Check Docker mapping:

```bash
docker ps --filter name=cloudforge-dashboard
```

Expected:

```text
0.0.0.0:8080->8000/tcp
```

---

# 36. Troubleshooting — No Container Data

Check the runtime status:

```bash
cat /opt/cloudforge/runtime/status.json
```

If the file is missing, check:

```bash
sudo systemctl status cloudforge-status-publisher.service
```

Then:

```bash
sudo journalctl -u cloudforge-status-publisher.service -n 50
```

---

# 37. Troubleshooting — No Incident

Check:

```bash
ls -la /opt/cloudforge/incidents/
```

If no incident JSON exists, the dashboard has no incident record to display.

A controlled chaos test can be used to generate a new incident.

---

# 38. Troubleshooting — No AI Analysis

Check:

```bash
ls -lt /opt/cloudforge/incidents/*-ai.txt
```

If no AI report exists:

1. Verify an incident JSON exists.
2. Verify the analyzer environment.
3. Verify Gemini configuration.
4. Run the analyzer manually.

Example:

```bash
/opt/cloudforge/analyzer/run_analyzer.sh
```

The dashboard only displays the generated report.

---

# 39. Troubleshooting — Runtime Volume

The dashboard container uses:

```text
-v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro
```

Verify the host file:

```bash
ls -l /opt/cloudforge/runtime/status.json
```

Verify the container mounts:

```bash
docker inspect cloudforge-dashboard
```

The runtime volume should be read-only.

---

# 40. Troubleshooting — Incident Volume

Verify:

```bash
ls -ld /opt/cloudforge/incidents
```

and:

```bash
ls -la /opt/cloudforge/incidents
```

The dashboard container uses:

```text
-v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro
```

This prevents the dashboard from modifying incident evidence.

---

# 41. Dashboard Deployment Update

When dashboard source code changes:

```text
Source change
     |
     v
Git commit
     |
     v
Build new image
     |
     v
Stop old dashboard
     |
     v
Remove old container
     |
     v
Start new dashboard
     |
     v
Health check
     |
     v
HTTP verification
```

Example:

```bash
docker stop cloudforge-dashboard
docker rm cloudforge-dashboard
```

Build:

```bash
cd /opt/cloudforge
docker build -t cloudforge-dashboard:<new-version> ./dashboard
```

Start:

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:<new-version>
```

---

# 42. Dashboard Versioning

Explicit image tags are used when testing dashboard changes.

Examples from the development history include:

```text
cloudforge-dashboard:1.0.1
cloudforge-dashboard:1.0.2
cloudforge-dashboard:1.0.3
cloudforge-dashboard:1.0.4
cloudforge-dashboard:1.0.5
```

The current reproducible dashboard image is:

```text
cloudforge-dashboard:1.0.5
```

---

# 43. Reproducible Dashboard Build Verification

The dashboard source was verified from the CloudForge Git repository.

The verification process was:

```text
Git repository
      |
      v
dashboard/
      |
      v
Docker build
      |
      v
cloudforge-dashboard:rebuild-test
      |
      v
Temporary container
      |
      v
/dashboard/ → HTTP 200
      |
      v
/api/dashboard → live CloudForge data
```

The image was built with:

```bash
cd /opt/cloudforge
docker build -t cloudforge-dashboard:rebuild-test ./dashboard
```

The build completed successfully.

The rebuilt container was tested locally on the EC2 host.

Dashboard verification returned:

```text
HTTP/1.1 200 OK
```

The dashboard API also returned live information including:

```text
Application
Container state
System metrics
Latest incident
AI analysis
Timestamp
```

After verification, the temporary test container was removed:

```bash
docker rm -f cloudforge-dashboard-rebuild-test
```

The temporary test image was also removed:

```bash
docker rmi cloudforge-dashboard:rebuild-test
```

This verification demonstrates that the dashboard can be rebuilt from repository source rather than depending on a manually created image.

---

# 44. Final Live Dashboard Verification

A complete dashboard verification should confirm:

```text
[ ] Dashboard source exists under dashboard/
[ ] Dockerfile exists under dashboard/
[ ] Dashboard image builds successfully
[ ] Dashboard container starts
[ ] Port 8080 maps to container port 8000
[ ] Docker health check becomes healthy
[ ] /dashboard/ returns HTTP 200
[ ] /api/dashboard returns live data
[ ] Runtime status is available
[ ] Latest incident is available
[ ] Latest AI analysis is available
[ ] CPU information is displayed
[ ] Memory information is displayed
[ ] Container state is displayed
[ ] Dashboard reflects self-healing results
```

---

# 45. Dashboard Security Considerations

The dashboard exposes operational information such as:

```text
Container names
Image names
Instance information
Incident information
System metrics
Deployment information
AI-generated analysis
```

Therefore the dashboard should not be considered a completely public production dashboard.

Potential future improvements include:

```text
Authentication
Authorization
HTTPS
Reverse proxy
Private networking
VPN access
AWS ALB authentication
```

The current implementation is a staging/portfolio system and intentionally focuses on demonstrating cloud, DevOps, observability, self-healing, and backend integration.

---

# 46. Complete CloudForge Dashboard Architecture

The dashboard fits into the complete CloudForge platform as follows:

```text
                         GitHub
                            |
                            v
                         Jenkins
                            |
                            v
                           ECR
                            |
                            v
                      Staging EC2
                            |
              +-------------+-------------+
              |                           |
              v                           v
       cloudforge-api              cloudforge-dashboard
            :8000                         :8080
              |
              v
       Health Endpoint
              |
              v
       Health Monitoring
              |
              v
         Self-Healing
              |
              v
       Incident Evidence
              |
              v
       Gemini Analyzer
              |
              v
          AI Report
              |
              +--------------------+
                                   |
                                   v
                             Dashboard Backend
                                   |
                                   v
                              Browser UI
```

The operational responsibilities are intentionally separated:

```text
API
    → Application

Monitoring
    → Detection

Self-Healing
    → Recovery

Incident System
    → Evidence

Gemini Analyzer
    → Analysis

Dashboard
    → Visibility
```

---

# 47. Portfolio Value

The dashboard demonstrates several engineering concepts in one system:

```text
FastAPI
Docker
AWS EC2
Terraform
Jenkins
ECR
SSM
Linux
Runtime observability
Incident management
Self-healing
AI-assisted incident analysis
Frontend/backend integration
Reproducible builds
Chaos testing
Load testing
```

The dashboard is therefore not only a UI project. It is the operational visibility layer of the CloudForge DevOps platform.

---

# 48. Summary

The CloudForge dashboard provides a read-oriented operational view of the staging platform.

It combines:

```text
Container State
       +
Runtime Status
       +
System Metrics
       +
Incident Evidence
       +
AI Analysis
```

The final design follows three clear responsibilities:

```text
Self-Healing
    → controls recovery

Dashboard
    → provides visibility

AI Analyzer
    → provides incident analysis
```

The dashboard is independently containerized, stored in Git, reproducibly built from the repository, and verified against live CloudForge runtime data.

This makes the dashboard a complete part of the CloudForge AWS DevOps portfolio project rather than a manually created EC2-only component.
