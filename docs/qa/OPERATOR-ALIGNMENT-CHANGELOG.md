Latest purpose-statement follow-up: [all 80 matching objectives](CARD-OBJECTIVES-REVIEW.md). The earlier rollout below remains historical.

# Operator alignment — change log and follow-ups

Owner approved October 20, 2026. Base public release: 70bf66c. The Group Memberships pilot from PR #75 is included; its behavior changes remain separately attributable.

## Completed scope

- 80 script cards: approved short names, accurate scope and input format, STEPS before Download / View Code, one operational DETAILS disclosure and three task-related tools.
- 65 script presentation revisions: matching simple banners where available, one objective where needed, neutral completion markers in pause paths, and consistent Enter wording. Non-presentation token fingerprints compare unchanged with the immediate prior source.
- 15 specialized sources preserved byte-for-byte: coupled IR, Git commands, terminal animations/themes, execution setup and the folder-map helper. Their cards still use the shared design and explicit launch exceptions.
- All 315 scripts and quick commands have three task-related destinations. Shared card chrome and related-item links cover references too. The 235 quick-command texts, preparation commands, target examples and safety warnings remain intact. Source-pending entries remain unavailable.
- Existing script filenames and handoff filenames stay stable. Former titles remain searchable through the original metadata.
- Main navigation/dashboard is unchanged.

## Testing and release attribution

The original 78 accepted releases remain accepted for their recorded source and scope. This presentation pass does not reopen those batches or claim a new live tenant run. Changed files receive new presentation revisions and keep their prior evidence in OPERATOR-SCRIPT-ALIGNMENT.json. Under the existing exact-byte rule, 14 untouched releases keep the current VERIFIED mark; changed presentation revisions are not falsely marked as newly operator tested.

The Group Memberships pilot includes earlier result-state, identity-resolution and export changes. The 65-file presentation comparison starts from that pilot for this one script; it does not reclassify those prior behavior changes as mere wording.

Local checks passed: 44 JavaScript tests, 338-entry/92-source integrity gate, PowerShell parsing, required offline suites, 65 non-presentation token comparisons and deterministic metadata generation. Exact revised-source Windows/tenant execution and full pagination are not claimed. CI, code scanning and deployment are checked through the protected PR before publication.

## Follow-ups

| Item | Follow-up |
|---|---|
| 65 presentation revisions | Exact revised-source Windows acceptance remains separate from the accepted prior operational tests. |
| Get User Groups pilot | Confirm the revised not-found/partial outcomes, exact-identity resolution and exports in the client workflow; prior source acceptance is retained separately. |
| Get Group Owners | Banner is built through a reporting array rather than a simple top-level print. The existing GROUPS + OWNERS result heading is retained; finish prompt and actual final marker are aligned. |
| 15 specialized sources | Review their native title/finish controls individually if further alignment is useful; do not turn terminal helpers or IR handoffs into standalone auto-closing sessions. |
| Group targets | Get Group Members accepts group identifiers, not user UPNs. Scope intentionally says SINGLE or MULTI-GROUP. |
| Quick commands | Names and preparation are preserved. Duplicate/equivalent commands and deeper curation remain a separate review. |
| Source pending | Eleven entries remain planned with no download. Main-dashboard hiding/reorganization remains future work. |
| Browser coverage | Check live desktop/mobile card layout, related navigation, source view and downloads after deployment. Physical iPhone/Safari coverage is not implied by automated checks. |
| Existing known script limits | Prior source-specific findings, environment requirements and accepted test limits remain valid. No broad live security audit was performed by this presentation pass. |

## Every script

| Script | Card name | Scope | Source revision | Follow-up |
|---|---|---|---|---|
| GET-QUARTERLY-CLEANUP-REVIEW.ps1 | Review Account Cleanup | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-STALE-SIGNIN-REVIEW.ps1 | Review Stale Sign-ins | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-DISABLE-ACCOUNTS.ps1 | Disable User Accounts | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-DELETE-ACCOUNTS.ps1 | Delete User Accounts | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-ASSIGN-LICENSES.ps1 | Assign User Licenses | SINGLE or MULTI-USER | Presentation 1.0.3 | Recorded revision acceptance |
| INVOKE-REMOVE-LICENSES.ps1 | Remove User Licenses | SINGLE or MULTI-USER | Presentation 1.0.3 | Recorded revision acceptance |
| RESOLVE-NAMES-TO-UPNS.ps1 | Find User UPNs | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| GET-ACCOUNT-STATUS.ps1 | Get User Account Status | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| GET-DISTRIBUTION-GROUP-MEMBERS.ps1 | Get Distribution Group Members | SINGLE or MULTI-GROUP | Presentation 1.0.1 | Recorded revision acceptance |
| GET-GROUP-MEMBERS.ps1 | Get Group Members | SINGLE or MULTI-GROUP | Presentation 1.0.1 | Recorded revision acceptance |
| GET-USER-GROUPS.ps1 | Get User Groups | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-REMOVE-USER-GROUPS.ps1 | Remove User Groups | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1 | Create Dynamic License Group | SINGLE-GROUP | Presentation 1.0.2 | Recorded revision acceptance |
| GET-TENANT-GROUP-OWNERS.ps1 | Get Group Owners | TENANT | Presentation 1.0.1 | Console title is not a simple top-level banner; preserve rather than guess. |
| GET-MAILBOX-PERMISSIONS.ps1 | Get Mailbox Permissions | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| GET-MAILBOX-SECURITY-SNAPSHOT.ps1 | Get Mailbox Security | SINGLE-USER | Presentation 1.0.1 | Recorded revision acceptance |
| GET-MAILBOX-FORWARDING.ps1 | Get Mailbox Forwarding | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-LITIGATION-HOLD.ps1 | Set Litigation Hold | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| IR-INVOKE-EMAIL-RECOVERY.ps1 | Restore Email | SINGLE-USER | Presentation 1.0.1 | Recorded revision acceptance |
| ir-risk-assessment.ps1 | IR: Assess User Risk | SINGLE-USER | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| ir-contain-eradicate.ps1 | IR: Contain and Clean Up | SINGLE-USER | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| IR-GET-DATA-EXFIL-ACTIVITY.ps1 | IR: Review File Activity | SINGLE-USER | Presentation 1.0.1 | Recorded revision acceptance |
| IR-GET-IP-TRACE.ps1 | IR: Trace IP Activity | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| IR-GET-TENANT-EMAIL-SEARCH.ps1 | IR: Search Tenant Email | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| IR-GET-THREAT-INTEL-ACTIVITY.ps1 | IR: Check IP Reputation | SINGLE-IP | Presentation 1.0.1 | Recorded revision acceptance |
| IR-GET-TIMELINE-BUILDER.ps1 | IR: Build Incident Timeline | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| IR-GET-TOKEN-DECODE.ps1 | IR: Decode Token | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| IR-GET-TOKEN-REPLAY-CHECK.ps1 | IR: Review Token Replay | SINGLE-USER | Presentation 1.0.1 | Recorded revision acceptance |
| GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1 | Audit Shared Mailbox Sign-ins | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-APP-REGISTRATION-AUDIT.ps1 | Audit App Registrations | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-CONDITIONAL-ACCESS-GAPS.ps1 | Review Conditional Access | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-DEVICE-CODE-EXPOSURE.ps1 | Review Device Code Exposure | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-GUEST-APP-CONSENT-AUDIT.ps1 | Audit Guest App Consent | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-MFA-SECURITY-AUDIT.ps1 | Audit MFA Security | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-SECURE-SCORE-SNAPSHOT.ps1 | Get Secure Score | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-SERVICE-PRINCIPAL-OWNERS.ps1 | Get App Owners | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-SIGNIN-ANOMALIES.ps1 | Review Sign-in Anomalies | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-TRANSPORT-RULES-AUDIT.ps1 | Audit Mail Flow Rules | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| JOIN-COMPUTER-TO-DOMAIN.ps1 | Join Computer to Domain | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| DEPLOY-TCPIP-PRINTER.ps1 | Install Network Printer | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| BACKUP-USER-PROFILE.ps1 | Back Up User Profile | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| TEST-POWERSHELL-READINESS.ps1 | Check PowerShell Readiness | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| GET-FOLDER-INVENTORY.ps1 | Get Folder Inventory | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| INSTALL-M365-MODULES.ps1 | Install M365 Modules | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| TEST-SENSITIVE-DATA.ps1 | Check Sensitive Data | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| RESET-M365-SESSION.ps1 | Reset M365 Session | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| UPDATE-WINDOWS-APPS.ps1 | Update Windows Apps | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| GET-USER-PREDELETE-CHECK.ps1 | Check User Before Deletion | SINGLE-USER | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-ENFORCE-PER-USER-MFA.ps1 | Set Per-user MFA | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| GET-ADMIN-ROLE-AUDIT.ps1 | Audit Admin Roles | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-OAUTH-CONSENT-AUDIT.ps1 | Audit App Consent | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-GUEST-USER-AUDIT.ps1 | Review Guest Users | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-TENANT-LICENSING-AUDIT.ps1 | Audit Tenant Licenses | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-TENANT-INBOX-RULES-AUDIT.ps1 | Audit Tenant Inbox Rules | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-USER-SECURITY-SNAPSHOT.ps1 | Get User Security | SINGLE-USER | Presentation 1.0.1 | Recorded revision acceptance |
| GET-TENANT-SECURITY-SNAPSHOT.ps1 | Get Tenant Security | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-ROOM-RESOURCE-ACCESS.ps1 | Get Resource Mailbox Access | SINGLE or MULTI-MAILBOX | Presentation 1.0.1 | Recorded revision acceptance |
| GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1 | Audit Tenant Mailbox Access | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1 | Remove Disabled User Mailbox Access | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-TENANT-DRIFT-REVIEW.ps1 | Review Tenant Changes | TENANT | Presentation 1.0.1 | Recorded revision acceptance |
| GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1 | Review Windows Storage | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-RESET-CLOUD-USER-PASSWORD.ps1 | Reset Cloud User Password | SINGLE or MULTI-USER | Presentation 1.0.1 | Recorded revision acceptance |
| ir-recover-validate.ps1 | IR: Restore and Validate | SINGLE-USER | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| git-handoff.ps1 | Save Project Handoff | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| git-repo.ps1 | Manage Git Repository | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| git-security.ps1 | Review GitHub Security | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| set-execution.ps1 | Set Up Script Execution | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| attractor.ps1 | Attractor | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| rain.ps1 | Rain | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| static.ps1 | Static | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| SIGN-FOLDER-SCRIPTS.ps1 | Sign Scripts | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| GET-TERMINAL-READINESS-CHECK.ps1 | Check Terminal Readiness | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-FILE-INVENTORY.ps1 | Get File Inventory | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| INVOKE-MAP-KIT.ps1 | Map Folders | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| INVOKE-SESSION-RESET.ps1 | Reset Terminal Session | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
| SET-THEME-BASIC.ps1 | Basic Theme | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| SET-THEME-COBALT.ps1 | Cobalt Theme | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| SET-THEME-SEAGLASS.ps1 | Sea Glass Theme | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| SET-THEME-SILICON-VALLEY.ps1 | Silicon Valley Theme | LOCAL | Preserved | Preserved specialized workflow, terminal controls or reusable command behavior; card aligned. |
| MANAGE-CERT-SIGNATURES.ps1 | Manage Signing Certificates | LOCAL | Presentation 1.0.1 | Recorded revision acceptance |
