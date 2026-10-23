# Remaining card issues — October 21, 2026

| Issue | Resolution |
| --- | --- |
| 11 entries have no source | Moved out of active search, navigation counts and working cards. About → Planned Tools retains their names and objectives. This does not implement the planned scripts. |
| Automatic quick-command relationships | Replaced with 235 explicit, source-bound sets of three destinations. Relationships are recorded in command-relationship-specs.json and checked against current command code. |
| Incidental search matches | Search eligibility uses task names, purpose and task-specific aliases. Code, connection/setup notes, broad command subareas and prerequisite text no longer create incidental matches. Exact command search and assessment/offboarding starting points remain covered. |
| Technical BEC wording | Defines BEC, uses “approved Windows support computer,” explains the full sign-in address and customer environment, and preserves exact module names/versions where needed. |
| App-name lookup defect | Corrected the URI variable boundary and required matching result IDs. Added isolated tests against the actual current function; retired the narrow safety exception. |

The working library has 327 entries: 80 scripts, 235 quick commands and 12 references. Eleven source-less plans are listed separately. All script cards and quick commands have three distinct, available related destinations. No planned tool appears as runnable. Related Items continues to show only clear names and impact labels.

The related-command review groups actual operations by task and platform. Examples: printing leads to printer installation/status/jobs; mailbox delegation leads to mailbox permission/forwarding/security review; group membership keeps AD, Entra and distribution-group tasks explicit; repair commands lead to diagnostic checks before more changes. Relations are navigation choices, not a promise that command output is compatible input for another tool.

Validation and limits: site behavior checks, source/card parity, PowerShell parsing, source/command screening and BEC isolated lookup regressions run without tenant actions. Containment/recovery only advance their package version comments. Fresh native Windows or live-tenant acceptance remains distinct from these checks. The 11 planned scripts remain future implementation work.

Completed local checks: 54 site/theme tests; 93 PowerShell files and 315 command blocks parsed; all 80 source/objective comparisons; 80 bounded operational comparisons; seven isolated BEC lookup scenarios; shared Graph screening with zero active URI exceptions.
