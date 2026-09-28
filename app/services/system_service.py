import socket
from datetime import datetime, timezone

import psutil


def get_system_metrics():
    memory = psutil.virtual_memory()

    return {
        "cpu_percent": psutil.cpu_percent(interval=0.2),
        "memory_percent": memory.percent,
        "memory_used_mb": round(memory.used / 1024 / 1024, 2),
        "memory_total_mb": round(memory.total / 1024 / 1024, 2),
        "hostname": socket.gethostname(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
