
# CloudForge Setup Guide

This document explains how to set up the CloudForge AWS environment from a fresh GitHub clone.

CloudForge uses Terraform to provision the AWS infrastructure and AWS Systems Manager (SSM) to access the EC2 instance without requiring SSH keys.

---

## 1. Prerequisites

Before starting, make sure the following are installed on your local machine.

### Required

- Git
- AWS CLI
- Terraform
- An AWS account
- AWS CLI credentials with permission to manage the CloudForge resources

### Versions used during CloudForge development

The project was tested with:

```text
Terraform: 1.16.1
AWS Provider: 6.x
AWS CLI: configured for us-east-1
````

The exact provider version may change when Terraform initializes the project.

---

# 2. Clone the Repository

Clone the CloudForge repository:

```powershell
git clone https://github.com/Savio9481/cloudforge.git
```

Enter the project directory:

```powershell
cd cloudforge
```

Verify the repository:

```powershell
git status
```

Expected:

```text
On branch main
```

---

# 3. Configure AWS CLI

CloudForge currently uses the AWS region:

```text
us-east-1
```

Configure AWS CLI:

```powershell
aws configure
```

Provide your AWS credentials when prompted.

Set:

```text
AWS Access Key ID: <your-access-key>
AWS Secret Access Key: <your-secret-key>
Default region name: us-east-1
Default output format: json
```

Never commit AWS credentials to the Git repository.

---

# 4. Verify AWS Authentication

Check the AWS identity:

```powershell
aws sts get-caller-identity
```

The command should return information similar to:

```json
{
    "UserId": "...",
    "Account": "...",
    "Arn": "arn:aws:iam::...:user/..."
}
```

This confirms that the AWS CLI is authenticated successfully.

---

# 5. Verify the AWS Region

Check the configured AWS region:

```powershell
aws configure get region
```

Expected:

```text
us-east-1
```

CloudForge Terraform environments are currently configured for this region.

---

# 6. Move to the Staging Terraform Environment

CloudForge uses separate Terraform environments.

The current project structure is:

```text
terraform/
├── modules/
│   ├── network/
│   └── compute/
│
└── environments/
    ├── dev/
    └── staging/
```

For the staging environment:

```powershell
cd terraform\environments\staging
```

Verify the location:

```powershell
Get-Location
```

---

# 7. Initialize Terraform

Initialize Terraform:

```powershell
terraform init
```

Terraform will:

* Initialize the backend
* Download required providers
* Initialize Terraform modules
* Prepare the working directory

Expected result:

```text
Terraform has been successfully initialized!
```

If Terraform reports that initialization is successful, continue to validation.

---

# 8. Validate Terraform Configuration

Run:

```powershell
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

This checks the Terraform configuration syntax and internal structure.

It does not create or modify AWS resources.

---

# 9. Review the Terraform Plan

Before creating or modifying anything, always run:

```powershell
terraform plan
```

Terraform compares:

```text
Terraform configuration
        ↓
Terraform state
        ↓
Actual AWS infrastructure
```

The plan shows what Terraform would create, modify, or destroy.

---

## 9.1 Expected Result When Infrastructure Already Exists

If the AWS infrastructure is already deployed and matches the Terraform configuration, Terraform should report:

```text
No changes. Your infrastructure matches the configuration.
```

This means Terraform does not need to modify anything.

---

# 10. Apply the Infrastructure

For a new CloudForge environment, apply the Terraform configuration:

```powershell
terraform apply
```

Terraform will display the planned changes.

Review the plan carefully.

When prompted:

```text
Enter a value:
```

Enter:

```text
yes
```

Terraform will then provision the configured AWS resources.

---

# 11. AWS Resources Created by Terraform

The staging environment currently includes resources such as:

### Networking

```text
VPC
Subnet
Internet Gateway
Route Table
Route Table Association
```

### Security

```text
Security Group
IAM Role
IAM Instance Profile
AmazonSSMManagedInstanceCore
```

### Compute

```text
EC2 instance
```

### Monitoring

```text
CloudWatch Log Group
```

The exact resource IDs are environment-specific and should not be hard-coded into documentation.

---

# 12. Verify Terraform After Apply

After `terraform apply` completes, run:

```powershell
terraform plan
```

A healthy Terraform-managed environment should return:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that the infrastructure matches the Terraform configuration.

---

# 13. Find the EC2 Instance

You can inspect the Terraform output/state or use AWS CLI.

Example:

```powershell
aws ec2 describe-instances `
  --filters "Name=tag:Project,Values=CloudForge" `
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}" `
  --output table
```

The instance should appear with its current state.

---

# 14. Access the EC2 Instance Using AWS Systems Manager

CloudForge uses AWS Systems Manager Session Manager instead of traditional SSH for the management workflow.

First identify the EC2 instance ID.

Example:

```text
i-xxxxxxxxxxxxxxxxx
```

Start an SSM session:

```powershell
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx
```

If the instance is online and SSM is configured correctly, a shell session will open.

---

# 15. Switch to the CloudForge User

The SSM session may initially open as the default shell user.

CloudForge uses `ssm-user` for the application management workflow.

Run:

```bash
sudo su - ssm-user
```

Then verify:

```bash
whoami
```

Expected:

```text
ssm-user
```

---

# 16. Verify the EC2 Environment

Check the operating system:

```bash
uname -a
```

Check Docker:

```bash
docker --version
```

Check Git:

```bash
git --version
```

Check the CloudForge directory:

```bash
ls -la /opt/cloudforge
```

---

# 17. Clone CloudForge on the EC2 Instance

Move to `/opt`:

```bash
cd /opt
```

Clone the repository:

```bash
sudo git clone https://github.com/Savio9481/cloudforge.git cloudforge
```

Change ownership:

```bash
sudo chown -R ssm-user:ssm-user /opt/cloudforge
```

Enter the project:

```bash
cd /opt/cloudforge
```

Verify:

```bash
git status
```

---

# 18. Verify the CloudForge Project

Check the project structure:

```bash
ls -la
```

Important directories include:

```text
app/
analyzer/
docs/
scripts/
terraform/
```

The API source is located under:

```text
app/
```

The AI incident analyzer is located under:

```text
analyzer/
```

The self-healing scripts are located under:

```text
scripts/
```

---

# 19. Verify Docker

Check Docker:

```bash
docker --version
```

Check the Docker service:

```bash
sudo systemctl status docker
```

Docker should be active.

You can also run:

```bash
docker ps
```

---

# 20. Build the CloudForge API Image

Move into the application directory:

```bash
cd /opt/cloudforge/app
```

Build the Docker image:

```bash
docker build -t cloudforge-api:1.0.0 .
```

Verify the image:

```bash
docker images | grep cloudforge-api
```

---

# 21. Run the CloudForge API

Start the application:

```bash
docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  cloudforge-api:1.0.0
```

Check the container:

```bash
docker ps
```

Expected port mapping:

```text
0.0.0.0:8000->8000/tcp
```

---

# 22. Verify the API Health

From the EC2 instance:

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{"status":"healthy","version":"1.0.0"}
```

This confirms that the application is running inside Docker.

---

# 23. Verify Docker Health

Check the container:

```bash
docker ps
```

The status should eventually show:

```text
healthy
```

You can inspect the health status directly:

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

Expected:

```text
healthy
```

---

# 24. Verify the CloudForge Monitoring System

CloudForge contains a monitoring loop that periodically checks the API.

The health check script is:

```text
/opt/cloudforge/scripts/health-check.sh
```

The monitoring script is:

```text
/opt/cloudforge/scripts/monitor.sh
```

The self-healing script is:

```text
/opt/cloudforge/scripts/self-heal.sh
```

The runtime status publisher is:

```text
/opt/cloudforge/scripts/status-publisher.sh
```

---

# 25. Verify Runtime Status

CloudForge publishes container runtime information to:

```text
/opt/cloudforge/runtime/status.json
```

Check it with:

```bash
cat /opt/cloudforge/runtime/status.json
```

The status contains information such as:

```json
{
  "container": {
    "name": "cloudforge-api",
    "status": "running",
    "running": true,
    "health": "healthy"
  }
}
```

This information is also consumed by the dashboard.

---

# 26. Verify Systemd Services

Check the runtime status publisher:

```bash
sudo systemctl status cloudforge-status-publisher.service
```

The service should be:

```text
active (running)
```

The CloudForge monitoring service can be checked with:

```bash
sudo systemctl status cloudforge-monitor.service
```

---

# 27. Verify Incident Storage

CloudForge stores incident records under:

```text
/opt/cloudforge/incidents/
```

Check:

```bash
ls -la /opt/cloudforge/incidents
```

Incident files use JSON format.

Example:

```text
incident-YYYY-MM-DD-HHMMSS.json
```

AI analysis files use:

```text
incident-YYYY-MM-DD-HHMMSS-ai.txt
```

---

# 28. Gemini Analyzer Setup

The AI incident analyzer is separate from the main API application.

Its dependencies are stored in:

```text
analyzer/requirements.txt
```

The analyzer uses a Python virtual environment:

```text
/opt/cloudforge/.venv
```

Create the environment if it does not exist:

```bash
cd /opt/cloudforge
python3 -m venv .venv
```

Activate it:

```bash
. /opt/cloudforge/.venv/bin/activate
```

Install analyzer dependencies:

```bash
python -m pip install -r analyzer/requirements.txt
```

Verify the Gemini SDK:

```bash
python -c "from google import genai; print('Analyzer dependencies OK')"
```

Expected:

```text
Analyzer dependencies OK
```

The Gemini API key must be supplied through the environment configuration.

Do not commit the API key to GitHub.

---

# 29. Run the AI Analyzer

The analyzer wrapper is:

```text
/opt/cloudforge/analyzer/run_analyzer.sh
```

It automatically finds the latest incident JSON and sends it to the AI analyzer.

Run:

```bash
/opt/cloudforge/analyzer/run_analyzer.sh
```

The generated AI report is stored alongside the incident:

```text
incident-YYYY-MM-DD-HHMMSS-ai.txt
```

---

# 30. Dashboard

CloudForge also contains a monitoring dashboard.

The dashboard provides visibility into:

* Application status
* Environment
* Container status
* Docker health
* CPU usage
* Memory usage
* Latest incident
* AI incident analysis
* Runtime information
* Self-healing activity

The dashboard is served separately from the API.

The dashboard container uses:

```text
cloudforge-dashboard
```

The external port is:

```text
8080
```

The dashboard URL follows:

```text
http://<EC2-PUBLIC-IP>:8080/dashboard/
```

The public IP can change when an EC2 instance is stopped and started unless an Elastic IP is used.

---

# 31. ECR

CloudForge uses Amazon Elastic Container Registry (ECR) for container images in the CI/CD workflow.

The API repository is:

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

ECR is primarily used by the Jenkins CI/CD pipeline.

---

# 32. Jenkins

Jenkins is used for CloudForge CI/CD.

The pipeline performs steps such as:

```text
GitHub
   ↓
Jenkins
   ↓
Build
   ↓
Test
   ↓
Docker Image
   ↓
ECR
   ↓
Deploy to Staging
   ↓
Health Check
```

The Jenkins job used during development is:

```text
CloudForge-CI-CD
```

Detailed CI/CD instructions are documented separately in:

```text
docs/ci-cd.md
```

---

# 33. CloudWatch

CloudForge uses CloudWatch Logs for AWS-side logging.

The staging log group is:

```text
/cloudforge/staging
```

You can verify the log group through the AWS Console or AWS CLI.

Example:

```powershell
aws logs describe-log-groups `
  --log-group-name-prefix /cloudforge/
```

---

# 34. Verify the Complete Setup

At this point the basic CloudForge environment should look like:

```text
Local Machine
      |
      | Terraform
      v
AWS
      |
      +--- VPC
      |
      +--- Public Subnet
      |
      +--- Security Group
      |
      +--- IAM Role
      |
      +--- EC2
              |
              +--- Docker
              |      |
              |      +--- cloudforge-api
              |
              +--- Monitoring
              |
              +--- Self-Healing
              |
              +--- Incident Records
              |
              +--- Gemini Analyzer
              |
              +--- Dashboard
```

---

# 35. Basic Verification Checklist

Run the following checks before considering the environment ready.

### Git

```bash
git status
```

### Terraform

```powershell
terraform validate
terraform plan
```

Expected:

```text
Success! The configuration is valid.
```

and, when already synchronized:

```text
No changes. Your infrastructure matches the configuration.
```

### EC2

```bash
docker ps
```

### API

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{"status":"healthy","version":"1.0.0"}
```

### Runtime status

```bash
cat /opt/cloudforge/runtime/status.json
```

### Monitoring

```bash
sudo systemctl status cloudforge-monitor.service
```

### Status publisher

```bash
sudo systemctl status cloudforge-status-publisher.service
```

### Incidents

```bash
ls -la /opt/cloudforge/incidents
```

---

# 36. Important Operational Rule

Do not run:

```bash
terraform apply
```

just because you want to start a stopped EC2 instance.

Terraform manages the infrastructure configuration, while EC2 can be independently stopped or started.

If the infrastructure already matches the Terraform configuration:

```text
No changes. Your infrastructure matches the configuration.
```

Starting the EC2 instance is an AWS operational action.

---

# 37. Starting a Stopped Staging Instance

From the local machine:

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

Wait until:

```text
running
```

Then verify SSM connectivity:

```powershell
aws ssm start-session --target <instance-id>
```

---

# 38. Stopping the Staging Instance

When you are finished working with the environment:

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

Stopping the EC2 instance prevents normal EC2 compute usage while preserving the instance and its attached storage.

Other AWS resources may still incur charges.

---

# 39. Destroying the Environment

When the CloudForge learning environment is no longer required, Terraform can remove the infrastructure.

First review:

```powershell
terraform plan
```

Then:

```powershell
terraform destroy
```

Review the resources carefully.

When Terraform asks for confirmation:

```text
Enter a value:
```

Enter:

```text
yes
```

Detailed cleanup guidance should be maintained in:

```text
docs/cleanup.md
```

---

# 40. Important Safety Rules

Before running destructive commands:

### Always review Terraform plan

```powershell
terraform plan
```

### Before destroy

```powershell
terraform plan -destroy
```

### Never commit credentials

Do not commit:

```text
AWS access keys
AWS secret keys
Gemini API keys
Passwords
Private keys
```

### Do not expose sensitive endpoints publicly

CloudForge's chaos/self-healing controls should not be exposed as an unauthenticated public API.

---

# 41. CloudForge Setup Lifecycle

The complete setup process is:

```text
1. Clone GitHub repository
          ↓
2. Configure AWS CLI
          ↓
3. Verify AWS identity
          ↓
4. Enter Terraform environment
          ↓
5. terraform init
          ↓
6. terraform validate
          ↓
7. terraform plan
          ↓
8. terraform apply
          ↓
9. Verify EC2
          ↓
10. Connect using SSM
          ↓
11. Clone CloudForge on EC2
          ↓
12. Build Docker image
          ↓
13. Run CloudForge API
          ↓
14. Verify /health
          ↓
15. Enable monitoring
          ↓
16. Enable self-healing
          ↓
17. Configure AI analyzer
          ↓
18. Start dashboard
          ↓
19. Configure Jenkins CI/CD
          ↓
20. Run chaos/load tests
```

---

# 42. Final Setup State

A successfully configured CloudForge environment should provide:

```text
Terraform
    ↓
AWS Infrastructure
    ↓
EC2
    ↓
Docker
    ↓
CloudForge API
    ↓
Health Monitoring
    ↓
Self-Healing
    ↓
Incident Recording
    ↓
AI Incident Analysis
    ↓
Dashboard
    ↓
Jenkins CI/CD
    ↓
ECR
    ↓
CloudWatch
```

This completes the initial CloudForge environment setup.

Continue with the following documentation for the individual systems:

```text
docs/deployment.md
docs/self-healing.md
docs/ai-incident-analyzer.md
docs/dashboard.md
docs/ci-cd.md
docs/chaos-testing.md
docs/load-testing.md
docs/cleanup.md
```
