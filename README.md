# Gadriel — AI Security Harness for OpenAI Codex

Codex writes code fast. Gadriel makes sure what it writes is safe.

This is the Codex build of the [Gadriel](https://gadriel.ai) AI Security
Harness (there is a sibling [Claude Code plugin](https://github.com/Gadriel-ai/gadriel-claude-plugin)).
Every file Codex writes is scanned the moment it is written; when the change
introduces a serious finding, Gadriel hands it straight back to Codex with the
fix, so it is corrected before the turn moves on. Around that guardrail, Codex
gets Gadriel's security MCP server and 17 skills.

Gadriel covers SAST, secrets, dependencies (SCA and SBOM), containers and
configuration, including AI-specific risks such as prompt injection and the
OWASP LLM Top 10, with 3,000+ rules. Scanning runs on your machine.

## Install

```
codex plugin marketplace add Gadriel-ai/gadriel-codex-plugin
```

Then install and enable it:

```
codex plugin add gadriel@security-harness
```

To use it, ask Codex in natural language — e.g. *"Run a Gadriel security scan on
this repo"* — which activates the `gadriel-scan` skill. The first scan creates
`.security/` in the repo and switches the guardrail on there; the plugin is
enabled globally but only acts in repositories you have scanned, and never
writes into one you have not.

## What you get

- **The guardrail** (`hooks.json`). After Codex applies a patch or edits a
  file, Gadriel re-scans it. A finding at or above High is returned to Codex
  with the remediation, so it fixes the code before continuing.
- **MCP server** `gadriel` (`.mcp.json`): `validate_file`, `validate_buffer`,
  `findings_for_path`, `fix_finding`, `dismiss_false_positive`, and more.
- **Action skills** — invoked by asking in natural language (Codex has no
  plugin slash commands; skills are the mechanism, and `/skills` lists them):
  `gadriel-scan` (full scan), `gadriel-diff-scan` (changed files only, pre-PR),
  `gadriel-fix` (remediate one finding), `gadriel-reports` (compliance PDFs),
  `gadriel-status` (open findings).
- **17 guidance skills** loaded when relevant: OWASP Web Top 10, OWASP LLM Top
  10, AI secrets catalog, AI config security, API security patterns, Dockerfile
  best practices, SBOM guidance, license compatibility, EU AI Act and NIST AI
  RMF mappers, and others.

## How the scanner gets onto your machine

The plugin is small; the scanner is the `gadriel` binary. `bin/gadriel` uses,
in order: `$GADRIEL_BIN` if set; a `gadriel` already on `PATH`; otherwise the
pinned release (**1.4.0**), downloaded once from `registry.npmjs.org` and
verified against the SHA-512 pinned in the launcher before it is cached or run.
Supported: macOS and Linux (glibc), x64 and arm64. Needs `curl` and `tar` for
the first download.

## Network and data

Your code is scanned locally and is not uploaded. On first run Gadriel
registers an anonymous device credential with `app.gadriel.ai` (a random device
ID, no hostname/username/keys); set `GADRIEL_NO_ANONYMOUS_AUTH=1` to skip it.
Rule and vulnerability-database updates come from Gadriel servers and the public
[OSV](https://osv.dev) database. See the [privacy policy](https://gadriel.ai/privacy).

## Configuration

| Variable | Effect |
|---|---|
| `GADRIEL_GUARDRAIL` | `off` disables the edit guardrail; `critical` blocks only on critical findings |
| `GADRIEL_NO_ANONYMOUS_AUTH` | `1` skips anonymous device registration |
| `GADRIEL_BIN` | use this `gadriel` binary instead of resolving one |

## License

The plugin — everything in this repository — is [Apache-2.0](LICENSE). The
`gadriel` scanner it runs is proprietary, under the [Gadriel terms](https://gadriel.ai/terms).
