# FIELD // KIT Audit Limbo

This file tracks scripts and catalog entries intentionally kept out of the public library while overlap, edge-case value, or replacement status is reviewed.

The rule is simple: similarity alone is not enough to remove a tool. A duplicate is only removed when another tool preserves the useful behavior and edge cases without making the common job harder.

## Status Key

- HOLD — keep out of the public catalog until overlap is resolved.
- SALVAGE — useful behavior exists, but the current script is too broad, too mixed, or not clean enough to publish as-is.
- REPLACEMENT — likely successor to a current public tool; compare behavior before swapping.
- ARCHIVE — historical/test lineage with no current public role.

## Current Limbo

No current HOLD, SALVAGE, or REPLACEMENT items. The reviewed overlaps from this audit have either been promoted into a stronger public survivor or archived as lineage.

## Resolved In This Audit

- Bulk mailbox review variants — archived. Mailbox Permissions Review already supports one or more mailboxes and keeps query failures visible; separate bulk cards added naming/output convenience rather than a distinct operational job.
- Mailbox Access Audit / Bulk Mailbox Access Audit — archived. Their useful permission/forwarding coverage is already represented by Mailbox Permissions Review, Mailbox Security Snapshot, and Tenant Mailbox Access Audit.
- Bulk Mailbox Forwarding and Permissions Audit — archived. Its useful checks overlap Mailbox Permissions Review; permissive error handling and CSV/summary convenience did not justify a competing public tool.
- group-members-audit-bulk-clean.ps1 / get-group-members-lookup-bulk.ps1 — replaced by Bulk Entra Group Members Review, which preserves the actual Entra direct-member job with tenant targeting, clearer failure handling, verified CSV, and a ticket-ready summary.
- 2-INVOKE-DISABLE-ACCOUNTS(2).ps1 — promoted as the Bulk Disable User Accounts implementation after authority, confirmation, validation, sync-state, session-revoke, and export review.
- UPN resolver variants — consolidated into Resolve Names to UPNs in Bulk; tenant targeting from the older resolver was preserved in the reviewed survivor.
- Redundant coverage placeholders — retired for external-forwarding inbox rules, app credential expiry, enterprise-app ownership, guest inventory, and orphaned Teams because promoted public tools now cover those jobs.

## Focused Extraction Backlog

No current items. The five focused jobs from the previous backlog were rebuilt as public tools in this round.

The remaining hidden Candidate entries are future coverage ideas with no current public source; they are not unresolved overlap decisions.

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
- User Security Snapshot — read-only one-user overview of identity state, password age, MFA methods, active admin roles, direct groups, and recent sign-ins.
- Tenant Security Snapshot — fast read-only tenant overview of users, stale enabled accounts, Conditional Access state, admin-role counts, and delegated OAuth grants.
- Room & Resource Access Review — focused room/equipment mailbox Full Access, booking-policy, and resource-delegate review.
- Tenant Mailbox Access Audit — tenant-wide forwarding, Full Access, Send As, and Send on Behalf review with query failures kept visible.
- Disabled User Mailbox Access Cleanup — guarded post-offboarding cleanup that verifies the account is disabled and requires typed confirmation before removing discovered Full Access or Send As rights.
- Resolve Names to UPNs in Bulk — tenant-targeted bulk identity resolver with exact/likely/multiple/no-match decisions plus verified review CSV and exact-match UPN TXT exports.
- Bulk Entra Group Members Review — focused multi-group Entra direct-membership review with explicit tenant context, verified CSV, and ticket-ready summary.
- Bulk Disable User Accounts — guarded authority-aware bulk disable workflow with typed confirmation, post-change validation, optional session revoke/sync, verified CSV, and ticket-ready summary.

## Historical / Archive Lineage

These are useful references for behavior archaeology but should not compete for public catalog space.

- jumpbox-user-snapshot.ps1 — earlier bare-bones user security snapshot.
- jumpbox-mailbox-snapshot.ps1 — earlier bare-bones mailbox snapshot.
- jumpbox-tenant-snapshot.ps1 — earlier bare-bones tenant security snapshot.
- jumpbox-resolve-upns-clean.ps1 — older resolver; explicit tenant targeting was preserved in the public survivor.
- multi-name-to-upn-reviewed.ps1 — reviewed resolver lineage promoted into the public survivor.
- multi-name-to-upn-screen-only.ps1 — screen-only resolver variant; behavior is covered by the public survivor.
- get-user-mailbox-permissions-bulk.ps1 / mailbox-permissions-audit-bulk-clean.ps1 — older bulk mailbox review lineage; core checks are covered by Mailbox Permissions Review.
- user-mailbox-audit.ps1 / user-mailbox-audit-bulk.ps1 — older mailbox-access lineage; no distinct public job remained after comparison.
- group-members-audit-bulk-clean.ps1 / get-group-members-lookup-bulk.ps1 — older Entra-only bulk group-member implementation replaced by the hardened public survivor.
- user-account-disable-bulk-clean.ps1 — earlier bulk-disable implementation replaced by the validated authority-aware workflow.
- Legacy RMM BEC triage / exposure / preflight variants — retained privately; public RMM is limited to the current Incident Response RMM tools.
- IR drill setup / verify / teardown tools — removed from the public catalog; test-only.

## Review Pattern

When a limbo item is revisited:

1. Compare actual executable behavior, not just names or comments.
2. Identify unique coverage or edge cases.
3. Move useful logic into the best existing tool when that reduces choice without losing capability.
4. Publish a separate tool only when its job is clearly distinct and defensible.
5. Archive the remainder.
