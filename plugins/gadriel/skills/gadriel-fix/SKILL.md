---
name: gadriel-fix
description: "Use to remediate ONE specific Gadriel finding identified by its rule ID (e.g. CODE-W1-L3-017). Applies or proposes a fix and re-scans the affected file to confirm the finding is resolved. Use when the user asks to fix, remediate, or resolve a named Gadriel finding. To discover findings first, use gadriel-scan; to see open findings use gadriel-status."
---

# Gadriel Fix

Remediate one Gadriel finding by its ID.

## Workflow

1. If the user did not give a finding ID, run `gadriel code findings` (or use the
   `findings_for_path` MCP tool) and ask which finding to fix.
2. Confirm the finding is still open in `.security/findings.json`.
3. Apply the remediation with `gadriel code fix <FINDING-ID>`, following the
   matching `gadriel-*` guidance skill and the codebase's existing patterns. The
   `fix_finding` MCP tool is also available. Never call `dismiss_false_positive`
   without explicit user confirmation.
4. Re-scan the affected file (`gadriel code scan <path>`) and confirm the finding
   is gone. Report what changed.
