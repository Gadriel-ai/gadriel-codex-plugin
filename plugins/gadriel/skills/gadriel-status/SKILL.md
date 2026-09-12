---
name: gadriel-status
description: "Use to show the open Gadriel findings from the last scan without re-scanning — counts by severity and the top findings. Use when the user asks 'is this repo clean?', for the current security status, or the open findings. Reads .security/; if there is no scan yet, suggest gadriel-scan."
---

# Gadriel Status

Report the current security posture from the last scan.

## Workflow

1. Run `gadriel code findings` (reads `.security/`, so it is only as fresh as the
   last scan). If there is no scan yet, say so and suggest `gadriel-scan`.
2. Give a one-screen answer: counts by severity and the few findings that matter
   most (rule_id, file, line). Note the last-scan time if available.
