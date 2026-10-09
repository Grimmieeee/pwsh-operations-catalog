# FIELD // KIT Audit Limbo

This file tracks scripts and catalog entries intentionally kept out of the public library while overlap, edge-case value, or replacement status is reviewed.

The rule is simple: similarity alone is not enough to remove a tool. A duplicate is only removed when another tool preserves the useful behavior and edge cases without making the common job harder.

## Status Key

- HOLD — keep out of the public catalog until overlap is resolved.
- SALVAGE — useful behavior exists, but the current script is too broad, too mixed, or not clean enough to publish as-is.
- REPLACEMENT — likely successor to a current public tool; compare behavior before swapping.
- ARCHIVE — historical/test lineage with no current public role.

## Current Limbo

No current HOLD, SALVAGE, or REPLACEMENT items.

The project operating contract is now documented in `OPERATING-STANDARDS.md`. New overlap decisions should follow that file first, then be recorded here when lineage needs to be preserved. The reviewed overlaps from this audit have either been promoted into a stronger public survivor or archived as lineage.

## Resolved In This Audit

- Bulk mailbox review variants — archived. Mailbox Permissions Review already supports one or more mailboxes and keeps query failures visible; separate bulk cards added naming/output convenience rather than a distinct operational job.
- Mailbox Access Audit / Bulk Mailbox Access Audit — archived. Their useful permission/forwarding coverage is already represented by Mailbox Permissions Review, Mailbox Security Snapshot, and Tenant Mailbox Access Audit.
- Bulk Mailbox Forwarding and Permissions Audit — archived. Its useful checks overlap Mailbox Permissions Review; permissive error handling and CSV/summary convenience did not justify a competing public tool.
- Group-member variants — consolidated into `GET-GROUP-MEMBERS.ps1`. The canonical tool now accepts one group or TXT/CSV input, preserves Exchange → Entra → AD resolution, and supports verified member CSV output. The separate Entra-bulk public source was retired.
- Disable-account variants — consolidated into `INVOKE-DISABLE-ACCOUNTS.ps1`. The canonical workflow accepts one UPN or TXT/CSV input while preserving hybrid authority, typed confirmation, post-change validation, optional session revoke/sync, and verified export behavior.
- UPN resolver variants — consolidated into Resolve Names to UPNs; tenant targeting and reviewed exports were preserved while direct one-object input was added alongside TXT/CSV.
- Account-status variants — consolidated into `GET-ACCOUNT-STATUS.ps1`; one-object and TXT/CSV review now use the same read-only resolution and reporting path.
- License assignment/removal variants — consolidated into `INVOKE-ASSIGN-LICENSES.ps1` and `INVOKE-REMOVE-LICENSES.ps1`; one-user and bulk inputs share the same preview, confirmation, and post-change verification.
- Delete-account variants — consolidated into `INVOKE-DELETE-ACCOUNTS.ps1`; one or many targets now share the same destructive safeguards and per-object evidence.
- User-group review/removal variants — consolidated into `GET-USER-GROUPS.ps1` and `INVOKE-REMOVE-USER-GROUPS.ps1`. AD and Entra observations stay separate; synced duplicates remain visible while changes follow the authoritative source.
- Litigation-hold variants — consolidated into `INVOKE-LITIGATION-HOLD.ps1` with one-or-many mailbox input and common verification.
- Per-user MFA variants — consolidated into `INVOKE-ENFORCE-PER-USER-MFA.ps1`; the canonical workflow now accepts one or many users while preserving guarded change behavior.
- Identity snapshot variants — consolidated toward `GET-USER-SECURITY-SNAPSHOT.ps1` as the canonical one-user security/identity review; mailbox and IR snapshots remain separate because they answer different operational questions.
- Tenant-wide files mislabeled as multi-user — reclassified where appropriate as tenant reviews, including stale sign-in, group-owner, transport-rule, Conditional Access gap, and tenant-drift workflows.
- Signed/internal duplicates — treated as release artifacts rather than separate implementations when executable behavior matches the unsigned canonical source.
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
- Resolve Names to UPNs — tenant-targeted 1-to-N identity resolver with exact/likely/multiple/no-match decisions plus verified review CSV and exact-match UPN TXT exports.
- Group Members — canonical group-to-members review for one group or TXT/CSV input across Exchange, Entra, and Active Directory.
- User Group Memberships — canonical user-to-groups review for one user or TXT/CSV input; Active Directory and Entra are reported independently and synced Entra observations remain visible.
- Disable User Accounts — guarded authority-aware 1-to-N disable workflow with typed confirmation, post-change validation, optional session revoke/sync, verified CSV, and ticket-ready summary.

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
- group-members-audit-bulk-clean.ps1 / get-group-members-lookup-bulk.ps1 / GET-ENTRA-GROUP-MEMBERS-BULK.ps1 — older Entra-only or bulk-only group-member lineage absorbed into the canonical 1-to-N Group Members tool.
- user-account-disable-bulk-clean.ps1 / INVOKE-DISABLE-ACCOUNTS-BULK.ps1 — earlier bulk-only disable lineage absorbed into the canonical 1-to-N Disable User Accounts workflow.
- Legacy RMM BEC triage / exposure / preflight variants — retained privately; public RMM is limited to the current Incident Response RMM tools.
- IR drill setup / verify / teardown tools — removed from the public catalog; test-only.

## Canonical Source / Signing Decision

Signed internal copies, renamed copies, and public unsigned copies are one lineage when executable behavior is otherwise the same. The unsigned canonical source is the behavior source of truth; signing is a release step rather than a competing implementation.

Recent uploaded variants confirmed exact post-signature duplicates for distribution-group members, mailbox permissions, mailbox forwarding, mailbox snapshot, several IR utilities, and other public sources. Those copies are not separate catalog jobs.

## Review Pattern

When a limbo item is revisited:

1. Compare actual executable behavior, not just names or comments.
2. Identify unique coverage or edge cases.
3. Move useful logic into the best existing tool when that reduces choice without losing capability.
4. Publish a separate tool only when its job is clearly distinct and defensible.
5. Archive the remainder.
