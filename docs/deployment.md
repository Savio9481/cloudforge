# CloudForge Deployment Guide

This document explains how to deploy CloudForge after the AWS infrastructure has been created with Terraform.

The deployment flow is:

```text
Terraform Infrastructure
        ↓
EC2 Instance
        ↓
AWS Systems Manager
        ↓
CloudForge Repository
        ↓
Docker Image
        ↓
CloudForge API
        ↓
Health Check
        ↓
Monitoring & Self-Healing
````

---

# 1. Deployment Prerequisites

Before deploying CloudForge, verify that the AWS infrastructure exists.

From the staging Terraform directory:

```powershell
cd terraform\environments\staging
```

Run:

```powershell
terraform validate
```

Then:

```powershell
terraform plan
```

If the infrastructure already matches Terraform, the expected result is:

```text
No changes. Your infrastructure matches the configuration.
```

---

# 2. Start the EC2 Instance

If the staging instance is stopped, start it from the local machine.

```powershell
aws ec2 start-instances --instance-ids <instance-id>
```

Example:

```powershell
aws ec2 start-instances --instance-ids i-xxxxxxxxxxxxxxxxx
```

Check the instance state:

```powershell
aws ec2 describe-instances `
  --instance-ids <instance-id> `
  --query "Reservations[0].Instances[0].State.Name" `
  --output text
```

Wait until the result is:

```text
running
```

---

# 3. Verify Systems Manager

CloudForge uses AWS Systems Manager Session Manager to access the EC2 instance.

Start a session:

```powershell
aws ssm start-session --target <instance-id>
```

Example:

```powershell
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx
```

If the session opens successfully, the EC2 instance is reachable through SSM.

---

# 4. Switch to the CloudForge User

Inside the SSM session:

```bash
sudo su - ssm-user
```

Verify:

```bash
whoami
```

Expected:

```text
ssm-user
```

---

# 5. Navigate to the Project

Move to the CloudForge directory:

```bash
cd /opt/cloudforge
```

Verify the project:

```bash
ls -la
```

Expected directories include:

```text
app/
analyzer/
docs/
scripts/
terraform/
```

---

# 6. Update the Source Code

If CloudForge is already cloned on the EC2 instance:

```bash
cd /opt/cloudforge
git pull origin main
```

Verify the current commit:

```bash
git log -1 --oneline
```

The commit should correspond to the latest version that is intended to be deployed.

---

# 7. Build the Docker Image

Move into the API application:

```bash
cd /opt/cloudforge/app
```

Build the image:

```bash
docker build -t cloudforge-api:1.0.0 .
```

Verify:

```bash
docker images | grep cloudforge-api
```

---

# 8. Stop an Existing API Container

If an old CloudForge API container is already running:

```bash
docker stop cloudforge-api
```

Remove it:

```bash
docker rm cloudforge-api
```

If the container does not exist, Docker may report an error. That is safe to ignore when performing a fresh deployment.

---

# 9. Start the CloudForge API

Run:

```bash
docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  cloudforge-api:1.0.0
```

Verify:

```bash
docker ps
```

Expected:

```text
cloudforge-api
```

with:

```text
0.0.0.0:8000->8000/tcp
```

---

# 10. Verify Container Health

Check the container:

```bash
docker ps
```

The health status should eventually become:

```text
healthy
```

You can check directly:

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

Expected:

```text
healthy
```

---

# 11. Verify the Application

Run the API health endpoint:

```bash
curl http://127.0.0.1:8000/health
```

Expected response:

```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

This confirms that:

```text
Docker
   ↓
Uvicorn
   ↓
FastAPI
   ↓
/health
```

is working.

---

# 12. Verify Container Logs

Check the latest logs:

```bash
docker logs --tail 50 cloudforge-api
```

For live logs:

```bash
docker logs -f cloudforge-api
```

Press:

```text
Ctrl + C
```

to stop following the logs.

---

# 13. Verify Docker Restart Policy

CloudForge uses:

```text
unless-stopped
```

Check:

```bash
docker inspect cloudforge-api \
  --format '{{.HostConfig.RestartPolicy.Name}}'
```

Expected:

```text
unless-stopped
```

This allows Docker to restart the application after Docker/host-level restarts in normal circumstances.

---

# 14. Verify CloudForge Monitoring

CloudForge's health-check script is:

```text
/opt/cloudforge/scripts/health-check.sh
```

Run it manually:

```bash
/opt/cloudforge/scripts/health-check.sh
```

Expected:

```text
CloudForge health check: HEALTHY
```

The API health response should also be displayed.

---

# 15. Verify the Monitoring Service

Check:

```bash
sudo systemctl status cloudforge-monitor.service
```

The service should be:

```text
active (running)
```

The monitoring loop periodically executes the health check.

Its basic flow is:

```text
Health Check
     ↓
Healthy?
  /       \
Yes        No
 |          |
Continue   Self-Healing
              ↓
        Restart Container
              ↓
        Check Health Again
```

---

# 16. Verify Runtime Status Publisher

Check:

```bash
sudo systemctl status cloudforge-status-publisher.service
```

Expected:

```text
active (running)
```

The service continuously publishes container state to:

```text
/opt/cloudforge/runtime/status.json
```

Check the file:

```bash
cat /opt/cloudforge/runtime/status.json
```

Important fields include:

```text
status
running
health
exit_code
oom_killed
restart_count
image
started_at
```

---

# 17. Deploying Through ECR

CloudForge also supports deployment using Amazon ECR.

The ECR repository is:

```text
cloudforge-api
```

The repository URI follows:

```text
<account-id>.dkr.ecr.<region>.amazonaws.com/cloudforge-api
```

Example:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api
```

---

# 18. Authenticate Docker With ECR

From a machine that has AWS CLI permissions:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login \
--username AWS \
--password-stdin \
<account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Example:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login \
--username AWS \
--password-stdin \
595319278112.dkr.ecr.us-east-1.amazonaws.com
```

Expected:

```text
Login Succeeded
```

---

# 19. Tag the Docker Image

Tag the local image:

```bash
docker tag cloudforge-api:1.0.0 \
<account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

Example:

```bash
docker tag cloudforge-api:1.0.0 \
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:latest
```

For CI/CD deployments, CloudForge uses commit-based image tags.

Example:

```text
195bc75
```

This makes it possible to identify which Git commit produced a container image.

---

# 20. Push the Image to ECR

Run:

```bash
docker push \
<account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

Example:

```bash
docker push \
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:latest
```

Verify the repository:

```bash
aws ecr describe-images \
  --repository-name cloudforge-api \
  --region us-east-1
```

---

# 21. Deploy an ECR Image

On the staging EC2 instance, authenticate with ECR:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login \
--username AWS \
--password-stdin \
<account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Pull the required image:

```bash
docker pull \
<account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

Example:

```bash
docker pull \
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:195bc75
```

---

# 22. Stop the Previous Container

Before deploying the new image:

```bash
docker stop cloudforge-api
```

Then:

```bash
docker rm cloudforge-api
```

---

# 23. Start the New Image

Run:

```bash
docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

Example:

```bash
docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:195bc75
```

---

# 24. Verify the Deployment

Check:

```bash
docker ps
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

Check the image:

```bash
docker inspect cloudforge-api \
  --format '{{.Config.Image}}'
```

This confirms which image is currently deployed.

---

# 25. Deployment Verification Sequence

Every deployment should finish with these checks:

```bash
docker ps
```

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

```bash
curl http://127.0.0.1:8000/health
```

```bash
docker logs --tail 50 cloudforge-api
```

Expected state:

```text
Container: RUNNING
Health:    HEALTHY
API:       HTTP 200
Logs:      No deployment errors
```

---

# 26. Dashboard Deployment

CloudForge uses a separate dashboard container.

Container name:

```text
cloudforge-dashboard
```

The dashboard is exposed on:

```text
8080
```

The dashboard application listens internally on:

```text
8000
```

Therefore the Docker mapping is:

```text
8080 → 8000
```

---

# 27. Build the Dashboard

The dashboard is part of the CloudForge application.

Build the dashboard image:

```bash
docker build -t cloudforge-dashboard:1.0.4 .
```

Use the appropriate build directory and version tag for the current dashboard source.

---

# 28. Start the Dashboard

The dashboard container requires read-only access to runtime and incident information.

Example:

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.4
```

---

# 29. Verify the Dashboard

Check:

```bash
docker ps --filter name=cloudforge-dashboard
```

Verify locally:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

Expected:

```text
HTTP/1.1 200 OK
```

From a browser:

```text
http://<EC2-PUBLIC-IP>:8080/dashboard/
```

---

# 30. Deployment Architecture

The deployed CloudForge staging environment looks like:

```text
                         AWS
                          |
                     VPC / Subnet
                          |
                     EC2 Instance
                          |
             +------------+------------+
             |                         |
       cloudforge-api          cloudforge-dashboard
          :8000                      :8080
             |                         |
             |                         |
        Health Check              Dashboard API
             |
       Monitor Service
             |
       Self-Healing
             |
       Incident JSON
             |
       Gemini Analyzer
```

---

# 31. CI/CD Deployment

The preferred automated deployment flow is:

```text
Developer
    |
    | git push
    v
GitHub
    |
    v
Jenkins
    |
    +--> Build
    |
    +--> Test
    |
    +--> Docker Build
    |
    +--> Push to ECR
    |
    +--> Deploy through SSM
    |
    +--> Health Check
    |
    v
Staging EC2
```

The Jenkins pipeline is responsible for automating the deployment process.

Detailed Jenkins instructions are documented in:

```text
docs/ci-cd.md
```

---

# 32. Deployment Failure Handling

If a deployment fails, do not immediately destroy the infrastructure.

First inspect:

### Container

```bash
docker ps -a
```

### Logs

```bash
docker logs --tail 100 cloudforge-api
```

### Health

```bash
curl http://127.0.0.1:8000/health
```

### Docker health

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

### Image

```bash
docker inspect cloudforge-api \
  --format '{{.Config.Image}}'
```

---

# 33. Common Deployment Problems

## Container does not start

Check:

```bash
docker ps -a
```

Then:

```bash
docker logs cloudforge-api
```

---

## Port 8000 is already in use

Check:

```bash
sudo ss -lntp | grep :8000
```

Also check:

```bash
docker ps
```

If an old CloudForge container is using the port:

```bash
docker stop cloudforge-api
docker rm cloudforge-api
```

Then deploy again.

---

## Health check fails

Run:

```bash
curl -v http://127.0.0.1:8000/health
```

Then inspect:

```bash
docker logs --tail 100 cloudforge-api
```

---

## ECR pull fails

Verify AWS identity:

```bash
aws sts get-caller-identity
```

Verify the ECR repository:

```bash
aws ecr describe-repositories \
  --repository-names cloudforge-api \
  --region us-east-1
```

Then authenticate again:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login \
--username AWS \
--password-stdin \
<account-id>.dkr.ecr.us-east-1.amazonaws.com
```

---

# 34. Post-Deployment Checklist

After every deployment:

```text
[ ] Git commit identified
[ ] Docker image built
[ ] Image pushed to ECR if using ECR
[ ] Correct image pulled
[ ] Old container stopped
[ ] New container started
[ ] Container is running
[ ] Container is healthy
[ ] /health returns HTTP 200
[ ] Docker logs checked
[ ] Monitoring service running
[ ] Runtime status updated
[ ] Dashboard accessible
```

---

# 35. Final Deployment State

A successful CloudForge deployment should result in:

```text
GitHub
   |
   v
Docker Image
   |
   v
ECR
   |
   v
Staging EC2
   |
   +-----------------------+
   |                       |
   v                       v
CloudForge API       CloudForge Dashboard
   |                       |
   v                       v
Health Check          Live Status
   |
   v
Monitor
   |
   v
Self-Healing
   |
   v
Incident Evidence
   |
   v
AI Analyzer
```

The deployment is considered successful only after the application health check confirms that the new container is healthy.

```
```
