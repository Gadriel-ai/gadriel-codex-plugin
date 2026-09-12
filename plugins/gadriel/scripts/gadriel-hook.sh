#!/bin/sh
# Codex lifecycle-hook shim for the Gadriel plugin.
#
# Codex runs a plugin's hook command with the working directory set to the
# PLUGIN directory (the same convention as the plugin's MCP `command`, and
# as the official figma plugin's `./scripts/...` hook). The code Codex is
# editing, however, lives in the user's PROJECT. So this script:
#
#   1. reads the hook payload from stdin,
#   2. recovers the project directory from it (the `cwd` / `workspace`
#      field Codex includes),
#   3. only acts in a project Gadriel already tracks — one with a
#      `.security/` directory, created by the first `gadriel code scan`;
#      everywhere else it exits 0 untouched, so an always-enabled plugin
#      never writes into a repo you have not scanned,
#   4. hands the payload to `gadriel hooks adapt --platform codex`, which
#      runs the same guardrail scan Gadriel uses everywhere else.
#
# On `post-edit`, a finding at or above the threshold makes gadriel print it
# and exit 2, which Codex feeds back so the code is fixed before the turn
# continues. Every other outcome exits 0. GADRIEL_GUARDRAIL=off disables the
# guardrail; =critical blocks only on critical findings.
#
# This script never re-implements JSON parsing beyond lifting one top-level
# string field, and it fails SAFE: if it cannot find the project dir or the
# binary, it exits 0 (never a spurious block).
set -eu

phase=${1:-post-edit}
case "$phase" in
  pre-edit) event=pre-tool-use ;;
  post-edit) event=post-tool-use ;;
  *) exit 0 ;;
esac

payload=$(cat)

# Recover the project directory from the payload. Codex includes the
# workspace path; accept the field names it may use. Tolerant sed over a
# flat top-level string — no dependency on jq/node/python.
project=""
for key in cwd workspace_root workspaceRoot workspace projectRoot project_dir; do
  v=$(printf '%s' "$payload" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n1)
  if [ -n "$v" ] && [ -d "$v" ]; then
    project="$v"
    break
  fi
done

# No resolvable project, or one Gadriel does not track yet: do nothing.
[ -n "$project" ] || exit 0
[ -d "$project/.security" ] || exit 0

# Resolve the launcher relative to this script (robust to the cwd).
launcher=$(CDPATH= cd "$(dirname "$0")/../bin" 2>/dev/null && pwd)/gadriel
[ -x "$launcher" ] || exit 0

# Hooks must never stall a turn on a first-run download.
export GADRIEL_PLUGIN_NO_DOWNLOAD=1
# The guardrail's stderr reaches Codex verbatim; keep log lines out of it.
export RUST_LOG=${RUST_LOG:-error}

# Run from the project so `adapt` resolves the edited file, and pass the
# original payload through.
cd "$project" || exit 0

if [ "$phase" = post-edit ]; then
  printf '%s' "$payload" | "$launcher" hooks adapt --platform codex --event "$event"
  # 2 is the guardrail's "fix this first"; anything else is not the agent's problem.
  [ $? -eq 2 ] && exit 2
  exit 0
fi

printf '%s' "$payload" | "$launcher" hooks adapt --platform codex --event "$event" >/dev/null 2>&1 || true
exit 0
