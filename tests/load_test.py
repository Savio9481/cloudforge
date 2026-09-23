import concurrent.futures
import time
import urllib.request

URL = "http://10.1.1.130:8000/health"
TOTAL_REQUESTS = 5000
CONCURRENCY = 50


def request():
    start = time.perf_counter()

    try:
        with urllib.request.urlopen(URL, timeout=5) as response:
            response.read()
            return True, time.perf_counter() - start
    except Exception:
        return False, time.perf_counter() - start


start_time = time.perf_counter()

with concurrent.futures.ThreadPoolExecutor(
    max_workers=CONCURRENCY
) as executor:
    results = list(executor.map(lambda _: request(), range(TOTAL_REQUESTS)))

total_time = time.perf_counter() - start_time

successful = sum(success for success, _ in results)
failed = TOTAL_REQUESTS - successful

latencies = [latency for _, latency in results]

print("CloudForge Load Test")
print("--------------------")
print(f"URL: {URL}")
print(f"Total requests: {TOTAL_REQUESTS}")
print(f"Concurrency: {CONCURRENCY}")
print(f"Successful: {successful}")
print(f"Failed: {failed}")
print(f"Total time: {total_time:.2f} seconds")
print(f"Average response time: {sum(latencies) / len(latencies) * 1000:.2f} ms")
print(f"Requests/second: {TOTAL_REQUESTS / total_time:.2f}")
