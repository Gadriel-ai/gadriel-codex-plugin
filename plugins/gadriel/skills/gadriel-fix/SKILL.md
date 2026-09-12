---
name: gadriel-fix
description: "Use to remediate ONE specific Gadriel finding identified by its rule ID (e.g. CODE-W1-L3-017). Applies or proposes a fix and re-scans the affected file to confirm the finding is resolved. Use when the user asks to fix, remediate, or resolve a named Gadriel finding. To discover findings first, use gadriel-scan; to see open findings use gadriel-status."
---

# Gadriel Fix

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

Remediate one Gadriel finding by its ID.

## Workflow

1. If the user did not give a finding ID, run `"$GAD" code findings` (or use the
   `findings_for_path` MCP tool) and ask which finding to fix.
2. Confirm the finding is still open in `.security/findings.json`.
3. Apply the remediation with `"$GAD" code fix <FINDING-ID>`, following the
   matching `gadriel-*` guidance skill and the codebase's existing patterns. The
   `fix_finding` MCP tool is also available. Never call `dismiss_false_positive`
   without explicit user confirmation.
4. Re-scan the affected file (`"$GAD" code scan <path>`) and confirm the finding
   is gone. Report what changed.
