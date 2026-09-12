---
name: gadriel-status
description: "Use to show the open Gadriel findings from the last scan without re-scanning — counts by severity and the top findings. Use when the user asks 'is this repo clean?', for the current security status, or the open findings. Reads .security/; if there is no scan yet, suggest gadriel-scan."
---

# Gadriel Status

## Finding the `gadriel` binary (Codex)

The `gadriel` CLI may not be on the Codex shell PATH. Resolve it once, then use
`"$GAD"` in place of `gadriel` for every command below:

```sh
GAD=$(command -v gadriel 2>/dev/null \
  || { [ -n "$CLAUDE_PLUGIN_ROOT" ] && [ -x "$CLAUDE_PLUGIN_ROOT/bin/gadriel" ] && echo "$CLAUDE_PLUGIN_ROOT/bin/gadriel"; } \
  || ls "$HOME"/.codex/plugins/cache/*/gadriel/*/bin/gadriel 2>/dev/null | head -1)
```

This uses the scanner the plugin already bundled and verified, so no global
install is required. Only if `$GAD` is empty should you tell the user to install
the CLI.

Report the current security posture from the last scan.

## Workflow

1. Run `"$GAD" code findings` (reads `.security/`, so it is only as fresh as the
   last scan). If there is no scan yet, say so and suggest `gadriel-scan`.
2. Give a one-screen answer: counts by severity and the few findings that matter
   most (rule_id, file, line). Note the last-scan time if available.
