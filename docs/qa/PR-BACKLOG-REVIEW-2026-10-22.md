# Pending PR review — October 22, 2026

Reviewed all five open PRs in creation order against the agreed standalone scope, clean lifecycle, catalog-wide consistency and evidence boundaries. An older PR is not automatically a release prerequisite.

| PR | Decision | Reason |
| --- | --- | --- |
| #9 — standalone IR assessment candidate | Hold draft | Adds a parallel legacy candidate, not the current published BEC implementation. Conflicts with current main; controlled runtime/interpretation gates remain in its own notes. Preserve as comparison material. |
| #10 — containment/eradication candidate | Hold draft | Targets #9's branch rather than main. Retains explicit sync-server/remoting and older phase decisions that differ from the accepted current direction. Not an independent production release. |
| #14 — checkout v7.0.1 | Hold | Conflicts with current workflows and changes only two checkout references; the later publishing workflow still uses the pinned current action. Requires a deliberate all-workflow compatibility wave, including runner and major-version behavior review. Not evidence that the upstream version is unsafe. |
| #19 — 64 console candidates | Hold draft | Broad older candidate set, old 338-entry inventory and known held defects. Current main already has newer source/card alignment and later fixes. Merging it would mix historical candidates with supported current files. |
| #87 — remove RMM setup guidance | Release | Directly enforces agreed scope without operational changes. An unresolved review correctly identified erased comparison baselines. Restored 1.0.0 hashes in all three ledgers, marked the revision changed and updated the source-comparison count. Both local comparisons and remote site/PowerShell/CodeQL CI passed before merge. |

#87 merged as `43e8220609f8617abcbad82bbdcf50a2e59f1e37`; its Publish live site run `39787940661` completed successfully. The four held PRs remain open; no drafts were promoted and no branches were deleted.

Next release wave: Stage 1 impact and authorization only. Retain goal-based workflow previews as unpublished discussion artifacts. Keep the permissions stage on hold until the Stage 1 release is reported back.
