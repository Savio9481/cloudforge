# CloudForge CI/CD Guide

This document explains the CloudForge CI/CD pipeline using Jenkins, GitHub, Docker, Amazon ECR, AWS Systems Manager (SSM), and the staging EC2 instance.

---

# 1. Purpose

CloudForge uses Jenkins to automate:

```text
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
AWS SSM
   ↓
Staging EC2
   ↓
Container Deployment
   ↓
Health Check
````

The goal is to avoid manually building and deploying every application change.

---

# 2. CI/CD Architecture

```text
                       GitHub
                          |
                          | Push
                          v
                    Jenkins Server
                          |
             +------------+------------+
             |                         |
             v                         v
        Application Tests        Docker Build
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
```

---

# 3. Technologies

The pipeline uses:

* GitHub
* Jenkins
* Docker
* Amazon ECR
* AWS Systems Manager
* EC2
* Terraform
* Python
* FastAPI

---

# 4. Source Repository

CloudForge source code is stored in:

```text
https://github.com/Savio9481/cloudforge.git
```

The primary branch is:

```text
main
```

---

# 5. Jenkins

Jenkins acts as the CI/CD controller.

The Jenkins server runs on the CloudForge development EC2 environment.

The Jenkins job is:

```text
CloudForge-CI-CD
```

---

# 6. Jenkins Pipeline

The pipeline is defined using:

```text
Jenkinsfile
```

The Jenkinsfile describes the automated deployment process.

The general pipeline is:

```text
Checkout
   ↓
Install/Test
   ↓
Docker Build
   ↓
Docker Push
   ↓
Deploy to Staging
   ↓
Health Check
```

---

# 7. Checkout Stage

Jenkins first obtains the latest source code from GitHub.

Conceptually:

```text
GitHub main
     ↓
Jenkins workspace
```

This ensures the pipeline builds the current version of the application.

---

# 8. Application Testing

Before deployment, the pipeline runs application tests.

The purpose is to catch application-level problems before the image is deployed to staging.

A simplified flow is:

```text
Source Code
    ↓
Tests
    |
    +---- Failure → Pipeline stops
    |
    +---- Success → Continue
```

A failed test should prevent deployment.

---

# 9. Docker Build

After successful tests, Jenkins builds the CloudForge API Docker image.

Example:

```bash
docker build -t cloudforge-api:<TAG> ./app
```

The image contains:

```text
FastAPI
Uvicorn
Application code
Application dependencies
Health check
```

---

# 10. Image Tagging

CloudForge uses Git commit-based image tags.

Example:

```text
cloudforge-api:195bc75
```

The tag:

```text
195bc75
```

represents the Git commit associated with that deployment.

This provides traceability between:

```text
Git commit
      ↓
Docker image
      ↓
Staging deployment
```

---

# 11. Amazon ECR

CloudForge stores Docker images in Amazon Elastic Container Registry (ECR).

Repository:

```text
cloudforge-api
```

Full repository address:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api
```

---

# 12. ECR Authentication

Jenkins authenticates Docker with ECR before pushing the image.

Conceptually:

```text
Jenkins
   |
   | AWS credentials
   v
ECR authentication
   |
   v
Docker push
```

The authentication token should never be hard-coded in the repository.

---

# 13. Push Image to ECR

The tagged image is pushed to ECR.

Example:

```bash
docker push \
  595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<TAG>
```

After the push:

```text
Git commit
     ↓
Docker image
     ↓
ECR
```

---

# 14. Staging Deployment

After the image reaches ECR, Jenkins deploys it to the staging EC2 instance.

The staging instance is:

```text
i-0298adbb36bf49d4c
```

The deployment uses AWS Systems Manager rather than SSH.

---

# 15. Why SSM Is Used

AWS Systems Manager allows Jenkins to execute commands on the EC2 instance without requiring an SSH server or SSH private key.

The deployment flow becomes:

```text
Jenkins
   ↓
AWS SSM
   ↓
Staging EC2
```

This reduces the need to expose SSH access.

---

# 16. SSM Deployment Flow

The deployment command executed through SSM performs the required container update.

Conceptually:

```text
SSM
 |
 +--> Authenticate Docker with ECR
 |
 +--> Pull new image
 |
 +--> Stop old container
 |
 +--> Remove old container
 |
 +--> Start new container
 |
 +--> Wait for health
 |
 +--> Verify /health
```

---

# 17. Pull New Image

The staging instance pulls the exact image generated by Jenkins.

Example:

```bash
docker pull \
  595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<TAG>
```

This ensures staging uses the same image that Jenkins pushed.

---

# 18. Replace Existing Container

The existing API container is:

```text
cloudforge-api
```

The deployment process replaces it with the newly built image.

The important principle is:

```text
Old image
   ↓
New image
   ↓
New container
```

---

# 19. Container Port

The CloudForge API listens on:

```text
8000
```

Docker maps:

```text
8000 → 8000
```

The health endpoint is:

```text
/health
```

---

# 20. Deployment Health Check

After starting the new container, Jenkins verifies:

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

The exact version depends on the application currently being deployed.

---

# 21. Why Health Verification Is Important

A successful Docker start does not necessarily mean the application is working.

For example:

```text
Docker container running
        ≠
Application healthy
```

Therefore CloudForge checks the actual application health endpoint.

---

# 22. Deployment Success

The deployment is considered successful when:

```text
Git checkout       ✓
Tests              ✓
Docker build       ✓
ECR push           ✓
SSM deployment     ✓
Container running  ✓
Health check       ✓
```

---

# 23. Deployment Failure

If an important stage fails:

```text
Git checkout       → STOP
Tests              → STOP
Docker build       → STOP
ECR push           → STOP
SSM deployment     → STOP
Health check       → FAIL
```

The Jenkins pipeline should report the failure instead of silently treating the deployment as successful.

---

# 24. CI vs CD

CloudForge separates two concepts.

## Continuous Integration

```text
GitHub
   ↓
Jenkins
   ↓
Checkout
   ↓
Test
   ↓
Docker Build
```

This verifies that the application can be built and tested.

## Continuous Deployment

```text
Docker Image
     ↓
ECR
     ↓
SSM
     ↓
Staging EC2
     ↓
Health Check
```

This deploys the verified image to the staging environment.

---

# 25. Complete Pipeline

The complete CloudForge pipeline is:

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
    +---- Checkout
    |
    +---- Tests
    |
    +---- Docker Build
    |
    +---- Tag Image
    |
    v
Amazon ECR
    |
    v
AWS SSM
    |
    v
Staging EC2
    |
    +---- docker pull
    |
    +---- replace container
    |
    +---- health check
    |
    v
Deployment Complete
```

---

# 26. Jenkins Job

The Jenkins job is:

```text
CloudForge-CI-CD
```

When a build is triggered, Jenkins executes the Jenkinsfile from the repository.

---

# 27. GitHub Webhook

CloudForge can use a GitHub webhook to trigger Jenkins when changes are pushed.

Conceptually:

```text
git push
    ↓
GitHub
    ↓
Webhook
    ↓
Jenkins
    ↓
Pipeline
```

This removes the need to manually start Jenkins for every change.

---

# 28. GitHub Webhook Security

The webhook endpoint should not be exposed without appropriate protection.

Use Jenkins/GitHub webhook security mechanisms rather than accepting arbitrary unauthenticated deployment requests.

---

# 29. Jenkins Credentials

Credentials required by Jenkins should be stored in the Jenkins credential store.

Do not put secrets inside:

```text
Jenkinsfile
GitHub repository
Dockerfile
Shell scripts
README
```

Examples of sensitive values include:

```text
AWS access credentials
GitHub tokens
Webhook secrets
Gemini API keys
```

---

# 30. AWS Permissions

The Jenkins environment needs only the permissions required by the pipeline.

Typical permissions include access required for:

```text
ECR authentication
ECR image push
SSM command execution
```

Avoid giving unnecessary administrative permissions.

---

# 31. ECR Permissions

The Jenkins identity requires appropriate ECR permissions to push images.

The general flow is:

```text
Jenkins
   ↓
ECR Login
   ↓
Push Image
```

---

# 32. SSM Permissions

Jenkins also requires permission to send commands through AWS Systems Manager.

Conceptually:

```text
Jenkins AWS identity
        |
        v
ssm:SendCommand
        |
        v
Staging EC2
```

The staging EC2 instance itself must also be configured correctly for SSM.

---

# 33. Staging EC2 SSM Requirement

The EC2 instance requires the appropriate IAM role and SSM configuration.

CloudForge provisions the required EC2 IAM configuration through Terraform.

The instance should appear as an online managed node in Systems Manager.

---

# 34. Deployment Traceability

One important CloudForge feature is deployment traceability.

Example:

```text
Git commit:
195bc75

        ↓

Docker image:
cloudforge-api:195bc75

        ↓

ECR:
cloudforge-api:195bc75

        ↓

Staging:
cloudforge-api container
```

This makes it easier to identify which source revision is running.

---

# 35. Checking the Running Image

On staging:

```bash
docker inspect cloudforge-api \
  --format '{{.Config.Image}}'
```

Example:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:195bc75
```

This identifies the image currently configured for the container.

---

# 36. Checking Container Health

Run:

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

Expected:

```text
healthy
```

---

# 37. Checking Application Health

Run:

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

# 38. Checking Jenkins Build Logs

If a deployment fails, inspect the Jenkins console output.

Look for the stage that failed:

```text
Checkout
Test
Docker Build
ECR Push
SSM Deploy
Health Check
```

The failing stage determines the troubleshooting path.

---

# 39. Troubleshooting — Docker Build Failure

Check:

```text
Dockerfile
requirements.txt
Application dependencies
Python syntax
Docker build logs
```

Run locally:

```bash
docker build -t cloudforge-api:test ./app
```

---

# 40. Troubleshooting — ECR Push Failure

Check:

```text
AWS credentials
AWS region
ECR repository
ECR permissions
Docker ECR login
```

Verify the repository:

```bash
aws ecr describe-repositories \
  --repository-names cloudforge-api \
  --region us-east-1
```

---

# 41. Troubleshooting — SSM Deployment Failure

Check that the staging instance is:

```text
Running
```

and:

```text
Online in Systems Manager
```

Then verify the EC2 IAM role and SSM agent.

---

# 42. Troubleshooting — Health Check Failure

Check the container:

```bash
docker ps -a --filter name=cloudforge-api
```

Check logs:

```bash
docker logs --tail 100 cloudforge-api
```

Check the health endpoint:

```bash
curl http://127.0.0.1:8000/health
```

---

# 43. Jenkins and Self-Healing

Jenkins and CloudForge self-healing have different responsibilities.

Jenkins handles:

```text
Build
Test
Deploy
Verify
```

CloudForge monitoring handles:

```text
Monitor
Detect failure
Collect evidence
Restart container
Create incident
Run AI analysis
```

Therefore:

```text
Jenkins
   |
   | Deployment
   v
CloudForge
   |
   | Runtime monitoring
   v
Self-Healing
```

---

# 44. Jenkins and Dashboard

The dashboard provides visibility after deployment.

The relationship is:

```text
Jenkins
   ↓
Deploy new image
   ↓
Staging EC2
   ↓
Runtime status publisher
   ↓
Dashboard
```

The dashboard can therefore show the state of the deployed container.

---

# 45. CI/CD + Self-Healing Lifecycle

The complete operational lifecycle is:

```text
Developer pushes code
        ↓
GitHub
        ↓
Jenkins
        ↓
Tests
        ↓
Docker build
        ↓
ECR
        ↓
SSM deployment
        ↓
Staging EC2
        ↓
Health verification
        ↓
Monitoring
        ↓
Failure?
   ┌────┴────┐
   │         │
  No        Yes
   │         │
   │         v
   │    Self-Healing
   │         |
   │         v
   │    Incident JSON
   │         |
   │         v
   │    Gemini Analyzer
   │         |
   └────┬────┘
        ↓
    Dashboard
```

---

# 46. Recommended Deployment Workflow

For normal development:

```text
1. Modify application
2. Test locally
3. Commit changes
4. Push to GitHub
5. Jenkins starts
6. Jenkins runs tests
7. Jenkins builds Docker image
8. Jenkins pushes image to ECR
9. Jenkins deploys through SSM
10. Jenkins verifies /health
11. Dashboard shows runtime state
12. Monitor continues watching application
```

---

# 47. Manual Deployment Alternative

If Jenkins is unavailable, the deployment can still be performed manually.

The general process is:

```text
Build Docker image
      ↓
Tag image
      ↓
Login to ECR
      ↓
Push image
      ↓
SSM into staging
      ↓
Pull image
      ↓
Replace container
      ↓
Verify health
```

This is useful for troubleshooting the CI/CD system itself.

---

# 48. CI/CD Verification Checklist

Before considering CI/CD complete:

```text
[ ] GitHub repository accessible
[ ] Jenkins job configured
[ ] Jenkinsfile present
[ ] Jenkins can checkout repository
[ ] Tests execute
[ ] Docker image builds
[ ] Image receives Git commit tag
[ ] ECR repository exists
[ ] Jenkins can push to ECR
[ ] Staging EC2 is SSM managed
[ ] Jenkins can send SSM command
[ ] Staging pulls image
[ ] API container starts
[ ] Health check passes
[ ] Dashboard shows deployed state
```

---

# 49. Security Checklist

```text
[ ] No secrets committed to Git
[ ] Jenkins credentials stored securely
[ ] AWS permissions limited
[ ] ECR permissions limited
[ ] SSM permissions limited
[ ] GitHub webhook protected
[ ] No SSH private key stored in repository
[ ] Gemini API key stored outside source code
[ ] Dashboard does not have Docker socket access
```

---

# 50. Final Architecture

CloudForge's CI/CD architecture can be summarized as:

```text
                   GitHub
                      |
                      v
                  Jenkins
                      |
          +-----------+-----------+
          |                       |
          v                       v
        Tests                Docker Build
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
                    +-------------+-------------+
                    |                           |
                    v                           v
             CloudForge API              Dashboard
                    |
                    v
                Monitoring
                    |
                    v
               Self-Healing
                    |
                    v
             Incident Records
                    |
                    v
             Gemini Analyzer
```

---

# 51. Summary

CloudForge CI/CD automates the path from source code to a verified staging deployment.

The core pipeline is:

```text
GitHub
  ↓
Jenkins
  ↓
Test
  ↓
Docker
  ↓
ECR
  ↓
SSM
  ↓
EC2
  ↓
Health Check
```

After deployment, CloudForge continues operating independently through:

```text
Monitoring
   ↓
Self-Healing
   ↓
Incident Evidence
   ↓
AI Analysis
   ↓
Dashboard
```

This demonstrates an end-to-end DevOps workflow rather than only a Docker deployment.

