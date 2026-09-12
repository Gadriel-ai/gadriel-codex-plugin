#!/bin/sh
# Codex lifecycle-hook shim for the Gadriel plugin.
#
# Codex runs a plugin's hook command with the working directory set to the
# user's PROJECT and exports CLAUDE_PLUGIN_ROOT (and PLUGIN_ROOT) pointing at
# the installed plugin. hooks.json invokes this as
# `sh "$CLAUDE_PLUGIN_ROOT/scripts/gadriel-hook.sh" <phase>`.
#
# Phases:
#   prewarm   (SessionStart) — ensure the bundled `gadriel` binary is
#             downloaded + verified, in the background, so the first scan/edit
#             is instant. No project needed; never blocks.
#   pre-edit  (PreToolUse)   — advisory; silent; never blocks.
#   post-edit (PostToolUse)  — the guardrail. Re-scans the file just written;
#             if it has a finding at/above the threshold, surface it to the
#             agent as a NON-BLOCKING warning (Codex `systemMessage` +
#             `additionalContext`) so the agent fixes it before moving on. It
#             does not block the tool call, so it can never cause a retry loop.
#             Only runs in a repo Gadriel already tracks (has `.security/`),
#             so an always-enabled plugin never touches an unscanned repo.
#
# GADRIEL_GUARDRAIL=off disables the guardrail; =critical warns only on
# critical findings. Fails SAFE: any resolution problem exits 0 silently.
set -eu

phase=${1:-post-edit}

# --- resolve the bundled launcher (works for every phase) ------------------
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

# --- prewarm: download + cache the binary in the background ----------------
if [ "$phase" = prewarm ]; then
  # Allow the one-time npm download here (unlike the edit hooks), off the
  # critical path, so the first real scan/edit does not pay for it.
  ( RUST_LOG=error "$launcher" --version >/dev/null 2>&1 & ) >/dev/null 2>&1 || true
  exit 0
fi

case "$phase" in
  pre-edit) event=pre-tool-use ;;
  post-edit) event=post-tool-use ;;
  *) exit 0 ;;
esac

payload=$(cat)

# Project dir: prefer a cwd/workspace field in the payload, else the process
# cwd (Codex runs edit hooks in the project).
project=""
for key in cwd workspace_root workspaceRoot workspace projectRoot project_dir; do
  v=$(printf '%s' "$payload" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n1)
  if [ -n "$v" ] && [ -d "$v" ]; then project="$v"; break; fi
done
[ -n "$project" ] || project="$PWD"

# Only act in a repo Gadriel already tracks.
[ -d "$project/.security" ] || exit 0

# Edit hooks must never stall a turn on a download; use only the cached binary.
export GADRIEL_PLUGIN_NO_DOWNLOAD=1
export RUST_LOG=${RUST_LOG:-error}
cd "$project" || exit 0

if [ "$phase" = post-edit ]; then
  # Run the guardrail scan. gadriel prints the finding to stderr and exits 2
  # when the file has a finding at/above the threshold.
  set +e
  reason=$(printf '%s' "$payload" | "$launcher" hooks adapt --platform codex --event "$event" 2>&1)
  rc=$?
  set -e
  if [ "$rc" -eq 2 ]; then
    # Surface it to the agent WITHOUT blocking the tool call (no retry loop):
    # a non-blocking `systemMessage` plus `additionalContext`. JSON-safe reason:
    # flatten newlines/tabs to spaces, strip control bytes, escape \ and ".
    esc=$(printf '%s' "$reason" \
      | tr '\t\r\n' '   ' \
      | tr -d '\000-\037' \
      | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s Fix this before continuing."}}\n' "$esc" "$esc"
  fi
  exit 0
fi

# pre-edit: advisory only.
printf '%s' "$payload" | "$launcher" hooks adapt --platform codex --event "$event" >/dev/null 2>&1 || true
exit 0
