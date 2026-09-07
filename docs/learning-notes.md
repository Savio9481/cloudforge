# CloudForge Learning Notes

## Day 1

### What is CloudForge?

CloudForge is a self-healing AWS DevOps/SRE platform
that closes the loop between deployment, monitoring,
incident detection, analysis, recovery, and verification.

### What I want to learn

- AWS infrastructure
- Terraform
- Jenkins
- Docker
- AWS networking
- Observability
- CI/CD
- SRE
- Chaos engineering
- AIOps
- DevSecOps

### Important principle

I am not building this only to deploy an application.

I am building it to understand how a production system
can detect failures, respond to them, recover, and prove
that recovery worked.

# Step 3 — Application & Containerization

## What I built

Created a FastAPI application for CloudForge.

The application provides:

- `/`
- `/health`
- `/version`
- `/metrics`

## Why `/health` matters

The health endpoint will later be used by:

- Load Balancer health checks
- Jenkins deployment validation
- Self-healing mechanisms
- Rollback validation

## Why `/version` matters

CloudForge needs to know which application version is
currently deployed so that deployments and rollbacks can
be verified.

## Why `/metrics` matters

The application exposes CPU and memory information that
will later be correlated with infrastructure monitoring.

## Docker

The application was packaged into a Docker image.

Image:

cloudforge-api:1.0.0

## Failure experiment

Stopped the application container manually.

Result:

Application became unreachable.

Restarted the container.

Result:

Application recovered successfully.

## Important lesson

A container running successfully does not mean the overall
system is healthy.

We need:

Application
→ Health checks
→ Monitoring
→ Detection
→ Recovery


# Step 4 — Docker Reliability

## Docker Health Checks

A running container does not necessarily mean that the
application inside the container is healthy.

CloudForge uses an application health endpoint:

/health

Docker periodically checks this endpoint.

## Resource Limits

The CloudForge container was tested with CPU and memory
limits.

Example:

CPU: 0.5
Memory: 256 MB

Resource limits are important for controlled failure and
stress experiments.

## Container Logs

Application logs can be inspected using:

docker logs

These logs will eventually become an input to CloudForge's
incident analysis system.

## Failure Experiment

The CloudForge container was intentionally stopped/killed.

Result:

Application became unavailable.

The container was then restarted.

Result:

Application recovered.

## Important Lesson

Docker provides basic container-level reliability features,
but CloudForge will eventually operate at a higher level:

Detect → Analyze → Decide → Recover → Verify

## Key Concepts Learned

- Docker image
- Docker container
- Docker health check
- Environment variables
- Container logs
- Resource limits
- Docker restart policies