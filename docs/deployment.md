# CloudForge Deployment Guide

This document describes how CloudForge is deployed from source control to the AWS staging environment.

The primary deployment architecture is:

```text
GitHub
   |
   v
Jenkins
   |
   v
Build + Test
   |
   v
Docker Image
   |
   v
Amazon ECR
   |
   v
AWS Systems Manager
   |
   v
Staging EC2
   |
   v
CloudForge API
   |
   v
Health Verification
````

The dashboard is deployed as a separate container and provides operational visibility into the running environment.

---

# 1. Deployment Goals

The CloudForge deployment process is designed to:

* Build the application consistently.
* Run automated tests.
* Package the API as a Docker image.
* Push the image to Amazon ECR.
* Deploy the selected image to the staging EC2 instance.
* Verify application health after deployment.
* Keep deployment repeatable through Jenkins.
* Use AWS Systems Manager instead of requiring SSH as the normal deployment mechanism.
* Maintain versioned container images for traceability and rollback.

---

# 2. Current Deployment Environment

The documented deployment environment is:

```text
AWS Region: us-east-1
Environment: staging
Compute: Amazon EC2
Container Runtime: Docker
Image Registry: Amazon ECR
Remote Management: AWS Systems Manager
CI/CD: Jenkins
Application Port: 8000
Dashboard Port: 8080
```

The main application container is:

```text
cloudforge-api
```

The dashboard runs independently:

```text
cloudforge-dashboard
```

---

# 3. Deployment Architecture

The current deployment flow is:

```text
                         GitHub
                            |
                            v
                    CloudForge source
                            |
                            v
                         Jenkins
                            |
                +-----------+-----------+
                |                       |
                v                       v
              Tests               Docker Build
                                        |
                                        v
                                      ECR
                                        |
                                        v
                                      SSM
                                        |
                                        v
                                Staging EC2
                                        |
                              +---------+---------+
                              |                   |
                              v                   v
                       cloudforge-api     cloudforge-dashboard
                           :8000                  :8080
                              |
                              v
                           /health
                              |
                              v
                       Health Verification
```

---

# 4. Source Control

The CloudForge repository is:

```text
https://github.com/Savio9481/cloudforge.git
```

The deployment branch is:

```text
main
```

Before deployment, Jenkins checks out the selected source revision.

The deployment should always be traceable to a Git commit.

---

# 5. Jenkins Pipeline

The CloudForge CI/CD pipeline is defined by:

```text
Jenkinsfile
```

The Jenkins job used by the project is:

```text
CloudForge-CI-CD
```

The high-level pipeline is:

```text
Checkout
    |
    v
Test
    |
    v
Docker Build
    |
    v
ECR Push
    |
    v
SSM Deployment
    |
    v
Health Verification
```

---

# 6. Checkout Stage

Jenkins retrieves the CloudForge source code from GitHub.

The basic flow is:

```text
GitHub
   |
   v
Jenkins Workspace
```

The deployment is performed from the checked-out source revision rather than from manually modified application files on EC2.

---

# 7. Test Stage

Before deployment, the application should pass its automated tests.

The application includes testing dependencies such as:

```text
pytest
httpx
```

The test stage prevents an invalid application build from proceeding directly to deployment.

The exact commands are maintained in the project's `Jenkinsfile`.

---

# 8. Docker Build Stage

The CloudForge API source is located under:

```text
app/
```

A local equivalent of the Docker build is:

```bash
docker build -t cloudforge-api:local ./app
```

Jenkins performs the equivalent build as part of the CI/CD pipeline.

---

# 9. Image Tagging

CloudForge uses versioned image tags.

An example verified deployment image is:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:195bc75
```

The tag:

```text
195bc75
```

identifies a specific application build/commit.

Using versioned tags makes it easier to identify exactly which image is running.

---

# 10. Amazon ECR

The CloudForge API image is stored in Amazon Elastic Container Registry.

Repository:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api
```

The flow is:

```text
Jenkins
   |
   v
Docker Build
   |
   v
ECR Authentication
   |
   v
Docker Push
   |
   v
ECR Repository
```

---

# 11. ECR Authentication

An appropriately permissioned AWS environment can authenticate with ECR using:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin \
595319278112.dkr.ecr.us-east-1.amazonaws.com
```

Expected result:

```text
Login Succeeded
```

Credentials must never be written into the Jenkinsfile or committed to GitHub.

---

# 12. Push Image to ECR

The general manual workflow is:

```bash
docker build -t cloudforge-api:<tag> ./app
```

Tag the image:

```bash
docker tag cloudforge-api:<tag> \
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

Push:

```bash
docker push \
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

In the normal CloudForge workflow, Jenkins performs these operations.

---

# 13. Deployment Through AWS Systems Manager

CloudForge uses AWS Systems Manager to deploy to the staging EC2 instance.

The architecture is:

```text
Jenkins
   |
   v
AWS Systems Manager
   |
   v
Staging EC2
```

This avoids requiring public SSH access as the normal deployment mechanism.

The EC2 instance must have the appropriate SSM IAM instance profile.

---

# 14. EC2 Deployment Target

The staging EC2 instance runs:

```text
Docker
CloudForge API
CloudForge Dashboard
Monitoring
Self-Healing
Runtime Status Publisher
AI Incident Analyzer
```

The API deployment affects:

```text
cloudforge-api
```

The dashboard is deployed separately from:

```text
dashboard/
```

---

# 15. Deployment Sequence on EC2

The API deployment conceptually follows:

```text
Receive deployment command
        |
        v
Authenticate to ECR
        |
        v
Pull selected image
        |
        v
Stop/replace existing API container
        |
        v
Start new container
        |
        v
Wait for health
        |
        v
Verify /health
        |
        v
Deployment complete
```

The exact deployment commands are maintained in the project's `Jenkinsfile`.

---

# 16. Current API Container

The staging API container is:

```text
cloudforge-api
```

The container listens on:

```text
8000
```

The host mapping is:

```text
EC2 :8000
    |
    v
Container :8000
```

---

# 17. Deployment Health Check

After deployment, CloudForge verifies:

```text
http://127.0.0.1:8000/health
```

Expected response:

```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

A deployment is not considered complete merely because Docker successfully started the container.

The application health endpoint must respond successfully.

---

# 18. Manual Deployment Verification

If verification is performed directly on EC2:

```bash
docker ps --filter name=cloudforge-api
```

Check recent logs:

```bash
docker logs --tail 100 cloudforge-api
```

Then:

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

# 19. Verify the Running Image

Run:

```bash
docker inspect cloudforge-api \
  --format '{{.Config.Image}}'
```

This displays the image currently used by the container.

For the documented deployment example:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:195bc75
```

---

# 20. Verify Container Health

Run:

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

Expected:

```text
healthy
```

Also:

```bash
docker ps --filter name=cloudforge-api
```

The container should be running and healthy.

---

# 21. Deployment Verification Through the Dashboard

The CloudForge dashboard exposes:

```text
/api/dashboard
```

The response contains operational information such as:

```text
Application
Environment
Container
Health
Image
System metrics
Latest incident
AI analysis
Timestamp
```

This provides a second operational view of the deployment.

---

# 22. Runtime Status

CloudForge maintains current runtime state in:

```text
/opt/cloudforge/runtime/status.json
```

Check:

```bash
cat /opt/cloudforge/runtime/status.json
```

The status includes information such as:

```text
Container name
Container status
Running state
Health
Exit code
OOM state
Restart count
Image
Start time
Updated time
```

The image reported here should correspond to the deployed version.

---

# 23. Deployment and Monitoring

Monitoring continues independently after deployment.

The relationship is:

```text
Deployment
    |
    v
Health Verification
    |
    v
Monitoring
    |
    v
Continuous Health Checks
```

If a later runtime failure occurs, the CloudForge self-healing workflow handles recovery.

---

# 24. Deployment and Self-Healing

Deployment and self-healing have different responsibilities.

### Jenkins

```text
Build
Test
Package
Deploy
Verify
```

### Self-Healing

```text
Detect runtime failure
Collect evidence
Recover container
Verify health
Create incident
Run AI analysis
```

Self-healing is not a replacement for CI/CD.

Jenkins is not the runtime monitoring engine.

---

# 25. Deployment Failure

If the new container fails health verification:

```text
Deployment
    |
    v
Container starts
    |
    v
Health check fails
    |
    v
Deployment verification fails
```

Inspect:

```bash
docker ps -a
```

Then:

```bash
docker logs --tail 100 cloudforge-api
```

And:

```bash
curl http://127.0.0.1:8000/health
```

Determine whether the issue is related to:

```text
Application
Docker
Configuration
Image
Dependency
Infrastructure
Network
```

---

# 26. Deployment Logs

For application-level problems:

```bash
docker logs --tail 100 cloudforge-api
```

For the status publisher:

```bash
sudo journalctl -u cloudforge-status-publisher.service -n 50
```

For monitoring/self-healing:

```bash
sudo journalctl -u cloudforge-monitor.service -n 100
```

For CI/CD problems, inspect the Jenkins console output for:

```text
CloudForge-CI-CD
```

---

# 27. Deployment Evidence

A successful deployment should provide evidence at multiple levels:

```text
Jenkins
    |
    +--> Build passed

ECR
    |
    +--> Image exists

EC2
    |
    +--> Container running

Docker
    |
    +--> Container healthy

Application
    |
    +--> /health returns healthy

Runtime
    |
    +--> status.json updated

Dashboard
    |
    +--> Current state visible
```

This is stronger than relying on a single deployment check.

---

# 28. Dashboard Deployment

The dashboard is a separate container.

The current verified dashboard image is:

```text
cloudforge-dashboard:1.0.5
```

Build it from the repository root:

```bash
cd /opt/cloudforge
docker build -t cloudforge-dashboard:1.0.5 ./dashboard
```

Start it:

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.5
```

The dashboard reads runtime and incident information through read-only mounts.

---

# 29. Dashboard Verification

Check:

```bash
docker ps --filter name=cloudforge-dashboard
```

Then:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

Expected:

```text
HTTP/1.1 200 OK
```

Check live dashboard data:

```bash
curl -s http://127.0.0.1:8080/api/dashboard
```

---

# 30. Public Dashboard Access

Find the current EC2 public IP:

```powershell
aws ec2 describe-instances `
  --instance-ids <instance-id> `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text
```

Open:

```text
http://<EC2-PUBLIC-IP>:8080/dashboard/
```

Do not permanently document a public IP because the address may change after the instance is stopped and started.

---

# 31. Deployment Versioning

CloudForge uses explicit image tags.

Example:

```text
cloudforge-api:195bc75
```

Full image:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:195bc75
```

The current dashboard image is:

```text
cloudforge-dashboard:1.0.5
```

Versioned images make deployment state easier to identify.

---

# 32. Deployment Traceability

A deployment can be traced through:

```text
Git Commit
    |
    v
Jenkins Build
    |
    v
Docker Image Tag
    |
    v
ECR Image
    |
    v
EC2 Container
```

For example:

```text
Git commit
    ↓
195bc75
    ↓
cloudforge-api:195bc75
    ↓
ECR
    ↓
cloudforge-api
```

This makes it easier to determine which build is currently deployed.

---

# 33. Rollback

Versioned ECR images provide a foundation for rollback.

For example:

```text
Current:
cloudforge-api:<new-tag>

Previous:
cloudforge-api:<previous-tag>
```

A previous known-good image can be deployed again if required.

However, **fully automated rollback is not currently implemented as an automatic self-healing action**.

It should therefore not be described as an active automated feature.

---

# 34. Manual Rollback Process

A rollback conceptually follows:

```text
Identify previous known-good image
        |
        v
Verify image exists in ECR
        |
        v
Deploy previous image
        |
        v
Wait for health
        |
        v
Verify application
        |
        v
Record result
```

The deployment should use the same controlled Jenkins/SSM deployment mechanism where possible.

---

# 35. Deployment vs Runtime Recovery

These workflows are separate.

### Deployment

```text
New Version
    |
    v
Build
    |
    v
Test
    |
    v
Deploy
    |
    v
Verify
```

### Runtime Recovery

```text
Existing Version
    |
    v
Failure
    |
    v
Detect
    |
    v
Recover
    |
    v
Verify
```

CloudForge implements these as separate operational workflows.

---

# 36. Jenkins Responsibilities

Jenkins is responsible for:

```text
Source checkout
Automated tests
Docker build
ECR push
SSM deployment
Deployment health verification
```

Jenkins is not responsible for continuous runtime monitoring.

---

# 37. Self-Healing Responsibilities

The self-healing system is responsible for:

```text
Health monitoring
Failure detection
Docker evidence collection
Host evidence collection
Container recovery
Health verification
Incident creation
AI analyzer invocation
```

This allows CloudForge to recover certain runtime failures without requiring a new Jenkins build.

---

# 38. Incident Creation

When self-healing detects a failed application:

```text
Health Check
    |
    v
Failure
    |
    v
Docker Evidence
    |
    v
Host Evidence
    |
    v
Recovery
    |
    v
Health Verification
    |
    v
Incident JSON
```

Incident records are stored under:

```text
/opt/cloudforge/incidents/
```

---

# 39. AI Analysis

After an incident record is created, the AI analyzer can generate:

```text
incident-<timestamp>-ai.txt
```

The analyzer provides analysis covering:

```text
What happened
Likely cause
Impact
Recovery performed
Recovery assessment
Recommended next actions
```

The analyzer uses the incident evidence and should clearly distinguish confirmed facts from uncertain conclusions.

---

# 40. CloudWatch

CloudWatch provides additional observability.

The project uses the documented staging log group:

```text
/cloudforge/staging
```

Verify log groups with:

```powershell
aws logs describe-log-groups `
  --log-group-name-prefix /cloudforge
```

CloudWatch complements the application-level health checks and incident evidence.

---

# 41. Deployment Troubleshooting

## Jenkins Build Fails

Check:

```text
Jenkins console output
Git checkout
Application tests
Docker build
AWS credentials
```

---

## ECR Push Fails

Check:

```text
AWS region
ECR repository
IAM permissions
ECR authentication
Docker image tag
```

---

## SSM Deployment Fails

Check:

```text
EC2 instance state
SSM agent
IAM instance profile
Network connectivity
SSM command output
```

---

## Container Does Not Start

Run:

```bash
docker ps -a
```

Then:

```bash
docker logs --tail 100 cloudforge-api
```

---

## Container Starts but Is Unhealthy

Run:

```bash
curl http://127.0.0.1:8000/health
```

Then:

```bash
docker logs --tail 100 cloudforge-api
```

---

## Dashboard Shows Old State

Check:

```bash
cat /opt/cloudforge/runtime/status.json
```

Then:

```bash
docker inspect cloudforge-api \
  --format '{{.Config.Image}}'
```

The status publisher may need a short interval to publish the updated state.

---

# 42. Deployment Verification Checklist

After every staging deployment:

```text
[ ] Jenkins build succeeded
[ ] Automated tests passed
[ ] Docker image built
[ ] Image pushed to ECR
[ ] Correct image tag exists
[ ] SSM deployment succeeded
[ ] cloudforge-api container is running
[ ] Container is healthy
[ ] /health returns healthy
[ ] Runtime status updated
[ ] Dashboard shows current state
```

---

# 43. Complete Deployment Verification

Run:

```bash
docker ps --filter name=cloudforge-api
```

Then:

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

Then:

```bash
docker inspect cloudforge-api \
  --format '{{.Config.Image}}'
```

Then:

```bash
curl http://127.0.0.1:8000/health
```

Then:

```bash
cat /opt/cloudforge/runtime/status.json
```

Finally:

```bash
curl -s http://127.0.0.1:8080/api/dashboard
```

Together these verify:

```text
Container
Health
Image
Application
Runtime state
Dashboard
```

---

# 44. Deployment Lifecycle

The complete CloudForge deployment lifecycle is:

```text
Developer Commit
       |
       v
GitHub
       |
       v
Jenkins
       |
       +--> Checkout
       |
       +--> Test
       |
       +--> Docker Build
       |
       +--> ECR Push
       |
       v
AWS Systems Manager
       |
       v
Staging EC2
       |
       v
CloudForge API
       |
       v
Health Verification
       |
       v
Monitoring
       |
       v
Operational Runtime
```

---

# 45. Relationship With the Dashboard

The dashboard does not replace deployment verification.

Instead:

```text
Jenkins
    → verifies the CI/CD workflow

Health Endpoint
    → verifies the application

Runtime Publisher
    → publishes current state

Dashboard
    → visualizes current state
```

This gives CloudForge multiple levels of verification.

---

# 46. Reproducibility

The deployment process is designed to be reproducible.

Important source-controlled components include:

```text
Jenkinsfile
app/
dashboard/
analyzer/
scripts/
tests/
terraform/
docs/
```

The deployment host should not be treated as the source of truth for application code.

The intended source of truth is:

```text
GitHub
```

---

# 47. Current Verified Deployment Example

A verified API image used by the staging environment is:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:195bc75
```

The staging API container is:

```text
cloudforge-api
```

The application listens on:

```text
8000
```

The dashboard uses:

```text
cloudforge-dashboard:1.0.5
```

and host port:

```text
8080
```

These values describe the verified project state and may change in future deployments.

---

# 48. Cost-Conscious Deployment

CloudForge is a learning/staging project.

When deployment and verification are complete, stop the EC2 instance if it is no longer required:

```powershell
aws ec2 stop-instances --instance-ids <instance-id>
```

Verify:

```powershell
aws ec2 describe-instances `
  --instance-ids <instance-id> `
  --query "Reservations[0].Instances[0].State.Name" `
  --output text
```

Expected:

```text
stopped
```

The public IP may change when the instance is started again.

---

# 49. Implemented vs Future Deployment Features

CloudForge currently implements:

```text
GitHub source control
Jenkins CI/CD
Docker image build
Amazon ECR
AWS Systems Manager deployment
EC2 staging deployment
Health verification
Versioned container images
```

Future deployment extensions may include:

```text
Automated rollback
Application Load Balancer
Blue/green deployment
Canary deployment
Advanced deployment policies
Policy-driven remediation
```

These should only be described as implemented after they are actually added and verified.

---

# 50. Final Deployment Architecture

```text
                         +----------------+
                         |    Developer   |
                         +-------+--------+
                                 |
                                 v
                         +----------------+
                         |     GitHub     |
                         +-------+--------+
                                 |
                                 v
                         +----------------+
                         |    Jenkins     |
                         +-------+--------+
                                 |
                 +---------------+---------------+
                 |                               |
                 v                               v
              Tests                         Docker Build
                                                 |
                                                 v
                                           +-------------+
                                           |     ECR     |
                                           +------+------+
                                                  |
                                                  v
                                           +-------------+
                                           |     SSM     |
                                           +------+------+
                                                  |
                                                  v
                                      +-----------+-----------+
                                      |      Staging EC2      |
                                      |                       |
                                      |  +-----------------+  |
                                      |  | cloudforge-api  |  |
                                      |  |      :8000      |  |
                                      |  +--------+--------+  |
                                      |           |           |
                                      |           v           |
                                      |       /health         |
                                      |           |           |
                                      |           v           |
                                      |      Monitoring       |
                                      |           |           |
                                      |           v           |
                                      |     Self-Healing      |
                                      |                       |
                                      |  +-----------------+  |
                                      |  | dashboard       |  |
                                      |  |      :8080      |  |
                                      |  +-----------------+  |
                                      +-----------+-----------+
                                                  |
                                                  v
                                               Browser
```

---

# 51. Final Summary

CloudForge follows a repeatable DevOps deployment workflow:

```text
Code
  ↓
GitHub
  ↓
Jenkins
  ↓
Test
  ↓
Docker Build
  ↓
Amazon ECR
  ↓
AWS Systems Manager
  ↓
EC2
  ↓
Health Verification
  ↓
Monitoring
  ↓
Operational Runtime
```

The responsibilities are separated clearly:

```text
Jenkins
    → delivers the application

ECR
    → stores versioned images

SSM
    → executes deployment commands

EC2/Docker
    → runs the application

Health Check
    → verifies the deployment

Self-Healing
    → handles certain runtime failures

AI Analyzer
    → analyzes incident evidence

Dashboard
    → provides operational visibility
```

This deployment architecture makes CloudForge reproducible, traceable, and suitable for demonstrating AWS DevOps/SRE practices in a portfolio environment.

```
```
