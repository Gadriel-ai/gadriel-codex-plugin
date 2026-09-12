---
name: gadriel-diff-scan
description: "Use to security-scan only the files changed in the working tree or a diff — the fast pre-PR / pre-commit check. Scans the changed paths with Gadriel instead of the whole repo. Use when the user asks to scan changes, the diff, staged files, or 'before I open a PR'. For a full repository scan use gadriel-scan."
---

# Gadriel Diff Scan

Scan only the changed files — the pre-PR check.

## Workflow

1. Collect the changed files. Typical sources:
   - working tree + staged: `git diff --name-only HEAD`
   - staged only: `git diff --name-only --cached`
   - vs a base branch: `git diff --name-only <base>...HEAD`
   Keep only files that still exist (skip deletions).
2. Scan them. Simplest: `gadriel code scan <dir>` scoped to the changed area, or
   scan the changed files/paths directly. (Gadriel's scan is path-scoped.)
3. Report new/affected findings by severity with rule_id, file and line, and
   flag anything at or above High as a merge blocker. Offer `gadriel-fix`.

## Note

This complements the automatic edit guardrail (which checks each file as it is
written); the diff scan is the explicit "check everything I changed" pass.
