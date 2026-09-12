---
name: gadriel-scan
description: "Use to run a Gadriel security scan of the whole repository or a scoped path/package/folder/file. This is the default full scan: SAST, secrets, dependencies (SCA), containers and configuration, including AI-specific risks (OWASP LLM Top 10). It writes results to .security/ and arms Gadriel's edit guardrail. Use whenever the user asks to scan, security-scan, audit, or check a repo or path for vulnerabilities. For remediating one known finding use gadriel-fix; for changed-files-only use gadriel-diff-scan."
---

# Gadriel Security Scan

Run Gadriel's full code-security scan and report the result.

## Workflow

1. Resolve the target: the repo root by default, or a path the user named (a
   directory or a single file).
2. From the repo root, run the scanner:
   - Whole repo: `gadriel code scan`
   - Scoped: `gadriel code scan <path>`
   (`gadriel scan …` is an accepted alias.) The first run creates `.security/`
   and switches on the edit guardrail for this repo.
3. Read the result from `.security/findings.json` (and `.security/pillar-scores.json`).
   Report: the verdict, counts by severity (critical/high/medium/low), and the
   most important findings with `rule_id`, file and line.
4. Offer `gadriel-fix <FINDING-ID>` for anything the user wants remediated.

## Notes

- If `gadriel` is not on PATH, tell the user to install it (`npm install -g gadriel`)
  or run it through the plugin; do not fabricate findings.
- For per-file checks without a full scan, the `gadriel` MCP tools
  `validate_file` and `findings_for_path` are available.
- A PARTIAL/DEGRADED verdict (e.g. OSV not synced) is normal; report it as-is.
