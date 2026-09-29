# CloudForge — Self-Healing AWS DevOps & AI Incident Response Platform

CloudForge is a hands-on AWS DevOps project that demonstrates how to build, deploy, monitor, automatically recover, analyze, and test a containerized application on AWS.

The project combines:

- AWS infrastructure provisioning with Terraform
- EC2 and VPC networking
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

The goal is to demonstrate a complete DevOps lifecycle rather than only individual AWS or Docker commands.

---

## Architecture

```text
                         GitHub
                           │
                           ▼
                    Jenkins CI/CD
                           │
                 Build + Test + Push
                           │
                           ▼
                  Amazon ECR Repository
                           │
                           ▼
                    AWS SSM Deploy
                           │
                           ▼
              ┌─────────────────────────┐
              │      AWS Staging EC2    │
              │                         │
              │  ┌───────────────────┐  │
              │  │   CloudForge API  │  │
              │  │   Docker          │  │
              │  │   Port 8000       │  │
              │  └───────────────────┘  │
              │                         │
              │  Health Monitor         │
              │       │                 │
              │       ▼                 │
              │  Self-Healing           │
              │       │                 │
              │       ▼                 │
              │  Incident JSON          │
              │       │                 │
              │       ▼                 │
              │  Gemini AI Analyzer     │
              │                         │
              │  Status Publisher       │
              └───────────┬─────────────┘
                          │
                          ▼
                 CloudForge Dashboard
                    Port 8080
```

---

# 1. Project Structure

```text
cloudforge/
│
├── app/
│   ├── main.py
│   ├── Dockerfile
│   ├── requirements.txt
│   │
│   ├── services/
│   │   ├── docker_service.py
│   │   ├── incident_service.py
│   │   └── system_service.py
│   │
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
│   │
│   └── environments/
│       ├── dev/
│       └── staging/
│
├── docs/
│   ├── architecture.md
│   ├── chaos-testing.md
│   ├── learning-notes.md
│   ├── load-testing.md
│   └── roadmap.md
│
├── Jenkinsfile
├── README.md
└── .gitignore
```

---

# 2. Technologies Used

| Area | Technology |
|---|---|
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Compute | EC2 |
| Networking | VPC, Subnet, Route Table, Internet Gateway |
| Access | IAM + AWS Systems Manager |
| Containerization | Docker |
| Container Registry | Amazon ECR |
| CI/CD | Jenkins |
| Application | Python + FastAPI |
| Monitoring | Bash + systemd |
| Self-Healing | Docker + Bash |
| AI Analysis | Google Gemini |
| Dashboard | HTML + CSS + JavaScript + FastAPI |
| Logging | Amazon CloudWatch |
| Testing | Pytest + custom load test |
| Chaos Testing | Docker stop/kill + firewall failure |

---

# 3. Prerequisites

Install/configure the following on your local machine:

```text
Git
AWS CLI
Terraform
An AWS account
Docker (optional locally)
```

Verify:

```bash
git --version
aws --version
terraform version
docker --version
```

AWS CLI must be configured with credentials that have permission to create the required AWS resources.

---

# 4. Clone the Repository

```bash
git clone https://github.com/Savio9481/cloudforge.git
cd cloudforge
```

Check the repository:

```bash
git status
git branch
```

The main branch is:

```text
main
```

---

# 5. Configure AWS CLI

CloudForge currently uses:

```text
AWS Region: us-east-1
```

Configure AWS CLI:

```bash
aws configure
```

Enter your AWS credentials and region.

Example:

```text
AWS Access Key ID: <YOUR_ACCESS_KEY>
AWS Secret Access Key: <YOUR_SECRET_KEY>
Default region name: us-east-1
Default output format: json
```

Verify the identity:

```bash
aws sts get-caller-identity
```

The command should return the AWS account and IAM identity being used.

Never commit AWS credentials to GitHub.

---

# 6. Terraform Infrastructure

CloudForge uses Terraform to create the AWS infrastructure.

The Terraform structure is:

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

The infrastructure includes resources such as:

```text
VPC
Subnet
Internet Gateway
Route Table
Security Group
EC2
IAM Role
IAM Instance Profile
SSM permissions
CloudWatch resources
```

---

# 7. Deploy the Staging Infrastructure

Move into the staging environment:

```bash
cd terraform/environments/staging
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

Review the infrastructure plan:

```bash
terraform plan
```

If the plan is correct:

```bash
terraform apply
```

Confirm with:

```text
yes
```

Terraform will create/update the AWS infrastructure.

---

# 8. Verify Terraform

After applying Terraform:

```bash
terraform output
```

Check the AWS resources:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}" \
  --output table
```

The staging EC2 instance should eventually show:

```text
running
```

---

# 9. Connect to EC2 Using AWS Systems Manager

CloudForge uses AWS Systems Manager instead of requiring SSH access.

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

Switch to the CloudForge user:

```bash
sudo su - ssm-user
```

Move to the project directory:

```bash
cd /opt/cloudforge
```

---

# 10. Verify EC2 Environment

Check Docker:

```bash
docker --version
```

Check Git:

```bash
git --version
```

Check Python:

```bash
python3 --version
```

Check systemd:

```bash
systemctl --version
```

The EC2 host is used as the staging environment for:

```text
Docker
CloudForge API
Monitoring
Self-Healing
AI Analyzer
Dashboard
Load Testing
```

---

# 11. Clone CloudForge on EC2

If the repository is not already present:

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

# 12. Build the CloudForge API

Move into the application directory:

```bash
cd /opt/cloudforge/app
```

Build the Docker image:

```bash
docker build -t cloudforge-api:1.0.0 .
```

Verify:

```bash
docker images
```

---

# 13. Run the CloudForge API

Start the API:

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

Check the health endpoint locally:

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{"status":"healthy","version":"1.0.0"}
```

---

# 14. Docker Health Check

The application Dockerfile contains a health check.

Check it:

```bash
docker ps
```

The container should eventually show:

```text
healthy
```

You can also inspect it:

```bash
docker inspect cloudforge-api \
  --format '{{.State.Health.Status}}'
```

Expected:

```text
healthy
```

---

# 15. Application API

CloudForge uses FastAPI.

Important endpoint:

```text
GET /health
```

Example:

```bash
curl http://127.0.0.1:8000/health
```

The endpoint is used by the monitoring system to determine whether the application is healthy.

---

# 16. CloudForge Monitoring

The monitoring architecture is:

```text
monitor.sh
     │
     ▼
health-check.sh
     │
     ├── HEALTHY
     │      │
     │      ▼
     │   Continue
     │
     └── FAILED
            │
            ▼
       self-heal.sh
            │
            ▼
       Restart container
            │
            ▼
       Check health again
```

The monitor checks the application repeatedly.

The health check uses:

```text
http://127.0.0.1:8000/health
```

---

# 17. Health Check

Run manually:

```bash
/opt/cloudforge/scripts/health-check.sh
```

Healthy result:

```text
CloudForge health check: HEALTHY
{"status":"healthy","version":"1.0.0"}
```

Failure result:

```text
CloudForge health check: FAILED
```

---

# 18. Self-Healing

CloudForge automatically attempts to recover a failed application container.

The recovery flow is:

```text
Health Check Fails
       │
       ▼
Failure Detected
       │
       ▼
Collect Docker Evidence
       │
       ▼
Collect Host Evidence
       │
       ▼
Restart Container
       │
       ▼
Wait for Health
       │
       ├── Healthy
       │     │
       │     ▼
       │  Incident JSON
       │
       └── Still Failed
             │
             ▼
          Recovery Failed
```

Run the self-healing script manually:

```bash
/opt/cloudforge/scripts/self-heal.sh
```

---

# 19. Monitor Service

CloudForge uses a systemd service called:

```text
cloudforge-monitor.service
```

Check it:

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

Restart:

```bash
sudo systemctl restart cloudforge-monitor
```

View logs:

```bash
sudo journalctl -u cloudforge-monitor -f
```

The monitor continuously runs:

```text
health-check.sh
```

and calls:

```text
self-heal.sh
```

when the application becomes unhealthy.

---

# 20. Runtime Status Publisher

CloudForge also publishes the current Docker runtime state to:

```text
/opt/cloudforge/runtime/status.json
```

The publisher tracks:

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

The service is:

```text
cloudforge-status-publisher.service
```

Check it:

```bash
sudo systemctl status cloudforge-status-publisher
```

View logs:

```bash
sudo journalctl -u cloudforge-status-publisher -f
```

Check the generated status:

```bash
cat /opt/cloudforge/runtime/status.json
```

Example:

```json
{
  "container": {
    "name": "cloudforge-api",
    "status": "running",
    "running": true,
    "health": "healthy",
    "exit_code": 0,
    "oom_killed": false,
    "restart_count": 0
  }
}
```

---

# 21. Incident Records

When CloudForge detects and successfully recovers from an incident, it creates an incident JSON file:

```text
/opt/cloudforge/incidents/
```

Example:

```text
incident-2026-09-28-061731.json
```

Incident information includes:

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
Container logs
Kernel logs
```

View incidents:

```bash
ls -lah /opt/cloudforge/incidents
```

View the latest incident:

```bash
ls -t /opt/cloudforge/incidents/*.json | head -n 1
```

---

# 22. AI Incident Analyzer

CloudForge uses Google Gemini to analyze incident evidence.

The analyzer receives the incident JSON and asks the AI to explain:

```text
1. What happened
2. Likely cause
3. Impact
4. Recovery performed
5. Recovery assessment
6. Recommended next actions
```

The analyzer is designed to use the evidence contained in the incident record and clearly state when the exact root cause cannot be determined.

---

# 23. Configure Gemini

Create a Gemini API key using your Google AI/Gemini account.

Configure it as an environment variable:

```bash
export GEMINI_API_KEY="<YOUR_GEMINI_API_KEY>"
```

For a persistent EC2 configuration, store the environment variable using a secure host-level configuration method.

Do not put the real key inside:

```text
Git
GitHub
README.md
Python source code
Dockerfile
Jenkinsfile
```

Never commit the API key.

---

# 24. Create the Analyzer Virtual Environment

On EC2:

```bash
cd /opt/cloudforge
```

Create the virtual environment:

```bash
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

Verify:

```bash
python -c "from google import genai; print('Analyzer dependencies OK')"
```

---

# 25. Run the AI Analyzer

First make sure at least one incident JSON exists.

Then:

```bash
cd /opt/cloudforge
./analyzer/run_analyzer.sh
```

The analyzer selects the latest incident:

```text
/opt/cloudforge/incidents/*.json
```

and creates:

```text
incident-YYYY-MM-DD-HHMMSS-ai.txt
```

View the AI analysis:

```bash
cat /opt/cloudforge/incidents/*-ai.txt
```

---

# 26. Dashboard

CloudForge includes a live DevOps dashboard.

The dashboard displays information such as:

```text
Application status
Environment
Container state
Docker health
CPU usage
Memory usage
Incident information
AI incident analysis
Recovery activity
Runtime information
Load-testing information
```

The dashboard communicates with the FastAPI backend.

Architecture:

```text
Browser
   │
   ▼
CloudForge Dashboard
   │
   ▼
FastAPI
   │
   ├── Container Status
   ├── System Metrics
   ├── Incident Data
   └── AI Analysis
```

---

# 27. Dashboard API

The dashboard backend exposes:

```text
/api/dashboard
/api/container
```

Test:

```bash
curl http://127.0.0.1:8000/api/dashboard
```

---

# 28. Build Dashboard Image

The dashboard uses the CloudForge application image structure.

Build:

```bash
cd /opt/cloudforge/app

docker build -t cloudforge-dashboard:1.0.0 .
```

---

# 29. Run Dashboard Container

The dashboard runs separately from the API container.

```bash
docker run -d \
  --name cloudforge-dashboard \
  -p 8080:8000 \
  -v /opt/cloudforge/runtime:/opt/cloudforge/runtime:ro \
  -v /opt/cloudforge/incidents:/opt/cloudforge/incidents:ro \
  --restart unless-stopped \
  cloudforge-dashboard:1.0.0
```

Check:

```bash
docker ps
```

Test locally:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

Open in a browser:

```text
http://<EC2_PUBLIC_IP>:8080/dashboard/
```

---

# 30. Dashboard Live Polling

The dashboard periodically requests:

```text
/api/dashboard
```

This allows the UI to update without manually refreshing the browser.

The dashboard can therefore show changes such as:

```text
HEALTHY
   ↓
INCIDENT DETECTED
   ↓
SELF-HEALING
   ↓
RECOVERED
   ↓
AI ANALYSIS
```

---

# 31. Amazon ECR

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

# 32. Jenkins CI/CD

CloudForge uses Jenkins to automate:

```text
GitHub
   │
   ▼
Jenkins
   │
   ├── Checkout
   ├── Test
   ├── Docker Build
   ├── Push to ECR
   └── Deploy to EC2 using SSM
```

The Jenkins pipeline is defined in:

```text
Jenkinsfile
```

---

# 33. Jenkins Pipeline

The pipeline performs the main CI/CD workflow:

```text
Developer Push
      │
      ▼
GitHub
      │
      ▼
Jenkins
      │
      ▼
Checkout Code
      │
      ▼
Run Tests
      │
      ▼
Build Docker Image
      │
      ▼
Push Image to ECR
      │
      ▼
Deploy Using AWS SSM
      │
      ▼
Wait for Health
      │
      ▼
Deployment Complete
```

---

# 34. Jenkins Configuration

Jenkins requires access to:

```text
GitHub
AWS
Amazon ECR
AWS Systems Manager
```

Configure the required credentials in Jenkins rather than putting credentials inside the repository.

Create a Jenkins pipeline job pointing to:

```text
Jenkinsfile
```

Configure the GitHub webhook so a repository push can trigger Jenkins.

---

# 35. Deployment Using Jenkins

After Jenkins is configured, the normal deployment flow becomes:

```bash
git add .
git commit -m "Update CloudForge"
git push origin main
```

Then:

```text
GitHub
  ↓
Jenkins
  ↓
Tests
  ↓
Docker Build
  ↓
ECR Push
  ↓
SSM Deployment
  ↓
Container Restart
  ↓
Health Check
```

This removes the need to manually build and deploy every application change.

---

# 36. CloudWatch

CloudForge also integrates with CloudWatch logging.

The staging environment uses the CloudWatch log group:

```text
/cloudforge/staging
```

CloudWatch can be used to investigate:

```text
Application activity
Deployment activity
Operational events
Infrastructure-related logs
```

---

# 37. Chaos Testing

CloudForge was intentionally tested by creating controlled failures.

The purpose is to verify:

```text
Failure detection
Evidence collection
Automatic recovery
Health verification
Recovery limitations
```

---

# 38. Chaos Test — Container Stop

Stop the API container:

```bash
docker stop cloudforge-api
```

The monitoring system should detect the failed health check.

Expected flow:

```text
Container stopped
      ↓
Health check fails
      ↓
Monitor detects failure
      ↓
Self-healing starts
      ↓
Container restarted
      ↓
Health check succeeds
      ↓
Incident JSON created
      ↓
AI analysis generated
```

Check:

```bash
docker ps
```

The application should return to:

```text
healthy
```

---

# 39. Chaos Test — Force Kill

Forcefully terminate the container:

```bash
docker kill cloudforge-api
```

The monitor should detect the failure and attempt recovery.

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
{"status":"healthy","version":"1.0.0"}
```

---

# 40. Chaos Test — Network Failure

A network-level failure can be simulated with:

```bash
sudo iptables -I INPUT -p tcp --dport 8000 -j REJECT
```

CloudForge will detect that the health check is failing.

However, restarting the container does not remove the firewall rule.

Therefore:

```text
Container Restart
        ↓
Still blocked
        ↓
Health check still fails
```

Remove the test rule:

```bash
sudo iptables -D INPUT -p tcp --dport 8000 -j REJECT
```

Then verify:

```bash
curl http://127.0.0.1:8000/health
```

---

# 41. Current Self-Healing Boundary

CloudForge currently handles failures that can be recovered by restarting the application container.

It does not automatically repair every possible infrastructure or network problem.

For example:

```text
Container stopped       → Recoverable
Container killed        → Recoverable
Application restart     → Recoverable

Firewall blocking port  → Detected, but not automatically fixed
Network infrastructure  → Requires additional recovery logic
Host failure            → Requires infrastructure-level recovery
```

This limitation is intentional and provides the foundation for future policy-engine and AI-driven recovery improvements.

---

# 42. Load Testing

CloudForge includes:

```text
tests/load_test.py
```

The test sends concurrent requests to the health endpoint.

Before running it, make sure the target URL inside:

```text
tests/load_test.py
```

matches the private IP or reachable address of your current staging EC2 instance.

Do not assume that a previously used EC2 private IP will remain the same after recreating the infrastructure.

Run:

```bash
cd /opt/cloudforge
python3 tests/load_test.py
```

---

# 43. Example Load Test Metrics

CloudForge was tested with different request/concurrency levels.

Example results from the staging environment:

```text
100 requests / concurrency 5
Success: 100
Failures: 0

1000 requests / concurrency 10
Success: 1000
Failures: 0

2000 requests / concurrency 20
Success: 2000
Failures: 0

5000 requests / concurrency 50
Success: 5000
Failures: 0
```

One 5000-request private-IP test produced approximately:

```text
Requests:       5000
Failures:       0
Duration:       3.45 seconds
Average latency: 33.56 ms
Throughput:     1448.67 requests/sec
```

These numbers are measurements from the tested staging environment and should not be treated as universal performance guarantees.

---

# 44. Docker Resource Observation

During load testing, Docker resource usage was also observed.

Example:

```text
CPU:    ~0.25%
Memory: ~59.53 MiB
Memory limit: ~7.59 GiB
```

This showed that the tested workload did not consume a large portion of the available container memory.

Actual results will depend on:

```text
EC2 instance type
Network
Application version
Concurrency
Request type
System load
AWS environment
```

---

# 45. Git Workflow

After making changes:

```bash
git status
```

Review:

```bash
git diff
```

Stage:

```bash
git add .
```

Commit:

```bash
git commit -m "Describe the change"
```

Push:

```bash
git push origin main
```

Pull the latest version:

```bash
git pull origin main
```

---

# 46. Important Git Rule

Do not commit:

```text
AWS credentials
Gemini API keys
Passwords
Private keys
.env files containing secrets
Terraform state containing sensitive information
Temporary incident data if it contains sensitive information
```

The personal file:

```text
commandss
```

should remain untracked if it is only being used as a personal command/reference file.

---

# 47. Terraform Verification

At any time, verify that Terraform matches the actual AWS infrastructure:

```bash
cd terraform/environments/staging
terraform plan
```

A clean infrastructure state should show:

```text
No changes.
Your infrastructure matches the configuration.
```

This is an important verification step before making further changes.

---

# 48. Safe Project Shutdown

CloudForge is designed as a learning/testing project.

When you are finished working for the day, stop the EC2 instance if you want to retain the infrastructure for later use.

Find the instance:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name}" \
  --output table
```

Stop it:

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

---

# 49. Important AWS Cost Note

Stopping an EC2 instance stops normal instance compute charges, but some AWS resources can continue to incur charges.

Examples include:

```text
EBS volumes
Elastic IPs
NAT Gateways
Load Balancers
CloudWatch resources/log storage
ECR storage
Other retained AWS resources
```

Always check AWS Billing/Cost Explorer before leaving the project running.

---

# 50. Restart the Project Later

If the infrastructure still exists:

```bash
aws ec2 start-instances \
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
running
```

Then connect:

```bash
aws ssm start-session --target <INSTANCE_ID>
```

Verify Docker:

```bash
docker ps
```

Verify the API:

```bash
curl http://127.0.0.1:8000/health
```

---

# 51. Destroy the Project

When the project is completely finished and the AWS resources are no longer required, Terraform can remove the infrastructure.

First:

```bash
cd terraform/environments/staging
```

Review what would be destroyed:

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

# 52. Dev Environment

CloudForge also contains a separate Terraform environment:

```text
terraform/environments/dev
```

The purpose is to keep development infrastructure separate from staging infrastructure.

The environments follow the same Terraform modules:

```text
terraform/modules/network
terraform/modules/compute
```

This demonstrates a multi-environment Terraform structure rather than placing all infrastructure into a single configuration.

---

# 53. Project Lifecycle

The complete CloudForge workflow is:

```text
1. Clone GitHub repository
        ↓
2. Configure AWS CLI
        ↓
3. Terraform init
        ↓
4. Terraform validate
        ↓
5. Terraform plan
        ↓
6. Terraform apply
        ↓
7. AWS VPC + EC2 + IAM + Security Group
        ↓
8. Connect through AWS SSM
        ↓
9. Clone CloudForge on EC2
        ↓
10. Build Docker image
        ↓
11. Run CloudForge API
        ↓
12. Configure health monitoring
        ↓
13. Configure self-healing
        ↓
14. Configure runtime status publisher
        ↓
15. Configure Gemini analyzer
        ↓
16. Start CloudForge dashboard
        ↓
17. Configure Jenkins
        ↓
18. Push image to ECR
        ↓
19. Jenkins deploys through SSM
        ↓
20. Run chaos tests
        ↓
21. Run load tests
        ↓
22. Review incidents + AI analysis
        ↓
23. Verify Terraform
        ↓
24. Stop or destroy AWS resources
```

---

# 54. Failure Recovery Lifecycle

The main CloudForge self-healing workflow is:

```text
                 Application
                     │
                     ▼
                Health Check
                     │
             ┌───────┴───────┐
             │               │
          Healthy          Failed
             │               │
             ▼               ▼
         Continue       Collect Evidence
                             │
                             ▼
                       Self-Healing
                             │
                             ▼
                     Restart Container
                             │
                             ▼
                       Health Check
                             │
                  ┌──────────┴──────────┐
                  │                     │
               Healthy               Failed
                  │                     │
                  ▼                     ▼
             Incident Record       Recovery Failed
                  │
                  ▼
             Gemini Analysis
                  │
                  ▼
               Dashboard
```

---

# 55. What This Project Demonstrates

CloudForge demonstrates practical knowledge of:

```text
AWS
Terraform
VPC
EC2
IAM
SSM
Docker
ECR
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
AI-assisted Troubleshooting
Chaos Engineering
Load Testing
Infrastructure as Code
Multi-Environment Deployment
```

---

# 56. Key DevOps Concepts Demonstrated

## Infrastructure as Code

Terraform creates and manages the AWS infrastructure.

```text
Terraform
   ↓
Repeatable infrastructure
```

## Continuous Integration

Jenkins validates and builds the application.

```text
Git Push
   ↓
Jenkins
   ↓
Tests
   ↓
Docker Build
```

## Continuous Deployment

The built image is pushed to ECR and deployed to EC2.

```text
Docker Image
   ↓
ECR
   ↓
SSM
   ↓
EC2
```

## Monitoring

The health endpoint is checked continuously.

```text
/health
```

## Self-Healing

Detected container failures trigger automated recovery.

```text
Failure
   ↓
Detect
   ↓
Restart
   ↓
Verify
```

## Incident Response

Evidence is stored in structured JSON.

```text
Incident
   ↓
Evidence
   ↓
Recovery
   ↓
Analysis
```

## AI-Assisted Operations

Gemini analyzes incident evidence and produces an operational explanation.

```text
Incident JSON
     ↓
Gemini
     ↓
AI Analysis
```

## Chaos Engineering

Controlled failures are introduced to verify recovery behavior.

```text
Stop
Kill
Network Failure
```

## Performance Testing

The application is tested under concurrent request load.

```text
Requests
   ↓
Concurrency
   ↓
Latency
   ↓
Throughput
```

---

# 57. Important Limitations

CloudForge is a learning and portfolio project.

The current implementation has boundaries.

### Self-Healing

The current self-healing system primarily handles application/container failures.

It does not automatically repair every infrastructure problem.

### AI Analysis

Gemini analysis is based on the evidence provided to the analyzer.

If the available evidence does not identify the exact root cause, the analyzer should state that the exact root cause cannot be conclusively determined.

### Load Testing

The load-testing results depend on the specific EC2 instance, application version, network conditions, and test configuration.

### Security

The dashboard and testing endpoints should not be exposed publicly without appropriate authentication and authorization.

Do not expose destructive Docker or chaos operations as an unauthenticated public API.

---

# 58. Future Improvements

Possible future CloudForge improvements include:

```text
Policy-based self-healing
Automatic network recovery
Auto Scaling
Application Load Balancer
HTTPS
Authentication
Role-based dashboard access
Prometheus
Grafana
Distributed tracing
CloudWatch alarms
SNS notifications
Slack notifications
Incident history database
AI-powered remediation recommendations
AI-powered recovery policies
Multi-region deployment
Kubernetes deployment
EKS integration
Blue/Green deployment
Canary deployment
Advanced security scanning
Container vulnerability scanning
```

---

# 59. Useful Commands

Check API:

```bash
curl http://127.0.0.1:8000/health
```

Check Docker:

```bash
docker ps
```

Check API logs:

```bash
docker logs cloudforge-api
```

Follow API logs:

```bash
docker logs -f cloudforge-api
```

Inspect container:

```bash
docker inspect cloudforge-api
```

Check monitor:

```bash
sudo systemctl status cloudforge-monitor
```

Check status publisher:

```bash
sudo systemctl status cloudforge-status-publisher
```

View monitor logs:

```bash
sudo journalctl -u cloudforge-monitor -f
```

View runtime state:

```bash
cat /opt/cloudforge/runtime/status.json
```

List incidents:

```bash
ls -lah /opt/cloudforge/incidents
```

Check latest incident:

```bash
ls -t /opt/cloudforge/incidents/*.json | head -n 1
```

Check Git:

```bash
git status
```

Check Terraform:

```bash
cd terraform/environments/staging
terraform plan
```

---

# 60. Troubleshooting

## API is unhealthy

Check:

```bash
docker ps
```

Then:

```bash
docker logs cloudforge-api
```

Then:

```bash
curl http://127.0.0.1:8000/health
```

---

## Container is stopped

Check:

```bash
docker inspect cloudforge-api \
  --format '{{.State.Status}}'
```

Start:

```bash
docker start cloudforge-api
```

Then:

```bash
curl http://127.0.0.1:8000/health
```

---

## Monitor is not running

Check:

```bash
sudo systemctl status cloudforge-monitor
```

Start:

```bash
sudo systemctl start cloudforge-monitor
```

View logs:

```bash
sudo journalctl -u cloudforge-monitor -n 100
```

---

## AI analyzer fails

Check the virtual environment:

```bash
cd /opt/cloudforge
. .venv/bin/activate
```

Check Gemini dependency:

```bash
python -c "from google import genai; print('Gemini SDK OK')"
```

Check that the environment variable exists without printing the secret:

```bash
if [ -n "$GEMINI_API_KEY" ]; then
    echo "GEMINI_API_KEY is configured"
else
    echo "GEMINI_API_KEY is not configured"
fi
```

Never print the actual API key.

---

## Dashboard is not loading

Check:

```bash
docker ps --filter name=cloudforge-dashboard
```

Check logs:

```bash
docker logs cloudforge-dashboard
```

Test locally:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

Verify the AWS Security Group allows the required dashboard port only when appropriate.

---

# 61. Evidence Produced by CloudForge

The project produces operational evidence such as:

```text
Docker container state
Application health responses
Incident JSON records
Container logs
Host kernel logs
Recovery duration
Recovery status
AI incident analysis
CPU usage
Memory usage
Load-test results
Terraform plans
Jenkins deployment results
```

This evidence makes the project demonstrable rather than only theoretical.

---

# 62. Final Verification Checklist

Before considering the project complete:

```text
[ ] GitHub repository works
[ ] AWS CLI configured
[ ] Terraform initializes
[ ] terraform validate passes
[ ] terraform plan is understood
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
[ ] AWS resources stopped or destroyed after testing
```

---

# 63. CloudForge in One Sentence

> **CloudForge is a Terraform-managed AWS DevOps platform that deploys a Dockerized application through Jenkins and ECR, continuously monitors it, automatically recovers container failures, records incident evidence, analyzes incidents with Gemini AI, and visualizes the system through a live dashboard.**

---

# 64. Repository

GitHub:

```text
https://github.com/Savio9481/cloudforge
```

Main branch:

```text
main
```

---

# 65. Project Goal

The purpose of CloudForge is to demonstrate a complete practical DevOps workflow:

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
AI
      +
Dashboard
      +
Chaos Testing
      +
Performance Testing
```

The project can be expanded progressively into a more advanced production-style cloud platform.