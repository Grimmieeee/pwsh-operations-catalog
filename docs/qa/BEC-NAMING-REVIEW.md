# BEC naming and superseded PR cleanup

October 22, 2026. One naming wave; permissions and lifecycle redesign are outside scope.

Closed PRs #9, #10 and #19 as superseded, without merging their code or deleting their branches. #14 remains separate dependency work. The old drafts and their validation limits remain accessible in GitHub history.

All eleven active IR-prefixed response/investigation scripts now use BEC-prefixed filenames and BEC: catalog/console titles. The response navigation and Revoke Sessions command also display BEC. IR, incident response, former display names and old filenames remain searchable aliases. General-purpose identity/mailbox tools keep their existing names.

The three workflow files are:

- BEC-RISK-ASSESSMENT.ps1
- BEC-CONTAIN-ERADICATE.ps1
- BEC-RECOVER-VALIDATE.ps1

Download the new workflow package and replace the three files together. Do not mix old and new phase filenames. The canonical raw URLs change; the former filenames remain search aliases, not executable wrappers or duplicated supported tools. Existing external direct links to the removed IR paths must be updated.

Companion calls, launch guidance, ZIP contents, relationships, current inventories, source hashes, tests and maintenance-builder inputs move together. Internal IR function names and the in-memory FieldKitIRSession variable remain stable. Their names are implementation details; renaming them would add operational churn without changing the requested catalog experience.

The adjacent JSON records every changed source, prior/current hashes, names, versions, operational fingerprints, BOM handling and the exact replacement pairs. Applying those pairs in reverse must reconstruct the prior source bytes exactly. The three-phase package retains its pinned historical accepted baseline separately; current naming review does not imply fresh Windows/tenant execution.

Validation includes the full existing site suite, five naming regressions, all 81 objective/source comparisons, parsing and offline execution of the actual handoff helpers against disposable companion files. Handoff cases cover all three destinations, final-review target transfer, declined navigation, NoPause, missing companion and missing context. No live customer services are contacted.

## Findings retained from the closed drafts

PR #19's formatting work did not resolve every behavior finding. Account Status still classifies absent accountEnabled as Disabled. Its notes also identified denied group reads/ambiguous matching and a group-owner parser defect; reconcile each against current source before treating it as open or fixed. Closing the draft does not certify these findings resolved. The original branches and review documents are retained for that reconciliation.
