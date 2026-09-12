#!/bin/sh
# Codex lifecycle-hook shim for the Gadriel plugin.
#
# Codex runs a plugin's hook command with the working directory set to the
# user's PROJECT (where the edit happened) and exports CLAUDE_PLUGIN_ROOT (and
# PLUGIN_ROOT) pointing at the installed plugin directory. hooks.json invokes
# this script as `sh "$CLAUDE_PLUGIN_ROOT/scripts/gadriel-hook.sh" <phase>`.
#
# This script:
#   1. only acts in a project Gadriel already tracks — one with a `.security/`
#      directory, created by the first `gadriel code scan`; everywhere else it
#      exits 0 untouched, so an always-enabled plugin never writes into a repo
#      you have not scanned,
#   2. hands the payload to `gadriel hooks adapt --platform codex`, which runs
#      the same guardrail scan Gadriel uses everywhere else.
#
# On `post-edit`, a finding at or above the threshold makes gadriel print it and
# exit 2, which Codex feeds back so the code is fixed before the turn continues.
# Every other outcome exits 0. GADRIEL_GUARDRAIL=off disables the guardrail;
# =critical blocks only on critical findings. Fails SAFE: if it cannot find the
# project or the binary, it exits 0 — never a spurious block.
set -eu

phase=${1:-post-edit}
case "$phase" in
  pre-edit) event=pre-tool-use ;;
  post-edit) event=post-tool-use ;;
  *) exit 0 ;;
esac

payload=$(cat)

# Codex runs the hook in the project directory. Prefer the payload's own cwd if
# it carries one (more precise, and correct on other hosts), else the process
# working directory.
project=""
for key in cwd workspace_root workspaceRoot workspace projectRoot project_dir; do
  v=$(printf '%s' "$payload" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n1)
  if [ -n "$v" ] && [ -d "$v" ]; then project="$v"; break; fi
done
[ -n "$project" ] || project="$PWD"

# Only act in a repo Gadriel already tracks.
[ -d "$project/.security" ] || exit 0

# Resolve the launcher: the plugin root Codex gave us, then this script's own
# location, then a gadriel on PATH. Exit 0 (no block) if none is found.
selfbin=$(CDPATH= cd "$(dirname "$0")/../bin" 2>/dev/null && pwd || true)
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -x "$CLAUDE_PLUGIN_ROOT/bin/gadriel" ]; then
  launcher="$CLAUDE_PLUGIN_ROOT/bin/gadriel"
elif [ -n "${PLUGIN_ROOT:-}" ] && [ -x "$PLUGIN_ROOT/bin/gadriel" ]; then
  launcher="$PLUGIN_ROOT/bin/gadriel"
elif [ -n "$selfbin" ] && [ -x "$selfbin/gadriel" ]; then
  launcher="$selfbin/gadriel"
elif command -v gadriel >/dev/null 2>&1; then
  launcher=gadriel
else
  exit 0
fi

# Hooks must never stall a turn on a first-run download.
export GADRIEL_PLUGIN_NO_DOWNLOAD=1
# The guardrail's stderr reaches Codex verbatim; keep log lines out of it.
export RUST_LOG=${RUST_LOG:-error}

cd "$project" || exit 0

if [ "$phase" = post-edit ]; then
  printf '%s' "$payload" | "$launcher" hooks adapt --platform codex --event "$event"
  # 2 is the guardrail's "fix this first"; anything else is not the agent's problem.
  [ $? -eq 2 ] && exit 2
  exit 0
fi

printf '%s' "$payload" | "$launcher" hooks adapt --platform codex --event "$event" >/dev/null 2>&1 || true
exit 0
