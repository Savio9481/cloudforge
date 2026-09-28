import json
import os
import sys
from pathlib import Path

from google import genai


def analyze_with_ai(file_path):
    file_path = Path(file_path)

    with open(file_path, "r") as file:
        incident = json.load(file)

    client = genai.Client(
        api_key=os.environ["GEMINI_API_KEY"]
    )

    prompt = f"""
You are the AI incident analyzer for CloudForge,
a self-healing AWS deployment platform.

Analyze the following incident.

Incident data:
{json.dumps(incident, indent=2)}

Provide a concise incident report with these sections:

1. What happened
2. Likely cause
3. Impact
4. Recovery performed
5. Recovery assessment
6. Recommended next actions

Only use information available in the incident data.
Clearly state when the exact root cause cannot be determined
from the available evidence.
"""

    response = client.interactions.create(
        model="gemini-3.6-flash",
        input=prompt
    )

    report = response.output_text

    report_file = file_path.with_name(
        file_path.stem + "-ai.txt"
    )

    with open(report_file, "w") as file:
        file.write("CloudForge AI Incident Analysis\n")
        file.write("=" * 35 + "\n\n")
        file.write(report)
        file.write("\n")

    print("CloudForge AI Incident Analysis")
    print("=" * 35)
    print()
    print(report)
    print()
    print(f"AI report saved to: {report_file}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python ai_analyzer.py <incident.json>")
        sys.exit(1)

    analyze_with_ai(sys.argv[1])
