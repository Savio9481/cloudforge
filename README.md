# CloudForge — Self-Healing AWS DevOps & AI Incident Response Platform

CloudForge is a hands-on AWS DevOps platform that demonstrates how to provision infrastructure, containerize an application, deploy it through CI/CD, monitor its health, automatically recover container failures, collect incident evidence, analyze incidents using Google Gemini AI, and visualize the system through a live DevOps dashboard.

The project combines:

- AWS infrastructure provisioning with Terraform
- AWS VPC and EC2
- IAM and AWS Systems Manager
- Docker containerization
- Amazon ECR
- Jenkins CI/CD
- Automated health monitoring
- Container self-healing
- Incident evidence collection
- Google Gemini AI incident analysis
- Live DevOps dashboard
- Chaos testing
- Load testing
- CloudWatch logging
- Multi-environment Terraform structure

The goal is to demonstrate a complete DevOps lifecycle rather than isolated AWS, Docker, or Jenkins commands.

---

## Architecture

CloudForge is designed as a self-healing AWS DevOps platform combining
Infrastructure as Code, CI/CD, containerization, monitoring, automated
recovery, AI-assisted incident analysis, and operational visibility.

![CloudForge Architecture](docs/assets/cloudforge-architecture.png)

```text
                         GitHub
                            |
                            v
                    Jenkins CI/CD
                            |
                  Build + Test + Push
                            |
                            v
                     Amazon ECR
                            |
                            v
                    AWS Systems Manager
                            |
                            v
              +---------------------------+
              |       AWS Staging EC2     |
              |                           |
              |   +-------------------+   |
              |   |   CloudForge API  |   |
              |   |   Docker :8000    |   |
              |   +-------------------+   |
              |             |             |
              |             v             |
              |      Health Monitor       |
              |             |             |
              |             v             |
              |       Self-Healing        |
              |             |             |
              |             v             |
              |      Incident JSON        |
              |             |             |
              |             v             |
              |      Gemini AI Analyzer    |
              |                           |
              |      Status Publisher      |
              |             |             |
              +-------------|-------------+
                            |
                            v
                    CloudForge Dashboard
                         :8080
````

### Recovery lifecycle

```text
Application
     |
     v
Health Check
     |
     +-------------------+
     |                   |
  Healthy              Failed
     |                   |
     v                   v
 Continue         Collect Evidence
                         |
                         v
                    Self-Healing
                         |
                         v
                  Restart Container
                         |
                         v
                    Health Check
                         |
                +--------+--------+
                |                 |
             Healthy            Failed
                |                 |
                v                 v
         Incident Record    Recovery Failed
                |
                v
          Gemini Analysis
                |
                v
            Dashboard
```

---

# Features

## Infrastructure as Code

Terraform manages the AWS infrastructure.

Current structure:

```text
terraform/
├── modules/
│   ├── network/
│   └── compute/
└── environments/
    ├── dev/
    └── staging/
```

The infrastructure includes:

* VPC
* Subnet
* Internet Gateway
* Route Table
* Security Groups
* EC2
* IAM Role
* IAM Instance Profile
* AWS Systems Manager integration
* CloudWatch resources

---

## Containerization

The CloudForge API is containerized using Docker.

```text
Python + FastAPI
       |
       v
Docker Image
       |
       v
cloudforge-api
       |
       v
Port 8000
```

The application includes a Docker health check.

---

## CI/CD

Jenkins automates the main deployment workflow:

```text
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
   +--> Push to ECR
   |
   +--> Deploy through SSM
   |
   +--> Health Verification
```

---

## Self-Healing

CloudForge continuously checks:

```text
http://127.0.0.1:8000/health
```

If the health check fails:

```text
Health Failure
      |
      v
Evidence Collection
      |
      v
Container Restart
      |
      v
Health Verification
      |
      v
Incident JSON
      |
      v
Gemini Analysis
```

The current implementation automatically recovers application/container failures that can be fixed by restarting the container.

---

## Incident Evidence

When a failure is detected and successfully recovered, CloudForge creates a structured incident JSON record.

Incident evidence includes:

* Incident ID
* Environment
* Application
* Version
* Failure type
* Detection time
* Recovery action
* Recovery time
* Recovery duration
* Recovery status
* Health status
* Docker status
* Exit code
* OOM status
* Restart count
* Container logs
* Host kernel logs

---

## AI Incident Analyzer

CloudForge uses Google Gemini to analyze incident evidence.

The analyzer produces:

1. What happened
2. Likely cause
3. Impact
4. Recovery performed
5. Recovery assessment
6. Recommended next actions

The analyzer is evidence-based and is instructed to clearly state when the exact root cause cannot be determined from the available evidence.

---

## Live DevOps Dashboard

CloudForge has a separate dashboard container.

```text
Browser
   |
   v
Dashboard :8080
   |
   v
FastAPI
   |
   +--> Container Status
   |
   +--> System Metrics
   |
   +--> Incident Data
   |
   +--> AI Analysis
```

The dashboard provides visibility into:

* Application status
* Environment
* Container state
* Docker health
* CPU usage
* Memory usage
* Runtime information
* Incident information
* Recovery activity
* AI incident analysis

Dashboard source:

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

# Technology Stack

| Area                   | Technology                                     |
| ---------------------- | ---------------------------------------------- |
| Cloud                  | AWS                                            |
| Infrastructure as Code | Terraform                                      |
| Compute                | Amazon EC2                                     |
| Networking             | VPC, Subnet, Route Table, Internet Gateway     |
| Access                 | IAM + AWS Systems Manager                      |
| Containerization       | Docker                                         |
| Container Registry     | Amazon ECR                                     |
| CI/CD                  | Jenkins                                        |
| Application            | Python + FastAPI                               |
| Monitoring             | Bash + systemd                                 |
| Self-Healing           | Docker + Bash                                  |
| AI Analysis            | Google Gemini                                  |
| Dashboard              | HTML + CSS + JavaScript + FastAPI              |
| Logging                | Amazon CloudWatch                              |
| Testing                | Pytest + custom load testing                   |
| Chaos Testing          | Docker stop/kill + controlled firewall failure |

---

# Project Structure

```text
cloudforge/
│
├── app/
│   ├── main.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── analyzer/
│   ├── ai_analyzer.py
│   ├── requirements.txt
│   └── run_analyzer.sh
│
├── dashboard/
│   ├── Dockerfile
│   ├── main.py
│   ├── requirements.txt
│   ├── services/
│   │   ├── docker_service.py
│   │   ├── incident_service.py
│   │   └── system_service.py
│   └── static/
│       ├── index.html
│       ├── style.css
│       └── dashboard.js
│
├── scripts/
│   ├── health-check.sh
│   ├── self-heal.sh
│   ├── monitor.sh
│   └── status-publisher.sh
│
├── tests/
│   └── load_test.py
│
├── terraform/
│   ├── modules/
│   │   ├── network/
│   │   └── compute/
│   └── environments/
│       ├── dev/
│       └── staging/
│
├── docs/
│   ├── architecture.md
│   ├── setup.md
│   ├── deployment.md
│   ├── self-healing.md
│   ├── ai-incident-analyzer.md
│   ├── dashboard.md
│   ├── ci-cd.md
│   ├── chaos-testing.md
│   ├── load-testing.md
│   ├── cleanup.md
│   ├── learning-notes.md
│   └── roadmap.md
│
├── Jenkinsfile
├── README.md
└── .gitignore
```

---

# Quick Start

There are two ways to use CloudForge.

### Option 1 — Run locally with Docker

Use this if you want to clone the repository and test the application/dashboard without creating AWS infrastructure.

### Option 2 — Full AWS deployment

Use this if you want to reproduce the complete CloudForge AWS environment with Terraform, EC2, SSM, ECR, monitoring, self-healing, AI analysis, and Jenkins.

---

# Option 1 — Run Locally with Docker

## 1. Prerequisites

Install:

* Git
* Docker

Verify:

```bash
git --version
docker --version
```

---

## 2. Clone the Repository

```bash
git clone https://github.com/Savio9481/cloudforge.git
```

Move into the project:

```bash
cd cloudforge
```

Verify:

```bash
git status
```

You should see:

```text
On branch main
```

---

# 3. Build the API

From the repository root:

```bash
docker build -t cloudforge-api:1.0.0 ./app
```

Verify:

```bash
docker images
```

---

# 4. Run the API

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

---

# 5. Test the API

Run:

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{"status":"healthy","version":"1.0.0"}
```

You can also open:

```text
http://127.0.0.1:8000/docs
```

to view the FastAPI documentation.

---

# 6. Build the Dashboard

The dashboard is a separate application and must be built from the `dashboard/` directory.

From the repository root:

```bash
docker build -t cloudforge-dashboard:1.0.5 ./dashboard
```

---

# 7. Create Runtime and Incident Directories

For the dashboard to read runtime and incident information:

```bash
mkdir -p runtime
mkdir -p incidents
```

---

# 8. Run the Dashboard

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v "$(pwd)/runtime:/opt/cloudforge/runtime:ro" \
  -v "$(pwd)/incidents:/opt/cloudforge/incidents:ro" \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.5
```

On Windows PowerShell, use:

```powershell
docker run -d `
  --name cloudforge-dashboard `
  -p 8080:8000 `
  -v "${PWD}/runtime:/opt/cloudforge/runtime:ro" `
  -v "${PWD}/incidents:/opt/cloudforge/incidents:ro" `
  --restart unless-stopped `
  cloudforge-dashboard:1.0.5
```

---

# 9. Open the Dashboard

Open:

```text
http://127.0.0.1:8080/dashboard/
```

The dashboard container should be visible with:

```bash
docker ps
```

Check dashboard health:

```bash
curl http://127.0.0.1:8080/health
```

Test dashboard API:

```bash
curl http://127.0.0.1:8080/api/dashboard
```

---

# 10. Stop the Local Containers

API:

```bash
docker stop cloudforge-api
```

Dashboard:

```bash
docker stop cloudforge-dashboard
```

Remove them if required:

```bash
docker rm cloudforge-api
docker rm cloudforge-dashboard
```

---

# Option 2 — Full AWS Deployment

The full CloudForge platform uses AWS.

## AWS Prerequisites

Install/configure:

* Git
* AWS CLI
* Terraform
* Docker
* An AWS account

Verify:

```bash
git --version
aws --version
terraform version
docker --version
```

---

# 1. Configure AWS CLI

CloudForge currently uses:

```text
AWS Region: us-east-1
```

Configure the AWS CLI:

```bash
aws configure
```

Set:

```text
AWS Access Key ID: <YOUR_ACCESS_KEY>
AWS Secret Access Key: <YOUR_SECRET_KEY>
Default region name: us-east-1
Default output format: json
```

Verify:

```bash
aws sts get-caller-identity
```

Never commit AWS credentials to GitHub.

---

# 2. Clone CloudForge

```bash
git clone https://github.com/Savio9481/cloudforge.git
cd cloudforge
```

Verify:

```bash
git status
git branch
```

The main branch is:

```text
main
```

---

# 3. Initialize Terraform

Move to the staging environment:

```bash
cd terraform/environments/staging
```

Initialize Terraform:

```bash
terraform init
```

---

# 4. Validate Terraform

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

# 5. Review the Infrastructure Plan

```bash
terraform plan
```

Always review the plan before applying infrastructure.

---

# 6. Create the AWS Infrastructure

If the plan is correct:

```bash
terraform apply
```

Terraform will ask for confirmation.

Enter:

```text
yes
```

Terraform will create/update the required AWS infrastructure.

---

# 7. Verify the EC2 Instance

From the AWS CLI:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}" \
  --output table
```

The staging instance should eventually show:

```text
running
```

---

# 8. Connect Using AWS Systems Manager

Find the instance ID:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --query "Reservations[].Instances[].InstanceId" \
  --output text
```

Start an SSM session:

```bash
aws ssm start-session --target <INSTANCE_ID>
```

On the EC2 instance:

```bash
sudo su - ssm-user
```

Then:

```bash
cd /opt/cloudforge
```

---

# 9. Clone CloudForge on EC2

If the repository does not already exist:

```bash
cd /opt
git clone https://github.com/Savio9481/cloudforge.git
cd cloudforge
```

Verify:

```bash
git status
```

---

# 10. Build the API Image on EC2

From the repository root:

```bash
cd /opt/cloudforge
```

Build:

```bash
docker build -t cloudforge-api:1.0.0 ./app
```

---

# 11. Run the API Container

```bash
docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  cloudforge-api:1.0.0
```

Check:

```bash
docker ps
```

Test:

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{"status":"healthy","version":"1.0.0"}
```

---

# 12. Configure Monitoring

The monitoring system uses:

```text
scripts/health-check.sh
scripts/monitor.sh
scripts/self-heal.sh
```

The health endpoint is:

```text
http://127.0.0.1:8000/health
```

Run the health check manually:

```bash
/opt/cloudforge/scripts/health-check.sh
```

Expected:

```text
CloudForge health check: HEALTHY
{"status":"healthy","version":"1.0.0"}
```

---

# 13. Configure the Monitor Service

Check:

```bash
sudo systemctl status cloudforge-monitor
```

Start:

```bash
sudo systemctl start cloudforge-monitor
```

Enable at boot:

```bash
sudo systemctl enable cloudforge-monitor
```

View logs:

```bash
sudo journalctl -u cloudforge-monitor -f
```

---

# 14. Configure the Runtime Status Publisher

CloudForge publishes current container state to:

```text
/opt/cloudforge/runtime/status.json
```

Check the service:

```bash
sudo systemctl status cloudforge-status-publisher
```

Check the status file:

```bash
cat /opt/cloudforge/runtime/status.json
```

The status contains information such as:

```text
Container name
Container status
Running state
Health
Exit code
OOM status
Restart count
Image
Start time
Last update
```

---

# 15. Configure Gemini AI Analyzer

The AI analyzer uses Google Gemini.

Create a Gemini API key using your Google AI/Gemini account.

Configure the key securely on the EC2 host.

Example:

```bash
export GEMINI_API_KEY="<YOUR_GEMINI_API_KEY>"
```

Do not put the real key in:

```text
GitHub
README.md
Python source code
Dockerfile
Jenkinsfile
```

For persistent configuration, use a secure host-level environment configuration.

Never commit the API key.

---

# 16. Create the Analyzer Environment

From:

```bash
cd /opt/cloudforge
```

Create the Python virtual environment:

```bash
python3 -m venv .venv
```

Activate it:

```bash
. /opt/cloudforge/.venv/bin/activate
```

Install dependencies:

```bash
python -m pip install -r analyzer/requirements.txt
```

Verify:

```bash
python -c "from google import genai; print('Analyzer dependencies OK')"
```

Expected:

```text
Analyzer dependencies OK
```

---

# 17. Run the AI Analyzer

First make sure an incident JSON exists.

Then:

```bash
cd /opt/cloudforge
./analyzer/run_analyzer.sh
```

The analyzer selects the latest incident:

```text
/opt/cloudforge/incidents/*.json
```

and creates an AI analysis file:

```text
incident-YYYY-MM-DD-HHMMSS-ai.txt
```

View it:

```bash
cat /opt/cloudforge/incidents/*-ai.txt
```

---

# 18. Build the Dashboard

The dashboard is maintained separately from the API.

From the repository root:

```bash
cd /opt/cloudforge
```

Build:

```bash
docker build -t cloudforge-dashboard:1.0.5 ./dashboard
```

---

# 19. Run the Dashboard

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.5
```

Check:

```bash
docker ps
```

The dashboard should expose:

```text
0.0.0.0:8080 -> 8000
```

---

# 20. Test the Dashboard

On EC2:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

Test the dashboard API:

```bash
curl http://127.0.0.1:8080/api/dashboard
```

If the AWS Security Group allows port 8080, open:

```text
http://<EC2_PUBLIC_IP>:8080/dashboard/
```

Do not hard-code the public IP in documentation because the public IP can change when the instance is restarted.

---

# Amazon ECR

CloudForge uses Amazon ECR to store application images.

Repository:

```text
cloudforge-api
```

Login:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login \
  --username AWS \
  --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

Build:

```bash
docker build -t cloudforge-api:1.0.0 ./app
```

Tag:

```bash
docker tag \
  cloudforge-api:1.0.0 \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:1.0.0
```

Push:

```bash
docker push \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:1.0.0
```

---

# Jenkins CI/CD

The Jenkins pipeline is defined in:

```text
Jenkinsfile
```

The pipeline performs:

```text
GitHub
   |
   v
Checkout
   |
   v
Tests
   |
   v
Docker Build
   |
   v
Push to ECR
   |
   v
Deploy through AWS SSM
   |
   v
Health Verification
```

Jenkins requires appropriate access to:

* GitHub
* AWS
* Amazon ECR
* AWS Systems Manager

Credentials should be stored in Jenkins credentials management rather than inside the repository.

---

# CloudWatch

CloudForge uses the CloudWatch log group:

```text
/cloudforge/staging
```

CloudWatch can be used to investigate:

* Application activity
* Deployment activity
* Operational events
* Infrastructure-related logs

---

# Testing

## API Health Test

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{"status":"healthy","version":"1.0.0"}
```

---

# Chaos Testing

CloudForge has been tested using controlled failures.

## Container Stop

```bash
docker stop cloudforge-api
```

Expected:

```text
Health failure
      |
      v
Monitor detects failure
      |
      v
Self-healing
      |
      v
Container restarted
      |
      v
Health restored
      |
      v
Incident created
```

---

## Container Force Kill

```bash
docker kill cloudforge-api
```

Verify:

```bash
docker ps
```

Then:

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{"status":"healthy","version":"1.0.0"}
```

---

## Network Failure

A controlled firewall failure can be simulated with:

```bash
sudo iptables -I INPUT -p tcp --dport 8000 -j REJECT
```

CloudForge detects the health failure.

However, restarting the container does not remove the firewall rule.

Remove the test rule:

```bash
sudo iptables -D INPUT -p tcp --dport 8000 -j REJECT
```

Then verify:

```bash
curl http://127.0.0.1:8000/health
```

This demonstrates an important current limitation:

```text
Container failure
        |
        v
Automatically recoverable

Network/firewall failure
        |
        v
Detected
        |
        v
Requires additional recovery logic
```

---

# Load Testing

CloudForge includes:

```text
tests/load_test.py
```

Run:

```bash
cd /opt/cloudforge
python3 tests/load_test.py
```

The test sends concurrent requests to the application health endpoint.

The target URL must match the current reachable address of the staging EC2 instance.

Do not assume that a previously used private IP will remain unchanged after recreating infrastructure.

---

# Example Load Test Results

Example measurements from the tested staging environment:

| Requests | Concurrency | Success | Failures |
| -------: | ----------: | ------: | -------: |
|      100 |           5 |     100 |        0 |
|     1000 |          10 |    1000 |        0 |
|     2000 |          20 |    2000 |        0 |
|     5000 |          50 |    5000 |        0 |

One 5000-request private-IP test produced approximately:

```text
Requests:       5000
Failures:       0
Duration:       3.45 seconds
Average latency: 33.56 ms
Throughput:     1448.67 requests/sec
```

These are measurements from the tested environment and are not universal performance guarantees.

---

# Documentation

Detailed documentation is available under:

```text
docs/
```

| Document                  | Description                                 |
| ------------------------- | ------------------------------------------- |
| `architecture.md`         | Complete system architecture                |
| `setup.md`                | Detailed installation and environment setup |
| `deployment.md`           | Deployment workflow                         |
| `self-healing.md`         | Monitoring and automated recovery           |
| `ai-incident-analyzer.md` | Gemini incident analysis                    |
| `dashboard.md`            | Dashboard architecture and implementation   |
| `ci-cd.md`                | Jenkins CI/CD                               |
| `chaos-testing.md`        | Failure injection and recovery tests        |
| `load-testing.md`         | Performance/load testing                    |
| `cleanup.md`              | AWS cleanup and cost control                |
| `learning-notes.md`       | Concepts learned during development         |
| `roadmap.md`              | Future improvements                         |

---

# Project Verification

Before considering the project complete, verify:

```text
[ ] Repository cloned successfully
[ ] AWS CLI configured
[ ] Terraform initialized
[ ] Terraform validate passes
[ ] Terraform plan reviewed
[ ] AWS infrastructure created
[ ] EC2 accessible through SSM
[ ] Docker installed
[ ] CloudForge API running
[ ] /health returns healthy
[ ] Docker health check works
[ ] Monitor service running
[ ] Self-healing tested
[ ] Incident JSON generated
[ ] Gemini analyzer works
[ ] AI analysis generated
[ ] Runtime status publisher works
[ ] Dashboard works
[ ] ECR repository works
[ ] Jenkins pipeline works
[ ] CI/CD deployment tested
[ ] Container stop chaos test completed
[ ] Container kill chaos test completed
[ ] Network failure test completed
[ ] Load test completed
[ ] Terraform plan verified
[ ] AWS resources stopped or destroyed
```

---

# Current Self-Healing Boundary

CloudForge currently focuses on application/container-level recovery.

| Failure                        | Current behavior                        |
| ------------------------------ | --------------------------------------- |
| Container stopped              | Automatically recoverable               |
| Container killed               | Automatically recoverable               |
| Application restart failure    | Recovery attempted                      |
| Firewall blocking port         | Detected but not automatically repaired |
| Network infrastructure failure | Requires additional recovery logic      |
| Host failure                   | Requires infrastructure-level recovery  |

The current implementation intentionally does not claim to automatically repair every possible infrastructure failure.

---

# Security Considerations

Do not commit:

```text
AWS credentials
Gemini API keys
Passwords
Private keys
.env files containing secrets
Sensitive Terraform state
Sensitive incident data
```

Never expose destructive Docker or chaos operations as an unauthenticated public API.

The dashboard should be protected with appropriate authentication and authorization before being used in a real production environment.

---

# Cost Control

CloudForge is a learning and portfolio project.

AWS resources can create charges.

When finished testing, stop the EC2 instance:

```bash
aws ec2 stop-instances \
  --region us-east-1 \
  --instance-ids <INSTANCE_ID>
```

Verify:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text
```

Expected:

```text
stopped
```

Stopping EC2 does not necessarily eliminate all AWS charges.

Other resources may continue to incur charges, including:

* EBS volumes
* ECR storage
* CloudWatch log storage
* Load balancers
* NAT gateways
* Elastic IPs
* Other retained AWS resources

Always check AWS Billing and Cost Explorer.

---

# Destroy AWS Infrastructure

When the project is completely finished:

```bash
cd terraform/environments/staging
```

Review the destroy plan:

```bash
terraform plan -destroy
```

If the plan is correct:

```bash
terraform destroy
```

Confirm:

```text
yes
```

After destruction, verify the AWS resources and billing console.

---

# Dev Environment

CloudForge also contains:

```text
terraform/environments/dev
```

The purpose is to maintain separate Terraform environments while reusing common modules:

```text
terraform/modules/network
terraform/modules/compute
```

This demonstrates a multi-environment infrastructure structure.

---

# Project Lifecycle

```text
Clone Repository
       |
       v
Configure AWS
       |
       v
Terraform
       |
       v
AWS Infrastructure
       |
       v
SSM Access
       |
       v
Docker Application
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
Gemini AI Analysis
       |
       v
Dashboard
       |
       v
Jenkins CI/CD
       |
       v
ECR
       |
       v
SSM Deployment
       |
       v
Chaos Testing
       |
       v
Load Testing
       |
       v
Verification
       |
       v
Stop / Destroy AWS Resources
```

---

# What This Project Demonstrates

CloudForge demonstrates practical experience with:

* AWS
* Terraform
* VPC
* EC2
* IAM
* AWS Systems Manager
* Docker
* Amazon ECR
* Linux
* Bash
* systemd
* FastAPI
* Jenkins
* CI/CD
* CloudWatch
* Monitoring
* Self-Healing
* Incident Management
* AI-assisted Troubleshooting
* Chaos Engineering
* Load Testing
* Infrastructure as Code
* Multi-Environment Deployment

---

# Limitations

CloudForge is a learning and portfolio project rather than a production platform.

Current limitations include:

### Self-Healing

The current recovery mechanism primarily handles application/container failures.

### AI Analysis

Gemini analysis depends on the evidence available in the incident record.

If the evidence is insufficient, the analyzer should state that the exact root cause cannot be conclusively determined.

### Load Testing

Performance results depend on:

* EC2 instance type
* Network conditions
* Application version
* Concurrency
* Request type
* System load
* AWS environment

### Security

The current dashboard should not be treated as a production-ready authenticated operations platform.

---

# Future Improvements

Potential future improvements include:

* Policy-based self-healing
* Automatic network recovery
* Application Load Balancer
* HTTPS
* Authentication
* Role-based dashboard access
* Prometheus
* Grafana
* CloudWatch alarms
* SNS notifications
* Slack notifications
* Incident history database
* AI-powered remediation recommendations
* AI-powered recovery policies
* Auto Scaling
* Multi-region deployment
* Kubernetes/EKS integration
* Blue/Green deployments
* Canary deployments
* Container vulnerability scanning
* Advanced security scanning

---

# Useful Commands

## Check API

```bash
curl http://127.0.0.1:8000/health
```

## Check containers

```bash
docker ps
```

## API logs

```bash
docker logs cloudforge-api
```

## Follow API logs

```bash
docker logs -f cloudforge-api
```

## Inspect API container

```bash
docker inspect cloudforge-api
```

## Monitor service

```bash
sudo systemctl status cloudforge-monitor
```

## Monitor logs

```bash
sudo journalctl -u cloudforge-monitor -f
```

## Status publisher

```bash
sudo systemctl status cloudforge-status-publisher
```

## Runtime status

```bash
cat /opt/cloudforge/runtime/status.json
```

## Incidents

```bash
ls -lah /opt/cloudforge/incidents
```

## Latest incident

```bash
ls -t /opt/cloudforge/incidents/*.json | head -n 1
```

## Terraform verification

```bash
cd terraform/environments/staging
terraform plan
```

---

# Repository

GitHub:

[https://github.com/Savio9481/cloudforge](https://github.com/Savio9481/cloudforge)

Main branch:

```text
main
```

---

# CloudForge in One Sentence

> **CloudForge is a Terraform-managed AWS DevOps platform that deploys a Dockerized application through Jenkins and Amazon ECR, continuously monitors its health, automatically recovers container failures, records incident evidence, analyzes incidents with Gemini AI, and visualizes the system through a live DevOps dashboard.**

---

# Project Goal

The goal of CloudForge is to demonstrate a complete practical DevOps workflow combining:

```text
Infrastructure
      +
Application
      +
Containers
      +
CI/CD
      +
Monitoring
      +
Self-Healing
      +
Incident Response
      +
AI Analysis
      +
Dashboard
      +
Chaos Testing
      +
Performance Testing
```

The project can be progressively extended toward a more production-oriented cloud platform.

````

### One important point

I deliberately **didn't put every command from your 12 documentation files into the README**. The README should be the **entry point**:

```text
README
  │
  ├── Quick Start
  │
  ├── Full AWS Setup
  │
  └── docs/
       ├── setup.md
       ├── deployment.md
       ├── dashboard.md
       ├── self-healing.md
       ├── ...
````


