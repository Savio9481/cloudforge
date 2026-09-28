# CloudForge Cleanup and Cost Control Guide

This document explains how to safely stop, restart, and destroy CloudForge AWS resources.

CloudForge is a learning and portfolio project, so resources should not remain running when they are not being used.

---

# 1. Why Cleanup Is Important

CloudForge uses AWS resources such as:

- EC2
- EBS volumes
- VPC resources
- CloudWatch Logs
- IAM resources
- ECR
- Security Groups
- Networking resources

Some AWS resources can continue generating charges even when an EC2 instance is stopped.

Therefore, there are two different cleanup strategies:

```text
Temporary Pause
      ↓
Stop EC2
      ↓
Keep infrastructure
      ↓
Resume later
````

and:

```text
Permanent Cleanup
      ↓
Terraform Destroy
      ↓
Remove infrastructure
```

---

# 2. Three CloudForge States

CloudForge can be considered in three operational states.

## State 1 — Running

Used while actively developing or testing.

```text
EC2: Running
Docker: Running
Jenkins: Running
Dashboard: Running
```

This state can generate AWS usage charges.

---

## State 2 — Paused

Used when development is temporarily stopped.

```text
EC2: Stopped
Infrastructure: Retained
Terraform State: Retained
```

This reduces compute usage but does not necessarily eliminate all AWS charges.

---

## State 3 — Destroyed

Used when the project is finished or the infrastructure is no longer required.

```text
Terraform destroy
       ↓
AWS resources removed
```

This provides the strongest cleanup of Terraform-managed infrastructure.

---

# 3. Temporary Pause

If you plan to continue CloudForge later, stop the EC2 instance instead of destroying the infrastructure.

For staging:

```powershell
aws ec2 stop-instances `
  --instance-ids i-0298adbb36bf49d4c
```

Verify:

```powershell
aws ec2 describe-instances `
  --instance-ids i-0298adbb36bf49d4c `
  --query "Reservations[0].Instances[0].State.Name" `
  --output text
```

Expected:

```text
stopped
```

---

# 4. What Happens When EC2 Is Stopped

When the EC2 instance is stopped:

```text
EC2 compute
    ↓
Stopped
```

Docker containers stop because the underlying operating system is no longer running.

The EBS root volume normally remains attached to the stopped instance.

Therefore:

```text
Stopped EC2
≠
No AWS costs at all
```

Storage and other retained services may still incur charges.

---

# 5. Start CloudForge Again

When you want to continue the project:

```powershell
aws ec2 start-instances `
  --instance-ids i-0298adbb36bf49d4c
```

Check the state:

```powershell
aws ec2 describe-instances `
  --instance-ids i-0298adbb36bf49d4c `
  --query "Reservations[0].Instances[0].State.Name" `
  --output text
```

Wait until:

```text
running
```

---

# 6. Public IP Can Change

The staging EC2 instance uses a public IP.

When the instance is stopped and started, its public IP may change.

Therefore, after restarting:

```powershell
aws ec2 describe-instances `
  --instance-ids i-0298adbb36bf49d4c `
  --query "Reservations[0].Instances[0].PublicIpAddress" `
  --output text
```

Use the new IP when opening the dashboard.

Example:

```text
http://<NEW-PUBLIC-IP>:8080/dashboard/
```

---

# 7. Connect Through SSM

After the EC2 instance is running:

```bash
aws ssm start-session --target i-0298adbb36bf49d4c
```

Then:

```bash
sudo su - ssm-user
```

Move to the project:

```bash
cd /opt/cloudforge
```

---

# 8. Verify Docker

Run:

```bash
docker ps
```

Check the API:

```bash
docker ps --filter name=cloudforge-api
```

Check the dashboard:

```bash
docker ps --filter name=cloudforge-dashboard
```

---

# 9. Verify API Health

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

# 10. Verify Dashboard

Run:

```bash
curl -I http://127.0.0.1:8080/dashboard/
```

Expected:

```text
HTTP/1.1 200 OK
```

Then open:

```text
http://<EC2-PUBLIC-IP>:8080/dashboard/
```

---

# 11. Verify Self-Healing

Check the monitor:

```bash
sudo systemctl status cloudforge-monitor.service
```

Check the status publisher:

```bash
sudo systemctl status cloudforge-status-publisher.service
```

Both should be active when the staging environment is running.

---

# 12. Verify Runtime Status

Run:

```bash
cat /opt/cloudforge/runtime/status.json
```

The API should show:

```json
{
  "status": "running",
  "running": true,
  "health": "healthy"
}
```

The exact image, timestamp, and restart count depend on the current deployment.

---

# 13. Check Terraform Before Destroying

Before destroying anything, go to:

```text
terraform/environments/staging
```

Then run:

```powershell
terraform plan
```

The purpose is to understand what Terraform currently manages.

Do not run `terraform destroy` without reviewing the planned resources.

---

# 14. Terraform Destroy

When the CloudForge infrastructure is no longer required:

```powershell
terraform destroy
```

Terraform will display a destruction plan.

You will be asked to confirm.

Only type:

```text
yes
```

if you are certain that the staging infrastructure should be deleted.

---

# 15. What Terraform Destroy Removes

Terraform destroys resources that are managed by the staging Terraform configuration.

Depending on the current configuration, this can include:

```text
VPC
Subnets
Internet Gateway
Route Tables
Security Groups
EC2
IAM role
IAM instance profile
CloudWatch log group
Other Terraform-managed resources
```

The exact resources should always be confirmed using:

```powershell
terraform plan -destroy
```

before destruction.

---

# 16. Preview Destroy

A safer approach is:

```powershell
terraform plan -destroy
```

This shows what Terraform intends to remove without actually destroying anything.

Review the result carefully.

Then:

```powershell
terraform destroy
```

---

# 17. Important: Terraform State

Terraform uses its state to understand which AWS resources belong to the configuration.

Do not manually delete Terraform-managed resources unless there is a specific reason.

Prefer:

```text
Terraform
   ↓
Plan
   ↓
Destroy
```

This keeps the Terraform state consistent with AWS.

---

# 18. Verify After Destroy

After:

```powershell
terraform destroy
```

run:

```powershell
terraform plan
```

The expected result should indicate that there is no infrastructure requiring creation/change according to the current configuration.

You can also check AWS directly.

---

# 19. Verify EC2

Run:

```powershell
aws ec2 describe-instances `
  --instance-ids i-0298adbb36bf49d4c `
  --query "Reservations[0].Instances[0].State.Name" `
  --output text
```

If the instance was destroyed, the instance ID will no longer represent an existing instance.

---

# 20. Verify VPC

Check the staging VPC:

```powershell
aws ec2 describe-vpcs `
  --vpc-ids vpc-09d7693fbd9d55e5f
```

If Terraform destroyed the VPC, this should no longer return the staging VPC as an existing resource.

---

# 21. ECR Cleanup

ECR images may not necessarily be removed simply because the EC2 instance is destroyed.

Check the repository:

```powershell
aws ecr describe-repositories `
  --repository-names cloudforge-api `
  --region us-east-1
```

If the ECR repository is Terraform-managed and included in the destroy plan, Terraform will handle it.

If it is intentionally retained, clean it separately when appropriate.

---

# 22. ECR Image Cleanup

If you need to remove unused ECR images manually:

```powershell
aws ecr list-images `
  --repository-name cloudforge-api `
  --region us-east-1
```

Review the images before deleting anything.

Do not delete an image that is still required for a deployment or rollback.

---

# 23. CloudWatch Logs

CloudForge uses:

```text
/cloudforge/staging
```

for CloudWatch logs.

Check the log group:

```powershell
aws logs describe-log-groups `
  --log-group-name-prefix /cloudforge/staging `
  --region us-east-1
```

If Terraform manages the log group, verify whether it is included in the destroy plan.

---

# 24. IAM Resources

CloudForge creates IAM resources for EC2/SSM functionality.

Examples include:

```text
cloudforge-staging-ec2-role
cloudforge-staging-ec2-profile
```

Do not manually delete these while Terraform still manages them.

Allow Terraform to remove them during the appropriate destroy operation.

---

# 25. Security Groups

The staging security group is:

```text
cloudforge-staging-sg
```

Example ID:

```text
sg-0efe6755ba28f8279
```

Terraform should remove it after dependent resources have been removed.

---

# 26. Network Resources

The staging environment contains resources such as:

```text
VPC
Subnet
Internet Gateway
Route Table
Route Association
Security Group
```

Terraform manages these resources through the network module.

The correct cleanup order is handled by Terraform's dependency graph.

---

# 27. Do Not Manually Delete Random Dependencies

Avoid manually deleting:

```text
VPC
Subnet
Internet Gateway
Security Group
IAM role
```

one by one unless you have a specific recovery reason.

Manual deletion can cause:

```text
Terraform state mismatch
Dependency errors
Orphaned resources
```

Prefer Terraform for Terraform-managed infrastructure.

---

# 28. Development EC2

CloudForge also uses a development EC2 environment for tools such as Jenkins.

Before destroying the development environment, verify whether Jenkins or any other required project resources are still needed.

Check:

```powershell
aws ec2 describe-instances `
  --query "Reservations[].Instances[].{Id:InstanceId,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}" `
  --output table
```

---

# 29. Jenkins Cleanup

If Jenkins is no longer required:

```text
Stop/destroy Jenkins EC2
        ↓
Remove unused EBS
        ↓
Remove unused Jenkins resources
```

Do not destroy Jenkins if it is still needed for CloudForge CI/CD testing.

---

# 30. Cost-Safe Workflow

For a short development session:

```text
Start EC2
   ↓
Develop/Test
   ↓
Run Chaos Tests
   ↓
Run Load Tests
   ↓
Capture Evidence
   ↓
Stop EC2
```

When the project is completely finished:

```text
Review Terraform
      ↓
terraform plan -destroy
      ↓
Review resources
      ↓
terraform destroy
      ↓
Verify AWS
```

---

# 31. Recommended Session Workflow

When actively working on CloudForge:

```text
1. Start EC2
2. Wait for running state
3. Verify SSM
4. Connect
5. Verify Docker
6. Work on project
7. Run tests
8. Capture evidence
9. Stop EC2 when finished
```

This avoids leaving the instance running unnecessarily.

---

# 32. Before Stopping EC2

Before stopping the instance, make sure important work is stored in GitHub.

Check:

```powershell
git status
```

Then:

```powershell
git add .
git commit -m "Describe changes"
git push origin main
```

Do not commit secrets.

---

# 33. Before Terraform Destroy

Make sure:

```text
[ ] Important code pushed to GitHub
[ ] Documentation pushed
[ ] Test results saved
[ ] Screenshots captured
[ ] Dashboard screenshots captured
[ ] Chaos test evidence saved
[ ] Load test results saved
[ ] Jenkins evidence saved
[ ] AI analyzer evidence saved
[ ] No required AWS resource remains
```

---

# 34. Preserve Project Evidence

Before destroying the infrastructure, preserve evidence such as:

```text
GitHub commits
Terraform plan
Terraform apply output
Terraform destroy output
Docker images/tags
Jenkins build logs
Chaos test results
Load test results
AI incident reports
Dashboard screenshots
CloudWatch evidence
```

This is particularly useful for a portfolio project.

---

# 35. Useful AWS Cost Checks

Before and after cleanup, review AWS billing.

Check:

```text
Billing
Cost Explorer
Bills
Credits
```

Pay attention to services that may continue generating charges.

Typical areas to review include:

```text
EC2
EBS
ECR
CloudWatch
Elastic IP
Other AWS services
```

---

# 36. Stopped EC2 Is Not Complete Cleanup

Remember:

```text
EC2 stopped
     ↓
Compute usage reduced
     ↓
Storage/resources may remain
```

Therefore:

```text
Temporary pause → Stop
Permanent completion → Destroy
```

---

# 37. CloudForge Restart Lifecycle

After a temporary pause:

```text
Stopped
   ↓
Start EC2
   ↓
Wait for running
   ↓
SSM online
   ↓
Docker starts
   ↓
Services start
   ↓
Health check
   ↓
Dashboard
   ↓
Development continues
```

---

# 38. CloudForge Final Shutdown Lifecycle

When the project is finished:

```text
Stop development
       ↓
Push Git changes
       ↓
Save evidence
       ↓
Review Terraform
       ↓
terraform plan -destroy
       ↓
Review resources
       ↓
terraform destroy
       ↓
Verify AWS
       ↓
Review Billing
```

---

# 39. Emergency Cost-Control Step

If you realize an EC2 instance is running unnecessarily, stop it immediately.

Example:

```powershell
aws ec2 stop-instances `
  --instance-ids <INSTANCE-ID>
```

Then verify:

```powershell
aws ec2 describe-instances `
  --instance-ids <INSTANCE-ID> `
  --query "Reservations[0].Instances[0].State.Name" `
  --output text
```

Expected:

```text
stopped
```

This is preferable to leaving an unused instance running while investigating the project.

---

# 40. Cleanup Checklist

## Temporary Pause

```text
[ ] Push code
[ ] Save evidence
[ ] Stop EC2
[ ] Verify stopped state
[ ] Review billing
```

## Resume

```text
[ ] Start EC2
[ ] Verify running state
[ ] Verify SSM
[ ] Verify Docker
[ ] Verify API
[ ] Verify dashboard
[ ] Continue development
```

## Permanent Cleanup

```text
[ ] Push all code
[ ] Save documentation
[ ] Save screenshots
[ ] Save test results
[ ] Run terraform plan -destroy
[ ] Review resources
[ ] Run terraform destroy
[ ] Verify AWS resources
[ ] Review ECR
[ ] Review CloudWatch
[ ] Review Billing
```

---

# 41. Final Principle

CloudForge should follow this lifecycle:

```text
                DEVELOPMENT
                     |
                     v
                 TESTING
                     |
                     v
               DEMONSTRATION
                     |
                     v
              EVIDENCE CAPTURE
                     |
          +----------+----------+
          |                     |
          v                     v
       Continue               Finish
          |                     |
          v                     v
    Stop EC2                 Destroy
          |                     |
          v                     v
       Resume                Verify
```

The important distinction is:

```text
STOP = pause the environment

DESTROY = remove the infrastructure
```

Always review the Terraform plan before destroying resources.


