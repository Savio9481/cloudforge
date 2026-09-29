CloudForge — Self-Healing AWS DevOps & AI Incident Response Platform

CloudForge is a hands-on AWS DevOps platform that demonstrates how to provision infrastructure, containerize an application, deploy it through CI/CD, monitor its health, automatically recover container failures, collect incident evidence, analyze incidents using Google Gemini AI, and visualize the system through a live DevOps dashboard.

The project combines:

AWS infrastructure provisioning with Terraform
AWS VPC and EC2
IAM and AWS Systems Manager
Docker containerization
Amazon ECR
Jenkins CI/CD
Automated health monitoring
Container self-healing
Incident evidence collection
Google Gemini AI incident analysis
Live DevOps dashboard
Chaos testing
Load testing
CloudWatch logging
Multi-environment Terraform structure

The goal is to demonstrate a complete DevOps lifecycle rather than isolated AWS, Docker, Jenkins, or Terraform commands.

Architecture

High-Level Architecture
                         GitHub
                            │
                            ▼
                     Jenkins CI/CD
                            │
                     Build + Test
                            │
                            ▼
                       Amazon ECR
                            │
                            ▼
                   AWS Systems Manager
                            │
                            ▼
              ┌─────────────────────────────┐
              │        AWS Staging EC2      │
              │                             │
              │   ┌─────────────────────┐   │
              │   │   CloudForge API    │   │
              │   │      Docker :8000   │   │
              │   └──────────┬──────────┘   │
              │              │              │
              │              ▼              │
              │      Health Monitoring      │
              │              │              │
              │              ▼              │
              │        Self-Healing         │
              │              │              │
              │              ▼              │
              │       Incident Evidence     │
              │              │              │
              │              ▼              │
              │       Gemini AI Analyzer    │
              │                             │
              │       Status Publisher       │
              └──────────────┬──────────────┘
                             │
                             ▼
                    CloudForge Dashboard
                           :8080

       Terraform
           │
           ├── VPC
           ├── Subnet
           ├── Route Table
           ├── Security Group
           ├── EC2
           └── IAM / SSM

       CloudWatch
           │
           └── Operational Logs
Key Features
Infrastructure as Code

Terraform manages the AWS infrastructure using reusable modules and separate environments.

terraform/
├── modules/
│   ├── network/
│   └── compute/
└── environments/
    ├── dev/
    └── staging/

The infrastructure includes:

VPC
Subnet
Internet Gateway
Route Table
Security Group
EC2
IAM Role
IAM Instance Profile
AWS Systems Manager integration
CloudWatch resources
Docker Containerization

The CloudForge API is built with Python and FastAPI and packaged as a Docker image.

Python + FastAPI
       │
       ▼
 Docker Image
       │
       ▼
 cloudforge-api
       │
       ▼
    :8000

The API includes a Docker health check.

The dashboard is maintained as a separate Docker application:

cloudforge-dashboard
        │
        ▼
       :8080
CI/CD

Jenkins automates the application deployment workflow:

GitHub
   │
   ▼
Jenkins
   │
   ├── Checkout
   ├── Test
   ├── Docker Build
   ├── Push to ECR
   ├── Deploy through SSM
   └── Health Verification

AWS Systems Manager is used for deployment access instead of SSH.

Self-Healing

CloudForge continuously checks the application health endpoint:

http://127.0.0.1:8000/health

When a failure is detected:

Health Failure
      │
      ▼
Evidence Collection
      │
      ▼
Self-Healing
      │
      ▼
Container Restart
      │
      ▼
Health Verification
      │
      ├── Healthy ──► Incident Record + AI Analysis
      │
      └── Failed  ──► Recovery Failure

The current implementation automatically handles application/container failures that can be recovered by restarting the container.

Incident Evidence

When a failure is detected, CloudForge records structured incident evidence.

The evidence can include:

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
Docker status
Exit code
OOM status
Restart count
Container logs
Host kernel logs
AI Incident Analyzer

CloudForge uses Google Gemini to analyze incident evidence.

The analyzer produces:

What happened
Likely cause
Impact
Recovery performed
Recovery assessment
Recommended next actions

The analyzer follows an evidence-first approach and is instructed to clearly state when the exact root cause cannot be determined from the available evidence.

Live DevOps Dashboard

CloudForge includes a separate dashboard container.

Browser
   │
   ▼
Dashboard :8080
   │
   ▼
FastAPI Dashboard Service
   │
   ├── Container Status
   ├── System Metrics
   ├── Incident Data
   └── AI Analysis

The dashboard provides visibility into:

Application status
Environment
Container state
Docker health
CPU usage
Memory usage
Runtime information
Incident information
Recovery activity
AI incident analysis

Dashboard source:

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
Technology Stack
Area	Technology
Cloud	AWS
Infrastructure as Code	Terraform
Compute	Amazon EC2
Networking	VPC, Subnet, Route Table, Internet Gateway
Access	IAM + AWS Systems Manager
Containerization	Docker
Container Registry	Amazon ECR
CI/CD	Jenkins
Application	Python + FastAPI
Monitoring	Bash + systemd
Self-Healing	Docker + Bash
AI Analysis	Google Gemini
Dashboard	HTML + CSS + JavaScript + FastAPI
Logging	Amazon CloudWatch
Testing	Pytest + custom load testing
Chaos Testing	Docker stop/kill + controlled firewall failure
Project Structure
cloudforge/
│
├── app/
│   ├── main.py
│   ├── Dockerfile
│   └── requirements.txt
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
├── analyzer/
│   ├── ai_analyzer.py
│   ├── requirements.txt
│   └── run_analyzer.sh
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
│   ├── assets/
│   │   └── cloudforge-architecture.png
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
Quick Start

There are two ways to use CloudForge.

Option 1 — Run locally with Docker

Use this to clone the repository and run the API and dashboard without creating AWS infrastructure.

Option 2 — Reproduce the full AWS environment

Use this to provision AWS infrastructure with Terraform and reproduce the complete CloudForge environment.

Option 1 — Local Docker Setup

This is the easiest way for another developer to clone and test the application.

1. Prerequisites

Install:

Git
Docker

Verify:

git --version
docker --version
2. Clone the Repository
git clone https://github.com/Savio9481/cloudforge.git
cd cloudforge

Verify:

git status

You should see:

On branch main
3. Build the API

From the repository root:

docker build -t cloudforge-api:1.0.0 ./app
4. Run the API
docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  cloudforge-api:1.0.0

Verify:

docker ps
5. Test the API
curl http://127.0.0.1:8000/health

Expected:

{"status":"healthy","version":"1.0.0"}

FastAPI documentation:

http://127.0.0.1:8000/docs
6. Build the Dashboard

From the repository root:

docker build -t cloudforge-dashboard:1.0.5 ./dashboard
7. Create Runtime and Incident Directories

The dashboard reads runtime and incident information from these directories.

Linux/macOS:

mkdir -p runtime incidents

Windows PowerShell:

New-Item -ItemType Directory -Force runtime
New-Item -ItemType Directory -Force incidents
8. Run the Dashboard
Linux/macOS
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v "$(pwd)/runtime:/opt/cloudforge/runtime:ro" \
  -v "$(pwd)/incidents:/opt/cloudforge/incidents:ro" \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.5
Windows PowerShell
docker run -d `
  --name cloudforge-dashboard `
  -p 8080:8000 `
  -v "${PWD}/runtime:/opt/cloudforge/runtime:ro" `
  -v "${PWD}/incidents:/opt/cloudforge/incidents:ro" `
  --restart unless-stopped `
  cloudforge-dashboard:1.0.5
9. Open the Dashboard

Open:

http://127.0.0.1:8080/dashboard/

Check the dashboard container:

docker ps

Test its health endpoint:

curl http://127.0.0.1:8080/health

Test the dashboard API:

curl http://127.0.0.1:8080/api/dashboard
10. Stop the Local Containers
docker stop cloudforge-api
docker stop cloudforge-dashboard

Remove them if required:

docker rm cloudforge-api
docker rm cloudforge-dashboard
Option 2 — Full AWS Setup

The full CloudForge environment requires:

AWS account
AWS CLI
Terraform
Git
Docker

Verify:

git --version
aws --version
terraform version
docker --version

CloudForge currently uses:

AWS Region: us-east-1
1. Configure AWS CLI

Configure your AWS credentials:

aws configure

Use:

Default region name: us-east-1
Default output format: json

Verify authentication:

aws sts get-caller-identity

Never commit AWS credentials to the repository.

2. Clone CloudForge
git clone https://github.com/Savio9481/cloudforge.git
cd cloudforge

Verify:

git status
git branch

Expected branch:

main
3. Initialize Terraform
cd terraform/environments/staging
terraform init
4. Validate Terraform
terraform validate

Expected:

Success! The configuration is valid.
5. Review the Infrastructure Plan
terraform plan

Always review the plan before applying infrastructure.

6. Create AWS Infrastructure

If the plan is correct:

terraform apply

Confirm with:

yes

Terraform provisions the required infrastructure.

7. Find the EC2 Instance
aws ec2 describe-instances \
  --region us-east-1 \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}" \
  --output table
8. Connect Using AWS Systems Manager

Get the instance ID:

aws ec2 describe-instances \
  --region us-east-1 \
  --query "Reservations[].Instances[].InstanceId" \
  --output text

Start an SSM session:

aws ssm start-session --target <INSTANCE_ID>

On the EC2 instance:

sudo su - ssm-user
9. Clone the Repository on EC2
cd /opt
git clone https://github.com/Savio9481/cloudforge.git
cd cloudforge

Verify:

git status
10. Build the API
cd /opt/cloudforge

docker build -t cloudforge-api:1.0.0 ./app

Run:

docker run -d \
  --name cloudforge-api \
  -p 8000:8000 \
  --restart unless-stopped \
  cloudforge-api:1.0.0

Verify:

docker ps

Test:

curl http://127.0.0.1:8000/health
Monitoring and Self-Healing

The monitoring components are:

scripts/
├── health-check.sh
├── monitor.sh
└── self-heal.sh

Run the health check:

/opt/cloudforge/scripts/health-check.sh

Check the monitor service:

sudo systemctl status cloudforge-monitor

Start it if required:

sudo systemctl start cloudforge-monitor

Enable it at boot:

sudo systemctl enable cloudforge-monitor

View logs:

sudo journalctl -u cloudforge-monitor -f
Runtime Status Publisher

CloudForge publishes the current container state to:

/opt/cloudforge/runtime/status.json

Check the service:

sudo systemctl status cloudforge-status-publisher

View the status:

cat /opt/cloudforge/runtime/status.json

The status contains information such as:

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
Gemini AI Analyzer

The analyzer uses Google Gemini.

Configure the API key securely on the host.

For example:

export GEMINI_API_KEY="<YOUR_GEMINI_API_KEY>"

Do not place the real key in:

GitHub
README.md
Python source code
Dockerfile
Jenkinsfile

Create the analyzer environment:

cd /opt/cloudforge

python3 -m venv .venv

Activate it:

. /opt/cloudforge/.venv/bin/activate

Install dependencies:

python -m pip install -r analyzer/requirements.txt

Verify:

python -c "from google import genai; print('Analyzer dependencies OK')"

Run the analyzer:

./analyzer/run_analyzer.sh

The analyzer reads the latest incident JSON from:

/opt/cloudforge/incidents/

and generates an AI analysis file.

Dashboard Deployment

Build the dashboard from the repository root:

cd /opt/cloudforge

docker build -t cloudforge-dashboard:1.0.5 ./dashboard

Run:

docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.5

Verify:

docker ps

Test:

curl -I http://127.0.0.1:8080/dashboard/

Dashboard API:

curl http://127.0.0.1:8080/api/dashboard

If port 8080 is allowed by the AWS Security Group:

http://<EC2_PUBLIC_IP>:8080/dashboard/

The public IP should not be hard-coded because it can change when the EC2 instance is restarted.

Amazon ECR

CloudForge uses Amazon ECR to store application images.

Repository:

cloudforge-api

Authenticate:

aws ecr get-login-password --region us-east-1 | \
docker login \
  --username AWS \
  --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

Build:

docker build -t cloudforge-api:1.0.0 ./app

Tag:

docker tag \
  cloudforge-api:1.0.0 \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:1.0.0

Push:

docker push \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/cloudforge-api:1.0.0
Jenkins CI/CD

The pipeline is defined in:

Jenkinsfile

The deployment process is:

GitHub
   │
   ▼
Jenkins
   │
   ├── Checkout
   ├── Test
   ├── Docker Build
   ├── Push to ECR
   ├── Deploy through SSM
   └── Health Verification

Credentials should be stored using Jenkins credentials management rather than inside the repository.

CloudWatch

CloudForge uses CloudWatch logging for the staging environment.

Current log group:

/cloudforge/staging

CloudWatch can be used to investigate:

Application activity
Deployment activity
Operational events
Infrastructure-related logs
Chaos Testing

CloudForge has been tested using controlled failures.

Container Stop
docker stop cloudforge-api

The monitor detects the failure and attempts automatic recovery.

Observed result:

Container stopped
      ↓
Health failure detected
      ↓
Self-healing
      ↓
Container restarted
      ↓
Health restored
      ↓
Incident recorded
Container Force Kill
docker kill cloudforge-api

The system detects the failure and attempts recovery.

Network Failure

A controlled firewall failure was also tested:

sudo iptables -I INPUT -p tcp --dport 8000 -j REJECT

The failure was detected, but restarting the container could not repair the firewall rule.

Remove the test rule:

sudo iptables -D INPUT -p tcp --dport 8000 -j REJECT

This establishes the current self-healing boundary:

Container failure
      ↓
Automatically recoverable

Network/firewall failure
      ↓
Detected
      ↓
Requires additional recovery logic

See docs/chaos-testing.md for details.

Load Testing

CloudForge includes:

tests/load_test.py

Run:

python3 tests/load_test.py

Example measured result from the tested staging environment:

Requests	Concurrency	Success	Failures
100	5	100	0
1,000	10	1,000	0
2,000	20	2,000	0
5,000	50	5,000	0

One 5,000-request private-IP test produced:

Requests:          5000
Failures:          0
Duration:          3.45 seconds
Average latency:   33.56 ms
Throughput:        1448.67 requests/sec

These are measurements from the tested environment and are not universal performance guarantees.

See docs/load-testing.md.

Documentation

Detailed documentation is available under docs/.

Document	Description
architecture.md	Complete system architecture
setup.md	Detailed environment setup
deployment.md	Deployment workflow
self-healing.md	Monitoring and automated recovery
ai-incident-analyzer.md	Gemini incident analysis
dashboard.md	Dashboard architecture
ci-cd.md	Jenkins CI/CD
chaos-testing.md	Failure injection and recovery
load-testing.md	Load testing
cleanup.md	AWS cleanup and cost control
learning-notes.md	Development and learning notes
roadmap.md	Future improvements
Current Self-Healing Boundary
Failure	Current Behavior
Container stopped	Automatically recoverable
Container killed	Automatically recoverable
Application restart failure	Recovery attempted
Firewall blocking port	Detected but not automatically repaired
Network infrastructure failure	Requires additional recovery logic
Host failure	Requires infrastructure-level recovery

CloudForge intentionally does not claim to automatically repair every possible infrastructure failure.

Security Considerations

Never commit:

AWS credentials
Gemini API keys
Passwords
Private keys
.env files containing secrets
Sensitive Terraform state
Sensitive incident data

Never expose destructive Docker or chaos operations as an unauthenticated public API.

The current dashboard is intended for a learning/portfolio environment and should have proper authentication and authorization before being used as a production operations platform.

Cost Control

CloudForge is a learning and portfolio project, so AWS resources should be stopped or destroyed when they are no longer required.

Stop an EC2 instance:

aws ec2 stop-instances \
  --region us-east-1 \
  --instance-ids <INSTANCE_ID>

Verify:

aws ec2 describe-instances \
  --region us-east-1 \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text

Expected:

stopped

Stopping EC2 does not necessarily eliminate all AWS charges. Other resources such as EBS, ECR, CloudWatch, load balancers, NAT gateways, or other retained resources may continue to incur charges.

Always check AWS Billing and Cost Explorer.

Destroy AWS Infrastructure

When the project is completely finished:

cd terraform/environments/staging

Review:

terraform plan -destroy

If correct:

terraform destroy

Confirm:

yes

After destruction, verify the AWS resources and billing console.

Current Limitations
Self-Healing

The current recovery mechanism primarily handles application/container failures.

AI Analysis

Gemini analysis depends on the evidence available in the incident record.

If the evidence is insufficient, the analyzer should state that the exact root cause cannot be conclusively determined.

Load Testing

Performance depends on:

EC2 instance type
Network conditions
Application version
Concurrency
Request type
System load
AWS environment
Security

The current dashboard is not a production-ready authenticated operations platform.

Future Improvements

Potential future improvements include:

Policy-based self-healing
Automatic network recovery
Application Load Balancer
HTTPS
Authentication
Role-based dashboard access
Prometheus
Grafana
CloudWatch alarms
SNS notifications
Slack notifications
Incident history database
AI-powered remediation recommendations
AI-powered recovery policies
Auto Scaling
Multi-region deployment
Kubernetes/EKS integration
Blue/Green deployments
Canary deployments
Container vulnerability scanning
Advanced security scanning
Useful Commands
Check API
curl http://127.0.0.1:8000/health
Check containers
docker ps
API logs
docker logs cloudforge-api
Follow API logs
docker logs -f cloudforge-api
Inspect container
docker inspect cloudforge-api
Monitor service
sudo systemctl status cloudforge-monitor
Monitor logs
sudo journalctl -u cloudforge-monitor -f
Status publisher
sudo systemctl status cloudforge-status-publisher
Runtime status
cat /opt/cloudforge/runtime/status.json
Incidents
ls -lah /opt/cloudforge/incidents
Latest incident
ls -t /opt/cloudforge/incidents/*.json | head -n 1
Terraform verification
cd terraform/environments/staging
terraform plan
Project Verification Checklist

Use this checklist when reproducing CloudForge:

[ ] Repository cloned successfully
[ ] AWS CLI configured
[ ] Terraform initialized
[ ] Terraform validation passed
[ ] Terraform plan reviewed
[ ] AWS infrastructure created
[ ] EC2 accessible through SSM
[ ] Docker installed
[ ] CloudForge API running
[ ] /health returns healthy
[ ] Docker health check working
[ ] Monitor service running
[ ] Self-healing tested
[ ] Incident JSON generated
[ ] Gemini analyzer configured
[ ] AI analysis generated
[ ] Runtime status publisher working
[ ] Dashboard working
[ ] ECR repository working
[ ] Jenkins pipeline working
[ ] CI/CD deployment tested
[ ] Container stop chaos test completed
[ ] Container kill chaos test completed
[ ] Network failure test completed
[ ] Load test completed
[ ] AWS resources stopped or destroyed
What This Project Demonstrates

CloudForge demonstrates practical experience with:

AWS
Terraform
VPC
EC2
IAM
AWS Systems Manager
Docker
Amazon ECR
Linux
Bash
systemd
FastAPI
Jenkins
CI/CD
CloudWatch
Monitoring
Self-Healing
Incident Management
AI-assisted troubleshooting
Chaos Engineering
Load Testing
Infrastructure as Code
Multi-environment deployment
Repository

GitHub:

https://github.com/Savio9481/cloudforge

Main branch:

main
CloudForge in One Sentence

CloudForge is a Terraform-managed AWS DevOps platform that deploys a Dockerized application through Jenkins and Amazon ECR, continuously monitors its health, automatically recovers container failures, records incident evidence, analyzes incidents with Gemini AI, and visualizes the system through a live DevOps dashboard.

Project Goal

The goal of CloudForge is to demonstrate a complete practical DevOps workflow combining:

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

The project can be progressively extended toward a more production-oriented cloud platform.