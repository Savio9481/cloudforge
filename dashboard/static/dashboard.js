const telemetry = {
    cpu: [],
    memory: [],
    maxPoints: 20
};

function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
}

function setGauge(elementId, value, color) {
    const gauge = document.getElementById(elementId);
    const degrees = clamp(value, 0, 100) * 3.6;

    gauge.style.background =
        `conic-gradient(${color} 0deg ${degrees}deg, rgba(148,163,184,0.09) ${degrees}deg 360deg)`;
}

function addTelemetry(cpu, memory) {
    telemetry.cpu.push(cpu);
    telemetry.memory.push(memory);

    if (telemetry.cpu.length > telemetry.maxPoints) {
        telemetry.cpu.shift();
    }

    if (telemetry.memory.length > telemetry.maxPoints) {
        telemetry.memory.shift();
    }
}

function buildPoints(values, width, height) {
    if (!values.length) {
        return "";
    }

    if (values.length === 1) {
        return `0,${height / 2}`;
    }

    return values.map((value, index) => {
        const x = (index / (values.length - 1)) * width;
        const y = height - (clamp(value, 0, 100) / 100) * height;

        return `${x.toFixed(1)},${y.toFixed(1)}`;
    }).join(" ");
}

function updateCharts() {
    const miniWidth = 500;
    const miniHeight = 100;

    const cpuPoints = buildPoints(
        telemetry.cpu,
        miniWidth,
        miniHeight
    );

    const memoryPoints = buildPoints(
        telemetry.memory,
        miniWidth,
        miniHeight
    );

    document.getElementById("cpu-line").setAttribute(
        "points",
        cpuPoints
    );

    document.getElementById("memory-line").setAttribute(
        "points",
        memoryPoints
    );

    const chartWidth = 1000;
    const chartHeight = 280;

    document.getElementById("telemetry-cpu").setAttribute(
        "points",
        buildPoints(
            telemetry.cpu,
            chartWidth,
            chartHeight
        )
    );

    document.getElementById("telemetry-memory").setAttribute(
        "points",
        buildPoints(
            telemetry.memory,
            chartWidth,
            chartHeight
        )
    );
}

function updateDashboard(data) {
    const application = data.application;
    const container = data.container;
    const system = data.system;
    const incident = data.latest_incident;
    const aiReport = data.latest_ai_analysis;

    const cpu = Number(system.cpu_percent) || 0;
    const memory = Number(system.memory_percent) || 0;

    addTelemetry(cpu, memory);

    // -----------------------------
    // HERO
    // -----------------------------

    const healthy = container.health === "healthy";

    document.getElementById("hero-status").textContent =
        healthy
            ? "CloudForge is operational"
            : "CloudForge requires attention";

    document.getElementById("hero-description").textContent =
        healthy
            ? "All monitored application services are healthy."
            : "One or more monitored services are reporting degraded state.";

    document.getElementById("app-version").textContent =
        application.version;

    document.getElementById("last-update").textContent =
        new Date(data.timestamp).toLocaleTimeString();


    // -----------------------------
    // CPU
    // -----------------------------

    document.getElementById("cpu").textContent =
        `${cpu.toFixed(1)}%`;

    document.getElementById("cpu-gauge-value").textContent =
        `${cpu.toFixed(1)}%`;

    setGauge(
        "cpu-gauge",
        cpu,
        "#42c9ff"
    );


    // -----------------------------
    // MEMORY
    // -----------------------------

    document.getElementById("memory").textContent =
        `${memory.toFixed(1)}%`;

    document.getElementById("memory-gauge-value").textContent =
        `${memory.toFixed(1)}%`;

    setGauge(
        "memory-gauge",
        memory,
        "#a78bfa"
    );

    document.getElementById("memory-used").textContent =
        `${system.memory_used_mb.toFixed(0)} MB / ${system.memory_total_mb.toFixed(0)} MB`;


    // -----------------------------
    // CONTAINER
    // -----------------------------

    document.getElementById("container-status").textContent =
        container.status.toUpperCase();

    document.getElementById("container-name").textContent =
        container.name;

    document.getElementById("container-health").textContent =
        `Health ${container.health}`;

    document.getElementById("restart-count").textContent =
        container.restart_count;

    document.getElementById("oom-killed").textContent =
        container.oom_killed ? "YES" : "NO";

    document.getElementById("hostname").textContent =
        system.hostname;


    // -----------------------------
    // SYSTEM STATUS
    // -----------------------------

    const systemStatus =
        document.getElementById("system-status");

    const systemStatusText =
        document.getElementById("system-status-text");

    systemStatusText.textContent =
        healthy ? "OPERATIONAL" : "DEGRADED";

    systemStatus.classList.toggle(
        "danger",
        !healthy
    );


    // -----------------------------
    // INCIDENT
    // -----------------------------

    if (incident) {

        document.getElementById("incident-id").textContent =
            incident.incident_id;

        document.getElementById("incident-details").textContent =
            `Detected ${new Date(
                incident.detected_at
            ).toLocaleString()}`;

        document.getElementById("incident-failure").textContent =
            incident.failure_type;

        document.getElementById("incident-recovery").textContent =
            incident.recovery_action;

        document.getElementById("incident-duration").textContent =
            `${incident.recovery_duration_seconds}s`;

    } else {

        document.getElementById("incident-id").textContent =
            "No incident detected";

        document.getElementById("incident-details").textContent =
            "CloudForge has no recorded incidents.";

        document.getElementById("incident-failure").textContent =
            "--";

        document.getElementById("incident-recovery").textContent =
            "--";

        document.getElementById("incident-duration").textContent =
            "--";
    }


    // -----------------------------
    // AI
    // -----------------------------

    document.getElementById("ai-report").textContent =
        aiReport || "No AI analysis available.";


    // -----------------------------
    // LIVE ACTIVITY
    // -----------------------------

    document.getElementById("activity").innerHTML = `
        <div class="activity-item">
            <span class="activity-dot"></span>
            <div>
                <strong>CloudForge API is ${container.health}</strong>
                <span>Live health telemetry</span>
            </div>
        </div>

        <div class="activity-item">
            <span class="activity-dot"></span>
            <div>
                <strong>Container ${container.name} is ${container.status}</strong>
                <span>Docker runtime status</span>
            </div>
        </div>

        <div class="activity-item">
            <span class="activity-dot"></span>
            <div>
                <strong>CPU ${cpu.toFixed(1)}%  Memory ${memory.toFixed(1)}%</strong>
                <span>Current infrastructure utilization</span>
            </div>
        </div>

        <div class="activity-item">
            <span class="activity-dot"></span>
            <div>
                <strong>Self-healing telemetry active</strong>
                <span>CloudForge monitor is operational</span>
            </div>
        </div>

        <div class="activity-item">
            <span class="activity-dot"></span>
            <div>
                <strong>AI incident analysis available</strong>
                <span>Gemini analysis pipeline connected</span>
            </div>
        </div>
    `;

    updateCharts();
}


// -----------------------------
// API POLLING
// -----------------------------

async function loadDashboard() {

    try {

        const response =
            await fetch("/api/dashboard", {
                cache: "no-store"
            });

        if (!response.ok) {
            throw new Error(
                "Dashboard API request failed"
            );
        }

        const data =
            await response.json();

        updateDashboard(data);

    } catch (error) {

        console.error(error);

        document.getElementById(
            "system-status-text"
        ).textContent = "OFFLINE";

        document.getElementById(
            "hero-status"
        ).textContent = "Telemetry connection lost";

        document.getElementById(
            "hero-description"
        ).textContent = "Unable to reach CloudForge dashboard API.";

    }
}


// Initial load
loadDashboard();

// Refresh every 3 seconds
setInterval(
    loadDashboard,
    3000
);
