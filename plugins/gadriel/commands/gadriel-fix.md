# /gadriel-fix

Remediate one Gadriel finding by its ID.

## Arguments

- `finding_id`: the rule code Gadriel reported, e.g. `CODE-W1-L3-017` (required).

## Workflow

1. If no ID was given, run `gadriel code findings` and ask which finding to fix.
2. Run `gadriel code fix <finding_id>` and follow the matching `gadriel-*` skill,
   keeping to the codebase's existing patterns.
3. Re-scan the affected file with `gadriel code scan <path>` and confirm the
   finding is gone.
