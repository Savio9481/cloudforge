# CloudForge Load Testing

## Objective

Measure the baseline performance and behavior of the CloudForge API under controlled concurrent load.

The tests were performed against the `/health` endpoint using Python's built-in HTTP client and thread pool.

## Test Environment

- Environment: Staging
- Application: `cloudforge-api`
- Instance: AWS EC2 `m7i-flex.large`
- Endpoint: `/health`
- Application port: `8000`
- Test client: Python 3
- Initial tests: localhost (`127.0.0.1`)
- Network tests: EC2 private IP (`10.1.1.130`)

## Test Results

### Localhost Tests

| Requests | Concurrency | Successful | Failed | Avg Response | Requests/sec |
|---:|---:|---:|---:|---:|---:|
| 100 | 5 | 100 | 0 | 6.95 ms | 701.67 |
| 1,000 | 10 | 1,000 | 0 | 8.03 ms | 1,227.26 |
| 2,000 | 20 | 2,000 | 0 | 18.15 ms | 1,084.21 |
| 5,000 | 50 | 5,000 | 0 | 41.11 ms | 1,181.92 |

### EC2 Private-IP Tests

| Requests | Concurrency | Successful | Failed | Avg Response | Requests/sec |
|---:|---:|---:|---:|---:|---:|
| 100 | 5 | 100 | 0 | 6.30 ms | 775.35 |
| 2,000 | 20 | 2,000 | 0 | 13.36 ms | 1,466.52 |
| 5,000 | 50 | 5,000 | 0 | 33.56 ms | 1,448.67 |

## Resource Observation

After the 5,000-request / 50-concurrency private-IP test:

- Container CPU usage: 0.25%
- Container memory usage: 59.53 MiB
- Container memory usage: 0.77% of available limit
- Container processes: 6
- No CPU or memory exhaustion was observed.

## Findings

- All tested requests completed successfully.
- No HTTP request failures were observed during the tests.
- Response latency increased as concurrency increased.
- Throughput remained around 1,400 requests/sec during the higher-load private-IP tests.
- The container did not show significant CPU or memory consumption.

## Limitations

These tests target the lightweight `/health` endpoint and therefore do not represent the maximum capacity of the complete application.

The tests were also executed from the staging EC2 instance itself. They do not measure internet-facing latency, load-balancer performance, database performance, or behavior under realistic application workloads.

The measured requests/sec values should therefore be treated as controlled benchmark results rather than production capacity guarantees.

## Conclusion

CloudForge staging successfully handled a controlled load of 5,000 requests at 50 concurrent requests with zero request failures.

The test provides a baseline for future performance testing and can be extended later with realistic API workloads, external clients, ALB testing, database operations, and larger-scale distributed load generation.
