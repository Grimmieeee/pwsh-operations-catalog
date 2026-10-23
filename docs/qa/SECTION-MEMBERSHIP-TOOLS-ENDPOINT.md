# Tools and Endpoint membership review

Status: approved placements implemented in PR #110; runtime acceptance remains separate.

Reviewed 34 entries: 21 scripts and 13 references. Runtime acceptance remains separate. The adjacent JSON binds each decision to the current source checksum.

## Section boundaries

Endpoint: provision, maintain, back up or inspect the health/storage of a Windows endpoint. Exclude repository/publishing utilities and security screening before disclosure.

Tools: prepare or operate the support toolkit, manage sessions, inspect/manage project files, sign code, or consult supporting references. Security-specific tools can have a justified secondary entry point.

Reporting: the workflow produces an inventory, analysis, findings or comparison for review. Exclude prerequisite validators and operations that merely print completion status. Console output can be a report; local export/checkpoint writes do not automatically disqualify a workflow.

Start Here: a section within Home covering prerequisites, authorized target confirmation, one-job execution and completion/cleanup. Candidate links do not imply that every setup tool must be run.

## Proposed differences

| Entry | Primary section | Secondary section | Reporting | Reason |
|---|---|---|---|---|
| Check M365 PowerShell Readiness | Tools | — | Remove | Prerequisite readiness diagnostic; successful checks are not a reporting workflow. |
| Review Folder Contents | Endpoint → Tools | — | Retain | Inventories folders, scripts, signatures and Git status; toolkit/repository review rather than endpoint maintenance. |
| Check Sensitive Data | Endpoint → Security | Tools | Retain | Reports potential disclosure findings before sharing files; security review with a publishing-tool entry point. |
| Review GitHub Security | Tools | Security | Add | Reviews a supplied GitHub security export and reports actionable findings; may save local review checkpoints. Local writes do not remove reporting purpose. |
| Check Toolkit Setup | Tools | — | Remove | Validates expected toolkit files and prerequisites; readiness diagnostic. |

## Remaining catalog review

Review Reporting purpose across Identity, Mailbox, Licensing, Security and Incident Response next. In particular, Review Tenant Changes has reporting purpose despite a local baseline write. Resolve scope separately from domain and output type.

Before applying the full mapping, replace the generic Tools fallback with explicit reviewed memberships; require a review when source revisions change the recorded purpose, target or output. Add membership/exclusion tests from approved decisions.
