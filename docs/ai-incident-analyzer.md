# CloudForge AI Incident Analyzer

CloudForge includes an AI-assisted incident analysis component that analyzes evidence collected during runtime failures.

The analyzer is designed to help answer:

- What happened?
- What evidence was collected?
- What is the likely cause?
- What was the impact?
- What recovery action was performed?
- Was recovery successful?
- What should be investigated next?

The AI analyzer is an **analysis and recommendation component**. It does not independently control infrastructure recovery.

---

# 1. Overview

The CloudForge incident workflow is:

```text
Application Failure
        |
        v
Health Check
        |
        v
Self-Healing
        |
        v
Evidence Collection
        |
        v
Incident JSON
        |
        v
AI Incident Analyzer
        |
        v
Gemini
        |
        v
AI Analysis Report
        |
        v
Dashboard
````

The important separation is:

```text
Self-Healing
    -> performs recovery

AI Analyzer
    -> analyzes the incident
```

The AI analyzer does not replace the deterministic recovery logic.

---

# 2. Why CloudForge Uses an AI Analyzer

Traditional monitoring can tell an engineer:

```text
Container stopped
Exit code: 137
Recovery successful
```

However, an engineer still needs to interpret the available evidence.

The AI analyzer provides a structured explanation based on the incident record.

For example, an incident can contain:

```text
Failure type
Exit code
OOMKilled status
Restart count
Container logs
Host kernel logs
Recovery action
Recovery duration
Recovery status
```

The analyzer turns this evidence into a readable incident report.

---

# 3. Current AI Architecture

The current architecture is:

```text
+---------------------+
| CloudForge Monitor  |
+----------+----------+
           |
           v
+---------------------+
| Self-Healing Script |
+----------+----------+
           |
           v
+---------------------+
| Incident JSON       |
+----------+----------+
           |
           v
+---------------------+
| AI Analyzer         |
| ai_analyzer.py      |
+----------+----------+
           |
           v
+---------------------+
| Google Gemini       |
+----------+----------+
           |
           v
+---------------------+
| AI Analysis TXT     |
+----------+----------+
           |
           v
+---------------------+
| CloudForge Dashboard|
+---------------------+
```

---

# 4. AI Provider

CloudForge uses the Google Gemini API for incident analysis.

The Python SDK used by the analyzer is:

```text
google-genai
```

The analyzer dependency is intentionally separate from the application dependencies.

This keeps the main CloudForge API container lightweight and avoids coupling the API runtime to the AI SDK.

---

# 5. AI Model

The working Gemini model used during development is:

```text
gemini-3.6-flash
```

The model is used for text-based incident analysis.

The model name should be treated as a configuration value because model availability and naming can change over time.

---

# 6. Dependency Separation

CloudForge separates application dependencies from analyzer dependencies.

Application dependencies:

```text
app/requirements.txt
```

Current application dependencies include:

```text
fastapi
uvicorn[standard]
psutil
pytest
httpx
```

Analyzer dependencies:

```text
analyzer/requirements.txt
```

Current analyzer dependency:

```text
google-genai
```

This separation prevents the Gemini SDK from being installed unnecessarily inside the API container.

---

# 7. Analyzer Directory

The current analyzer directory is:

```text
analyzer/
├── ai_analyzer.py
├── requirements.txt
└── run_analyzer.sh
```

The main components are:

```text
ai_analyzer.py
    |
    +--> Reads incident JSON
    |
    +--> Sends evidence to Gemini
    |
    +--> Receives analysis
    |
    +--> Writes AI report

run_analyzer.sh
    |
    +--> Finds latest incident
    |
    +--> Runs ai_analyzer.py
```

---

# 8. Python Virtual Environment

The analyzer uses a dedicated Python virtual environment.

Location:

```text
/opt/cloudforge/.venv
```

Create it with:

```bash
cd /opt/cloudforge
python3 -m venv .venv
```

Activate it in the SSM shell:

```bash
. /opt/cloudforge/.venv/bin/activate
```

The `.` form is intentional because an SSM session may start with `/bin/sh`, where:

```bash
source
```

may not be available.

---

# 9. Install Analyzer Dependencies

Install the analyzer dependencies using:

```bash
cd /opt/cloudforge
. /opt/cloudforge/.venv/bin/activate
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

---

# 10. API Key Security

The Gemini API key is stored as an environment variable.

It must not be:

```text
Committed to GitHub
Written into source code
Written into Jenkinsfile
Included in incident JSON
Included in dashboard responses
Printed in logs
```

The environment configuration is stored outside the Git repository.

The project uses:

```text
/etc/cloudforge/cloudforge.env
```

for persistent environment configuration on the staging host.

---

# 11. Environment Configuration

The environment configuration is loaded by the runtime environment.

The important principle is:

```text
Secret
   |
   v
Environment Variable
   |
   v
AI Analyzer
```

The secret should never become part of:

```text
Git history
Docker image
Incident record
AI report
Dashboard JSON
```

---

# 12. Never Expose the API Key

Do not run commands that print the complete key.

For example, avoid:

```bash
echo "$GEMINI_API_KEY"
```

Do not paste the key into:

```text
ChatGPT
GitHub
Jenkinsfile
README.md
Documentation
Screenshots
Incident files
```

Only verify that the environment variable exists without displaying its value.

---

# 13. AI Analyzer Input

The analyzer receives an incident JSON file.

Example:

```text
/opt/cloudforge/incidents/incident-2026-09-28-061731.json
```

The incident contains structured evidence.

The analyzer does not need direct access to Docker to perform the analysis.

Instead:

```text
Docker
   |
   v
Self-Healing
   |
   v
Incident JSON
   |
   v
AI Analyzer
```

This creates a clear evidence boundary.

---

# 14. Incident Evidence

The incident record can contain:

```text
incident_id
environment
application
version
failure_type
detected_at
recovery_action
recovered_at
recovery_duration_seconds
recovery_status
health_status
docker_evidence
host_evidence
```

Docker evidence can include:

```text
Container status
Exit code
OOMKilled
Restart count
Container logs
```

Host evidence can include:

```text
Kernel logs
```

---

# 15. Why the Incident JSON Is Important

The incident JSON acts as the evidence package for the AI analyzer.

Without a structured incident record, the AI would have incomplete context.

The flow is therefore:

```text
Raw Runtime State
       |
       v
Evidence Collection
       |
       v
Structured Incident
       |
       v
AI Analysis
```

This makes the analysis more reproducible.

---

# 16. AI Analyzer Usage

The analyzer is executed using:

```bash
python ai_analyzer.py <incident.json>
```

For example:

```bash
cd /opt/cloudforge
. /opt/cloudforge/.venv/bin/activate

python analyzer/ai_analyzer.py \
  incidents/incident-2026-09-28-061731.json
```

The analyzer reads the specified incident.

---

# 17. Analyzer Wrapper

CloudForge also provides:

```text
analyzer/run_analyzer.sh
```

The wrapper automatically finds the latest incident.

Its basic workflow is:

```text
Incident Directory
       |
       v
Find Latest JSON
       |
       v
ai_analyzer.py
       |
       v
AI Report
```

---

# 18. run_analyzer.sh

The current wrapper is:

```bash
#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INCIDENT_DIR="$PROJECT_ROOT/incidents"
ANALYZER="$PROJECT_ROOT/analyzer/ai_analyzer.py"
PYTHON="$PROJECT_ROOT/.venv/bin/python"

LATEST_INCIDENT=$(ls -t "$INCIDENT_DIR"/*.json 2>/dev/null | head -n 1)

if [ -z "$LATEST_INCIDENT" ]; then
    echo "No incident files found."
    exit 1
fi

echo "Latest incident:"
echo "$LATEST_INCIDENT"
echo

"$PYTHON" "$ANALYZER" "$LATEST_INCIDENT"
```

The important design decision is that the wrapper uses:

```text
/opt/cloudforge/.venv/bin/python
```

directly.

This avoids depending on the current shell's Python environment.

---

# 19. Why the Wrapper Uses the Virtual Environment Directly

A monitoring or systemd process may not have the same shell environment as an interactive SSM session.

Instead of relying on:

```bash
python
```

the wrapper uses:

```text
/opt/cloudforge/.venv/bin/python
```

This makes the analyzer more reliable when called automatically.

---

# 20. AI Analysis Prompt

The analyzer sends the incident evidence to Gemini with instructions to analyze the available evidence.

The requested sections are:

```text
1. What happened
2. Likely cause
3. Impact
4. Recovery performed
5. Recovery assessment
6. Recommended next actions
```

The analyzer also instructs the model to:

```text
Use only the provided incident data.
Distinguish confirmed evidence from assumptions.
Clearly state when the exact root cause cannot be determined.
```

---

# 21. Evidence-First Analysis

CloudForge follows an evidence-first approach.

The analyzer should reason from:

```text
Incident JSON
```

rather than inventing information about the environment.

For example:

```text
Observed:
exit_code = 137

Observed:
oom_killed = false

Observed:
container recovered after docker_start
```

These facts can be stated directly.

The exact reason for the termination may remain uncertain.

---

# 22. Root Cause vs Evidence

An important principle of CloudForge is:

```text
Evidence
   !=
Guaranteed Root Cause
```

For example:

```text
Exit code 137
```

indicates a process was terminated with signal `SIGKILL`.

However, that alone does not necessarily establish exactly what initiated the termination.

The analyzer therefore needs to distinguish:

```text
Confirmed
Possible
Unknown
```

---

# 23. Example: Exit Code 137

One verified CloudForge incident contained:

```text
Exit code: 137
OOMKilled: false
```

The incident also contained Docker and host evidence.

The AI analysis concluded that:

```text
The process was terminated with SIGKILL.
The Docker evidence did not confirm an OOM kill.
The exact root cause could not be conclusively determined from the available evidence.
```

The analysis recommended investigating:

```text
Docker events
Deployment activity
Host activity
Maintenance activity
External stop/kill operations
```

This is an example of why the AI analyzer should not automatically convert one signal into a definitive root cause.

---

# 24. Example: Graceful Container Stop

Another controlled test used:

```bash
docker stop cloudforge-api
```

The resulting incident showed:

```text
Exit code: 0
OOMKilled: false
```

The container logs showed a graceful shutdown.

CloudForge then restarted the container.

The application became healthy again.

The AI analysis identified the shutdown as orderly while noting that the evidence did not establish what initiated the shutdown.

This was an intentional chaos test rather than an unexplained production failure.

---

# 25. Current Latest Intentional Test

A documented intentional test produced:

```text
incident-2026-09-28-061731.json
```

Important evidence included:

```text
failure_type: container_stopped
exit_code: 0
oom_killed: false
recovery_status: successful
health_status: healthy
recovery_duration_seconds: 2
```

The container was intentionally stopped during the test.

The self-healing system restarted it successfully.

---

# 26. AI Report Output

The analyzer generates a text report next to the incident file.

For example:

```text
incident-2026-09-28-061731-ai.txt
```

The relationship is:

```text
incident-2026-09-28-061731.json
              |
              v
        AI Analyzer
              |
              v
incident-2026-09-28-061731-ai.txt
```

---

# 27. AI Report Purpose

The report provides an engineer-friendly explanation of the incident.

It is useful for:

```text
Incident review
Learning
Debugging
Documentation
Operational investigation
Portfolio demonstration
```

It should not be treated as a replacement for raw evidence.

The original incident JSON remains the authoritative evidence record.

---

# 28. Raw Evidence vs AI Analysis

CloudForge keeps both:

```text
Raw Evidence
     |
     +--> incident JSON
     |
     +--> Docker logs
     |
     +--> Host logs

AI Interpretation
     |
     +--> AI text report
```

This distinction is important.

The AI report explains the evidence.

It does not replace the evidence.

---

# 29. AI Analyzer Failure

If the Gemini API is unavailable, the self-healing recovery should not depend on the AI analyzer.

The recovery sequence is:

```text
Failure
   |
   v
Self-Healing
   |
   v
Container Recovery
   |
   v
Health Verification
   |
   v
Incident Record
   |
   v
AI Analysis
```

The incident record is created as part of the recovery workflow.

AI analysis is an additional diagnostic capability.

---

# 30. Why AI Is Not Used for Recovery

CloudForge deliberately keeps recovery deterministic.

The recovery action is defined by the self-healing logic.

For the current supported failure:

```text
Container failure
        |
        v
Restart container
```

The AI system is not allowed to arbitrarily execute infrastructure commands.

This reduces the risk of unpredictable automated changes.

---

# 31. AI Analyzer and Security

The analyzer receives operational information.

Therefore incident data should be reviewed before expanding the system to include sensitive information.

Do not intentionally send:

```text
Passwords
API keys
Private credentials
Access tokens
Sensitive customer information
```

to the AI service.

The current incident data is designed around infrastructure and container evidence.

---

# 32. AI Analyzer and Privacy

The incident analyzer should follow the principle:

```text
Minimum required evidence
```

Only information needed to understand the incident should be included.

This reduces unnecessary exposure of operational data.

---

# 33. AI Analyzer and Dashboard

The dashboard displays the latest AI analysis.

The dashboard API includes:

```text
/api/dashboard
```

The response can contain:

```text
latest_incident
latest_ai_analysis
```

The architecture is:

```text
Incident JSON
      |
      +--------------------+
      |                    |
      v                    v
AI Analyzer           Dashboard
      |                    |
      v                    |
AI Report -----------------+
```

---

# 34. Dashboard AI Section

The dashboard can display information such as:

```text
Latest incident
Failure type
Recovery duration
Recovery status
AI analysis
Recommended next actions
```

This allows an engineer to understand the latest incident without opening the server shell.

---

# 35. AI Analyzer Testing

The analyzer can be tested independently from the monitoring loop.

First identify an incident:

```bash
ls -lt /opt/cloudforge/incidents/*.json
```

Then run:

```bash
cd /opt/cloudforge
. /opt/cloudforge/.venv/bin/activate

python analyzer/ai_analyzer.py \
  /opt/cloudforge/incidents/<incident-file>.json
```

Verify that an AI report is generated:

```bash
ls -lt /opt/cloudforge/incidents/*-ai.txt
```

---

# 36. Verify Analyzer Dependencies

Run:

```bash
cd /opt/cloudforge
. /opt/cloudforge/.venv/bin/activate

python -c "from google import genai; print('Analyzer dependencies OK')"
```

Expected:

```text
Analyzer dependencies OK
```

---

# 37. Verify the Analyzer Script

Run:

```bash
cd /opt/cloudforge

./analyzer/run_analyzer.sh
```

Expected behavior:

```text
Latest incident:
<incident-file>

AI analysis generated
```

The exact output depends on the analyzer implementation and API response.

---

# 38. Common Analyzer Problems

## Problem: Python module not found

Example:

```text
ModuleNotFoundError: No module named 'google'
```

Solution:

```bash
cd /opt/cloudforge
. /opt/cloudforge/.venv/bin/activate
python -m pip install -r analyzer/requirements.txt
```

---

# 39. Problem: Virtual Environment Not Active

If:

```bash
source /opt/cloudforge/.venv/bin/activate
```

fails in an SSM shell, use:

```bash
. /opt/cloudforge/.venv/bin/activate
```

This works with the shell environment commonly used by the SSM session.

---

# 40. Problem: No Incident Files

If the wrapper reports:

```text
No incident files found.
```

check:

```bash
ls -lt /opt/cloudforge/incidents/
```

The analyzer requires an incident JSON file as input.

---

# 41. Problem: AI API Configuration

If the analyzer cannot authenticate with Gemini, verify that the required environment variable is available to the process.

Do not print the secret.

Instead, verify only that the variable exists:

```bash
if [ -n "$GEMINI_API_KEY" ]; then
    echo "Gemini API key is configured"
else
    echo "Gemini API key is not configured"
fi
```

This does not reveal the key.

---

# 42. Problem: AI API Failure

If Gemini is temporarily unavailable:

```text
Self-Healing
     |
     v
Container Recovery
     |
     v
Successful
     |
     v
Incident Saved
     |
     v
AI Analysis
     |
     v
API Failure
```

The incident record should remain available for later analysis.

The AI component should not be treated as the mechanism responsible for application recovery.

---

# 43. Analyzer Dependency Verification

The project previously verified:

```text
google-genai
```

was installed successfully.

The verification command:

```bash
./.venv/bin/python -c \
"from google import genai; print('Analyzer dependencies OK')"
```

returned:

```text
Analyzer dependencies OK
```

---

# 44. Project Dependency Structure

The final dependency structure is:

```text
CloudForge
|
+-- app/
|    |
|    +-- FastAPI
|    +-- Uvicorn
|    +-- psutil
|    +-- pytest
|    +-- httpx
|
+-- analyzer/
     |
     +-- google-genai
```

This keeps AI-specific dependencies separate from the application container.

---

# 45. AI Analyzer Execution Model

The analyzer can be triggered after self-healing:

```text
Monitor
   |
   v
Self-Healing
   |
   v
Incident JSON
   |
   v
run_analyzer.sh
   |
   v
ai_analyzer.py
   |
   v
Gemini
   |
   v
AI Report
```

It can also be executed manually for testing.

---

# 46. Current AI Role

The current AI analyzer is responsible for:

```text
Incident interpretation
Evidence summarization
Likely-cause discussion
Impact explanation
Recovery assessment
Recommended investigation steps
```

It is not responsible for:

```text
Container restart
EC2 replacement
Security-group modification
Terraform changes
Automatic rollback
Infrastructure provisioning
```

---

# 47. Current AI Safety Boundary

CloudForge uses the following boundary:

```text
                 +----------------------+
                 |   Deterministic      |
                 |   Recovery Logic     |
                 +----------+-----------+
                            |
                            v
                     Runtime Recovery

                 +----------------------+
                 |      AI Analyzer     |
                 +----------+-----------+
                            |
                            v
                    Human-readable
                     interpretation
```

The AI can explain and recommend.

The deterministic system performs the current recovery.

---

# 48. Human Review

AI-generated analysis should be reviewed by an engineer before making consequential infrastructure changes.

For example:

```text
AI recommendation
       |
       v
Engineer reviews evidence
       |
       v
Engineer determines action
```

The AI report is therefore an operational assistant rather than an autonomous infrastructure controller.

---

# 49. Recommended Incident Investigation Flow

When an incident occurs:

```text
1. Check incident JSON
2. Check Docker evidence
3. Check host evidence
4. Check recovery result
5. Read AI analysis
6. Compare AI analysis with raw evidence
7. Investigate uncertain areas
8. Apply corrective action if required
```

This keeps the investigation evidence-driven.

---

# 50. Example Investigation

Suppose the incident contains:

```text
failure_type: container_stopped
exit_code: 137
oom_killed: false
recovery_status: successful
recovery_duration_seconds: 3
```

The correct interpretation is:

```text
Confirmed:
The container stopped.
The process exited with code 137.
Docker did not report OOMKilled.
The container was restarted successfully.
Recovery took approximately 3 seconds.
```

Potential explanation:

```text
The process may have received SIGKILL.
```

Unconfirmed:

```text
The exact actor or event that initiated the SIGKILL.
```

The next investigation should focus on additional host and Docker evidence.

---

# 51. Why This Design Is Useful

The AI analyzer demonstrates a practical DevOps/SRE workflow:

```text
Monitoring
    +
Automation
    +
Evidence Collection
    +
AI Assistance
    =
Incident Response Workflow
```

The AI component is therefore integrated into the operational workflow rather than being an unrelated chatbot feature.

---

# 52. Reproducibility

The analyzer source is stored in Git:

```text
analyzer/
├── ai_analyzer.py
├── requirements.txt
└── run_analyzer.sh
```

A fresh CloudForge environment can recreate the analyzer dependencies using:

```bash
cd /opt/cloudforge
python3 -m venv .venv
. /opt/cloudforge/.venv/bin/activate
python -m pip install -r analyzer/requirements.txt
```

The secret itself must be configured separately.

Secrets are intentionally not stored in the repository.

---

# 53. Git Repository Contents

The analyzer-related source-controlled files are:

```text
analyzer/ai_analyzer.py
analyzer/requirements.txt
analyzer/run_analyzer.sh
```

Incident output files are runtime artifacts and should not be committed.

The repository `.gitignore` excludes local runtime artifacts such as:

```text
.venv/
runtime/
```

and incident-related generated files.

---

# 54. Runtime vs Source Code

CloudForge separates:

```text
Source Code
    |
    +--> GitHub

Runtime Data
    |
    +--> incidents/
    +--> runtime/
    +--> AI reports
```

This prevents generated incident data from becoming part of the application source tree.

---

# 55. Current Verified AI Workflow

The verified workflow is:

```text
Controlled Failure
       |
       v
Health Check Failure
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
Gemini Analyzer
       |
       v
AI Analysis
       |
       v
Dashboard
```

This workflow has been exercised using controlled container failures.

---

# 56. Current Limitations

The current AI analyzer has several limitations.

It does not guarantee:

```text
Exact root-cause identification
Complete infrastructure visibility
Complete historical correlation
Automatic infrastructure remediation
Perfect interpretation of ambiguous evidence
```

The quality of the analysis depends on the evidence provided to the model.

---

# 57. Future Enhancements

Potential future improvements include:

```text
Incident classification
Historical incident comparison
Failure pattern detection
Incident severity estimation
Log correlation
CloudWatch evidence correlation
Docker event correlation
AWS event correlation
Deployment correlation
Suggested remediation policies
Human approval workflow
```

These are future enhancements and should not be represented as currently implemented capabilities.

---

# 58. Future Policy Engine

A future architecture could connect AI recommendations to a controlled policy engine:

```text
Incident
   |
   v
Evidence
   |
   v
AI Analysis
   |
   v
Recommendation
   |
   v
Policy Engine
   |
   +---- Approved ----> Remediation
   |
   +---- Rejected ---> Human Review
```

This would provide a safer path toward more automated remediation.

---

# 59. Future Historical Analysis

A future version could analyze multiple incidents:

```text
Incident 1
Incident 2
Incident 3
Incident 4
     |
     v
Historical Analysis
     |
     v
Repeated Failure Pattern
```

This could help identify recurring infrastructure or deployment problems.

This capability is not currently implemented.

---

# 60. AI Analyzer Verification Checklist

Verify the following:

```text
[ ] analyzer/ai_analyzer.py exists
[ ] analyzer/requirements.txt exists
[ ] analyzer/run_analyzer.sh exists
[ ] Python virtual environment exists
[ ] google-genai is installed
[ ] Gemini environment variable is configured
[ ] Incident JSON exists
[ ] Analyzer can read the incident
[ ] Gemini analysis is returned
[ ] AI report is generated
[ ] API key is not printed
[ ] API key is not committed
[ ] Dashboard can display AI analysis
```

---

# 61. Quick Verification Commands

Check analyzer files:

```bash
ls -la /opt/cloudforge/analyzer/
```

Check virtual environment:

```bash
ls -la /opt/cloudforge/.venv/bin/python
```

Check dependency:

```bash
/opt/cloudforge/.venv/bin/python \
  -c "from google import genai; print('Analyzer dependencies OK')"
```

Check incidents:

```bash
ls -lt /opt/cloudforge/incidents/
```

Run analyzer:

```bash
cd /opt/cloudforge
./analyzer/run_analyzer.sh
```

Check AI reports:

```bash
ls -lt /opt/cloudforge/incidents/*-ai.txt
```

---

# 62. End-to-End Example

A complete incident lifecycle looks like:

```text
                     APPLICATION
                          |
                          v
                    Health Check
                          |
                     Failure
                          |
                          v
                 +----------------+
                 | Self-Healing   |
                 +-------+--------+
                         |
              +----------+----------+
              |                     |
              v                     v
       Docker Evidence       Host Evidence
              |                     |
              +----------+----------+
                         |
                         v
                  Container Restart
                         |
                         v
                  Health Verification
                         |
                    +----+----+
                    |         |
                  Success   Failure
                    |         |
                    v         v
              Incident JSON  Recovery
                    |        Failed
                    v
              AI Analyzer
                    |
                    v
                 Gemini
                    |
                    v
              AI Report
                    |
                    v
                Dashboard
```

---

# 63. Final Architecture

The final implemented AI incident analysis architecture is:

```text
+----------------------------------------------------------+
|                    CloudForge EC2                        |
|                                                          |
|  +-------------------+                                   |
|  | CloudForge API    |                                   |
|  |      :8000        |                                   |
|  +---------+---------+                                   |
|            |                                              |
|            v                                              |
|  +-------------------+                                   |
|  | Health Monitoring |                                   |
|  +---------+---------+                                   |
|            |                                              |
|            v                                              |
|  +-------------------+                                   |
|  | Self-Healing      |                                   |
|  +---------+---------+                                   |
|            |                                              |
|            v                                              |
|  +-------------------+                                   |
|  | Incident JSON     |                                   |
|  +---------+---------+                                   |
|            |                                              |
|            v                                              |
|  +-------------------+                                   |
|  | AI Analyzer       |                                   |
|  +---------+---------+                                   |
|            |                                              |
+------------|----------------------------------------------+
             |
             v
      +--------------+
      | Google Gemini|
      +------+-------+
             |
             v
      +--------------+
      | AI Report    |
      +------+-------+
             |
             v
      +--------------+
      | Dashboard    |
      +--------------+
```

---

# 64. Final Summary

CloudForge's AI Incident Analyzer adds an AI-assisted investigation layer to the self-healing system.

The complete workflow is:

```text
Detect
  ↓
Collect Evidence
  ↓
Recover
  ↓
Verify
  ↓
Create Incident
  ↓
Analyze With AI
  ↓
Generate Report
  ↓
Display In Dashboard
```

The most important architectural separation is:

```text
Self-Healing
    = deterministic runtime recovery

AI Analyzer
    = evidence-based incident analysis
```

The AI analyzer does not independently restart containers or modify AWS infrastructure.

This keeps the recovery mechanism predictable while still using AI to make incident evidence easier to understand.

CloudForge therefore demonstrates the combination of:

```text
AWS
Docker
Linux
Python
FastAPI
Jenkins
Amazon ECR
AWS Systems Manager
Runtime Monitoring
Self-Healing
Incident Evidence
Google Gemini
AI-Assisted Incident Analysis
Operational Dashboard
Chaos Testing
```

The current implementation focuses on container-level recovery and AI-assisted analysis, while broader autonomous remediation remains a future extension.

```
```
