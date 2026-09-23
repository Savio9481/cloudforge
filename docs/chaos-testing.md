# CloudForge Chaos Testing

## Purpose

CloudForge was tested by intentionally creating controlled failures in the staging environment.

The goal was to verify:

- Failure detection
- Automatic recovery
- Health verification
- Recovery limitations

## Test 1 — Container Stop

Failure:

docker stop cloudforge-api

Result:

- CloudForge detected the failed health check.
- Self-healing restarted the container.
- Application became healthy again.
- Incident record was created.

Recovery time: approximately 2 seconds after failure detection.

Result: PASS

## Test 2 — Container Force Kill

Failure:

docker kill cloudforge-api

Result:

- Container was forcefully terminated.
- CloudForge detected the failure.
- Self-healing restarted the container.
- Application became healthy again.
- Incident record was created.

Incident:

incident-2026-09-23-075737

Recovery time: 2 seconds.

Result: PASS

## Test 3 — Network Failure

Failure:

sudo iptables -I INPUT -p tcp --dport 8000 -j REJECT

Result:

- CloudForge detected the health-check failure.
- Self-healing attempted to restart the container.
- Recovery continued to fail because the firewall was still blocking port 8000.
- Removing the firewall rule restored application health.

Result: DETECTED — RECOVERY LIMITATION IDENTIFIED

## Current Self-Healing Boundary

CloudForge currently handles failures that can be fixed by restarting the application container.

Network-level failures require a different recovery action.

This limitation will be considered when building the future CloudForge policy engine and AI incident analyzer.
