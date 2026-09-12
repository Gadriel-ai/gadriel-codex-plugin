---
name: gadriel-reports
description: "Use to generate Gadriel's compliance reports (PDF) from the latest scan — one per pillar plus an umbrella report, mapped to frameworks such as OWASP LLM Top 10, SOC 2, HIPAA, EU AI Act and NIST AI RMF. Use when the user asks for a compliance report, audit report, or framework-mapped evidence. Requires a prior scan (gadriel-scan)."
---

# Gadriel Compliance Reports

Render Gadriel's compliance reports from the latest scan.

## Workflow

1. Ensure a scan has run (a `.security/findings.json` exists). If not, run
   `gadriel-scan` first.
2. Run `gadriel code report --format pdf --all-pillars --fail-on render-only`.
   Reports are written to `.security/compliance/`.
3. List the generated files with their sizes.

## Note

A PARTIAL compliance verdict is normal for any repo with open findings and is
not a rendering failure — `--fail-on render-only` reserves a non-zero exit for a
report that could not be rendered.
