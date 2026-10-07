# FIELD // KIT Audit Limbo

This file tracks scripts and catalog entries intentionally kept out of the public library while overlap, edge-case value, or replacement status is reviewed.

The rule is simple: similarity alone is not enough to remove a tool. A duplicate is only removed when another tool preserves the useful behavior and edge cases without making the common job harder.

## Status Key

- HOLD — keep out of the public catalog until overlap is resolved.
- SALVAGE — useful behavior exists, but the current script is too broad, too mixed, or not clean enough to publish as-is.
- REPLACEMENT — likely successor to a current public tool; compare behavior before swapping.
- ARCHIVE — historical/test lineage with no current public role.

## Current Limbo

| Item | Status | Why it is here | Possible value to preserve |
| --- | --- | --- | --- |
| Bulk Mailbox Permissions Review | HOLD | Covered by the reviewed Mailbox Permissions Review, which already accepts one or more mailbox UPNs. | None identified yet beyond bulk naming. |
| Mailbox Access Audit | HOLD | Older overlapping mailbox-access card; source is not part of the current canonical baseline. | Review only if a missing access edge case is found. |
| Bulk Mailbox Access Audit | HOLD | Older bulk mailbox-access card overlapping the current reviewed mailbox tools. | Review only if it contains coverage the current tool lacks. |
| Bulk Mailbox Forwarding and Permissions Audit | SALVAGE | Broad bulk audit with CSV and summary output, but uses permissive error handling and needs behavior review before replacing anything. | Bulk TXT/CSV input, forwarding + delegate + risky inbox-rule review, export. |
| group-access-audit-bulk-clean.ps1 | SALVAGE | Useful but mixes groups, rooms, equipment mailboxes, mailbox delegates, and calendar booking delegates in one workflow. | Potential future Exchange Access Review, or split room/resource access logic into a focused tool. |
| tenant-user-access-audit-clean.ps1 | SALVAGE | Broad tenant audit overlaps focused disabled-user group debt and mailbox-access reviews. Uses permissive error handling and incomplete mailbox permission coverage. | Possible future consolidated Tenant Access Debt Audit after hardening. |
| tenant-conditional-access-audit-clean.ps1 | ARCHIVE | Simpler Conditional Access listing/gap audit appears superseded by tenant-cap-gaps-audit-clean.ps1, which adds deeper exclusion/device-code/location/coverage checks. | Revisit only if the simpler output is materially easier to use. |
| tenant-multifactor-audit-clean.ps1 | ARCHIVE | Earlier MFA registration audit is substantially covered by the newer MFA Security Audit with method-strength classification and optional CA context. | Keep only for behavior archaeology unless an edge case is found. |
| group-members-audit-bulk-clean.ps1 | HOLD | Entra-only bulk group member audit overlaps the current Bulk Group Members Review. | Compare CSV/reporting behavior and direct-member edge cases before deciding which implementation survives. |
| jumpbox-disabled-mailbox-access.ps1 | SALVAGE | Older single-user disabled-account cleanup tool combines mailbox permissions, distribution-list context, and optional removal. Too broad/legacy to publish as-is. | Possible source for a focused Disabled User Access Cleanup workflow or improvements to Offboarding. |
| resolve-names-to-upns.ps1 | HOLD | Appears alongside bulk-resolve-upns.ps1 in the same Verify-Status folder. Source comparison still needed. | Preserve only if it resolves edge cases the bulk resolver does not. |
| 2-INVOKE-DISABLE-ACCOUNTS(2).ps1 | REPLACEMENT | Newer account-disable implementation than the current catalog source. | Better authority handling, validation, session revoke, sync state, verified CSV, and ticket-note output. |

## Focused Extraction Backlog

These are good single-use jobs discovered inside broader or older tools. They are intentionally not public yet because the useful behavior should be rebuilt or extracted cleanly rather than exposing the legacy wrapper.

- User Security Snapshot — one-user overview of identity state, MFA methods, admin roles, group memberships, and recent sign-ins. The old bare-bones snapshot proves the job is useful, but it needs a current public revision.
- Tenant Security Snapshot — fast high-level tenant overview of users, stale accounts, Conditional Access policy state, admin-role counts, and OAuth grant count. Useful as an overview even though deeper focused audits now exist.
- Room & Resource Access Review — extract room/equipment mailbox Full Access, BookInPolicy, and ResourceDelegate logic from group-access-audit-bulk-clean.ps1.
- Tenant Mailbox Access Audit — extract tenant-wide mailbox forwarding, Full Access, and Send As review from tenant-user-access-audit-clean.ps1.
- Disabled User Access Cleanup — evaluate the useful removal logic in jumpbox-disabled-mailbox-access.ps1 against current Offboarding before deciding whether this deserves its own guarded workflow.

## Promoted From Leftovers

These started as outliers or older focused scripts, survived behavior review, and now have a defensible public job.

- Admin Role Audit — active Entra admin-role assignments with disabled/stale account context.
- OAuth Consent Audit — delegated OAuth grants and risky scopes.
- Guest User Hygiene Audit — stale, disabled, unused, or unaccepted guest accounts.
- Tenant Licensing Audit — SKU usage plus disabled-licensed and enabled-unlicensed users.
- Tenant Inbox Rules Audit — tenant-wide inbox-rule review with shared-mailbox and suspicious-only options.
- Join Computer to Domain — focused endpoint join workflow with pre-flight checks and typed confirmation.
- Deploy Printer — focused direct TCP/IP printer deployment.
- Back Up User Profile — focused local profile-folder backup with dated destination and log.

## Historical / Archive Lineage

These are useful references for behavior archaeology but should not compete for public catalog space.

- jumpbox-user-snapshot.ps1 — earlier bare-bones user security snapshot.
- jumpbox-mailbox-snapshot.ps1 — earlier bare-bones mailbox snapshot.
- jumpbox-tenant-snapshot.ps1 — earlier bare-bones tenant security snapshot.
- Legacy RMM BEC triage / exposure / preflight variants — retained privately; public RMM is limited to the current Incident Response RMM tools.
- IR drill setup / verify / teardown tools — removed from the public catalog; test-only.

## Review Pattern

When a limbo item is revisited:

1. Compare actual executable behavior, not just names or comments.
2. Identify unique coverage or edge cases.
3. Move useful logic into the best existing tool when that reduces choice without losing capability.
4. Publish a separate tool only when its job is clearly distinct and defensible.
5. Archive the remainder.
