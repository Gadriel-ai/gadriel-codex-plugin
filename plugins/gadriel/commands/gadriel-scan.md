# /gadriel-scan

Run a Gadriel security scan over the repository, or a path passed as an argument.

## Arguments

- `path`: a directory or single file to scope the scan to (optional; defaults to the whole repo).

## Workflow

1. Run `gadriel code scan $path` from the project root. The first scan creates
   `.security/` in the repo and switches on Gadriel's edit guardrail there.
2. Summarize the verdict, the finding counts by severity, and the most
   important findings with file and line.
3. Offer `/gadriel-fix <FINDING-ID>` for anything the user wants remediated.

Results are written to `.security/` (findings, SBOMs, compliance reports).
