# /gadriel-status

Show the open Gadriel findings from the last scan.

## Workflow

1. Run `gadriel code findings` (reads `.security/`, so it is only as fresh as
   the last scan; suggest `/gadriel-scan` first if there is none).
2. Give a one-screen answer to "is this repo clean?": counts by severity and
   the few findings that matter most.
