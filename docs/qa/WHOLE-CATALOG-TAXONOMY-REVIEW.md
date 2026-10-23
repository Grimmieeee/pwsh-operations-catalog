# Whole-catalog taxonomy double-check

Review basis: main ee16829288e4d6e9c06c6eabe569e005c5ad3cf4. Review only; proposed taxonomy changes below are not implemented.

Coverage: all 329 catalog entries (81 scripts, 235 Quick Commands, 13 references). Compared current routing, source objectives and declared target scopes for scripts, command bodies/platforms for Quick Commands, and the earlier Tools/Endpoint review. This is taxonomy review, not full execution or renewed runtime acceptance.

## Additional findings

| Finding | Recommended correction |
|---|---|
| Create Dynamic License Group creates an Entra group of already-licensed users; it does not assign licenses. | Identity primary; Licensing secondary. Retain change impact. |
| Tenant Drift Review is excluded from Reporting because it can save a baseline. | Include in Reporting; preserve local baseline-write disclosure. |
| BEC: Decode Token is a local decoder, not a findings/report workflow. | Keep Incident Response; cross-list Security and Tools; exclude from Reporting. |
| Distribution Group Members is only under Identity. | Also list under Mailbox. |
| Mailbox Security Snapshot, Shared Mailbox Sign-in Audit, Transport Rules Audit, Tenant Inbox Rules Audit and Tenant Mailbox Access Audit have explicit security-review purposes. | Retain Mailbox primary; add Security entry points. Do not cross-list every mailbox operation merely because access is involved. |
| Reporting subviews cover user/mailbox targets and tenant scope only. Twelve current reports have group, IP or local targets. | Preserve access through All reports. Add clearly named target filters if needed; never relabel a group/IP/local workflow as Single User or Organization. Local execution and target scope are distinct. |
| Quick Commands uses broad keyword routing and fallbacks. Four Purview commands land in Windows CLI; Remote Desktop status lands in Terminal; ISP/location lookup lands in Windows CLI. | Explicit Purview, Endpoint and Network membership. Keep platform separate from domain. |
| Three pairs have identical command bodies after whitespace normalization. | One canonical entry per pair, preserve alternate names as search aliases and related links. |

Duplicate pairs: Remove All Inbox Rules / Delete All Inbox Rules; Show Wi-Fi Connection / Show Wi-Fi Interface; Show Locally Logged-On Users / Show Logged-On Users. Other similarly named commands were not assumed duplicates.

Resolve Names to UPNs produces a human-review mapping CSV and clean target TXT. Retain its Reporting membership as a mapping/inventory workflow; output purpose is substantive, not merely completion status. Pre-delete User Check likewise produces dependency findings and stays in Reporting. Change workflows do not become Reporting simply because they print an action summary or export execution evidence.

## Existing first-pass corrections still pending

Repository Inventory to Tools; Sensitive Data Check to Security with Tools secondary; PowerShell Readiness and Terminal Readiness out of Reporting; GitHub Security Check into Reporting with Security secondary. See SECTION-MEMBERSHIP-TOOLS-ENDPOINT.md for source-bound decisions.

## Drift prevention

Use explicit canonical entry memberships for domain, target scope, workflow purpose and impact independently. Replace the generic Tools fallback and command keyword routing with reviewed records. Allow justified cross-listing without duplicating source entries. Bind review records to source checksums. Require inventory coverage and expected membership/exclusion checks when sources change. Keep historical runtime acceptance separate from taxonomy review.

No additional top-level section is required. Remaining Identity, Licensing, Mailbox, Security, Incident Response, Endpoint, Tools, Extras and reference placements are defensible under these boundaries. Start Here remains within Home. Cards can follow the taxonomy corrections.

## Current Quick Command groups

- Active Directory: 20
- Graph: 35
- Account Response: 1
- Windows CLI: 84
- Exchange: 44
- Network CLI: 37
- Terminal: 9
- WinGet: 5
