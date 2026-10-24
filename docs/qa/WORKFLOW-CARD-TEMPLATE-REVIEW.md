# Workflow card template review

Reviewed all 81 downloadable PowerShell workflows. Quick Commands and reference documents are outside this sweep.

## Template

- Results: one short export note only when it adds useful information; otherwise omitted.
- Behavior: removed.
- Common Issues: zero to two source-matched blockers and short fixes. Optional export troubleshooting is omitted.
- Permissions: the existing reviewed access and technical requirements remain collapsed.
- Preview: explicit operator inputs use angle-bracket placeholders; collected sample data stays sample data.

## Edge cases

| Case | Treatment |
| --- | --- |
| BEC assessment, containment and recovery | Keep the incident handoff in STEPS; preserve partial-action and synchronization warnings in previews. |
| Existing terminals and session reset | Keep their specific launch/close behavior; do not imply a fresh sign-in or that another window is disconnected. |
| 18 workflows using implicit context or without runtime targets | No fabricated input prompt or placeholder. |
| Returned group members, delegates, tenant-wide users and findings | Keep illustrative sample data; these values are not operator inputs. |
| CSV headers, menu keys, approval words and script names | Keep literal syntax; bracket only replacement values. |
| JWT, API keys and certificate passwords | Use placeholders only; no live credentials or tokens. |
| Optional exports | Keep a short result note where relevant; omit secondary failure instructions. |
| Sparse/local visual tools | Omit Common Issues when no source-supported primary blocker is documented. |

## Validation

99 Node tests pass. Source integrity, impact, permissions, taxonomy, preview and detail gates pass. Downloadable script bytes and requested permissions were not changed; no new runtime acceptance is claimed.

## Per-script review

| Script | Source hash prefix | Result notes | Primary issues | Preview operator inputs |
| --- | --- | ---: | --- | --- |
| GET-QUARTERLY-CLEANUP-REVIEW.ps1 | df729d70508b | 1 | Required Graph access is missing; Required module is missing | Tenant domain |
| GET-STALE-SIGNIN-REVIEW.ps1 | 27e946107282 | 0 | Required module is missing | Implicit context / no runtime input |
| INVOKE-DISABLE-ACCOUNTS.ps1 | a123394ca9a0 | 0 | User address is invalid; CSV has no targets | User; TXT/CSV alternative; Sync server (optional) |
| INVOKE-DELETE-ACCOUNTS.ps1 | 0831cf439bc4 | 0 | User address is invalid; No writable domain controller is reachable | User; TXT/CSV alternative; Sync server (optional) |
| INVOKE-ASSIGN-LICENSES.ps1 | b41987e2a591 | 0 | Wrong tenant session; User address is invalid | User; TXT/CSV alternative; Tenant ID; License; UsageLocation (if missing) |
| INVOKE-REMOVE-LICENSES.ps1 | 0fb9b390bdc1 | 0 | Wrong tenant session; User address is invalid | User; TXT/CSV alternative; Tenant ID; License |
| RESOLVE-NAMES-TO-UPNS.ps1 | 8b150fd6e093 | 0 | Input file was not found; CSV column was not found | Name / email; TXT/CSV alternative; Tenant domain |
| GET-ACCOUNT-STATUS.ps1 | 94258427439c | 0 | User address is invalid; Required Graph access is missing | User; TXT/CSV alternative |
| GET-DISTRIBUTION-GROUP-MEMBERS.ps1 | c91680865f7b | 1 | Exchange module is missing; Group lookup failed | Group; TXT/CSV alternative |
| GET-GROUP-MEMBERS.ps1 | 5c7baa7d0551 | 0 | Group was not found; Required module is missing | Group; TXT/CSV alternative |
| GET-USER-GROUPS.ps1 | d0b71178ddca | 0 | User was not found; Required module is missing | User; TXT/CSV alternative |
| INVOKE-REMOVE-USER-GROUPS.ps1 | 8bc820639a1d | 0 | User address is invalid; User was not found | User; TXT/CSV alternative; Sync server (optional) |
| INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1 | 7ed4b8f50be4 | 0 | Wrong tenant session; More than one group matches | Group; Tenant ID; Mail nickname |
| GET-TENANT-GROUP-OWNERS.ps1 | dc04a5c13230 | 1 | Required module is missing | Implicit context / no runtime input |
| GET-MAILBOX-PERMISSIONS.ps1 | 76535edd6d3e | 1 | Mailbox lookup failed; Required module is missing | Mailbox; TXT/CSV alternative |
| GET-MAILBOX-SECURITY-SNAPSHOT.ps1 | e9e75ef77efe | 1 | Required module is missing | Mailbox |
| GET-MAILBOX-FORWARDING.ps1 | 0e184a41bd35 | 0 | Required module is missing | Mailbox; TXT/CSV alternative |
| INVOKE-LITIGATION-HOLD.ps1 | 1ea2ff740e1f | 0 | CSV has no targets; Required module is missing | Mailbox; TXT/CSV alternative; Ticket; Hold owner |
| BEC-INVOKE-EMAIL-RECOVERY.ps1 | bbbe2551ba60 | 0 | Required Graph access is missing; Required module is missing | Mailbox; Source folder; Target folder |
| BEC-RISK-ASSESSMENT.ps1 | 94526ec8ea67 | 0 | Account or tenant could not be verified; Next workflow script is missing | User; Tenant |
| BEC-CONTAIN-ERADICATE.ps1 | c8b857d6191a | 0 | Rule remains after removal; Next workflow script is missing | User; Tenant |
| BEC-GET-DATA-EXFIL-ACTIVITY.ps1 | 1fa5c320ff44 | 0 | Audit search is unavailable; Required module is missing | User; Lookback; IP filter (optional) |
| BEC-GET-IP-TRACE.ps1 | a97b049fad9c | 0 | Audit search is unavailable; Required module is missing | Target IP; Lookback |
| BEC-GET-TENANT-EMAIL-SEARCH.ps1 | 3a78895cbec1 | 0 | Message-trace command is unavailable; Required module is missing | Sender (optional); Recipient (optional); Source IP (optional); Lookback |
| BEC-GET-THREAT-INTEL-ACTIVITY.ps1 | e0864cdd7dd8 | 0 | No reputation API key; No eligible public IPs | Public IP / TXT; Provider key |
| BEC-GET-TIMELINE-BUILDER.ps1 | a80ca2ee465d | 0 | Case folder was not found | Case folder; Manual event (optional) |
| BEC-GET-TOKEN-DECODE.ps1 | 809933ffd675 | 0 | Token format is unsupported; Token could not be decoded | Token |
| BEC-GET-TOKEN-REPLAY-CHECK.ps1 | aacd5c9a0c91 | 1 | Required Graph access is missing; Required module is missing | User; Lookback |
| GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1 | 3f365d6e8677 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID; Lookback |
| GET-APP-REGISTRATION-AUDIT.ps1 | 76613d836742 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-CONDITIONAL-ACCESS-GAPS.ps1 | adebcd1ba46c | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-DEVICE-CODE-EXPOSURE.ps1 | 9595b261ea55 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID; Lookback |
| GET-GUEST-APP-CONSENT-AUDIT.ps1 | 0e9676a036af | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-MFA-SECURITY-AUDIT.ps1 | da69d7308448 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-SECURE-SCORE-SNAPSHOT.ps1 | bf4d87b38d22 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID; Previous snapshot (optional) |
| GET-SERVICE-PRINCIPAL-OWNERS.ps1 | 7f300774005a | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-SIGNIN-ANOMALIES.ps1 | dcde2b39589b | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID; Lookback; User filter (optional); Expected locations |
| GET-TRANSPORT-RULES-AUDIT.ps1 | 7c4ff63bee17 | 0 | Required module is missing | Implicit context / no runtime input |
| JOIN-COMPUTER-TO-DOMAIN.ps1 | 231cef1b8c4c | 0 | None added | Domain; Credentials; OU (optional); Ticket |
| DEPLOY-TCPIP-PRINTER.ps1 | adcb0d7445bb | 0 | None added | Printer; Address; Driver |
| BACKUP-USER-PROFILE.ps1 | dd1d1e62acc1 | 0 | None added | Source; Destination |
| TEST-POWERSHELL-READINESS.ps1 | fee19c4cac0b | 0 | Module installer is unavailable | Implicit context / no runtime input |
| GET-FOLDER-INVENTORY.ps1 | 218d4e788913 | 0 | Folder was not found | Folder |
| INSTALL-M365-MODULES.ps1 | 6c5fb208fea4 | 0 | Module installer is unavailable | Selection |
| TEST-SENSITIVE-DATA.ps1 | 594d18150acb | 0 | Path was not found | Path |
| RESET-M365-SESSION.ps1 | a08270181dc4 | 0 | None added | Implicit context / no runtime input |
| UPDATE-WINDOWS-APPS.ps1 | 32fcfc1c2984 | 0 | WinGet review failed | Implicit context / no runtime input |
| GET-USER-PREDELETE-CHECK.ps1 | 4ae5545f7382 | 1 | None added | User |
| INVOKE-ENFORCE-PER-USER-MFA.ps1 | 23a9db7bcacb | 0 | User address is invalid; Required Graph access is missing | User; TXT/CSV alternative |
| GET-ADMIN-ROLE-AUDIT.ps1 | 764cf4825fa9 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-OAUTH-CONSENT-AUDIT.ps1 | 3f18ee028932 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-GUEST-USER-AUDIT.ps1 | 641555328872 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-TENANT-LICENSING-AUDIT.ps1 | d9d7da1dc4f7 | 0 | Wrong tenant session; Tenant ID is invalid | Tenant ID |
| GET-TENANT-INBOX-RULES-AUDIT.ps1 | c0a1a2459471 | 0 | None added | Implicit context / no runtime input |
| GET-USER-SECURITY-SNAPSHOT.ps1 | b9d8d41d6fe8 | 1 | Required Graph access is missing; Required module is missing | User |
| GET-TENANT-SECURITY-SNAPSHOT.ps1 | 342829ae9c8d | 1 | Required module is missing | Implicit context / no runtime input |
| GET-ROOM-RESOURCE-ACCESS.ps1 | 476e8e8458b7 | 0 | Mailbox lookup failed; Required module is missing | Mailbox |
| GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1 | 90eadb894e2a | 0 | Required module is missing | Implicit context / no runtime input |
| CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1 | c50e6a31dbf3 | 0 | Required Graph access is missing; Required module is missing | User |
| GET-TENANT-DRIFT-REVIEW.ps1 | f5f1fdd5b2d6 | 0 | Baseline belongs to another tenant; Required Graph access is missing | Baseline |
| GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1 | 7af474157506 | 0 | Drive was not found | Drive |
| INVOKE-RESET-CLOUD-USER-PASSWORD.ps1 | 40abec4baa94 | 0 | User address is invalid; Required module is missing | User; TXT/CSV alternative |
| BEC-RECOVER-VALIDATE.ps1 | 1b21a21f15d6 | 0 | Account enablement did not verify; Next workflow script is missing | User; Tenant |
| git-handoff.ps1 | de09cbd42d12 | 0 | Handoff folder is tracked by Git | Repository |
| git-repo.ps1 | 3bcd5f6b61c9 | 0 | No upstream branch | Repository; Action; Commit message (send) |
| git-security.ps1 | 8082019f51b7 | 0 | Security export was not found; Security export is invalid | Account; Export |
| set-execution.ps1 | 4379e986662f | 0 | Execution policy did not change | Implicit context / no runtime input |
| attractor.ps1 | 126868034207 | 0 | None added | Implicit context / no runtime input |
| rain.ps1 | f793a1a68a82 | 0 | None added | Implicit context / no runtime input |
| static.ps1 | 4aa3ae630d96 | 0 | None added | Implicit context / no runtime input |
| SIGN-FOLDER-SCRIPTS.ps1 | 2890218ee695 | 0 | Signing certificate is missing | Folder; Certificate |
| GET-TERMINAL-READINESS-CHECK.ps1 | 0cdf541f4222 | 0 | None added | Kit root |
| INVOKE-FILE-INVENTORY.ps1 | 435f354240c3 | 1 | Output folder was not found; Root folder was not found | Root |
| INVOKE-MAP-KIT.ps1 | ea3b5ee21dbd | 0 | Root folder was not found; Path was not found | Root |
| INVOKE-SESSION-RESET.ps1 | 2fa5b247f31b | 0 | None added | Implicit context / no runtime input |
| SET-THEME-BASIC.ps1 | 9dc01f2210cf | 0 | None added | Implicit context / no runtime input |
| SET-THEME-COBALT.ps1 | 602ddcb368e7 | 0 | None added | Implicit context / no runtime input |
| SET-THEME-SEAGLASS.ps1 | 629b919cea8a | 0 | None added | Implicit context / no runtime input |
| SET-THEME-SILICON-VALLEY.ps1 | aab046497075 | 0 | None added | Implicit context / no runtime input |
| MANAGE-CERT-SIGNATURES.ps1 | d28176159f67 | 0 | Signing certificate is missing | Action; Certificate (when requested); Name (create); File (import/export); Password (private key) |
| PREPARE-FIELD-KIT.ps1 | 8b555611dffc | 0 | Module repository is not approved | Profile |

