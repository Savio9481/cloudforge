# CloudForge Setup Guide

This guide explains how to prepare the CloudForge development and AWS environments from the repository.

CloudForge is designed as a learning and portfolio project, so the setup is intentionally reproducible and cost-conscious.

The main environment used during development is:

```text
AWS Region: us-east-1
```

---

# 1. Setup Overview

The CloudForge setup process is:

```text
Local Machine
    |
    +--> Git
    +--> AWS CLI
    +--> Terraform
    |
    v
CloudForge Repository
    |
    v
Terraform
    |
    v
AWS Infrastructure
    |
    v
EC2
    |
    +--> Docker
    +--> CloudForge API
    +--> Monitoring
    +--> Self-Healing
    +--> Incident Evidence
    +--> AI Analyzer
    +--> Dashboard
```

Jenkins and ECR are used as part of the CI/CD deployment workflow.

---

# 2. Prerequisites

The following tools are required on the local development machine:

```text
Git
AWS CLI
Terraform
```

For development and testing, the following are also useful:

```text
PowerShell
VS Code
Docker
```

The AWS resources themselves run on Amazon EC2.

---

# 3. AWS Account

CloudForge requires an AWS account with permission to create the resources defined by the Terraform configuration.

The project was developed in:

```text
us-east-1
```

Before creating resources, confirm that the AWS account is active and that billing/payment setup is complete.

Because CloudForge uses paid AWS resources, resources should be stopped or destroyed when they are no longer needed.

---

# 4. Configure AWS CLI

Verify that AWS CLI is installed:

```powershell
aws --version
```

Configure credentials if this is a new machine:

```powershell
aws configure
```

Provide:

```text
AWS Access Key ID
AWS Secret Access Key
Default region name: us-east-1
Default output format: json
```

Do not commit AWS credentials to GitHub.

---

# 5. Verify AWS Identity

After configuring AWS CLI:

```powershell
aws sts get-caller-identity
```

The command should return the AWS account and identity associated with the configured credentials.

This confirms that the local AWS CLI can authenticate successfully.

---

# 6. Verify AWS Region

Run:

```powershell
aws configure get region
```

Expected:

```text
us-east-1
```

CloudForge Terraform configuration is designed around this region in the documented environment.

---

# 7. Clone the Repository

Clone the CloudForge repository:

```powershell
git clone https://github.com/Savio9481/cloudforge.git
```

Enter the repository:

```powershell
cd cloudforge
```

Verify the repository:

```powershell
git status
```

The repository should contain directories such as:

```text
app/
dashboard/
analyzer/
scripts/
tests/
docs/
terraform/
```

---

# 8. Recommended Repository Structure

The important project directories are:

```text
cloudforge/
├── app/
├── dashboard/
├── analyzer/
├── scripts/
├── tests/
├── docs/
└── terraform/
```

Their responsibilities are:

```text
app/
    CloudForge API

dashboard/
    Operational dashboard

analyzer/
    AI incident analyzer

scripts/
    Monitoring and self-healing

tests/
    Application/load/verification tests

docs/
    Project documentation

terraform/
    AWS infrastructure
```

---

# 9. Terraform Version

Verify Terraform:

```powershell
terraform version
```

The project was validated with:

```text
Terraform v1.16.1
```

The AWS provider used by the project was:

```text
hashicorp/aws v6.62.0
```

Exact versions may change as the project evolves, so the Terraform lock file should be retained when present.

---

# 10. Terraform Directory

Move into the staging environment:

```powershell
cd terraform\environments\staging
```

The Terraform environment structure is:

```text
terraform/
├── modules/
│   ├── network/
│   └── compute/
└── environments/
    ├── dev/
    └── staging/
```

The modules contain reusable infrastructure logic.

The environment directories contain environment-specific configuration.

---

# 11. Initialize Terraform

Run:

```powershell
terraform init
```

This downloads the required providers and initializes the Terraform working directory.

A successful initialization allows the next validation steps to run.

---

# 12. Validate Terraform

Run:

```powershell
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

This verifies the Terraform configuration syntax and internal structure.

---

# 13. Review Terraform Plan

Before creating or changing AWS resources:

```powershell
terraform plan
```

Review the planned changes carefully.

The plan should show the infrastructure Terraform intends to manage.

Do not run `terraform apply` blindly.

---

# 14. Apply Infrastructure

When the plan has been reviewed:

```powershell
terraform apply
```

Terraform will ask for confirmation.

Enter:

```text
yes
```

Terraform creates or updates the resources defined by the staging environment.

---

# 15. Main AWS Infrastructure

The CloudForge staging environment includes infrastructure such as:

```text
VPC
Internet Gateway
Public Subnet
Route Table
Security Group
EC2
IAM Role
IAM Instance Profile
```

The exact resource IDs are environment-specific and should not be hard-coded into documentation.

Use Terraform outputs or AWS CLI queries to discover current values.

---

# 16. EC2 Instance

The staging environment runs CloudForge on an EC2 instance.

The compute module receives values such as:

```text
Environment
AMI
Instance type
Subnet
Security group
IAM instance profile
Root volume size
Public IP association
```

The project uses an Ubuntu EC2 host.

---

# 17. AWS Systems Manager

CloudForge uses AWS Systems Manager for remote management.

The EC2 instance must have the required IAM instance profile.

The relevant managed permission used by the instance is:

```text
AmazonSSMManagedInstanceCore
```

The instance also needs network connectivity to communicate with Systems Manager endpoints.

---

# 18. Verify the EC2 Instance

From PowerShell:

```powershell
aws ec2 describe-instances `
  --filters "Name=tag:Project,Values=CloudForge" `
  --query "Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]" `
  --output table
```

If the project contains multiple environments, use the appropriate environment filter or instance ID.

---

# 19. Start the Staging Instance

When the staging instance is intentionally stopped to save cost:

```powershell
aws ec2 start-instances --instance-ids <instance-id>
```

Check the state:

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

# 20. Connect Through SSM

Start an SSM session:

```powershell
aws ssm start-session --target <instance-id>
```

The CloudForge staging instance was accessed using SSM rather than requiring a normal SSH workflow.

---

# 21. Switch to the CloudForge User

The operational CloudForge files are under:

```text
/opt/cloudforge
```

When using an SSM shell, switch to the intended operational user if required:

```bash
sudo su - ssm-user
```

Then:

```bash
cd /opt/cloudforge
```

---

# 22. Verify the Repository on EC2

Check:

```bash
cd /opt/cloudforge
git status
```

The EC2 checkout should match the intended GitHub branch.

Update it when required:

```bash
git pull --ff-only
```

Avoid making undocumented local source changes on the deployment host.

---

# 23. Docker Setup

Verify Docker:

```bash
docker --version
```

CloudForge was tested with Docker 29.x.

Verify that Docker is available:

```bash
docker ps
```

If Docker is not installed on a newly created EC2 instance, install it according to the project's deployment/setup process before continuing.

---

# 24. Build the CloudForge API

The API source is located under:

```text
app/
```

Build the image:

```bash
cd /opt/cloudforge
docker build -t cloudforge-api:1.0.0 ./app
```

Verify:

```bash
docker images | grep cloudforge-api
```

---

# 25. Run the CloudForge API

For a direct local staging test:

```bash
docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  cloudforge-api:1.0.0
```

Check:

```bash
docker ps --filter name=cloudforge-api
```

The container should eventually show:

```text
healthy
```

---

# 26. Verify the API

From the EC2 instance:

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

This is the primary health signal used by CloudForge monitoring and recovery.

---

# 27. Runtime Directory

CloudForge uses a runtime directory for current operational state:

```text
/opt/cloudforge/runtime
```

Create it when preparing a fresh environment:

```bash
mkdir -p /opt/cloudforge/runtime
```

The status publisher writes runtime state into:

```text
/opt/cloudforge/runtime/status.json
```

The runtime directory is local operational state and is not intended to be committed to Git.

---

# 28. Incident Directory

CloudForge stores incident evidence under:

```text
/opt/cloudforge/incidents
```

Create it:

```bash
mkdir -p /opt/cloudforge/incidents
```

Incident records are generated at runtime.

Typical files include:

```text
incident-<timestamp>.json
incident-<timestamp>-ai.txt
```

These files are operational evidence and should not be treated as source code.

---

# 29. Monitoring Scripts

The monitoring scripts are stored under:

```text
/opt/cloudforge/scripts
```

Important scripts include:

```text
health-check.sh
monitor.sh
self-heal.sh
status-publisher.sh
```

Their responsibilities are:

```text
health-check.sh
    Check application health

monitor.sh
    Repeatedly run health checks

self-heal.sh
    Collect evidence and recover the API container

status-publisher.sh
    Publish current runtime state
```

---

# 30. Health Check

The health check uses:

```text
http://127.0.0.1:8000/health
```

Run it manually:

```bash
/opt/cloudforge/scripts/health-check.sh
```

Healthy output should indicate:

```text
CloudForge health check: HEALTHY
```

---

# 31. Monitoring Service

The monitor continuously checks the application.

The monitoring loop is responsible for:

```text
Run health check
     |
     +--> Healthy
     |
     +--> Failed
              |
              v
        Start self-healing
```

The monitor is separate from the dashboard.

---

# 32. Runtime Status Publisher Service

The status publisher runs as:

```text
cloudforge-status-publisher.service
```

Check its status:

```bash
sudo systemctl status cloudforge-status-publisher.service
```

It should be:

```text
active (running)
```

The service is configured to restart automatically when required.

---

# 33. Verify Runtime Status

Check:

```bash
cat /opt/cloudforge/runtime/status.json
```

The status should contain information such as:

```text
container name
status
running state
health
exit code
OOM state
restart count
image
start time
updated time
```

---

# 34. Self-Healing Setup

The self-healing script is:

```text
/opt/cloudforge/scripts/self-heal.sh
```

It performs the following high-level operations:

```text
Health failure
     |
     v
Collect Docker evidence
     |
     v
Collect host evidence
     |
     v
Start/restart container
     |
     v
Wait for health
     |
     v
Create incident JSON
     |
     v
Run AI analyzer
```

---

# 35. Self-Healing Boundary

The current recovery mechanism is primarily designed for application-container failures.

It can recover cases such as:

```text
docker stop cloudforge-api
docker kill cloudforge-api
```

It does not automatically repair all external failures.

For example, a firewall rule blocking port 8000 can continue to prevent health verification even after a container restart.

This limitation is intentionally documented as part of the project.

---

# 36. Python Virtual Environment

The AI analyzer uses a separate Python virtual environment:

```text
/opt/cloudforge/.venv
```

Create it on a fresh environment:

```bash
cd /opt/cloudforge
python3 -m venv .venv
```

Activate it in the EC2 shell:

```bash
. /opt/cloudforge/.venv/bin/activate
```

The leading dot is intentional because the SSM shell may start as `/bin/sh`.

---

# 37. Python Dependencies

Install the analyzer dependencies:

```bash
cd /opt/cloudforge
. /opt/cloudforge/.venv/bin/activate
python -m pip install --upgrade pip
pip install -r analyzer/requirements.txt
```

The analyzer requirements include:

```text
google-genai
```

The Gemini SDK belongs to the analyzer environment and is not required by the main application container or dashboard container.

---

# 38. Verify Gemini SDK

Run:

```bash
/opt/cloudforge/.venv/bin/python -c "from google import genai; print('Analyzer dependencies OK')"
```

Expected:

```text
Analyzer dependencies OK
```

---

# 39. Gemini API Configuration

The analyzer requires a Gemini API key.

The key must be provided through an environment variable.

Do not place the key inside:

```text
ai_analyzer.py
```

Do not commit the key to GitHub.

The production-style local configuration used by CloudForge stores the environment configuration outside the Git repository.

For example, the system environment file is:

```text
/etc/cloudforge/cloudforge.env
```

The exact secret value must never be documented or committed.

---

# 40. AI Analyzer Verification

The analyzer entry point is:

```text
/opt/cloudforge/analyzer/run_analyzer.sh
```

It locates the latest incident JSON and sends it to the analyzer.

Run:

```bash
/opt/cloudforge/analyzer/run_analyzer.sh
```

If an incident exists, the analyzer should generate an AI report under:

```text
/opt/cloudforge/incidents/
```

---

# 41. Dashboard Setup

The dashboard source is:

```text
dashboard/
```

The structure is:

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

---

# 42. Build the Dashboard

From the repository root:

```bash
cd /opt/cloudforge
docker build -t cloudforge-dashboard:1.0.5 ./dashboard
```

Verify:

```bash
docker images | grep cloudforge-dashboard
```

---

# 43. Start the Dashboard

Run:

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.5
```

The dashboard reads operational information through read-only mounts.

---

# 44. Verify Dashboard

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

Check the dashboard API:

```bash
curl -s http://127.0.0.1:8080/api/dashboard
```

The response should include:

```text
application
container
system
latest_incident
latest_ai_analysis
timestamp
```

---

# 45. Open the Dashboard

Find the current public IP:

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

Do not permanently document a public IP because it can change after the instance is stopped and started.

---

# 46. Jenkins Setup

Jenkins is used for the CloudForge CI/CD pipeline.

The Jenkins controller runs in the development environment.

The main job is:

```text
CloudForge-CI-CD
```

The pipeline is defined by:

```text
Jenkinsfile
```

---

# 47. Jenkins Responsibilities

The CloudForge Jenkins pipeline performs the deployment workflow:

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
ECR Login
   |
   v
Push Image
   |
   v
SSM Deployment
   |
   v
Health Verification
```

This keeps deployment steps repeatable.

---

# 48. Amazon ECR Setup

The API image repository is:

```text
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api
```

The CI/CD pipeline authenticates to ECR and pushes versioned images.

An example image tag used by the project is:

```text
195bc75
```

---

# 49. ECR Login Test

From an appropriately configured AWS environment:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin \
595319278112.dkr.ecr.us-east-1.amazonaws.com
```

A successful login should report:

```text
Login Succeeded
```

Do not expose the generated password.

---

# 50. Build and Tag an ECR Image

Example:

```bash
docker build -t cloudforge-api:local ./app
```

Tag it:

```bash
docker tag cloudforge-api:local \
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

Push:

```bash
docker push \
595319278112.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:<tag>
```

In normal operation, Jenkins performs this process.

---

# 51. SSM Deployment

The Jenkins deployment stage uses AWS Systems Manager to execute deployment commands on the staging EC2 instance.

The high-level process is:

```text
Jenkins
   |
   v
AWS SSM
   |
   v
Staging EC2
   |
   v
Pull ECR image
   |
   v
Replace API container
   |
   v
Health check
```

The exact commands are maintained in the project's `Jenkinsfile`.

---

# 52. CloudWatch Setup

CloudWatch is used for staging logging/observability.

The project uses:

```text
/cloudforge/staging
```

as the documented staging log group.

Verify available log groups if required:

```powershell
aws logs describe-log-groups `
  --log-group-name-prefix /cloudforge
```

---

# 53. Fresh Environment Verification

After setup, verify the following from the EC2 host:

### Docker

```bash
docker --version
docker ps
```

### API

```bash
curl http://127.0.0.1:8000/health
```

### Runtime status

```bash
cat /opt/cloudforge/runtime/status.json
```

### Dashboard

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

### Dashboard API

```bash
curl -s http://127.0.0.1:8080/api/dashboard
```

### Incidents

```bash
ls -la /opt/cloudforge/incidents/
```

### Status publisher

```bash
sudo systemctl status cloudforge-status-publisher.service
```

---

# 54. Terraform Verification

After infrastructure setup, run:

```powershell
cd terraform\environments\staging
terraform plan
```

A clean environment should eventually report:

```text
No changes. Your infrastructure matches the configuration.
```

This verifies that the actual infrastructure is consistent with the Terraform configuration.

---

# 55. Git Verification

From the repository root:

```powershell
git status
```

Generated runtime files should not appear as repository changes when the `.gitignore` configuration is correct.

CloudForge intentionally keeps local/generated items such as:

```text
.venv/
runtime/
incidents/
*.pyc
__pycache__/
```

out of source control as appropriate.

---

# 56. What Should Be Committed

Source code and configuration that belong to the project should be committed.

Examples:

```text
app/
dashboard/
analyzer/
scripts/
tests/
docs/
terraform/
Jenkinsfile
.gitignore
README.md
```

Do not commit:

```text
AWS credentials
Gemini API keys
.venv/
runtime status files
temporary incident output
Python cache files
temporary test artifacts
```

---

# 57. Fresh Clone Reproducibility

A clean CloudForge checkout should be sufficient to reproduce the source structure.

The expected process is:

```text
git clone
    |
    v
Terraform init
    |
    v
Terraform validate
    |
    v
Terraform plan
    |
    v
Infrastructure
    |
    v
EC2 setup
    |
    v
Docker build
    |
    v
Application
    |
    v
Dashboard
    |
    v
Monitoring
    |
    v
Self-Healing
    |
    v
AI Analyzer
```

Runtime-generated state is created after deployment rather than being required in Git.

---

# 58. Cost-Conscious Development

CloudForge is a learning project and AWS resources should not remain running unnecessarily.

When the environment is not needed, stop the EC2 instance:

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

---

# 59. Stop vs Destroy

Stopping an EC2 instance:

```text
EC2 compute stops
```

but the infrastructure still exists.

Destroying Terraform-managed infrastructure:

```text
AWS resources are removed
```

Use stop when you intend to continue the project soon.

Use destroy when the environment is no longer required.

Always review the Terraform plan before destroying resources.

---

# 60. Important Public IP Behavior

The staging instance uses a normal public IP rather than a permanently assigned Elastic IP.

Therefore:

```text
Start EC2
    |
    v
Public IP may change
```

After every restart, retrieve the current address:

```powershell
aws ec2 describe-instances `
  --instance-ids <instance-id> `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text
```

Use that address when opening the dashboard.

---

# 61. Setup Verification Checklist

Before considering CloudForge setup complete:

```text
[ ] AWS CLI installed
[ ] AWS credentials configured
[ ] AWS identity verified
[ ] Region verified
[ ] Repository cloned
[ ] Terraform initialized
[ ] Terraform validated
[ ] Terraform plan reviewed
[ ] Infrastructure applied
[ ] EC2 instance running
[ ] SSM connection works
[ ] Docker available
[ ] CloudForge API builds
[ ] CloudForge API is healthy
[ ] Runtime directory exists
[ ] Incident directory exists
[ ] Health monitoring configured
[ ] Self-healing configured
[ ] Status publisher active
[ ] Python virtual environment created
[ ] Analyzer dependencies installed
[ ] Gemini configuration available
[ ] Dashboard builds
[ ] Dashboard is healthy
[ ] Dashboard HTTP endpoint works
[ ] Dashboard API returns live data
[ ] ECR repository available
[ ] Jenkins pipeline configured
[ ] CloudWatch logging available
```

---

# 62. Setup Completion

Once the above checks pass, the CloudForge environment is ready for:

```text
CI/CD
Deployment
Self-Healing
Chaos Testing
Load Testing
AI Incident Analysis
Dashboard Monitoring
```

The next recommended validation is not another installation step. It is to verify the complete operational lifecycle:

```text
Deploy
  ↓
Health Check
  ↓
Intentional Failure
  ↓
Self-Healing
  ↓
Incident Creation
  ↓
AI Analysis
  ↓
Dashboard Verification
```

That workflow demonstrates the main purpose of CloudForge.

---

# 63. Final Setup Architecture

The completed setup results in:

```text
                       GitHub
                          |
                          v
                      Jenkins
                          |
                  +-------+-------+
                  |               |
                  v               v
             Docker Build       Tests
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
       +----------+----------+
       |                     |
       v                     v
cloudforge-api       cloudforge-dashboard
    :8000                    :8080
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
                       Dashboard
```

CloudForge is now prepared as a reproducible AWS DevOps/SRE environment rather than a collection of manually configured services.
