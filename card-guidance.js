// Reviewed card copy, bound to exact source bytes. Wording review does not confer runtime verification.
window.FIELD_KIT_CARD_GUIDANCE = Object.freeze({
  "GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "checks": [
      "Disabled policies",
      "Report-only policies",
      "User / group exclusions",
      "Device-code gaps",
      "Location conditions",
      "Weak coverage indicators"
    ],
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "sourceSha256": "133e3a33c7a988c5e3ec93344355feb034c9fec685253f45aa27bf617d9549c3",
    "objective": "Reviews Conditional Access configuration for common coverage gaps and exceptions that warrant operator review.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + Policy.Read.All + Directory.Read.All",
    "notes": "Read-only Conditional Access posture review that flags disabled/report-only policies, exclusions, device-code gaps, location conditions, and other weak-coverage indicators.",
    "startMode": "right-click",
    "completion": {
      "result": "Policy settings and possible protection gaps are listed.",
      "next": "Review how the policies apply to the affected users; configuration flags alone do not prove effective coverage.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INVOKE-ASSIGN-LICENSES.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview, plus exact user sign-in names (UPNs) or a TXT/CSV list. Choose a license from the numbered list. Enter a country/region code only for users missing UsageLocation.",
    "checks": [
      "Available license types",
      "Checks each user’s license and any approved country/region change",
      "Shows failed or unconfirmed results; optional CSV report"
    ],
    "guards": [
      "Checks the tenant and signed-in account",
      "Shows each user, selected license, and country/region change before approval",
      "Type ASSIGN to approve; stops preparation if a user cannot be read"
    ],
    "sourceSha256": "289d921e47af9ba0d05c0ecaef218a25101c704529e9aa31c85e4aa5d1e158b5",
    "objective": "Assigns one selected Microsoft 365 license to one or more approved users and verifies the final assignment state.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + User.ReadWrite.All + Directory.Read.All + Organization.Read.All",
    "notes": "Shows available tenant SKUs, previews the selected license operation, optionally sets missing UsageLocation, requires typed ASSIGN confirmation, and re-reads each user to verify the selected SKU is present.",
    "startMode": "right-click",
    "completion": {
      "result": "Each user’s selected license and any approved country/region change are checked again.",
      "next": "Review failed or unconfirmed users; a successful license assignment does not prove every service is ready.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. Defaults offered: group name Dynamic-Group-AnyLicense and alias DG_AnyLicense; change them before approval if needed.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: Group.ReadWrite.All and Directory.Read.All; tenant rights and licensing for dynamic groups.",
    "guards": [
      "Checks the tenant and signed-in account",
      "Stops creation if an existing-group lookup fails or has more than one match",
      "Type CREATE to approve the displayed group and membership rule"
    ],
    "sourceSha256": "7068d41c2fecf17249bbcb888534987f046c68ebcbc51133b9c23186daf37153",
    "objective": "Creates and verifies an Entra dynamic security group for enabled users with an active license or service plan.",
    "notes": "Creates one Entra dynamic security group for enabled users with an active license/service plan. Shows the membership rule, requires typed CREATE confirmation, and re-reads the group to verify its dynamic configuration.",
    "startMode": "right-click",
    "completion": {
      "result": "The new group’s dynamic membership settings are checked after creation.",
      "next": "Check membership processing in Entra ID. Creating this group does not assign a license to it.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "INVOKE-REMOVE-LICENSES.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview, plus exact user sign-in names (UPNs) or a TXT/CSV user list (UPN column recommended). Choose a license from the numbered list, or ALL.",
    "checks": [
      "Current assigned licenses",
      "Checks each user’s licenses after removal",
      "Shows failed or unconfirmed results; optional CSV report"
    ],
    "guards": [
      "Checks the tenant and signed-in account",
      "Shows each user and selected license before approval",
      "Type REMOVE to approve; cancelling makes no changes"
    ],
    "sourceSha256": "eedbc44f46a0078347ebe4b7ac414b197ba47e6449a7ee8162b40ba9aeb13450",
    "objective": "Removes one selected license or all licenses from one or more approved users and verifies the final state.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + User.ReadWrite.All + Directory.Read.All + Organization.Read.All",
    "notes": "Validates the expected tenant, previews each exact target UPN and planned license, requires one typed REMOVE approval, and re-reads each user. Failed or unverified results remain incomplete. License removal alone is not offboarding.",
    "startMode": "right-click",
    "completion": {
      "result": "Each user’s licenses are checked again after the approved removal.",
      "next": "Review failed or unconfirmed users. License removal alone does not complete offboarding.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "input": "Tenant domain (for example, contoso.com). Default inactivity threshold: 90 days.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, AuditLog.Read.All, Group.Read.All; ExchangeOnlineManagement with recipient-read access.",
    "checks": [
      "Enabled users with old or missing sign-in records",
      "Active admin roles and cloud groups with no owner",
      "External mailbox forwarding"
    ],
    "guards": [
      "Shows failed checks; exports only when requested",
      "Desktop HTML report is optional; keep exported client information private"
    ],
    "sourceSha256": "dfc7e8526aea4a3bfd36d934dad90378fde0800514fd597aa6ad6e2da6288093",
    "objective": "Reviews stale enabled users, admin roles, ownerless cloud groups, and external mailbox forwarding across a tenant.",
    "notes": "Periodic read-only tenant hygiene review covering stale enabled users, active admin-role counts, ownerless cloud-manageable groups, and external mailbox forwarding.",
    "startMode": "right-click",
    "completion": {
      "result": "Findings for old sign-ins, admin roles, groups without owners, and external forwarding; failed checks remain gaps.",
      "next": "Review each finding before planning cleanup. This tool makes no tenant changes. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information."
  },
  "GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "checks": [
      "Finds the requested distribution group",
      "Direct member details",
      "Optional member CSV"
    ],
    "guards": [
      "Shows failed lookups and groups with more than one match"
    ],
    "sourceSha256": "9e7862eefbdb1c7c89177f076d2c8030b26b65869623d6414f9ebf005d16f0ea",
    "objective": "Shows who belongs to one or more Exchange Online distribution groups.",
    "input": "Distribution group names or email addresses, entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Focused Exchange Online lookup for one or more distribution groups. Accepts a direct group name/address or TXT/CSV input and can export verified member detail.",
    "startMode": "right-click",
    "completion": {
      "result": "Direct members of the requested distribution groups, with lookup problems shown.",
      "next": "Review unresolved group names; nested groups require their own membership review.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INVOKE-REMOVE-USER-GROUPS.ps1": {
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: User.Read.All, Group.Read.All, GroupMember.ReadWrite.All; ActiveDirectory module and AD change rights for synced memberships.",
    "checks": [
      "Group memberships in Active Directory and Entra ID",
      "Removal results and remaining memberships",
      "Optional CSV report, checked after saving"
    ],
    "guards": [
      "Complete removal plan before changes",
      "Typed REMOVE GROUPS confirmation",
      "Skips dynamic groups, groups used for admin roles, and Exchange-managed groups",
      "Changes synced group memberships in Active Directory"
    ],
    "sourceSha256": "a813ab576da5f82eb11ae0d1ee6e26134b03997e73692c9e5d6181ed20d09b55",
    "objective": "Remove the reviewed, removable group memberships for approved users; skip protected and unsupported groups.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional sync server if you request an immediate sync.",
    "notes": "Offboarding-style cleanup for one or many users. Shows Active Directory and Entra memberships independently, keeps synced Entra observations visible, acts once at the authoritative source, skips dynamic/role-assignable/Exchange-managed memberships, requires typed REMOVE GROUPS confirmation, and validates removals.",
    "startMode": "right-click",
    "completion": {
      "result": "Removal results and remaining memberships for the approved users.",
      "next": "Review failed and skipped memberships. Check synchronized changes in Entra ID before closing the work.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "checks": [
      "Current per-user MFA state",
      "Post-change MFA state for each user"
    ],
    "guards": [
      "Shows every target before approval",
      "Typed ENFORCE confirmation",
      "Does not replace Conditional Access or Security Defaults"
    ],
    "sourceSha256": "52c6ce8dc1af2323b9dcc6c831cdd211b555ae44280417181599290212fcf7bd",
    "objective": "Enforces legacy per-user MFA for one or more approved accounts and verifies the final state.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + Policy.ReadWrite.AuthenticationMethod + UserAuthenticationMethod.Read.All + User.Read.All",
    "notes": "Uses the Microsoft Graph beta authentication requirements endpoint. Per-user MFA is separate from Conditional Access and Security Defaults. Shows all target states first, requires typed ENFORCE confirmation, and re-reads each user to verify the resulting MFA state.",
    "startMode": "right-click",
    "completion": {
      "result": "Each approved user’s per-user MFA setting is checked again.",
      "next": "Confirm the intended sign-in experience. This legacy setting does not replace Conditional Access or Security Defaults.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement; rights to read recipient, mailbox configuration, inbox rules and mailbox permissions. Microsoft Graph is not used.",
    "sourceSha256": "10e8a2aae2fff3b4a3708510008ac6a1f9b7892358256480c7a57d6a8dfabe2c",
    "objective": "Checks a mailbox for forwarding, rules, delegates, and other access that may matter during an investigation.",
    "input": "One mailbox sign-in name (UPN).",
    "notes": "Reviews forwarding, inbox rules, permissions, and legacy protocol state.",
    "startMode": "right-click",
    "completion": {
      "result": "Mailbox forwarding, rules, permissions, and mail-protocol settings.",
      "next": "Use the findings to choose deeper checks or approved containment; this snapshot does not clear an incident. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "guards": [
      "Desktop HTML report is optional; keep exported client information private"
    ]
  },
  "IR-INVOKE-EMAIL-RECOVERY.ps1": {
    "input": "Mailbox sign-in name (UPN). Defaults: move from RSS Subscriptions to Restored Messages, looking back 24 hours. Review or change the folders before approving moves.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: delegated Mail.ReadWrite.Shared AND existing access to the target mailbox/folders. An admin role alone does not grant mailbox access.",
    "checks": [
      "Folders selected for the email move",
      "Message preview and selected move results",
      "Checks both folders after moving email"
    ],
    "guards": [
      "Preview and typed MOVE confirmation",
      "Target folder creation requires approval"
    ],
    "sourceSha256": "e00946f377bdd4b0e9eb87d04025906763bb8c7307ecdaf87f5016f006ea6aaf",
    "objective": "Moves email back to the mailbox location you choose after an incident.",
    "notes": "Moves messages back from attacker-hidden or incorrect folders.",
    "startMode": "right-click",
    "completion": {
      "result": "Selected email moves and checks of the source and recovery folders.",
      "next": "Have the user confirm the recovered messages are in the expected place. Review any failed moves before retrying.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "ir-risk-assessment.ps1": {
    "reviewNote": "Known limitation: app display names may be unresolved. Review the app IDs and grants; an unresolved name does not clear a finding.",
    "checks": [
      "Account status, password change date, and admin roles",
      "Sign-in methods and enabled Conditional Access policies",
      "Up to 25 recent sign-ins from the last 10 days",
      "Mailbox rules, forwarding, shared access, app permissions, and mail protocols"
    ],
    "guards": [
      "Read-only assessment; no tenant changes",
      "Shows checks that could not run; findings need review before deciding the account is compromised"
    ],
    "sourceSha256": "07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b",
    "objective": "Check an account and mailbox for suspicious activity before deciding on containment.",
    "input": "One exact user sign-in name (UPN) and tenant domain. Later steps reuse the user and checked connection in the same PowerShell window.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Windows jumpbox; Microsoft.Graph.Authentication 2.x; ExchangeOnlineManagement 3.2+; delegated tenant rights. AD changes require local Windows AD rights.",
    "notes": "Makes no tenant changes. Conditional Access is an enabled-policy inventory, not proof of user coverage. User-tested on a client jumpbox; module versions, tenant policy and AD/cloud synchronization still need environment-specific validation. Keep all three files together and launch in one existing PowerShell window. No automatic delta sync, exports, module installs or execution-policy changes. Read the IR workflow guide before use.",
    "details": "Keep all three scripts in one folder and use the same PowerShell window. Sign-in requests permissions for all three steps; assessment makes no tenant changes. There is no automatic sync, export, module install, or execution-policy change. Module compatibility, local AD permissions, and synchronization must be checked for the client. The policy list does not prove that Conditional Access protects this user.",
    "startMode": "workflow"
  },
  "ir-contain-eradicate.ps1": {
    "checks": [
      "Results of blocking sign-in, resetting the password, and revoking sessions",
      "Selected mailbox rules, forwarding, and shared access",
      "Selected app permissions and the result after removal"
    ],
    "guards": [
      "Runs only the actions you select and approve",
      "For synced users, matches the Windows security ID (SID) to Active Directory; local AD permissions are required",
      "Does not force a sync; check that changes reach Entra ID",
      "Shows a temporary password only after reset; clears its variable after you confirm secure delivery"
    ],
    "sourceSha256": "e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb",
    "objective": "Block an approved account and remove selected mailbox access, rules, forwarding, and app permissions.",
    "input": "One exact user sign-in name (UPN) and tenant domain. Later steps reuse the user and checked connection in the same PowerShell window.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Windows jumpbox; Microsoft.Graph.Authentication 2.x; ExchangeOnlineManagement 3.2+; delegated tenant rights. AD changes require local Windows AD rights.",
    "notes": "Revocation, sign-in block, password reset and selected persistence deletion require explicit approvals. Synced AD changes use a SID-matched account. MFA is operator-confirmed, not independently enforced by the script. A temporary password can appear in terminal capture/transcripts; no automatic export or clipboard copy. User-tested on a client jumpbox; module versions, tenant policy and AD/cloud synchronization still need environment-specific validation. Keep all three files together and launch in one existing PowerShell window. No automatic delta sync, exports, module installs or execution-policy changes. Read the IR workflow guide before use.",
    "details": "Keep all three scripts in one folder and use the same PowerShell window. Sign-in requests permissions for all three steps; assessment makes no tenant changes. There is no automatic sync, export, module install, or execution-policy change. Module compatibility, local AD permissions, and synchronization must be checked for the client. You confirm trusted MFA methods; the script does not enforce them. A temporary password can remain in terminal capture/transcripts even after its variable is cleared.",
    "startMode": "workflow"
  },
  "ir-recover-validate.ps1": {
    "checks": [
      "Rechecks the account, mailbox, and remaining unwanted access",
      "Checks that the account was enabled in the system that manages it",
      "Recovery summary and sign-in/MFA follow-up"
    ],
    "guards": [
      "You confirm the user, cleanup, investigation scope, and trusted MFA methods",
      "Explicit approval before restoring access",
      "A pending sync is not reported as confirmed recovery",
      "No password reset or persistence removal in recovery"
    ],
    "sourceSha256": "c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04",
    "objective": "Confirm recovery readiness and restore approved account access.",
    "input": "One exact user sign-in name (UPN) and tenant domain. Later steps reuse the user and checked connection in the same PowerShell window.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Windows jumpbox; Microsoft.Graph.Authentication 2.x; ExchangeOnlineManagement 3.2+; delegated tenant rights. AD changes require local Windows AD rights.",
    "notes": "RECOVER attests user identity, remediation, trusted MFA methods and owner approval. Rechecks available evidence; does not reset a password. User sign-in with MFA and monitoring remain required. User-tested on a client jumpbox; module versions, tenant policy and AD/cloud synchronization still need environment-specific validation. Keep all three files together and launch in one existing PowerShell window. No automatic delta sync, exports, module installs or execution-policy changes. Read the IR workflow guide before use.",
    "details": "Keep all three scripts in one folder and use the same PowerShell window. Sign-in requests permissions for all three steps; assessment makes no tenant changes. There is no automatic sync, export, module install, or execution-policy change. Module compatibility, local AD permissions, and synchronization must be checked for the client. Recovery does not reset passwords or remove unwanted access. Verify user sign-in with MFA and complete the follow-up monitoring.",
    "startMode": "workflow"
  },
  "IR-GET-DATA-EXFIL-ACTIVITY.ps1": {
    "input": "Target UPN; lookback days (default 30, maximum 90); optional source IP.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement; permission to run Search-UnifiedAuditLog.",
    "checks": [
      "SharePoint and OneDrive download and sharing events",
      "Source IP addresses and bursts of downloads",
      "Optional activity CSV"
    ],
    "guards": [
      "Unusual activity needs review; it does not prove data was stolen"
    ],
    "sourceSha256": "73a83bd02db13481dbd1feb9d9088bfedf6a5f925c09fa71c241eaa83f9746a0",
    "objective": "Looks for unusual file activity that could indicate data was copied or taken.",
    "notes": "Reviews SharePoint/OneDrive activity for possible download, sharing, or exfiltration behavior.",
    "startMode": "right-click",
    "completion": {
      "result": "Available file-download and sharing events, plus download-burst indicators.",
      "next": "Investigate unusual events using the original records; the flags do not prove that data was stolen.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "IR-GET-IP-TRACE.ps1": {
    "input": "Suspect IP; lookback days (default 7, maximum 90).",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement; permission to run Search-UnifiedAuditLog.",
    "checks": [
      "Unified Audit Log activity for the source IP",
      "Daily search windows and optional CSV"
    ],
    "guards": [
      "Shows failed search periods and results cut short by limits"
    ],
    "sourceSha256": "6f1bacdb932aa3e2e5077b3c810a0cfb9969e4c24b07e285e1ecdf53d3fffd2d",
    "objective": "Finds tenant activity tied to an IP address.",
    "notes": "Pivots on a source IP across tenant audit activity.",
    "startMode": "right-click",
    "completion": {
      "result": "Available audit events for the IP, with failed search periods and limits reported.",
      "next": "Review the events in context and resolve gaps before describing the search as complete.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "IR-GET-TENANT-EMAIL-SEARCH.ps1": {
    "input": "Sender, recipient or source IP; lookback days (default 7, maximum 90).",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement with Get-MessageTraceV2; message-trace read rights.",
    "checks": [
      "Message traces matching supplied indicators",
      "Search windows and optional CSV"
    ],
    "guards": [
      "Searches in periods of up to 10 days; reports results cut short by limits"
    ],
    "sourceSha256": "e4b41e56c30b37ea2ec5de44d5e2851fd5fd1c656122d03d9b2a21b4c89de83c",
    "objective": "Find email delivery records by sender, recipient, or source IP address.",
    "notes": "Searches tenant message trace by sender, recipient, source IP, or combination.",
    "startMode": "right-click",
    "completion": {
      "result": "Matching email delivery records, with search periods and result limits shown.",
      "next": "Review recipients and delivery status; use a separate content-search tool when message content is needed.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "IR-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "input": "Public IP addresses or TXT list; API key for each enabled provider.",
    "requires": "HTTPS access to the selected VirusTotal and/or AbuseIPDB API; provider API keys. No M365 connection.",
    "checks": [
      "VirusTotal and/or AbuseIPDB IP reputation",
      "Optional reputation CSV"
    ],
    "guards": [
      "Selected public IPs are sent to enabled providers",
      "API keys are not written to disk by this script"
    ],
    "sourceSha256": "a9126fcc537a71b9471d49ecfe5f714ede93bc5e1306b3eee9fe9ea7f014859a",
    "objective": "Check public IP addresses against VirusTotal or AbuseIPDB reputation reports.",
    "notes": "Adds reputation context to suspicious IP addresses.",
    "startMode": "right-click",
    "completion": {
      "result": "Reputation results from the enabled providers, or their lookup errors.",
      "next": "Compare reputation with client evidence. A clean reputation result does not prove an IP is safe.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "IR-GET-TIMELINE-BUILDER.ps1": {
    "input": "Local case folder or manual event entries; optional search text.",
    "checks": [
      "Events sorted by time from JSON, text, log, and Markdown files",
      "Optional manual events and TXT timeline"
    ],
    "guards": [
      "Labels events that use a file modification time instead of an event time",
      "Source evidence is never modified"
    ],
    "sourceSha256": "483a49fbc5439e1f6282a5fefd44bc6b085376092a27659991f056385b9d4469",
    "objective": "Builds a simple incident timeline from collected events.",
    "requires": "Local case outputs",
    "notes": "Builds a simple chronology from IR notes, logs, JSON, or manual entries.",
    "startMode": "right-click",
    "completion": {
      "result": "Events sorted by time and an optional saved timeline.",
      "next": "Check event time zones and entries based on file modification times before sharing the timeline.",
      "blocked": "If input cannot be read, check its path or format. Keep the original evidence unchanged."
    }
  },
  "IR-GET-TOKEN-DECODE.ps1": {
    "checks": [
      "Decodes the token header and contents on this computer"
    ],
    "guards": [
      "No network or export",
      "Does not check whether the token is signed, trusted, or usable"
    ],
    "sourceSha256": "89be0780dd4434bbd1dfebf54bfe06df1f0bb3db23f1df111b1a3143f57918bf",
    "objective": "Decodes a JWT locally so you can inspect its claims.",
    "input": "JWT token",
    "requires": "PowerShell on this computer.",
    "notes": "Decodes JWT header/payload locally for claim inspection.",
    "startMode": "right-click",
    "completion": {
      "result": "The token’s decoded header and contents are shown locally.",
      "next": "Inspect the claims without treating decoding as proof of a valid or trusted token. Keep the token private.",
      "blocked": "If input cannot be read, check its path or format. Keep the original evidence unchanged."
    }
  },
  "IR-GET-TOKEN-REPLAY-CHECK.ps1": {
    "input": "Target UPN; lookback hours (default 48); expected country/region (default US).",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: User.Read.All, AuditLog.Read.All, IdentityRiskEvent.Read.All; tenant licensing and role access for the requested logs.",
    "checks": [
      "Entra sign-ins and Identity Protection risk detections",
      "Risk signals related to stolen tokens, plus sign-in locations"
    ],
    "guards": [
      "Unavailable data remains a limitation",
      "An unexpected location alone does not prove a stolen session",
      "Desktop HTML report is optional; keep exported client information private"
    ],
    "sourceSha256": "5b2d89608eb132a45412260ed831f4c17030ea00b073f80789b5b5dcd4cb3d52",
    "objective": "Looks for sign-in patterns that may indicate a stolen session or AiTM attack.",
    "notes": "Looks for suspicious sign-in patterns consistent with token replay/AiTM.",
    "startMode": "right-click",
    "completion": {
      "result": "Available sign-in and risk records for the user and selected time period.",
      "next": "Review token-specific signals and missing data; an unexpected location alone does not prove a stolen session. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information."
  },
  "GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, Application.Read.All.",
    "checks": [
      "App permissions approved by guest users",
      "App and service names when they can be found",
      "Granted app permissions that may create risk"
    ],
    "sourceSha256": "4eda293e510d60604da0508715db31807223de1cd5cfa9f3b356393d715f6c18",
    "objective": "Finds guest app consent and access that may need review.",
    "notes": "Reviews guest/application consent exposure.",
    "startMode": "right-click",
    "completion": {
      "result": "Guest-approved app permissions and the permissions flagged for review.",
      "next": "Confirm the guest, app, and business need before revoking access.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default sign-in review period: 72 hours.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: ExchangeOnlineManagement with recipient-read access; Microsoft.Graph.Authentication: AuditLog.Read.All, User.Read.All, Directory.Read.All; sign-in log role and licensing access.",
    "sourceSha256": "6ebe7be5484bca187bd5182753057874c43daa87a55956e40e4ccdef74f97f0a",
    "objective": "Shows whether shared mailboxes are being signed into directly.",
    "notes": "Finds shared mailboxes with direct sign-in exposure.",
    "startMode": "right-click",
    "completion": {
      "result": "Shared-mailbox sign-in records for the selected period.",
      "next": "Investigate unexpected direct sign-ins and confirm that log access covered the period needed.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-APP-REGISTRATION-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default credential-expiry warning: within 30 days.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: Application.Read.All, Directory.Read.All.",
    "sourceSha256": "8d82e57d695c5ee034525d3664dd4d6dc257c2c9345b49cfbbed24a526c942c3",
    "objective": "Finds app registrations with risky permissions, expiring credentials, or missing owners.",
    "notes": "Reviews app registrations and related security posture.",
    "startMode": "right-click",
    "completion": {
      "result": "App credentials, permission flags, and owner findings.",
      "next": "Confirm an app’s purpose and owner before changing permissions or rotating credentials.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-DEVICE-CODE-EXPOSURE.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default sign-in review period: 72 hours.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: Policy.Read.ConditionalAccess, AuditLog.Read.All, Directory.Read.All; policy/sign-in log role and licensing access.",
    "sourceSha256": "2a064c402cd8dda51e4f7ade3a9c3ed7645784ffc9f63804820dec3dc8aca2db",
    "objective": "Checks whether device-code sign-in is exposed and whether it has been used recently.",
    "notes": "Reviews device-code authentication exposure.",
    "startMode": "right-click",
    "completion": {
      "result": "Device-code policy settings and recent device-code sign-ins.",
      "next": "Check whether each sign-in is expected before planning policy changes.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-MFA-SECURITY-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, Reports.Read.All, UserAuthenticationMethod.Read.All; Policy.Read.ConditionalAccess when CA review is requested; appropriate report-read role.",
    "sourceSha256": "6eb755d2b8190da12132b30eb0080b2367a35a28129ac1f239d3c098571b444d",
    "objective": "Shows where MFA coverage or registered methods may leave gaps.",
    "notes": "Reviews MFA coverage and security gaps.",
    "details": "Default review covers MFA registration and methods. To include Conditional Access policy review, launch in a terminal with -IncludeConditionalAccess. Policy settings alone do not prove protection for every user.",
    "startMode": "right-click",
    "completion": {
      "result": "MFA registration and method findings; policy review is included only when requested.",
      "next": "Check users with missing or weaker methods. Registration does not prove MFA is enforced for every sign-in.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Optional previous JSON snapshot for comparison.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: SecurityEvents.Read.All, SecurityActions.Read.All, Directory.Read.All; Secure Score read access.",
    "sourceSha256": "707321b6f1ae7285ae0ccb03b2061ae36280432bf6b296d72bde8ad93ba03db0",
    "objective": "Shows the tenant's current Microsoft Secure Score and the areas affecting it.",
    "notes": "Captures Microsoft Secure Score posture.",
    "startMode": "right-click",
    "completion": {
      "result": "Current Secure Score data and a comparison when a previous snapshot is supplied.",
      "next": "Prioritize controls that fit the client; the score is not proof that the tenant is secure.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: Application.Read.All, Directory.Read.All, User.Read.All.",
    "sourceSha256": "15c73ae6c21e78fc694aa3b0f20b4a6c941a9c5a7dbb5b328935eb77dfeb6a5f",
    "objective": "Find enterprise apps (service principals) with missing or unclear owners.",
    "notes": "Reviews enterprise/service principal ownership.",
    "startMode": "right-click",
    "completion": {
      "result": "Enterprise app owners and apps with no recorded owner.",
      "next": "Confirm who manages each app before assigning or removing owners.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-SIGNIN-ANOMALIES.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. Defaults: last 24 hours, expected country US, up to five pages of results. Optional user sign-in name (UPN) filter.",
    "guards": [
      "Shows expected countries before flagging sign-ins from elsewhere",
      "Marks the review incomplete when the page limit is reached",
      "Stops if required data is missing or cannot be read"
    ],
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication: AuditLog.Read.All, User.Read.All, Directory.Read.All; sign-in log role and licensing access.",
    "sourceSha256": "bbc41b082ff6daff44f853527b6afe0a609b8ae29cecea4ad5c4bc22f2e77782",
    "objective": "Surfaces unusual sign-ins that deserve a closer look.",
    "notes": "Reviews suspicious or anomalous tenant sign-ins.",
    "startMode": "right-click",
    "completion": {
      "result": "Sign-ins flagged against the selected countries and time period, with page-limit gaps shown.",
      "next": "Review flagged events and any incomplete coverage before deciding the activity is expected or suspicious.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "checks": [
      "Administrator access, computer name, and current domain",
      "DNS settings and connection to the requested domain",
      "Domain join result"
    ],
    "guards": [
      "Typed JOIN confirmation",
      "Restart only when approved"
    ],
    "sourceSha256": "5e089c864ee6a869b050ccdfd7b6666b683eae845d188f8d1e3ba3c27d4d8f12",
    "objective": "Checks the workstation first, then joins it to an Active Directory domain only after typed confirmation.",
    "input": "Target domain and domain-join credentials. Optional organizational-unit path (OU) and ticket number.",
    "requires": "Local administrator + domain join credentials",
    "notes": "Runs admin, hostname, current-domain, DNS, and reachability checks before Add-Computer.",
    "startMode": "terminal-admin",
    "completion": {
      "result": "The approved domain join reports its result; a restart occurs only if approved.",
      "next": "Restart when required, then confirm domain membership and a permitted domain sign-in.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "DEPLOY-TCPIP-PRINTER.ps1": {
    "checks": [
      "Printer reachability and installed driver",
      "TCP/IP port and printer creation",
      "Optional default-printer and test-page actions"
    ],
    "guards": [
      "Typed ADD confirmation before adding the printer"
    ],
    "sourceSha256": "2bed1d7391d8bf6a27b2127c806c246fd93b2fe7e62d8b91268b17a31bf79649",
    "objective": "Adds a direct TCP/IP printer after checking reachability, driver availability, and existing printer state.",
    "input": "Printer display name and IP address or host name. Select an installed driver by its exact name; the script can list drivers.",
    "requires": "An installed printer driver and Windows permission to manage printers. The script does not download a driver.",
    "notes": "Creates the TCP/IP port when needed, adds the printer, and can set default or print a test page.",
    "startMode": "right-click",
    "completion": {
      "result": "The printer and TCP/IP port are created or their existing state is reported.",
      "next": "Print a test page and confirm the intended default printer with the user.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "BACKUP-USER-PROFILE.ps1": {
    "checks": [
      "Common profile folders and optional Downloads",
      "Dated destination folder and local copy log"
    ],
    "guards": [
      "Typed BACKUP confirmation before copying profile data"
    ],
    "sourceSha256": "f51c3c9ff843c5a569765c635a2e57a71b221d11f3bf64266775701a7af6abb6",
    "objective": "Copies common Windows profile folders to a dated backup location and writes a local backup log.",
    "input": "Profile folder to back up (blank uses your profile), backup destination, and whether to include Downloads.",
    "requires": "Read access to the profile folders and write access to the backup destination.",
    "notes": "Backs up Desktop, Documents, Pictures, Favorites, Signatures, Templates, and optionally Downloads.",
    "startMode": "right-click",
    "completion": {
      "result": "A dated backup folder and a copy log for the selected profile folders.",
      "next": "Review copy errors and open representative backed-up files before removing the original data.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-USER-PREDELETE-CHECK.ps1": {
    "input": "One exact user sign-in name (UPN). Access to the user’s Active Directory domain is needed for local AD checks.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: ActiveDirectory module/domain read access for AD coverage; Microsoft.Graph.Authentication: User.Read.All, Group.Read.All, Directory.Read.All; ExchangeOnlineManagement with mailbox, permission, transport-rule and retention read rights.",
    "checks": [
      "Active Directory account, groups, owned objects, and direct reports",
      "Mailbox forwarding, shared access, retention, and usage",
      "Mail groups, mail-flow rules, and Entra objects that depend on this user",
      "Direct application assignments and licenses"
    ],
    "guards": [
      "Review only; does not delete the user",
      "Desktop HTML report is optional; keep exported client information private"
    ],
    "sourceSha256": "e7e86d7ae9e59ba32a7752feb55562b782fc5cf6623b3f33d7c584ef6d945f0f",
    "objective": "Checks a user's identity, mailbox, ownership, app access, licenses, and retention dependencies before the AD object is removed.",
    "notes": "Read-only dependency review before deleting an on-premises AD user object; does not prove third-party or local-system dependencies are safe.",
    "startMode": "right-click",
    "completion": {
      "result": "Available identity, mailbox, ownership, app, license, and retention dependencies are listed.",
      "next": "Resolve dependencies and missing checks before deleting the account. Third-party and local-system dependencies still need separate review. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information."
  },
  "GET-ADMIN-ROLE-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default old-sign-in threshold: 30 days.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "checks": [
      "Active Entra directory role assignments",
      "Account status, where it is managed, and recorded last sign-in",
      "Optional role-review CSV"
    ],
    "sourceSha256": "58862647a3ffb1bb3b7b1e3d3879ca671de475ee7da90183af9247f0a54bd696",
    "objective": "Shows who has active Entra admin roles and flags disabled or stale admin accounts.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Directory.Read.All + RoleManagement.Read.Directory + User.Read.All + AuditLog.Read.All",
    "notes": "Reviews active Entra admin-role assignments with account state, hybrid status, and recent sign-in context.",
    "startMode": "right-click",
    "completion": {
      "result": "Active admin-role assignments with account status and available sign-in context.",
      "next": "Confirm whether the roles are still needed; this is not a complete review of eligible roles available through PIM.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-OAUTH-CONSENT-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "checks": [
      "App permissions approved on behalf of users",
      "App and service names when available",
      "Permissions that may create risk; optional CSV report"
    ],
    "sourceSha256": "c1a55d472ac898b856b1c93bb7ea1c945d62600dc2849bd7828381d2e0e5a6d4",
    "objective": "Review app permissions approved on behalf of users and flag permissions that may create risk.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Application.Read.All + Directory.Read.All",
    "notes": "Reviews delegated OAuth grants, resolves application/resource names, and flags high-risk scopes.",
    "startMode": "right-click",
    "completion": {
      "result": "App permissions approved on behalf of users, with higher-risk permissions flagged.",
      "next": "Confirm the app and business need before revoking grants; this does not cover every form of app access.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-GUEST-USER-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default old-sign-in threshold: 90 days.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "checks": [
      "Guest account status and whether the invitation was accepted",
      "Stale guests and unavailable sign-in history",
      "Optional guest-review CSV"
    ],
    "sourceSha256": "ff9f8a39d9e7c102a6bb303c22bd10e00dce16a2603d1ed41cbb845158b941f6",
    "objective": "Find guest accounts with old or missing sign-in records, disabled accounts, and unaccepted invitations.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: User.Read.All + Directory.Read.All + AuditLog.Read.All",
    "notes": "Reviews guest accounts for disabled state, stale/no sign-in, and unaccepted invitations.",
    "startMode": "right-click",
    "completion": {
      "result": "Guest status, invitation state, and available sign-in history.",
      "next": "Confirm the sponsor and business need before removing guests. Missing history does not prove that a guest was never used.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-TENANT-LICENSING-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "checks": [
      "Purchased license types and licenses assigned to users",
      "Disabled licensed and enabled unlicensed users"
    ],
    "sourceSha256": "7b7dba5740af97019b5fd2f969f5891dcd52ec0a8d6180bbff29f914411f0bf3",
    "objective": "Review license use, including disabled users with licenses and enabled users without one.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: User.Read.All + Directory.Read.All + Organization.Read.All",
    "notes": "Reviews subscribed SKUs and user license assignments, including disabled licensed users and enabled unlicensed users.",
    "startMode": "right-click",
    "completion": {
      "result": "License totals and user assignments, including disabled licensed and enabled unlicensed users.",
      "next": "Confirm business and retention needs before changing licenses.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "checks": [
      "Tenant mailbox rules and optional shared mailboxes",
      "Forward, redirect, delete, move and hidden-rule indicators",
      "Optional suspicious-only results and CSV"
    ],
    "sourceSha256": "85a1c9164ba0d0c0661b6c3e7ecb197f4ac7ab2865d3436de3a5f48f76844880",
    "objective": "Finds inbox rules across the tenant that forward, redirect, delete, hide, or move mail in suspicious ways.",
    "input": "Defaults: user mailboxes only and all rules, not just flagged rules. Use -IncludeShared or -SuspiciousOnly in a terminal to change the review scope.",
    "requires": "Exchange Online read access",
    "notes": "Reviews inbox rules across user mailboxes, optionally includes shared mailboxes, and can limit output to suspicious behavior.",
    "startMode": "right-click",
    "completion": {
      "result": "Inbox rules for the chosen mailbox scope, or only flagged rules when requested.",
      "next": "Confirm whether flagged rules are approved and follow up on mailboxes that could not be read.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "checks": [
      "Windows version and drive space used",
      "Space used by known cleanup locations",
      "Largest files and scan status"
    ],
    "guards": [
      "No deletion or settings changes",
      "Largest files are evidence, not automatically safe to delete",
      "Scanning the whole drive can take minutes and slow disk access"
    ],
    "sourceSha256": "c795ac5d107db35eed303dff231cedbee577824c6fe8b93285ad5895a97cd44b",
    "input": "Default scan: this Windows computer, C: drive, 10 largest files. Use -ComputerName, -DriveLetter, or -TopFiles in a terminal to change the target or count.",
    "requires": "PowerShell 5.1+ | Remote targets: PowerShell remoting / WinRM",
    "notes": "Full-drive largest-file scan is read-only but can take several minutes. Largest files are review evidence, not automatic deletion candidates.",
    "objective": "Review drive space, cleanup locations, and the largest files before deciding what to remove.",
    "startMode": "right-click",
    "completion": {
      "result": "Drive usage, measured cleanup locations, and largest-file findings; scan failures remain visible.",
      "next": "Review candidate files before any separate cleanup. Large files are not automatically safe to delete.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "checks": [
      "Whether users are cloud-only and whether each reset succeeded",
      "Optional password change required at next sign-in"
    ],
    "guards": [
      "Refuses synced users; reset those passwords in Active Directory",
      "Preview and typed RESET confirmation",
      "Temporary passwords shown only after successful reset; never exported"
    ],
    "sourceSha256": "5bf0df403969f64e2d7dd0787487dabf0abe183dce870dbf82b7b041da93bd11",
    "input": "Cloud-only user sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional tenant domain. Default generated password: 20 characters; the script asks whether to require a change at next sign-in (default Yes).",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication | Delegated: User.Read.All + User-PasswordProfile.ReadWrite.All",
    "notes": "Refuses synced users so Active Directory remains authoritative. Generated passwords are never exported.",
    "objective": "Reset passwords for approved cloud-only users and report each result.",
    "startMode": "right-click",
    "completion": {
      "result": "Each approved cloud-only user has a reset result; temporary passwords appear only after successful resets.",
      "next": "Deliver each password through the approved secure channel, confirm delivery at the pause, then verify the user’s next sign-in.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-TERMINAL-READINESS-CHECK.ps1": {
    "input": "Local kit root (default C:\\Field-Kit); review expected layout for your installation.",
    "checks": [
      "PowerShell, policy, modules and existing cloud sessions",
      "Expected kit folders, key files, and script signatures"
    ],
    "guards": [
      "Reports against a fixed expected layout; makes no changes"
    ],
    "sourceSha256": "e9d4d5f1974f2af40c01c23e4e4cf925f232baba8bd7f9b063f0c78110958c01",
    "objective": "Check the shell, modules, signing certificates, and expected toolkit files.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "This checks a fixed toolkit layout, not just PowerShell. Review $ExpectedFolders and $ExpectedFiles for your installation. Missing layout files are reported as failures. Root defaults to C:\\Field-Kit and can be changed at the prompt.",
    "startMode": "right-click",
    "completion": {
      "result": "Findings compare the chosen folder with the script’s fixed expected kit layout.",
      "next": "Check whether reported missing files are actually required for your installation before changing the layout.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INVOKE-MAP-KIT.ps1": {
    "input": "Confirm the detected root or select another folder. Default folder depth: 10; includes files and signature checks.",
    "checks": [
      "Folder counts, file map and script categories",
      "Signature state and cleanup/Git indicators"
    ],
    "guards": [
      "Reports findings; does not reorganize or change files"
    ],
    "sourceSha256": "22046718b32efd8f0d8d5e27bbccb78836ee52262159aa215796e6df5ff7e418",
    "objective": "Show a folder tree, script counts, signatures, and file warnings.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Uses root detection or -RootPath; confirms the selected folder. Reports naming and file-extension warnings, not a full secret scan. Does not enforce a fixed layout or export files.",
    "startMode": "right-click",
    "completion": {
      "result": "A folder map with counts, signature status, and available Git indicators.",
      "next": "Review naming and file warnings manually; this is not a complete secret scan.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INVOKE-SESSION-RESET.ps1": {
    "checks": [
      "Graph and Exchange disconnection",
      "Old Exchange connections and stored PowerShell errors"
    ],
    "guards": [
      "Unrelated remoting sessions remain intact",
      "Clearing the profile password variable and opening a new window are optional"
    ],
    "sourceSha256": "0f183c52bd1ca24dcccba318913eac70eb89848cbe32ef42fe631c6270744446",
    "objective": "Disconnect local Graph and Exchange sessions and clear session errors.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Run in the terminal you want to reset. Asks before cleanup; can clear the optional JumpboxSessionPassword profile variable and open a fresh PowerShell 7 window. Does not change tenant settings.",
    "input": "No account list needed. Use the PowerShell window whose connections you want to close.",
    "startMode": "terminal",
    "completion": {
      "result": "Graph/Exchange cleanup results for this window; optional variable cleanup or a new window only when requested.",
      "next": "Reconnect to the intended tenant when ready. Review cleanup failures instead of assuming every connection closed.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "SET-THEME-BASIC.ps1": {
    "checks": [
      "Plain-text status and field-output examples"
    ],
    "guards": [
      "Does not change the terminal; output is demonstration data"
    ],
    "sourceSha256": "a3959c764ee2c0b4e155f89b5cf28faed7db74f54f2b277e2152b453c392827f",
    "objective": "Preview plain terminal output and reusable message helpers.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Prints example messages and waits for Enter. No persistent theme changes. Example output is demonstration data.",
    "startMode": "terminal",
    "input": "Prints examples in this PowerShell window; no startup profile changes or settings to enter.",
    "completion": {
      "result": "Example terminal messages are printed; no persistent theme is installed.",
      "next": "Use the examples as a reference; their output is demonstration data.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    }
  },
  "SET-THEME-COBALT.ps1": {
    "checks": [
      "Cobalt palette and status-output preview"
    ],
    "guards": [
      "Changes this terminal and its execution policy; does not install a startup theme"
    ],
    "sourceSha256": "01b14b7f32a176f6f107ea73c1421a40d967dd634957f2fb849e94bedab92347",
    "objective": "Preview the Cobalt color palette and message styles.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Changes this terminal’s appearance and sets Process execution policy to Bypass. Prints a palette reference; does not install a persistent theme. Requires an ANSI-capable terminal.",
    "changeNote": "Changes this terminal and sets Process execution policy to Bypass; no profile installation.",
    "startMode": "terminal",
    "input": "Applies to this PowerShell window only, including its Process execution policy; no startup profile is installed.",
    "completion": {
      "result": "This terminal displays the Cobalt palette; no startup theme is installed.",
      "next": "Close the terminal to end session-only changes. Review the reported Process execution-policy change.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    }
  },
  "SET-THEME-SEAGLASS.ps1": {
    "checks": [
      "Sea Glass console colors and syntax highlighting"
    ],
    "guards": [
      "Writes a startup theme to your PowerShell profile",
      "Changes execution policy for this PowerShell window"
    ],
    "sourceSha256": "4b67f87297ce80e2f4f34d4bade7f784005ee4788686046968022e075df167c0",
    "objective": "Apply Sea Glass colors now and when PowerShell starts.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Writes CurrentUserAllHosts profile and replaces recognized theme blocks. Also sets Process execution policy to Bypass. Review your profile before running; remove the SEA GLASS THEME block to undo persistence.",
    "changeNote": "Writes CurrentUserAllHosts profile and replaces recognized theme blocks. Also sets Process execution policy to Bypass. Review your profile before running; remove the SEA GLASS THEME block to undo persistence.",
    "startMode": "terminal",
    "input": "Applies to this window and your current-user PowerShell startup profile. Review the existing profile before running.",
    "completion": {
      "result": "The theme is applied and its startup block is written to your PowerShell profile.",
      "next": "Open a new PowerShell window to confirm startup. Review the profile if other customizations changed.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "SET-THEME-SILICON-VALLEY.ps1": {
    "checks": [
      "Silicon Valley console and syntax colors"
    ],
    "guards": [
      "Writes a startup theme to your PowerShell profile"
    ],
    "sourceSha256": "f8de1e1fc05f78dbabfdaf6d156ebbdd13049cc2ff7067e177e3c80bb63050aa",
    "objective": "Apply Silicon Valley colors, keyboard shortcuts, and a startup banner.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Rewrites recognized theme blocks in CurrentUserAllHosts profile. Also installs and displays a date-seeded daily password generator. Its output is predictable: do not use it as a password. Remove the SILICON VALLEY THEME block to undo persistence.",
    "changeNote": "Rewrites recognized theme blocks in CurrentUserAllHosts profile. Also installs and displays a date-seeded daily password generator. Its output is predictable: do not use it as a password. Remove the SILICON VALLEY THEME block to undo persistence.",
    "startMode": "terminal",
    "input": "Writes to your current-user PowerShell startup profile. Review the existing profile before running; the displayed daily password is predictable.",
    "completion": {
      "result": "The profile theme and startup banner are installed.",
      "next": "Open a new PowerShell window to confirm startup. Never use the predictable date-based password output as a real password.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-STALE-SIGNIN-REVIEW.ps1": {
    "sourceSha256": "2c962dbc7d1ab56ef3a9968636e679c99ca482680ea7af4bdf859fb8a3c063ac",
    "objective": "Finds enabled member accounts with recorded Entra sign-in activity older than the selected threshold while keeping missing activity data separate.",
    "input": "No user list needed. Reviews enabled member accounts in the signed-in tenant; default inactivity threshold: 90 days. Use -Days in a terminal to change it.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + User.Read.All + Directory.Read.All + AuditLog.Read.All",
    "notes": "Tenant-wide review of enabled Entra member accounts. Missing sign-in activity is reported separately and is never classified as inactivity.",
    "startMode": "right-click",
    "completion": {
      "result": "Enabled users with sign-in records older than the threshold, with missing records listed separately.",
      "next": "Confirm whether each account is still needed before proposing changes.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INVOKE-DISABLE-ACCOUNTS.ps1": {
    "sourceSha256": "591c0dad82f02548b19d7a664ea5b2c70db85e0a6afac4f7e49b562c2dd244a4",
    "objective": "Disable approved users in Active Directory or Entra ID, then check each account’s status.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional sync server if you request an immediate sync.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + Graph account-change rights + Active Directory reachability for synced users",
    "notes": "Guarded account-disable workflow for one or many users. Uses Active Directory for synced users and Entra ID for cloud-only users, requires typed DISABLE confirmation, validates post-change state, and can optionally revoke sessions and request Entra Connect delta sync.",
    "startMode": "right-click",
    "completion": {
      "result": "A result for each approved account, including whether the disabled state was confirmed.",
      "next": "Check any failed account and confirm synced changes reach Entra ID. Session revocation is a separate optional action.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "INVOKE-DELETE-ACCOUNTS.ps1": {
    "sourceSha256": "0fbb42bb1db268b3f6e4b74a21af7008528b5acc2e684cccdf3696122fcb6bd2",
    "objective": "Delete approved users in Active Directory or Entra ID after you review the plan and type confirmation.",
    "input": "Exact user sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional sync server if you request an immediate sync.",
    "requires": "Microsoft Graph user-write rights + ActiveDirectory module / writable DC reachability for synced users",
    "notes": "Destructive identity deletion workflow for one or many explicitly approved users. Resolves exact UPNs, uses Active Directory for synced users and Entra ID for cloud-only/guest identities, shows a full plan, requires typed DELETE confirmation, and validates absence at the same authoritative source.",
    "startMode": "right-click",
    "completion": {
      "result": "A result for each approved deletion, checked in the system where the user was removed.",
      "next": "Keep failed deletions and pending synchronization open. Follow the separate mailbox and retention plan.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "RESOLVE-NAMES-TO-UPNS.ps1": {
    "sourceSha256": "9f0560d35c0941ff0723d400129f20b345673e0d9b6e4c751de48529ca6f232c",
    "objective": "Resolves one or more names, emails, or UPNs to reviewed Entra ID UPN matches.",
    "input": "Tenant domain, plus names, email addresses, or sign-in names (UPNs). Direct entries and TXT/CSV lists are supported.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + User.Read.All",
    "notes": "Tenant-targeted identity resolver for direct values or TXT/CSV input with exact/likely/multiple/no-match decisions plus verified review CSV and exact-match UPN TXT exports.",
    "startMode": "right-click",
    "completion": {
      "result": "Matches are separated into exact, likely, multiple, or no match.",
      "next": "Resolve uncertain matches before using the names in another tool. Export the exact-match list only when needed.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-ACCOUNT-STATUS.ps1": {
    "sourceSha256": "4a6e6aed3b612556706c107b667911ef79a4c6a47074d7054ab907cc3ca3dbfc",
    "objective": "Reviews account enabled state and available Entra sign-in activity for one or more users.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file. The script uses their shared domain unless a tenant domain is supplied.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + User.Read.All + Directory.Read.All + AuditLog.Read.All",
    "notes": "Checks exact UPN account state and recorded Entra sign-in activity. Missing sign-in data and query failures remain explicit and are never treated as inactivity.",
    "startMode": "right-click",
    "completion": {
      "result": "Account status and available sign-in records for the requested users.",
      "next": "Follow up on failed lookups or missing history before deciding an account is inactive.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-GROUP-MEMBERS.ps1": {
    "sourceSha256": "744ac9b55488b0b96f22f0ce886aee25698eb39cb15a82cbb1fb291d063d3478",
    "objective": "Shows direct members of one or more groups after resolving the appropriate source.",
    "input": "Group names or email addresses, entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement + Microsoft Graph group read access + Active Directory reachability when applicable",
    "notes": "General group-to-members review for one or many groups. Resolution order is Exchange distribution group, Entra ID group, then Active Directory group.",
    "startMode": "right-click",
    "completion": {
      "result": "Direct members of each group found in Exchange, Entra ID, or Active Directory.",
      "next": "Confirm the resolved group and system. Nested memberships are not a complete access review.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-USER-GROUPS.ps1": {
    "sourceSha256": "a423d1f10e9bcfee903c646d95cf5dbf2142eda04d014e0521a29114c1b55469",
    "objective": "Show each user’s direct groups in Active Directory and Entra ID, with both systems reported separately.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + User.Read.All + Group.Read.All + ActiveDirectory module / domain reachability for AD coverage",
    "notes": "User-to-groups review that independently checks Active Directory and Entra ID. Synced groups remain visible in Entra as [Synced] even when the same group is also observed in AD.",
    "startMode": "right-click",
    "completion": {
      "result": "Direct memberships from Active Directory and Entra ID, with each system’s coverage shown.",
      "next": "Follow up on systems that could not be checked. A synced group appearing in both systems is expected.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-TENANT-GROUP-OWNERS.ps1": {
    "sourceSha256": "830e2ed189de399a7f3813a021446ae68cba5c9c4e810b69cf41e5698751d786",
    "objective": "Shows owners for tenant groups across major Entra and Exchange group types and keeps unresolved ownership visible.",
    "input": "No group list needed. Reviews groups in the tenant you sign in to.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + Microsoft.Graph.Groups + Group.Read.All + User.Read.All + ExchangeOnlineManagement",
    "notes": "Tenant-wide owner review across Teams, Microsoft 365 groups, security groups, mail-enabled groups, and Exchange distribution groups. Lookup failures and ownerless groups remain visible.",
    "startMode": "right-click",
    "completion": {
      "result": "Owners across the supported group types, with missing owners and failed lookups visible.",
      "next": "Confirm a responsible owner before changing ownership; a failed lookup is not proof that a group has no owner. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "guards": [
      "Desktop HTML report is optional; keep exported client information private"
    ]
  },
  "GET-MAILBOX-PERMISSIONS.ps1": {
    "sourceSha256": "793bdd06ff9adadcae9312e8614513d7c6440f507858593a35eb05469fe43620",
    "objective": "Reviews forwarding, delegates, and inbox rules for one or more mailboxes.",
    "input": "Mailbox sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Read-only forwarding, delegate, and inbox-rule review for direct mailbox input or TXT/CSV lists. Query failures remain visible rather than being treated as empty results.",
    "startMode": "right-click",
    "completion": {
      "result": "Forwarding, shared access, and inbox-rule findings for the requested mailboxes.",
      "next": "Review each finding and unavailable check before deciding whether access should change. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "guards": [
      "Desktop HTML report is optional; keep exported client information private"
    ]
  },
  "GET-MAILBOX-FORWARDING.ps1": {
    "sourceSha256": "b99f2dc2c2b3eb9e4feff190f3fae7951dee4bfa2d95909eaad582457f9f768a",
    "objective": "Shows mailbox-level and inbox-rule forwarding for one or more mailboxes without hiding query failures.",
    "input": "Mailbox sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Focused read-only forwarding review for direct mailbox input or TXT/CSV lists. Checks mailbox-level forwarding plus visible/hidden inbox-rule forwarding and keeps query failures visible.",
    "startMode": "right-click",
    "completion": {
      "result": "Mailbox-level and inbox-rule forwarding for the requested mailboxes.",
      "next": "Confirm whether destinations are approved. A failed rule or mailbox query leaves the review incomplete.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INVOKE-LITIGATION-HOLD.ps1": {
    "sourceSha256": "c0d3bb2f0bf4857f45d6f6d52afb80b8171f4fc700d2e2999ec716b21df2cccf",
    "objective": "Enforces Unlimited Litigation Hold on one or more approved mailboxes and verifies the final state.",
    "input": "Mailbox sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement + rights to read and set mailbox Litigation Hold",
    "notes": "Reviews one or many mailboxes and changes only those not already compliant with LitigationHoldEnabled=True and Unlimited duration. Shows a full preview, requires typed HOLD confirmation, re-reads changed mailboxes, and can export evidence.",
    "startMode": "right-click",
    "completion": {
      "result": "Hold settings are read again for mailboxes changed to the requested unlimited hold.",
      "next": "Review failed or unconfirmed mailboxes and record the approved retention decision.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-TRANSPORT-RULES-AUDIT.ps1": {
    "sourceSha256": "38ca6289d157f33a57a60b316a3a0f1de15de8f07310b71eb977d1efbe86609f",
    "objective": "Reviews tenant-wide mail-flow rules and highlights actions that warrant operator review.",
    "input": "No rule list needed. Reviews mail-flow rules in the tenant you sign in to.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Tenant-wide read-only review of transport rules with flags for BCC, redirect, delete, quarantine, moderation, and other actions that can persist beyond mailbox remediation.",
    "startMode": "right-click",
    "completion": {
      "result": "Mail-flow rules with actions such as forwarding, redirection, deletion, or moderation.",
      "next": "Confirm the purpose of flagged rules before changing them; a flagged action can be legitimate.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "TEST-POWERSHELL-READINESS.ps1": {
    "sourceSha256": "a8a52521cfa5a63477558769b97805e64e24fb03452c349ece4c8b9facbf7449",
    "objective": "Checks whether this computer is ready to run the PowerShell tools.",
    "input": "Checks the Windows computer and PowerShell session where you run it. No target list or tenant ID is needed.",
    "requires": "PowerShell 5.1+",
    "notes": "Checks PowerShell, execution policy, elevation, Git, WinGet, PowerShellGet, Graph, Exchange Online, optional AD tooling, and active M365 sessions.",
    "startMode": "right-click",
    "completion": {
      "result": "Readiness findings for this computer’s shell, modules, tools, and connections.",
      "next": "Fix the requirements needed by your selected script; a readiness pass does not verify that script’s runtime behavior.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-FOLDER-INVENTORY.ps1": {
    "sourceSha256": "fc544a0aeef46727b8ba3ede8640114ea94707dd84a410a3c50cc36e0d273387",
    "objective": "Review a folder’s contents, script signatures, and Git status.",
    "input": "Confirm the detected folder or enter a folder/repository path. Default folder depth: 10; includes files and signature checks.",
    "requires": "PowerShell 5.1+",
    "notes": "Maps any selected folder or repository without enforcing a fixed structure.",
    "startMode": "right-click",
    "completion": {
      "result": "A folder map, file counts, signatures, and available Git status.",
      "next": "Review warnings before cleanup. This tool does not reorganize files or enforce a kit layout.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "INSTALL-M365-MODULES.ps1": {
    "sourceSha256": "a143a317bb85b76c39a5768b7b5cad4096d4acce4d5509465c01be820b37ff24",
    "objective": "Installs or updates the Graph and Exchange PowerShell modules you choose.",
    "input": "Choose Graph, Exchange Online, or both when prompted.",
    "requires": "PowerShellGet / PSGallery",
    "notes": "Installs or updates Microsoft Graph and ExchangeOnlineManagement in CurrentUser scope. Does not connect to a tenant.",
    "startMode": "right-click",
    "completion": {
      "result": "Installation or update results for the selected PowerShell modules.",
      "next": "Resolve failed installs before running dependent tools. Tenant sign-in is still a separate step.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "TEST-SENSITIVE-DATA.ps1": {
    "sourceSha256": "9543c614e26b54a6bb8776e5e6ccc23a04c644710f609cd192030cfd35b1f606",
    "objective": "Finds obvious secrets or internal details before you publish or share files.",
    "input": "Enter a file or folder path; blank uses the current PowerShell working folder. Optional extra search terms.",
    "requires": "PowerShell 5.1+",
    "notes": "Checks source for information you may not want to publish. Reports only; never edits or sanitizes files.",
    "startMode": "right-click",
    "completion": {
      "result": "Files and text matching the selected sensitive-data patterns.",
      "next": "Review each match and the files themselves before sharing; no matches does not guarantee that all sensitive data was found.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "RESET-M365-SESSION.ps1": {
    "sourceSha256": "203ba913f1d8d1d72544ecf950c0b346e4e92244a9e6b75730095339c858a16a",
    "objective": "Disconnects Graph and Exchange and clears local PowerShell session state.",
    "input": "No account list needed. Use the PowerShell window whose connections you want to close.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Optional Microsoft.Graph / ExchangeOnlineManagement",
    "notes": "Disconnects Graph and Exchange Online, removes legacy Exchange PSSessions, and clears the local PowerShell error buffer.",
    "startMode": "terminal",
    "completion": {
      "result": "Graph/Exchange connections and stored errors are cleared in this PowerShell session where possible.",
      "next": "Reconnect in the intended tenant when ready. A new window does not inherit authenticated sessions.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "UPDATE-WINDOWS-APPS.ps1": {
    "sourceSha256": "e85573f369093020e66ae8ff1c33aeed71df83f7d579c4d7f888f4bab4d25a3b",
    "objective": "Shows available app updates and installs them after confirmation.",
    "input": "Choose review-only mode or approve updates to eligible apps on this computer.",
    "requires": "WinGet",
    "notes": "Reviews available WinGet upgrades, confirms before changes, updates normally eligible packages, then shows remaining updates.",
    "startMode": "right-click",
    "completion": {
      "result": "Available updates are listed; approved updates run and remaining upgrades are shown.",
      "next": "Review failed or remaining upgrades and check the affected applications with the user.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-USER-SECURITY-SNAPSHOT.ps1": {
    "sourceSha256": "52ac45625a7a12b01d9f1a27d34636423b791ec78d77ea7640d86edb66af2ff6",
    "objective": "Shows the security state around one user before you decide what needs deeper review.",
    "input": "One user sign-in name (UPN).",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: User.Read.All + UserAuthenticationMethod.Read.All + Directory.Read.All + AuditLog.Read.All",
    "notes": "Read-only one-user identity/security snapshot covering account state, authentication, privileged roles, direct groups, licensing, recent sign-ins, and explicit data gaps.",
    "startMode": "right-click",
    "completion": {
      "result": "Available account, sign-in, MFA, role, group, and license findings for the user.",
      "next": "Choose deeper reviews from the findings; missing data must remain unresolved. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "guards": [
      "Desktop HTML report is optional; keep exported client information private"
    ]
  },
  "GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "sourceSha256": "b4fbb3ad10dcde3e5beb1c414890597de2fd969a4e9fe4149f70b7bea2c5f44c",
    "objective": "Gives a fast tenant security overview before you open the deeper focused audits.",
    "input": "Reviews the tenant you sign in to; no user list needed. Default old-sign-in threshold: 90 days.",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Organization.Read.All + User.Read.All + AuditLog.Read.All + Directory.Read.All + RoleManagement.Read.Directory + Policy.Read.ConditionalAccess + DelegatedPermissionGrant.Read.All",
    "notes": "Fast tenant overview of users, stale enabled accounts, Conditional Access policy state, active admin roles, and delegated OAuth grants.",
    "startMode": "right-click",
    "completion": {
      "result": "An overview of users, old sign-ins, policies, admin roles, and app grants.",
      "next": "Open the focused audits for details and resolve missing checks before making tenant-wide conclusions. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "guards": [
      "Desktop HTML report is optional; keep exported client information private"
    ]
  },
  "GET-ROOM-RESOURCE-ACCESS.ps1": {
    "sourceSha256": "b7c2e01ae09248a8cfd83e997afaa9a17ef338d85d188ea6f96c83bc759c6cb0",
    "objective": "Shows who can access or book one or more room and equipment mailboxes.",
    "input": "Room or equipment mailbox addresses; separate multiple addresses with commas.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Focused review of room and equipment mailbox Full Access, in-policy booking principals, and resource delegates.",
    "startMode": "right-click",
    "completion": {
      "result": "Mailbox access, automatic booking permissions, and booking approvers are listed.",
      "next": "Confirm access and booking behavior with the resource owner before changing permissions.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "sourceSha256": "79cf872432e023f6eb0036e355a71fab156ec79489e84344be7eee0b82e68c15",
    "objective": "Finds mailbox forwarding and delegated access across the tenant without opening mailboxes one at a time.",
    "input": "No mailbox list needed. Reviews user and shared mailboxes in the tenant you sign in to.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Tenant-wide review of user/shared mailbox forwarding, Full Access, Send As, and Send on Behalf with query failures kept visible.",
    "startMode": "right-click",
    "completion": {
      "result": "Forwarding and supported mailbox-access permissions across user and shared mailboxes.",
      "next": "Review unexpected access and failed mailbox queries; findings alone do not authorize removal.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "sourceSha256": "8a48dd3160a4bd5228ac4490e081b3e49b7ff1a163d09878f1d9881766ae9bcb",
    "objective": "Remove a disabled user’s Full Access, Send As, and Send on Behalf permissions after reviewing the removal plan.",
    "input": "The disabled user’s exact sign-in name (UPN).",
    "requires": "Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: Microsoft.Graph.Authentication + User.Read.All + Directory.Read.All + Exchange Online permission-management rights + directory reachability for synced-user validation",
    "notes": "Post-offboarding cleanup that validates disabled state at the authoritative identity source, scans Exchange recipients for direct Full Access, Send As, and Send on Behalf rights, shows the exact removal plan, requires typed approval, and verifies each requested removal.",
    "startMode": "right-click",
    "completion": {
      "result": "Selected Full Access, Send As, and Send on Behalf removals are checked after approval.",
      "next": "Review each failed removal and remaining access before closing offboarding.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "GET-TENANT-DRIFT-REVIEW.ps1": {
    "sourceSha256": "668267cbadfc88d212a8708c77f0a5454343a0e4222e2e1cfaff2a44e84afb54",
    "objective": "Compare selected tenant settings with a saved local baseline and report changes.",
    "input": "Optional local JSON comparison file (baseline). By default, uses a tenant-specific file in the script’s BASELINES folder; offers to create one when missing.",
    "requires": "Microsoft Graph PowerShell with tenant read access. Permissions: Directory.Read.All, Application.Read.All, Policy.Read.All, RoleAssignmentSchedule.Read.Directory, RoleEligibilitySchedule.Read.Directory.",
    "notes": "Tenant configuration drift detector. Tenant operations are read-only; the only state change is creating or replacing a local JSON baseline after explicit approval, with readback verification.",
    "startMode": "right-click",
    "completion": {
      "result": "Changes from the saved tenant baseline, or a newly approved local baseline, are reported.",
      "next": "Investigate differences before replacing the baseline; saving current settings does not make them approved.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "connection-patterns.md": {
    "sourceSha256": "f186db47a6da071169e2ea0c1213a527f2f9eebbc78a4da2d1121db9fa387bc6",
    "notes": "Reusable Graph, Exchange Online, and hybrid connection guidance without environment-specific identifiers.",
    "objective": "Choose the right Graph, Exchange Online, or hybrid connection approach."
  },
  "OPERATING-STANDARDS.md": {
    "sourceSha256": "ade5ec3a333026e8811ea749d5c6df9f2cec95e77a044cf4c05f87d35ac26229",
    "notes": "Top-level project decision contract for canonical sources, 1-to-N input, safety, authentication, QA, release, and handoff/rebuild decisions.",
    "objective": "Read the project rules for building, reviewing, and releasing tools."
  },
  "field-kit-build-standard.md": {
    "sourceSha256": "c3802c7cb2cf32b7285c4b16c5cdb976f4b2e062709b58db06de324f3a01d5d0",
    "notes": "Locked baseline for FIELD // KIT visual design, navigation, sorting, card behavior, source publication, and release validation.",
    "objective": "Read the agreed site layout, card, and publishing standards."
  },
  "lessons-learned.md": {
    "sourceSha256": "f6bc6f62b00d32ef007589d931d6ee05e63944738a5df3d57a01344193c7e00f",
    "notes": "Small reusable rules captured from recurring PowerShell, authentication, hybrid, output, and publishing failures.",
    "objective": "Check lessons from earlier scripting and publishing problems."
  },
  "powershell-standards.md": {
    "sourceSha256": "78146e39af76b07c6fb945013d0971b45cd646c7bc0007bd678324aedd399785",
    "notes": "Script implementation baseline for interactive FIELD // KIT PowerShell tools.",
    "objective": "Read the coding, safety, and output standards for these PowerShell tools."
  },
  "publishing-checklist.md": {
    "sourceSha256": "2ee855b823d32f2e6b3c667eedfa019234df0a6a515bbd4ed271510b6ac596d6",
    "notes": "Final public-release gate for source, secrets, proprietary context, operational behavior, and catalog metadata.",
    "objective": "Check source, sensitive data, behavior, and card details before release."
  },
  "script-review-checklist.md": {
    "sourceSha256": "8ad6e773bf7edd85abc81a3f24ecd674c7a0ffc8d72e2638b3aafe6a9a98155e",
    "notes": "Reusable pre-approval review covering syntax, structure, authentication, data handling, safety, output, and publication.",
    "objective": "Review a script’s syntax, access, safety, and output before approval."
  },
  "skills.md": {
    "sourceSha256": "69280cbd4203c3d96717d7f0f2343ed0566eb8ea2d5c9e2222eb6b7441217f92",
    "notes": "Repeatable workflows for building, reviewing, aligning, troubleshooting, publishing, and handing off FIELD // KIT work.",
    "objective": "Find repeatable steps for building, reviewing, troubleshooting, and publishing tools."
  },
  "script-template-guide.md": {
    "sourceSha256": "49204f5c543f7a3a7a3ac0372d6d8e9111666b2d20824b68ff544c030f70ab30",
    "notes": "Structural guide for single-objective tools, multi-section reviews, and connected workflows.",
    "objective": "Choose a script structure and follow the input and output patterns."
  },
  "nato-phonetic-alphabet.md": {
    "sourceSha256": "c9dec1a66a3530972991663504e4c54e895e87093a43081404edfdf3da7288c7",
    "notes": "A-to-Z NATO spelling alphabet reference for clear verbal communication.",
    "objective": "Use standard spelling words for clear verbal communication."
  },
  "git-handoff.ps1": {
    "sourceSha256": "6783255cf5418e432da3677406f281460ab6538a1628f47b5c9ea3b558de70a6",
    "objective": "Save the current Git project state for your next session.",
    "notes": "Generates a repeatable context-state artifact from the Git repository containing the selected path. Captures branch, HEAD, upstream state, working-tree changes, stashes, recent commits, changes since the previous snapshot, and common project-document presence with readable names and best-effort sensitive-value redaction. Creates a local snapshot and local Git exclusion; does not stage, commit, fetch, or push. Review output before sharing. Run from a terminal; Windows validation pending.",
    "changeNote": "Writes a local handoff file and Git exclusion; does not commit or push.",
    "input": "Full path to the Git repository you want to summarize.",
    "requires": "Git for Windows. Run in an existing PowerShell window.",
    "startMode": "terminal",
    "launchArgs": " -Path (Read-Host \"Full path to the target Git repository\")",
    "details": "Writes .handoff/HANDOFF-SNAPSHOT.md and a local Git exclusion. Does not stage, commit, fetch, or push. Some sensitive values are removed, but review the file before sharing. Native Windows validation remains pending.",
    "completion": {
      "result": "A local .handoff/HANDOFF-SNAPSHOT.md file records the selected repository state.",
      "next": "Read the snapshot for sensitive details before sharing it. No commit or push is performed.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "PROJECT-HANDOFF.md": {
    "sourceSha256": "023b34f8460cdf2714f17e60542916227e20bc8c387c490c8019e3a1e37199a3",
    "notes": "Canonical project handoff template for source of truth, local/remote state, locked decisions, validation status, limitations, and next-session startup.",
    "objective": "Find the current project state, decisions, limits, and next steps."
  },
  "git-repo.ps1": {
    "sourceSha256": "4ec1ebc30c976a410c5dc616f0671727c34278b777b323e671189553f0b1aa7a",
    "objective": "Check repository changes, push reviewed work, or pull updates.",
    "requires": "Git for Windows; run from an existing terminal",
    "notes": "Standalone Git check, push and pull using the current repository or -Path. Default: -Action Check; add -Details for file names. -Action Push previews changes and requires typed approval before staging, committing and pushing. -Action Pull refuses a dirty tree and only fast-forwards. Run in a terminal; no profile dependency. File-name checks are not a secret scanner.",
    "input": "Full repository path. Starts with a read-only check; Push and Pull are separate actions.",
    "startMode": "terminal",
    "launchArgs": " -Path (Read-Host \"Full path to the target Git repository\")",
    "details": "The launch command runs a read-only check. For reviewed publishing or updates, use -Action Push or -Action Pull in the same terminal. Push previews changes and asks for typed approval; Pull requires no local changes. Check uses the last known remote state without fetching. File-name checks do not scan file contents for secrets.",
    "completion": {
      "result": "Check shows local and last-known remote state; Push or Pull reports its own result when explicitly requested.",
      "next": "Review errors and confirm the intended branch/remote. A Check result does not refresh remote state.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "git-security.ps1": {
    "sourceSha256": "3cba00d77603ffe94401fbda18953579b90492012be0446b08c6de806d5fe1e8",
    "objective": "Review a GitHub security-log export for new access and security flags.",
    "requires": "Windows PowerShell 5.1 or later. Uses a downloaded export; does not sign in to GitHub.",
    "notes": "Run .\\git-security.ps1 -Account your-github-handle. Export JSON from GitHub, then press Enter for the newest matching download. Shows actionable unreviewed access/security events. Complete reviews without flags update a local checkpoint; flagged exports require explicit acknowledgement. Changes local history only, never GitHub settings. ALL CLEAR means no rule matches, not proof of no compromise.",
    "input": "Your GitHub account name and a downloaded security-log export (JSON, JSON.GZ, or ZIP). Looks in your Downloads folder unless another path is supplied.",
    "startMode": "terminal",
    "launchArgs": " -Account (Read-Host \"GitHub account name\")",
    "details": "Download your security log from GitHub first. The script reviews the newest matching download or asks for a path. It saves local review history after a complete review without flags; flagged results require acknowledgement. ALL CLEAR means no matching warning rules, not proof that the account is secure.",
    "completion": {
      "result": "New security-log events matching the review rules, or a report that no warning rules matched.",
      "next": "Confirm actors and changes in the original GitHub log. ALL CLEAR is not proof that the account is secure.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "set-execution.ps1": {
    "sourceSha256": "fe6e46d409518b856bf52ee985d4298e41376676d2e984af8092c0ef316bf09f",
    "objective": "Prepare reviewed scripts to run under your current-user execution policy.",
    "notes": "Explicit local setup utility. Checks effective execution policy, sets CurrentUser RemoteSigned only when needed and not managed, and unblocks adjacent .ps1 files. Run only in a folder of scripts you have reviewed. Does not sign files or install modules. Colored result; Enter to exit.",
    "input": "Place this file beside only the reviewed .ps1 files you intend to unblock.",
    "startMode": "right-click",
    "requires": "PowerShell on this computer.",
    "completion": {
      "result": "A local setup result reports policy or unblock problems for adjacent scripts.",
      "next": "Resolve managed-policy blocks through the approved process; do not bypass them or unblock unreviewed files.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "git-tools.md": {
    "sourceSha256": "5aa1d822aa27dd41c43bab2554b87d925b1e1eb5fd41fc22f44c12d4cbfae21a",
    "notes": "Commands and operating boundaries for the standalone repository, security, handoff and execution-setup helpers."
  },
  "attractor.ps1": {
    "sourceSha256": "2adc04c32a4d20820577933c463d07642c8be18f9de17c739a617ffcc55c68a5",
    "objective": "Run a slowly evolving fractal animation with a floating label and clock.",
    "notes": "Slowly evolving Clifford attractor with floating branding and a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "input": "No input needed. Use an interactive terminal; Ctrl+C stops the animation.",
    "startMode": "terminal",
    "requires": "PowerShell on this computer; an interactive terminal for the display.",
    "completion": {
      "result": "The terminal animation runs until stopped.",
      "next": "Press Ctrl+C to stop. It is a display effect, not a screen lock.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    }
  },
  "rain.ps1": {
    "sourceSha256": "46d67ed7200597e89de91d76dbbceedb63f202852972070f18db6ea13f56a53c",
    "objective": "Run colorful terminal rain with a floating label and clock.",
    "notes": "Dense neon character rain, intermittent signal effects and a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "input": "No input needed. Use an interactive terminal; Ctrl+C stops the animation.",
    "startMode": "terminal",
    "requires": "PowerShell on this computer; an interactive terminal for the display.",
    "completion": {
      "result": "The terminal rain animation runs until stopped.",
      "next": "Press Ctrl+C to stop. It is a display effect, not a screen lock.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    }
  },
  "static.ps1": {
    "sourceSha256": "4e4db77166ad4f60ceb3e50b5aa3685719d9d84805ec93dbd729005074d86e1f",
    "objective": "Run drifting dots and static with a floating label and clock.",
    "notes": "Sparse pulsing dots, subtle static and drifting branding with a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "input": "No input needed. Use an interactive terminal; Ctrl+C stops the animation.",
    "startMode": "terminal",
    "requires": "PowerShell on this computer; an interactive terminal for the display.",
    "completion": {
      "result": "The terminal dots/static animation runs until stopped.",
      "next": "Press Ctrl+C to stop. It is a display effect, not a screen lock.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    }
  },
  "SIGN-FOLDER-SCRIPTS.ps1": {
    "sourceSha256": "b8a7e1411654e6f9aa358cf6def278b5df4d1f4ccef8c4d18549609a32f50b27",
    "objective": "Sign reviewed PowerShell scripts with a certificate you choose.",
    "input": "Folder of reviewed scripts and a signing certificate; the script can offer to create a self-signed certificate.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Uses an existing certificate or creates a local self-signed certificate. Optional trust adds it to the current-user TrustedPublisher and Root stores. Shows files and asks before signing; -ForceResign replaces existing signatures.",
    "startMode": "right-click",
    "completion": {
      "result": "Signing results are reported for the selected scripts.",
      "next": "Review failed signatures and verify trust on the computer that will run the scripts; signing does not prove code is safe.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  },
  "INVOKE-FILE-INVENTORY.ps1": {
    "sourceSha256": "acb04fd3968ef3a29356ef52583229a72926f7a6ed319b4b36bd01e56de28445",
    "objective": "Find duplicate scripts, signature problems, and leftover working copies.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Groups files into Active, Testing, and Archive; compares duplicate filenames by SHA256. Optional CSV export includes local paths and signer details. Root defaults to C:\\Field-Kit; keep reports private.",
    "input": "Working folder path; default C:\\Field-Kit. Choose an output folder only if exporting.",
    "startMode": "right-click",
    "completion": {
      "result": "Duplicate-name, content-hash, signature, and working-copy findings; optional CSV files are saved when requested.",
      "next": "Review file differences before deleting duplicates; keep exported local paths and signer information private.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    }
  },
  "MANAGE-CERT-SIGNATURES.ps1": {
    "sourceSha256": "1ce17ac14c10b3af62b553e2fde13423c039f24edea5e55eb2a86133cd5d7066",
    "objective": "Create and manage certificates used to sign PowerShell scripts.",
    "input": "Choose a certificate action. Have the certificate/file path and password ready when importing or exporting a private key.",
    "requires": "Windows PowerShell 5.1 or later",
    "notes": "Public .cer files share trust. Private .pfx files include the signing key and require explicit confirmation and a password. Lists certificates installed for the current user; select your own signing identity.",
    "startMode": "right-click",
    "completion": {
      "result": "The selected certificate action reports its result and any output path.",
      "next": "Check the intended store or output file. Keep PFX files and their passwords private; trust changes need separate review.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    }
  }
});

window.FIELD_KIT_PLAIN_PHRASES = Object.freeze({
  "Expected tenant/account validated before collection": "Checks the tenant and signed-in account before reading data",
  "Expected tenant and account validated": "Checks the tenant and signed-in account",
  "Expected tenant and signed-in account validated": "Checks the tenant and signed-in account",
  "Failed or unavailable reads stop the review": "Stops if required data cannot be read",
  "Query failures remain data gaps; no automatic export": "Shows failed checks; exports only when requested",
  "Stale enabled members and unavailable sign-in data": "Enabled users with old or missing sign-in records",
  "Active admin role counts and ownerless cloud groups": "Active admin roles and cloud groups with no owner",
  "Distribution group resolution": "Finds the requested distribution group",
  "Ambiguous or failed group lookups remain visible": "Shows failed lookups and groups with more than one match",
  "AD and Entra memberships and source authority": "Group memberships in Active Directory and Entra ID",
  "Optional verified result CSV": "Optional CSV report, checked after saving",
  "Synced memberships changed in AD": "Changes synced group memberships in Active Directory",
  "Dynamic, role-assignable and Exchange-managed groups skipped": "Skips dynamic groups, groups used for admin roles, and Exchange-managed groups",
  "Separate from Conditional Access and Security Defaults": "Does not replace Conditional Access or Security Defaults",
  "Source and destination folder selection": "Folders selected for the email move",
  "Post-move source and target validation": "Checks both folders after moving email",
  "Account state, password last changed and privileged roles": "Account status, password change date, and admin roles",
  "Authentication methods and enabled Conditional Access policy inventory": "Sign-in methods and enabled Conditional Access policies",
  "Latest-25 sign-in sample over 10 days": "Up to 25 recent sign-ins from the last 10 days",
  "Mailbox rules, forwarding, delegates, OAuth grants and protocols": "Mailbox rules, forwarding, shared access, app permissions, and mail protocols",
  "Unavailable checks remain visible; findings are not a compromise verdict": "Shows checks that could not run; findings need review before deciding the account is compromised",
  "Account containment, password reset and session revocation results": "Results of blocking sign-in, resetting the password, and revoking sessions",
  "Selected mailbox rules, forwarding and delegated access": "Selected mailbox rules, forwarding, and shared access",
  "Selected OAuth persistence and post-change state": "Selected app permissions and the result after removal",
  "Only selected, explicitly confirmed response actions": "Runs only the actions you select and approve",
  "Synced identity changes require SID-matched AD and local Windows rights": "For synced users, matches the Windows security ID (SID) to Active Directory; local AD permissions are required",
  "No automatic sync; validate propagation separately": "Does not force a sync; check that changes reach Entra ID",
  "Temporary password shown only after reset; cleared after secure-delivery pause": "Shows a temporary password only after reset; clears its variable after you confirm secure delivery",
  "Fresh account, mailbox and persistence readiness": "Rechecks the account, mailbox, and remaining unwanted access",
  "Authoritative account enable state after recovery": "Checks that the account was enabled in the system that manages it",
  "Operator confirms identity, remediation, scope review and MFA readiness": "You confirm the user, cleanup, investigation scope, and trusted MFA methods",
  "Pending AD-to-Entra sync remains unverified": "A pending sync is not reported as confirmed recovery",
  "Source IP and download-burst indicators": "Source IP addresses and bursts of downloads",
  "Indicators require analyst review; not proof of exfiltration": "Unusual activity needs review; it does not prove data was stolen",
  "Failed windows and record caps are reported as data gaps": "Shows failed search periods and results cut short by limits",
  "Windows limited to 10 days; capped results reported as incomplete": "Searches in periods of up to 10 days; reports results cut short by limits",
  "Chronological events from JSON, text, log and Markdown evidence": "Events sorted by time from JSON, text, log, and Markdown files",
  "File-modified fallback timestamps are explicitly labeled": "Labels events that use a file modification time instead of an event time",
  "JWT header and payload decoded locally": "Decodes the token header and contents on this computer",
  "Does not validate signature, trust or token usability": "Does not check whether the token is signed, trusted, or usable",
  "Token-specific risk signals and geography context": "Risk signals related to stolen tokens, plus sign-in locations",
  "Unexpected geography alone is not called token replay": "An unexpected location alone does not prove a stolen session",
  "Application/resource names where resolvable": "App and service names when they can be found",
  "High-risk granted scopes": "Granted app permissions that may create risk",
  "Delegated OAuth grants made by guests": "App permissions approved by guest users",
  "Expected regions are shown before interpreting foreign sign-ins": "Shows expected countries before flagging sign-ins from elsewhere",
  "Page-limit coverage remains explicitly partial": "Marks the review incomplete when the page limit is reached",
  "Failed or malformed reads stop the review": "Stops if required data is missing or cannot be read",
  "Elevation, hostname and current domain state": "Administrator access, computer name, and current domain",
  "DNS and target domain reachability": "DNS settings and connection to the requested domain",
  "AD identity, groups, ownership and direct reports": "Active Directory account, groups, owned objects, and direct reports",
  "Mailbox forwarding, delegates, retention and statistics": "Mailbox forwarding, shared access, retention, and usage",
  "Mail-group, transport-rule and Entra ownership dependencies": "Mail groups, mail-flow rules, and Entra objects that depend on this user",
  "User state, hybrid source and recorded last sign-in": "Account status, where it is managed, and recorded last sign-in",
  "Tenant delegated OAuth grants": "App permissions approved on behalf of users",
  "Application and resource name resolution": "App and service names when available",
  "High-risk scopes and optional CSV": "Permissions that may create risk; optional CSV report",
  "Guest state and invitation acceptance": "Guest account status and whether the invitation was accepted",
  "Subscribed SKUs and user license assignments": "Purchased license types and licenses assigned to users",
  "OS and drive utilization": "Windows version and drive space used",
  "Measured cleanup candidate sizes": "Space used by known cleanup locations",
  "Full-drive scans can take minutes and create disk I/O": "Scanning the whole drive can take minutes and slow disk access",
  "Synced users refused; AD remains authoritative": "Refuses synced users; reset those passwords in Active Directory",
  "Legacy Exchange PSSession cleanup and error-buffer reset": "Old Exchange connections and stored PowerShell errors",
  "Password-variable cleanup and new window are optional": "Clearing the profile password variable and opening a new window are optional",
  "Kit folder layout, anchor files and script signatures": "Expected kit folders, key files, and script signatures",
  "Reporter only; no enforced layout or file changes": "Reports findings; does not reorganize or change files",
  "Full preview before changes": "Shows the full change plan before approval",
  "Full plan before changes": "Shows the full change plan before approval",
  "Full target preview before changes": "Shows every target before approval",
  "Full deletion plan before action": "Shows the full deletion plan before approval",
  "Exact UPN resolution": "Matches the exact user sign-in name (UPN)",
  "AD authority for synced users": "Uses Active Directory for synced users",
  "Entra authority for cloud-only and guest users": "Uses Entra ID for cloud-only users and guests",
  "Per-user post-change SKU verification": "Checks each user’s license after the change",
  "Verified CSV when requested": "Optional CSV report, checked after saving",
  "Verified member CSV when requested": "Optional member CSV report, checked after saving",
  "Current-license review": "Currently assigned licenses",
  "Tenant SKU inventory": "Available license types",
  "UsageLocation handling when approved": "Sets missing country/region only when approved",
  "Tenant license inventory": "Available license types",
  "Per-user license and approved UsageLocation verification": "Checks each user’s license and any approved country/region change",
  "Failed and unverified results kept open; optional result CSV": "Shows failed or unconfirmed results; optional CSV report",
  "Per-user post-change removal verification": "Checks each user’s licenses after removal",
  "Each target and planned license/location shown before approval": "Shows each user, selected license, and country/region change before approval",
  "Typed ASSIGN confirmation; unavailable targets stop preparation": "Type ASSIGN to approve; stops preparation if a user cannot be read",
  "Each target UPN and planned license shown before approval": "Shows each user and selected license before approval",
  "Typed REMOVE confirmation; cancellation makes no changes": "Type REMOVE to approve; cancelling makes no changes",
  "Failed or ambiguous existing-group lookup blocks creation": "Stops creation if an existing-group lookup fails or has more than one match",
  "Typed CREATE approval of the displayed group and membership rule": "Type CREATE to approve the displayed group and membership rule",
  "Enabled licensed-user rule": "Membership rule for enabled users with a license or service plan",
  "Post-create group configuration verification": "Checks the new group’s settings",
  "Post-change state validation": "Checks the result after changes",
  "Validates post-change state": "Checks account status after changes",
  "Same-source post-delete validation": "Checks deletion in the system where the account was removed",
  "Cloud / synced / dynamic markers": "Labels cloud, synced, and dynamic groups",
  "Independent AD and Entra coverage": "Shows separately whether Active Directory and Entra were checked",
  "Synced Entra groups remain visible": "Includes synced groups found in Entra ID",
  "Separates synced and cloud-only authority": "Identifies whether Active Directory or Entra manages the user",
  "Shows the full disable preview": "Shows all planned account blocks before approval",
  "Validates disabled state at the authoritative identity source": "Confirms the user is disabled in the system that manages the account",
  "Scans Exchange recipients for Full Access": "Finds mailboxes where the user has Full Access",
  "Scans Send As": "Finds Send As permissions held by the user",
  "Scans Send on Behalf": "Finds Send on Behalf permissions held by the user",
  "Shows the complete removal plan": "Shows all planned removals before approval",
  "Requires typed confirmation tied to the target UPN": "Requires typed approval that includes the target user’s sign-in name",
  "Verifies each requested removal": "Checks each requested removal",
  "Pre-change hold-state review": "Current mailbox hold settings",
  "Changes only noncompliant mailboxes": "Changes only mailboxes not already on the requested hold",
  "Unlimited duration target": "Checks for a hold with no expiry date",
  "Post-change mailbox re-read": "Reads mailbox settings again after the change",
  "Optional CSV evidence": "Optional CSV report",
  "In-policy booking principals": "Users allowed to book automatically",
  "Resource delegates": "People who approve booking requests",
  "Explicit data gaps": "Shows data that could not be read",
  "Account state and hybrid source": "Account status and where it is managed",
  "Recorded Entra sign-in activity": "Recorded Entra sign-in history",
  "Missing sign-in data kept separate": "Keeps missing sign-in history separate from inactivity",
  "Query failures remain visible": "Shows checks that failed",
  "Delegated OAuth consent grants": "App permissions approved on behalf of users",
  "Conditional Access policy fingerprints": "Conditional Access policy settings for comparison",
  "Tenant-ID bound local baseline": "Matches the saved comparison file to the tenant",
  "Verified baseline writes only after approval": "Writes the comparison file only after approval, then checks the saved file",
  "Active privileged role assignments": "Active admin role assignments",
  "Eligible privileged role assignments": "Admin roles available to activate",
  "App registration credentials": "App secrets and certificates",
  "Application owners": "App owners",
  "Risky application permissions": "App permissions that may create risk",
  "No-MFA users": "Users without registered MFA",
  "Weak-only MFA": "Users with only weaker MFA methods",
  "MFA capability": "Whether registered methods can support MFA",
  "Conditional Access coverage when requested": "Conditional Access policy review when requested",
  "Foreign successful sign-ins": "Successful sign-ins outside expected countries",
  "New-IP non-interactive success": "Successful background sign-ins from new IP addresses",
  "Service principals": "Enterprise apps (service principals)",
  "Service-principal owners": "Enterprise app owners",
  "User-owned service principals": "Enterprise apps with user owners",
  "Service principals with no owners": "Enterprise apps with no owner",
  "PowerShellGet / PSGallery": "PowerShell module installer and gallery access",
  "Elevation state": "Whether PowerShell is running as administrator",
  "Authenticode signature state": "PowerShell script signature status",
  "Secret-like literals": "Text that looks like a password or secret",
  "Private-key / token material": "Private keys and access tokens",
  "Tenant or app GUIDs": "Tenant or app IDs",
  "UNC paths": "Network folder paths",
  "Authenticode blocks": "Script signing blocks",
  "Uses CurrentUser scope": "Installs only for the current Windows user",
  "Updates normally eligible packages": "Updates packages that WinGet allows",
  "Optional Active Directory module": "Whether the optional Active Directory module is installed",
  "No host appearance changes; sample output is illustrative": "Does not change the terminal; output is demonstration data",
  "Changes terminal appearance and Process execution policy; no profile installation": "Changes this terminal and its execution policy; does not install a startup theme",
  "Writes a persistent theme to the current-user all-hosts profile": "Writes a startup theme to your PowerShell profile",
  "Writes the theme to the PowerShell profile for persistence": "Writes a startup theme to your PowerShell profile",
  "Changes Process execution policy": "Changes execution policy for this PowerShell window",
  "Uses previous snapshot as the work boundary": "Compares with the previous saved project snapshot",
  "Preserves readable names and summaries with targeted redaction": "Keeps readable names and summaries; removes some sensitive values",
  "Writes .handoff/HANDOFF-SNAPSHOT.md and a local Git exclusion": "Saves .handoff/HANDOFF-SNAPSHOT.md and excludes local snapshots from Git",
  "Post-removal validation": "Checks remaining memberships after removal",
  "Cloud account eligibility and reset results": "Whether users are cloud-only and whether each reset succeeded",
  "Optional force-change-at-next-sign-in setting": "Optional password change required at next sign-in",
  "Tenant-target validation": "Checks that the connection targets the requested tenant",
  "Privileged roles": "Admin roles",
  "Post-change MFA state for each user": "Checks each user’s per-user MFA setting after the change",
  "Complete removal plan before changes": "Shows all planned removals before approval",
  "Exports verified results when requested": "Optional result report, checked after saving",
  "CSV / TXT evidence": "Optional CSV or text report",
  "Optionally requests Entra Connect delta sync": "Optional request to sync recent changes to Entra ID",
  "Removes legacy Exchange PSSessions": "Closes old Exchange remote connections",
  "Clears the local PowerShell error buffer": "Clears stored errors in this PowerShell window",
  "Temporary passwords shown only after successful reset; never exported": "Shows a temporary password only after a successful reset; does not export it",
  "Preview and typed RESET confirmation": "Shows the reset plan; type RESET to approve",
  "User / group exclusions": "Users and groups excluded from policies",
  "Report-only policies": "Policies that only report results without enforcing them",
  "Device-code gaps": "Possible gaps in policies for device-code sign-in",
  "Weak coverage indicators": "Settings that may leave users less protected",
  "MFA registration": "Whether users have registered MFA methods",
  "Authentication methods": "Registered sign-in methods",
  "Password state": "Recorded password settings",
  "License state": "Assigned licenses",
  "Full Access delegates": "People with Full Access permission",
  "Tenant transport rules": "Tenant mail-flow rules",
  "Tenant-wide transport rules": "Tenant mail-flow rules"
});

// Quick-command copy is applied only when the executable example still matches.
window.FIELD_KIT_COMMAND_GUIDANCE = Object.freeze({
  "Get User": {
    "code": "Get-ADUser \"username\" -Properties Enabled,UserPrincipalName,DisplayName,LockedOut,PasswordLastSet,PasswordNeverExpires |\n  Select-Object DisplayName,SamAccountName,UserPrincipalName,Enabled,LockedOut,PasswordLastSet,PasswordNeverExpires",
    "useFor": "Show one Active Directory user’s account status and password settings.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Show Password Expiry": {
    "code": "Get-ADUser \"username\" -Properties msDS-UserPasswordExpiryTimeComputed |\n  Select-Object SamAccountName,@{N=\"PasswordExpires\";E={[datetime]::FromFileTime($_.\"msDS-UserPasswordExpiryTimeComputed\")}}",
    "useFor": "Show the password expiry date reported by Active Directory.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Delete User": {
    "code": "Remove-ADUser -Identity \"username\" -Confirm:$true",
    "useFor": "Delete the selected Active Directory user after PowerShell confirmation.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the target; PowerShell asks for confirmation before removal."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Disable User": {
    "code": "Disable-ADAccount -Identity \"username\"",
    "useFor": "Disable the selected Active Directory account.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Enable User": {
    "code": "Enable-ADAccount -Identity \"username\"",
    "useFor": "Enable the selected Active Directory account.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Force Password Change Next Logon": {
    "code": "Set-ADUser -Identity \"username\" -ChangePasswordAtLogon $true",
    "useFor": "Require the user to change their password at next sign-in.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Reset Password": {
    "code": "$Password = Read-Host \"Temporary password\" -AsSecureString\nSet-ADAccountPassword -Identity \"username\" -Reset -NewPassword $Password",
    "useFor": "Set a new password for the selected Active Directory account.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Unlock User": {
    "code": "Unlock-ADAccount -Identity \"username\"",
    "useFor": "Unlock the selected Active Directory account.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Find User By Exact Display Name": {
    "code": "$Name = \"Jane Doe\"\nGet-MgUser -Filter \"displayName eq '$Name'\" -Property Id,DisplayName,UserPrincipalName,AccountEnabled |\n  Select-Object Id,DisplayName,UserPrincipalName,AccountEnabled",
    "useFor": "Find Entra users with the exact display name you enter; more than one match is possible.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"User.ReadWrite.All\",\"User.EnableDisableAccount.All\",\"User-PasswordProfile.ReadWrite.All\",\"User.RevokeSessions.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, User.ReadWrite.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, User.RevokeSessions.All.",
    "input": "Replace command examples with your exact display name. Review all target values before running."
  },
  "Get User By Upn": {
    "code": "Get-MgUser -UserId \"user@domain.com\" -Property Id,DisplayName,UserPrincipalName,AccountEnabled,OnPremisesSyncEnabled |\n  Select-Object Id,DisplayName,UserPrincipalName,AccountEnabled,OnPremisesSyncEnabled",
    "useFor": "Show the selected Entra user’s account status and sync setting.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"User.ReadWrite.All\",\"User.EnableDisableAccount.All\",\"User-PasswordProfile.ReadWrite.All\",\"User.RevokeSessions.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, User.ReadWrite.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, User.RevokeSessions.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Assigned Licenses": {
    "code": "Get-MgUserLicenseDetail -UserId \"user@domain.com\" |\n  Select-Object SkuPartNumber,SkuId",
    "useFor": "Show the user’s assigned license codes and IDs.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"User.ReadWrite.All\",\"User.EnableDisableAccount.All\",\"User-PasswordProfile.ReadWrite.All\",\"User.RevokeSessions.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, User.ReadWrite.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, User.RevokeSessions.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Manager": {
    "code": "Invoke-MgGraphRequest -Method GET -Uri \"https://graph.microsoft.com/v1.0/users/user@domain.com/manager?`$select=displayName,userPrincipalName\" |\n  Select-Object displayName,userPrincipalName",
    "useFor": "Show the user’s recorded manager.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"User.ReadWrite.All\",\"User.EnableDisableAccount.All\",\"User-PasswordProfile.ReadWrite.All\",\"User.RevokeSessions.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, User.ReadWrite.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, User.RevokeSessions.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Password Last Changed And Age": {
    "code": "$u = Get-MgUser -UserId \"user@domain.com\" -Property UserPrincipalName,LastPasswordChangeDateTime\n[pscustomobject]@{\n  User = $u.UserPrincipalName\n  LastPasswordChange = $u.LastPasswordChangeDateTime\n  PasswordAgeDays = if($u.LastPasswordChangeDateTime){ [math]::Floor(((Get-Date) - $u.LastPasswordChangeDateTime).TotalDays) } else { $null }\n}",
    "useFor": "Show the recorded password change date and calculated age.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Sync Source": {
    "code": "Get-MgUser -UserId \"user@domain.com\" -Property UserPrincipalName,OnPremisesSyncEnabled,OnPremisesLastSyncDateTime,OnPremisesDomainName,OnPremisesSamAccountName |\n  Select-Object UserPrincipalName,OnPremisesSyncEnabled,OnPremisesLastSyncDateTime,OnPremisesDomainName,OnPremisesSamAccountName",
    "useFor": "Show whether the user is synced from Active Directory and the last recorded sync.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Delete Cloud User": {
    "code": "Remove-MgUser -UserId \"user@domain.com\"",
    "useFor": "Delete the selected Entra user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Disable Sign-In": {
    "code": "Update-MgUser -UserId \"user@domain.com\" -AccountEnabled:$false",
    "useFor": "Block the selected user’s Entra sign-in.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.EnableDisableAccount.All\",\"User.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.EnableDisableAccount.All, User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Enable Sign-In": {
    "code": "Update-MgUser -UserId \"user@domain.com\" -AccountEnabled:$true",
    "useFor": "Allow the selected user’s Entra sign-in.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.EnableDisableAccount.All\",\"User.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.EnableDisableAccount.All, User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Revoke Active Sessions": {
    "code": "Revoke-MgUserSignInSession -UserId \"user@domain.com\"",
    "useFor": "Revoke the user’s sign-in sessions; existing access may not end immediately.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.RevokeSessions.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.RevokeSessions.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Cached Tickets": {
    "code": "klist",
    "useFor": "Show cached Kerberos tickets for the current Windows session.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Purge Cached Tickets": {
    "code": "klist purge",
    "useFor": "Clear cached Kerberos tickets for the current Windows session.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Local Administrators": {
    "code": "Get-LocalGroupMember -Group \"Administrators\" |\n  Select-Object Name,ObjectClass,PrincipalSource",
    "useFor": "List members of this computer’s Administrators group.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "The example uses the English group name Administrators; localized Windows installations may use another name."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Local Users": {
    "code": "Get-LocalUser |\n  Select-Object Name,Enabled,LastLogon,PasswordExpires,UserMayChangePassword",
    "useFor": "List local Windows users and their account settings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Add User To Administrators": {
    "code": "Add-LocalGroupMember -Group \"Administrators\" -Member \"DOMAIN\\User\"",
    "useFor": "Add the selected account to this computer’s Administrators group.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Account to add or remove; replace DOMAIN\\User."
  },
  "Remove User From Administrators": {
    "code": "Remove-LocalGroupMember -Group \"Administrators\" -Member \"DOMAIN\\User\"",
    "useFor": "Remove the selected account from this computer’s Administrators group.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Account to add or remove; replace DOMAIN\\User."
  },
  "Show All Authentication Methods For One User": {
    "code": "Get-MgUserAuthenticationMethod -UserId \"user@domain.com\" |\n  Select-Object Id,@{N=\"Type\";E={$_.AdditionalProperties.'@odata.type'}}",
    "useFor": "List the user’s registered authentication methods and IDs.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"Reports.Read.All\",\"UserAuthenticationMethod.Read.All\",\"UserAuthenticationMethod.ReadWrite.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, Reports.Read.All, UserAuthenticationMethod.Read.All, UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Microsoft Authenticator Methods": {
    "code": "Get-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId \"user@domain.com\" |\n  Select-Object Id,DisplayName,DeviceTag,PhoneAppVersion",
    "useFor": "List the user’s registered Microsoft Authenticator methods.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"Reports.Read.All\",\"UserAuthenticationMethod.Read.All\",\"UserAuthenticationMethod.ReadWrite.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, Reports.Read.All, UserAuthenticationMethod.Read.All, UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Phone Methods": {
    "code": "Get-MgUserAuthenticationPhoneMethod -UserId \"user@domain.com\" |\n  Select-Object Id,PhoneNumber,PhoneType,SmsSignInState",
    "useFor": "List the user’s registered phone authentication methods.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"Reports.Read.All\",\"UserAuthenticationMethod.Read.All\",\"UserAuthenticationMethod.ReadWrite.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, Reports.Read.All, UserAuthenticationMethod.Read.All, UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Registration Status For One User": {
    "code": "Get-MgReportAuthenticationMethodUserRegistrationDetail -Filter \"userPrincipalName eq 'user@domain.com'\" |\n  Select-Object UserPrincipalName,IsMfaRegistered,IsMfaCapable,DefaultMfaMethod,MethodsRegistered",
    "useFor": "Show the user’s MFA registration report.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"Reports.Read.All\",\"UserAuthenticationMethod.Read.All\",\"UserAuthenticationMethod.ReadWrite.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, Reports.Read.All, UserAuthenticationMethod.Read.All, UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Specific Authenticator Method": {
    "code": "$MethodId = \"AUTH-METHOD-ID\"\nRemove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId \"user@domain.com\" -MicrosoftAuthenticatorAuthenticationMethodId $MethodId",
    "useFor": "Remove one selected Microsoft Authenticator method from the user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"UserAuthenticationMethod.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; record ID from a prior lookup. Review all target values before running. Method ID from the user’s authentication-method lookup; choose the matching method type."
  },
  "Remove Specific Phone Method": {
    "code": "$MethodId = \"AUTH-METHOD-ID\"\nRemove-MgUserAuthenticationPhoneMethod -UserId \"user@domain.com\" -PhoneAuthenticationMethodId $MethodId",
    "useFor": "Remove one selected phone authentication method from the user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"UserAuthenticationMethod.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; record ID from a prior lookup. Review all target values before running. Method ID from the user’s authentication-method lookup; choose the matching method type."
  },
  "Show Delegated Grants For One User": {
    "code": "Get-MgUserOauth2PermissionGrant -UserId \"user@domain.com\" -All |\n  Select-Object Id,ClientId,ConsentType,Scope",
    "useFor": "List app permissions approved on behalf of this user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"DelegatedPermissionGrant.Read.All\",\"DelegatedPermissionGrant.ReadWrite.All\",\"Application.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, DelegatedPermissionGrant.Read.All, DelegatedPermissionGrant.ReadWrite.All, Application.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Potentially High-Impact Delegated Scopes": {
    "code": "Get-MgUserOauth2PermissionGrant -UserId \"user@domain.com\" -All |\n  Where-Object {\n    $_.Scope -match '(^| )(offline_access|User.ReadWrite|Mail\\.|MailboxSettings\\.|Files\\.|Sites\\.|Calendars\\.|Contacts\\.|Directory\\.)' -or\n    $_.Scope -match '\\.All($| )'\n  } |\n  Select-Object Id,ClientId,ConsentType,Scope",
    "useFor": "Find this user’s approved app permissions that match the listed high-impact patterns.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"DelegatedPermissionGrant.Read.All\",\"DelegatedPermissionGrant.ReadWrite.All\",\"Application.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, DelegatedPermissionGrant.Read.All, DelegatedPermissionGrant.ReadWrite.All, Application.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Specific Delegated Grant": {
    "code": "$GrantId = \"OAUTH-GRANT-ID\"\nRemove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $GrantId",
    "useFor": "Remove one selected app permission grant.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"DelegatedPermissionGrant.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: DelegatedPermissionGrant.ReadWrite.All.",
    "input": "Replace command examples with your record ID from a prior lookup. Review all target values before running. Grant ID from the app-permission lookup, not the app ID."
  },
  "Show Distribution Group Members": {
    "code": "$Group = \"group@domain.com\"\nGet-DistributionGroupMember -Identity $Group -ResultSize Unlimited |\n  Select-Object DisplayName,PrimarySmtpAddress,RecipientType",
    "useFor": "List direct members of an Exchange distribution group.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Distribution Group Owners": {
    "code": "$Group = \"group@domain.com\"\nGet-DistributionGroup -Identity $Group |\n  Select-Object -ExpandProperty ManagedBy",
    "useFor": "Show the recorded owners of an Exchange distribution group.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Add Distribution Group Member": {
    "code": "$Group = \"group@domain.com\"\n$Member = \"user@domain.com\"\nAdd-DistributionGroupMember -Identity $Group -Member $Member",
    "useFor": "Add one user to the selected distribution group.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Distribution Group Member": {
    "code": "$Group = \"group@domain.com\"\n$Member = \"user@domain.com\"\nRemove-DistributionGroupMember -Identity $Group -Member $Member -Confirm:$false",
    "useFor": "Remove one user from the selected distribution group.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show AD Group Members": {
    "code": "$Group = \"Group Name\"\nGet-ADGroupMember -Identity $Group |\n  Select-Object Name,SamAccountName,ObjectClass",
    "useFor": "List direct members of the selected Active Directory group.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name."
  },
  "Show AD User Group Memberships": {
    "code": "Get-ADPrincipalGroupMembership -Identity \"username\" |\n  Select-Object Name,GroupCategory,GroupScope",
    "useFor": "List the Active Directory groups reported for this user.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Add User to AD Group": {
    "code": "$Group = \"Group Name\"\nAdd-ADGroupMember -Identity $Group -Members \"username\"",
    "useFor": "Add the user to the selected Active Directory group.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name; group name or object ID. Review all target values before running. Exact target group name."
  },
  "Remove User from AD Group": {
    "code": "$Group = \"Group Name\"\nRemove-ADGroupMember -Identity $Group -Members \"username\" -Confirm:$false",
    "useFor": "Remove the user from the selected Active Directory group.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name; group name or object ID. Review all target values before running. Exact target group name."
  },
  "Find Exact Group": {
    "code": "$GroupName = \"Group Name\"\nGet-MgGroup -Filter \"displayName eq '$GroupName'\" -Property Id,DisplayName,Mail,GroupTypes,SecurityEnabled,MailEnabled |\n  Select-Object Id,DisplayName,Mail,GroupTypes,SecurityEnabled,MailEnabled",
    "useFor": "Find Entra groups with the exact display name; more than one match is possible.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"Group.Read.All\",\"GroupMember.Read.All\",\"GroupMember.ReadWrite.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: Group.Read.All, GroupMember.Read.All, GroupMember.ReadWrite.All, User.Read.All.",
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name."
  },
  "Show Entra Group Direct Members": {
    "code": "Get-MgGroupMember -GroupId \"GROUP-OBJECT-ID\" -All |\n  Select-Object Id,@{N=\"Type\";E={$_.AdditionalProperties.'@odata.type'}},@{N=\"DisplayName\";E={$_.AdditionalProperties.displayName}},@{N=\"UPN\";E={$_.AdditionalProperties.userPrincipalName}}",
    "useFor": "List direct members of an Entra group by its object ID.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"Group.Read.All\",\"GroupMember.Read.All\",\"GroupMember.ReadWrite.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: Group.Read.All, GroupMember.Read.All, GroupMember.ReadWrite.All, User.Read.All.",
    "input": "Replace command examples with your group name or object ID; target user UPN. Review all target values before running. Group object ID from the group lookup."
  },
  "Show Entra Group Owners": {
    "code": "Get-MgGroupOwner -GroupId \"GROUP-OBJECT-ID\" -All |\n  Select-Object Id,@{N=\"DisplayName\";E={$_.AdditionalProperties.displayName}},@{N=\"UPN\";E={$_.AdditionalProperties.userPrincipalName}}",
    "useFor": "List owners of an Entra group by its object ID.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"Group.Read.All\",\"GroupMember.Read.All\",\"GroupMember.ReadWrite.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: Group.Read.All, GroupMember.Read.All, GroupMember.ReadWrite.All, User.Read.All.",
    "input": "Replace command examples with your group name or object ID; target user UPN. Review all target values before running. Group object ID from the group lookup."
  },
  "Show Entra User Group Memberships": {
    "code": "Get-MgUserMemberOf -UserId \"user@domain.com\" -All |\n  Select-Object Id,@{N=\"Type\";E={$_.AdditionalProperties.'@odata.type'}},@{N=\"DisplayName\";E={$_.AdditionalProperties.displayName}}",
    "useFor": "List the Entra directory objects this user belongs to.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"Group.Read.All\"",
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, Group.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Add User to Entra Group": {
    "code": "$UserId = (Get-MgUser -UserId \"user@domain.com\").Id\nNew-MgGroupMemberByRef -GroupId \"GROUP-OBJECT-ID\" -OdataId \"https://graph.microsoft.com/v1.0/directoryObjects/$UserId\"",
    "useFor": "Add the user to the selected Entra group.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"GroupMember.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, GroupMember.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; group name or object ID. Review all target values before running. Group object ID from the group lookup."
  },
  "Remove User from Entra Group": {
    "code": "$UserId = (Get-MgUser -UserId \"user@domain.com\").Id\nRemove-MgGroupMemberByRef -GroupId \"GROUP-OBJECT-ID\" -DirectoryObjectId $UserId",
    "useFor": "Remove the user’s direct membership from the selected Entra group.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"GroupMember.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: User.Read.All, GroupMember.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; group name or object ID. Review all target values before running. Group object ID from the group lookup."
  },
  "Show Mailbox Protocol State": {
    "code": "Get-CASMailbox -Identity \"user@domain.com\" |\n  Select-Object PopEnabled,ImapEnabled,SmtpClientAuthenticationDisabled,MAPIEnabled,OWAEnabled,ActiveSyncEnabled",
    "useFor": "Show which mailbox access protocols are enabled.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Mailbox Summary": {
    "code": "Get-Mailbox -Identity \"user@domain.com\" |\n  Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails,ForwardingAddress,ForwardingSmtpAddress,DeliverToMailboxAndForward",
    "useFor": "Show the mailbox type, primary address, and forwarding settings.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Disable Mailbox SMTP AUTH": {
    "code": "Set-CASMailbox -Identity \"user@domain.com\" -SmtpClientAuthenticationDisabled $true",
    "useFor": "Disable SMTP authentication for this mailbox.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Disable Mailbox POP / IMAP": {
    "code": "Set-CASMailbox -Identity \"user@domain.com\" -PopEnabled $false -ImapEnabled $false",
    "useFor": "Disable POP and IMAP access for this mailbox.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Mailbox Full Access Delegates": {
    "code": "Get-MailboxPermission -Identity \"user@domain.com\" |\n  Where-Object { -not $_.IsInherited -and $_.User -ne \"NT AUTHORITY\\SELF\" } |\n  Select-Object User,AccessRights,Deny",
    "useFor": "List explicit mailbox permissions, excluding inherited entries and SELF.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Mailbox Forwarding": {
    "code": "Get-Mailbox -Identity \"user@domain.com\" |\n  Select-Object PrimarySmtpAddress,ForwardingAddress,ForwardingSmtpAddress,DeliverToMailboxAndForward",
    "useFor": "Show mailbox-level forwarding settings.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Mailbox Send As Delegates": {
    "code": "Get-RecipientPermission -Identity \"user@domain.com\" |\n  Where-Object { $_.Trustee -ne \"NT AUTHORITY\\SELF\" } |\n  Select-Object Trustee,AccessRights",
    "useFor": "List Send As permissions, excluding SELF.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Mailbox Send on Behalf Delegates": {
    "code": "Get-Mailbox -Identity \"user@domain.com\" |\n  Select-Object -ExpandProperty GrantSendOnBehalfTo",
    "useFor": "Show who can send on behalf of the mailbox.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Mailbox Full Access Delegate": {
    "code": "$Delegate = \"delegate@domain.com\"\nRemove-MailboxPermission -Identity \"user@domain.com\" -User $Delegate -AccessRights FullAccess -Confirm:$false",
    "useFor": "Remove the selected delegate’s Full Access permission.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Mailbox Forwarding": {
    "code": "Set-Mailbox -Identity \"user@domain.com\" -ForwardingAddress $null -ForwardingSmtpAddress $null -DeliverToMailboxAndForward $false",
    "useFor": "Clear mailbox-level forwarding; inbox rules are unchanged.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Mailbox Send As Delegate": {
    "code": "$Delegate = \"delegate@domain.com\"\nRemove-RecipientPermission -Identity \"user@domain.com\" -Trustee $Delegate -AccessRights SendAs -Confirm:$false",
    "useFor": "Remove the selected delegate’s Send As permission.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Mailbox Send on Behalf Delegate": {
    "code": "$Delegate = \"delegate@domain.com\"\nSet-Mailbox -Identity \"user@domain.com\" -GrantSendOnBehalfTo @{Remove=$Delegate}",
    "useFor": "Remove the selected delegate’s Send on Behalf permission.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Specific Transport Rule": {
    "code": "$Rule = \"Rule Name\"\nGet-TransportRule -Identity $Rule | Format-List *",
    "useFor": "Show all settings for the selected mail-flow rule.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running."
  },
  "Show Transport Rules": {
    "code": "Get-TransportRule |\n  Select-Object Name,State,Mode,Priority",
    "useFor": "List mail-flow rules with their status, mode, and priority.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter."
  },
  "Show Inbox Rules - Including Hidden": {
    "code": "Get-InboxRule -Mailbox \"user@domain.com\" -IncludeHidden |\n  Select-Object Name,Enabled,Priority,ForwardTo,RedirectTo,DeleteMessage,MoveToFolder,StopProcessingRules",
    "useFor": "List mailbox inbox rules, including hidden rules.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Suspicious Inbox Rules": {
    "code": "Get-InboxRule -Mailbox \"user@domain.com\" -IncludeHidden |\n  Where-Object { $_.ForwardTo -or $_.RedirectTo -or $_.DeleteMessage -or $_.StopProcessingRules } |\n  Select-Object Name,Enabled,ForwardTo,RedirectTo,DeleteMessage,MoveToFolder,StopProcessingRules",
    "useFor": "Find inbox rules with forwarding, redirect, deletion, or stop-processing actions.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove All Inbox Rules": {
    "code": "Get-InboxRule -Mailbox \"user@domain.com\" -IncludeHidden |\n  Remove-InboxRule -Confirm:$false",
    "useFor": "Delete every inbox rule in the selected mailbox, including hidden rules.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Deletes rules, not email. Export or record rules first if you may need to restore them."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Specific Inbox Rule": {
    "code": "$Rule = \"Rule Name\"\nRemove-InboxRule -Mailbox \"user@domain.com\" -Identity $Rule -Confirm:$false",
    "useFor": "Delete one selected inbox rule.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Deletes rules, not email. Export or record rules first if you may need to restore them."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address; target search, rule, task or subject. Review all target values before running."
  },
  "Show BitLocker Recovery Protectors": {
    "code": "Get-BitLockerVolume -MountPoint \"C:\" |\n  Select-Object -ExpandProperty KeyProtector |\n  Select-Object KeyProtectorType,KeyProtectorId,RecoveryPassword",
    "useFor": "Display BitLocker key protectors and recovery passwords for C:.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Contains recovery secrets or a private key; keep the output private."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Drive or file path shown in the command; change it if the target is not C:."
  },
  "Show BitLocker Status": {
    "code": "Get-BitLockerVolume |\n  Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionPercentage,EncryptionMethod",
    "useFor": "Show BitLocker protection and encryption status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Resume Protection": {
    "code": "Resume-BitLocker -MountPoint \"C:\"",
    "useFor": "Resume BitLocker protection on C:.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Drive or file path shown in the command; change it if the target is not C:."
  },
  "Suspend For One Reboot": {
    "code": "Suspend-BitLocker -MountPoint \"C:\" -RebootCount 1",
    "useFor": "Suspend BitLocker protection on C: for one reboot.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Drive or file path shown in the command; change it if the target is not C:."
  },
  "Find By Thumbprint": {
    "code": "Get-ChildItem Cert:\\CurrentUser\\My,Cert:\\LocalMachine\\My |\n  Where-Object Thumbprint -eq \"THUMBPRINT\" |\n  Select-Object Subject,Thumbprint,NotBefore,NotAfter,HasPrivateKey",
    "useFor": "Find a certificate by its thumbprint in the current-user and computer stores.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your certificate thumbprint. Review all target values before running."
  },
  "Show Expiring Certificates": {
    "code": "Get-ChildItem Cert:\\LocalMachine\\My |\n  Where-Object { $_.NotAfter -le (Get-Date).AddDays(30) } |\n  Select-Object Subject,Thumbprint,NotAfter",
    "useFor": "List computer certificates that expire within 30 days, including already expired ones.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Verify Script Signature": {
    "code": "$Path = \"C:\\Scripts\\script.ps1\"\nGet-AuthenticodeSignature -FilePath $Path |\n  Select-Object Status,StatusMessage,SignerCertificate",
    "useFor": "Show a script’s signature status and signing certificate.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:."
  },
  "Create Self-Signed App-Auth Certificate": {
    "code": "$Name = \"M365-AppAuth\"\nNew-SelfSignedCertificate `\n  -Subject \"CN=$Name\" `\n  -CertStoreLocation \"Cert:\\CurrentUser\\My\" `\n  -KeySpec KeyExchange `\n  -KeyExportPolicy Exportable `\n  -KeyLength 2048 `\n  -HashAlgorithm SHA256 `\n  -NotAfter (Get-Date).AddYears(2)",
    "useFor": "Create a self-signed certificate for app authentication in the current-user store.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your certificate subject name. Review all target values before running."
  },
  "Export Pfx": {
    "code": "$Thumbprint = \"THUMBPRINT\"\n$Path = \"C:\\Temp\\AppAuth.pfx\"\n$Password = Read-Host \"PFX password\" -AsSecureString\n$Cert = Get-Item \"Cert:\\CurrentUser\\My\\$Thumbprint\"\nExport-PfxCertificate -Cert $Cert -FilePath $Path -Password $Password",
    "useFor": "Export a certificate and its private key to a password-protected PFX file.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Contains recovery secrets or a private key; keep the output private."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your certificate thumbprint; local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:."
  },
  "Export Public Cer": {
    "code": "$Thumbprint = \"THUMBPRINT\"\n$Path = \"C:\\Temp\\AppAuth.cer\"\n$Cert = Get-Item \"Cert:\\CurrentUser\\My\\$Thumbprint\"\nExport-Certificate -Cert $Cert -FilePath $Path",
    "useFor": "Export a public certificate to a CER file without its private key.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your certificate thumbprint; local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:."
  },
  "Sign Script": {
    "code": "$Path = \"C:\\Scripts\\script.ps1\"\n$Thumbprint = \"THUMBPRINT\"\n$Cert = Get-Item \"Cert:\\CurrentUser\\My\\$Thumbprint\"\nSet-AuthenticodeSignature -FilePath $Path -Certificate $Cert -TimestampServer \"http://timestamp.digicert.com\"",
    "useFor": "Sign the selected script using the chosen certificate and timestamp service.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your certificate thumbprint; local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:."
  },
  "Find Exchange Service Principal By Appid": {
    "code": "$AppId = \"APP-ID\"\nGet-ServicePrincipal |\n  Where-Object AppId -eq $AppId |\n  Select-Object DisplayName,AppId,ObjectId",
    "useFor": "Find an Exchange service principal by its application ID.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your record ID from a prior lookup. Review all target values before running. Application (client) ID of the app to find."
  },
  "Calculate Sha256 Hash": {
    "code": "$Path = \"C:\\Temp\\file.exe\"\nGet-FileHash -Path $Path -Algorithm SHA256",
    "useFor": "Calculate a file’s SHA-256 hash for comparison with a trusted value.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:."
  },
  "Show Compliance Search Status": {
    "code": "$SearchName = \"SEARCH-NAME\"\nGet-ComplianceSearch -Identity $SearchName |\n  Select-Object Name,Status,Items,Size,SuccessResults",
    "useFor": "Show the selected Purview search’s status and result count.",
    "connectFirst": [
      "Connect-IPPSSession"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and Purview roles for this search or purge action. Your tenant must support the command shown.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running."
  },
  "Create Phishing Search By Subject": {
    "code": "$SearchName = \"IR_Clawback_$(Get-Date -Format 'yyyyMMdd_HHmmss')\"\n$Subject = \"phishing subject\"\nNew-ComplianceSearch `\n  -Name $SearchName `\n  -ExchangeLocation All `\n  -ContentMatchQuery \"subject:`\"$Subject`\"\"",
    "useFor": "Create a tenant-wide email search for a subject; this does not start the search.",
    "connectFirst": [
      "Connect-IPPSSession"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and Purview roles for this search or purge action. Your tenant must support the command shown.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running."
  },
  "Hard-Delete Search Results": {
    "code": "$SearchName = \"SEARCH-NAME\"\nNew-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete",
    "useFor": "Request hard deletion of the selected completed search’s results.",
    "connectFirst": [
      "Connect-IPPSSession"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Permanent deletion request. Review the completed search and obtain approval before running."
    ],
    "requires": "ExchangeOnlineManagement module and Purview roles for this search or purge action. Your tenant must support the command shown.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running."
  },
  "Start Compliance Search": {
    "code": "$SearchName = \"SEARCH-NAME\"\nStart-ComplianceSearch -Identity $SearchName",
    "useFor": "Start the selected Purview compliance search.",
    "connectFirst": [
      "Connect-IPPSSession"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and Purview roles for this search or purge action. Your tenant must support the command shown.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running."
  },
  "Run Quick Scan": {
    "code": "Start-MpScan -ScanType QuickScan",
    "useFor": "Start a Microsoft Defender quick scan.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Update Signatures": {
    "code": "Update-MpSignature",
    "useFor": "Update Microsoft Defender threat definitions.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Audit Inbox Rule Changes": {
    "code": "Search-UnifiedAuditLog `\n  -StartDate (Get-Date).AddDays(-14) `\n  -EndDate (Get-Date) `\n  -Operations New-InboxRule,Set-InboxRule `\n  -UserIds \"user@domain.com\" `\n  -ResultSize 5000 |\n  Select-Object CreationDate,UserIds,Operation,AuditData",
    "useFor": "Find inbox-rule creation and change events for one user over 14 days.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows available returned records only; this command does not collect every page or prove that no other activity exists."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Mail Delete And Move Audit": {
    "code": "Search-UnifiedAuditLog `\n  -StartDate (Get-Date).AddDays(-14) `\n  -EndDate (Get-Date) `\n  -Operations SoftDelete,HardDelete,MoveToDeletedItems,Update `\n  -UserIds \"user@domain.com\" `\n  -ResultSize 5000 |\n  Select-Object CreationDate,UserIds,Operation,AuditData",
    "useFor": "Find recorded email deletion, move, and update events for one user over 14 days.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows available returned records only; this command does not collect every page or prove that no other activity exists."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Mailitemsaccessed Audit": {
    "code": "Search-UnifiedAuditLog `\n  -StartDate (Get-Date).AddDays(-10) `\n  -EndDate (Get-Date) `\n  -Operations MailItemsAccessed `\n  -UserIds \"user@domain.com\" `\n  -ResultSize 5000 |\n  Select-Object CreationDate,UserIds,Operation,AuditData",
    "useFor": "Find recorded MailItemsAccessed events for one user over 10 days.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows available returned records only; this command does not collect every page or prove that no other activity exists."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Parse Mail Audit Subject, Ip, And Destination Folder": {
    "code": "Search-UnifiedAuditLog `\n  -StartDate (Get-Date).AddDays(-14) `\n  -EndDate (Get-Date) `\n  -Operations MailItemsAccessed,SoftDelete,HardDelete,MoveToDeletedItems,Update `\n  -UserIds \"user@domain.com\" `\n  -ResultSize 5000 |\n  Select-Object CreationDate,Operation,\n    @{N=\"EmailSubject\";E={(ConvertFrom-Json $_.AuditData).Item.Subject}},\n    @{N=\"ClientIP\";E={(ConvertFrom-Json $_.AuditData).ClientIP}},\n    @{N=\"DestFolder\";E={(ConvertFrom-Json $_.AuditData).DestinationFolder.Name}}",
    "useFor": "Extract available subject, IP address, and folder fields from mail audit events.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows available returned records only; this command does not collect every page or prove that no other activity exists."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Search Query Audit": {
    "code": "Search-UnifiedAuditLog -Operations SearchQueryInitiated -UserIds \"user@domain.com\" |\n  Select-Object CreationDate,UserIds,Operation,AuditData",
    "useFor": "Show recorded search-query audit events for one user.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows available returned records only; this command does not collect every page or prove that no other activity exists."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Unified Audit Log For One User": {
    "code": "Search-UnifiedAuditLog `\n  -StartDate (Get-Date).AddDays(-7) `\n  -EndDate (Get-Date) `\n  -UserIds \"user@domain.com\" `\n  -ResultSize 5000 |\n  Select-Object CreationDate,UserIds,Operation,AuditData",
    "useFor": "Show up to 5,000 audit events for one user over seven days.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows available returned records only; this command does not collect every page or prove that no other activity exists."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Risk Detections For One User": {
    "code": "$UserId = (Get-MgUser -UserId \"user@domain.com\").Id\nGet-MgRiskDetection -Filter \"userId eq '$UserId'\" -All |\n  Select-Object ActivityDateTime,RiskEventType,RiskLevel,RiskState,IPAddress,Location,Source",
    "useFor": "Show Identity Protection risk detections for one user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"IdentityRiskEvent.Read.All\",\"IdentityRiskyUser.Read.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: IdentityRiskEvent.Read.All, IdentityRiskyUser.Read.All, User.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Risky User State": {
    "code": "Get-MgRiskyUser -Filter \"userPrincipalName eq 'user@domain.com'\" |\n  Select-Object UserPrincipalName,RiskLevel,RiskState,RiskDetail,RiskLastUpdatedDateTime",
    "useFor": "Show the user’s current Identity Protection risk status.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"IdentityRiskEvent.Read.All\",\"IdentityRiskyUser.Read.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: IdentityRiskEvent.Read.All, IdentityRiskyUser.Read.All, User.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Recipient": {
    "code": "Get-MessageTraceV2 `\n  -RecipientAddress \"user@domain.com\" `\n  -StartDate (Get-Date).AddDays(-7) `\n  -EndDate (Get-Date) `\n  -ResultSize 5000 |\n  Select-Object Received,SenderAddress,RecipientAddress,Subject,Status,MessageTraceId",
    "useFor": "Trace email delivered to the selected recipient over seven days.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows the returned search results only; result limits can leave a large search incomplete."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Sender": {
    "code": "Get-MessageTraceV2 `\n  -SenderAddress \"user@domain.com\" `\n  -StartDate (Get-Date).AddDays(-7) `\n  -EndDate (Get-Date) `\n  -ResultSize 5000 |\n  Select-Object Received,SenderAddress,RecipientAddress,Subject,Status,MessageTraceId",
    "useFor": "Trace email from the selected sender over seven days.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows the returned search results only; result limits can leave a large search incomplete."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Message Trace Events": {
    "code": "$TraceId = \"MESSAGE-TRACE-ID\"\nGet-MessageTraceDetailV2 -MessageTraceId $TraceId -RecipientAddress \"recipient@domain.com\" |\n  Select-Object Date,Event,Action,Detail,Data",
    "useFor": "Show delivery events for a message trace ID and recipient.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address; record ID from a prior lookup. Review all target values before running. Message trace ID from a trace search and the exact recipient address."
  },
  "Show Message Trace Search Jobs": {
    "code": "Get-HistoricalSearch |\n  Sort-Object SubmitDate -Descending |\n  Select-Object -First 5 ReportTitle,Status,Rows,FileUrl,SubmitDate",
    "useFor": "Show the five most recent historical message-trace search jobs.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter."
  },
  "Who Received Mail From Suspicious Sender": {
    "code": "Get-MessageTraceV2 `\n  -SenderAddress \"badguy@evil.com\" `\n  -StartDate (Get-Date).AddDays(-10) `\n  -EndDate (Get-Date) `\n  -ResultSize 5000 |\n  Select-Object -ExpandProperty RecipientAddress |\n  Sort-Object -Unique",
    "useFor": "List recipients found in message traces for a suspect sender over 10 days.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Shows the returned search results only; result limits can leave a large search incomplete."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your suspect sender address. Review all target values before running."
  },
  "Show Failed Sign-Ins": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddHours(-48).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Where-Object { $_.Status.ErrorCode -ne 0 } |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,\n    @{N=\"ErrorCode\";E={$_.Status.ErrorCode}},\n    @{N=\"FailureReason\";E={$_.Status.FailureReason}}",
    "useFor": "Show failed sign-ins for one user over 48 hours.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: AuditLog.Read.All, User.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Last 10 Entra Sign-Ins": {
    "code": "Get-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com'\" -Top 10 -Sort \"createdDateTime desc\" |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,ConditionalAccessStatus,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed: $($_.Status.ErrorCode)\"}}},\n    @{N=\"Location\";E={\"$($_.Location.City), $($_.Location.State), $($_.Location.CountryOrRegion)\"}}",
    "useFor": "Show the user’s 10 most recent Entra sign-ins.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: AuditLog.Read.All, User.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Entra Sign-ins - Last 48 Hours": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddHours(-48).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,ConditionalAccessStatus,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed: $($_.Status.ErrorCode)\"}}}",
    "useFor": "Show the user’s Entra sign-ins over 48 hours.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: AuditLog.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Legacy / Other-client Sign-ins": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddDays(-7).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Where-Object { $_.ClientAppUsed -eq \"Other clients\" } |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed\"}}}",
    "useFor": "Show sign-ins classified as Other clients over seven days; this is not proof of legacy authentication.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: AuditLog.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Successful Sign-Ins": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddHours(-48).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Where-Object { $_.Status.ErrorCode -eq 0 } |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,ConditionalAccessStatus",
    "useFor": "Show successful sign-ins for one user over 48 hours.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: AuditLog.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Recent Application Errors": {
    "code": "Get-WinEvent -FilterHashtable @{LogName=\"Application\";Level=2;StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue |\n  Select-Object TimeCreated,ProviderName,Id,Message",
    "useFor": "Show application error events from the last 24 hours.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Some read errors are suppressed. No output does not prove that nothing exists."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Recent System Errors": {
    "code": "Get-WinEvent -FilterHashtable @{LogName=\"System\";Level=2;StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue |\n  Select-Object TimeCreated,ProviderName,Id,Message",
    "useFor": "Show system error events from the last 24 hours.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Some read errors are suppressed. No output does not prove that nothing exists."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Resolve Name": {
    "code": "$Name = \"example.com\"\nResolve-DnsName $Name",
    "useFor": "Look up DNS records for a domain or host name.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Show Configured Dns Servers": {
    "code": "Get-DnsClientServerAddress -AddressFamily IPv4 |\n  Select-Object InterfaceAlias,ServerAddresses",
    "useFor": "Show configured IPv4 DNS servers for each network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Flush Resolver Cache": {
    "code": "Clear-DnsClientCache",
    "useFor": "Clear this computer’s DNS resolver cache.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Windows Firewall Profiles": {
    "code": "Get-NetFirewallProfile |\n  Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction",
    "useFor": "Show Windows Firewall profile status and default actions.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Windows Firewall Rules by Name": {
    "code": "$Name = \"*Remote Desktop*\"\nGet-NetFirewallRule -DisplayName $Name |\n  Select-Object DisplayName,Enabled,Direction,Action,Profile",
    "useFor": "Find firewall rules whose display names match the supplied filter.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your firewall rule display-name filter. Review all target values before running."
  },
  "Ping Host": {
    "code": "Test-Connection -ComputerName \"server01\" -Count 4",
    "useFor": "Send four ping tests to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Show Active Adapters": {
    "code": "Get-NetAdapter |\n  Where-Object Status -eq \"Up\" |\n  Select-Object Name,InterfaceDescription,MacAddress,LinkSpeed",
    "useFor": "List network adapters whose status is Up.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Arp Neighbor Cache": {
    "code": "Get-NetNeighbor -AddressFamily IPv4 |\n  Select-Object IPAddress,LinkLayerAddress,State,InterfaceAlias",
    "useFor": "Show cached IPv4 neighbors and their hardware addresses.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Established Tcp Connections": {
    "code": "Get-NetTCPConnection -State Established |\n  Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,OwningProcess",
    "useFor": "List established TCP connections and their owning process IDs.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Ip Configuration": {
    "code": "Get-NetIPConfiguration |\n  Select-Object InterfaceAlias,IPv4Address,IPv4DefaultGateway,DNSServer",
    "useFor": "Show local IP addresses, gateways, and DNS servers.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Listening Tcp Ports": {
    "code": "Get-NetTCPConnection -State Listen |\n  Sort-Object LocalPort |\n  Select-Object LocalAddress,LocalPort,OwningProcess",
    "useFor": "List listening TCP ports and their owning process IDs.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Routing Table": {
    "code": "Get-NetRoute -AddressFamily IPv4 |\n  Sort-Object RouteMetric |\n  Select-Object DestinationPrefix,NextHop,InterfaceAlias,RouteMetric",
    "useFor": "Show IPv4 routes sorted by route metric.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Test Tcp Port": {
    "code": "Test-NetConnection -ComputerName \"server01\" -Port 443",
    "useFor": "Test a host’s TCP port; the example uses port 443.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Trace Route": {
    "code": "Test-NetConnection -ComputerName \"example.com\" -TraceRoute",
    "useFor": "Trace the network path to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Release And Renew Dhcp": {
    "code": "ipconfig /release\nipconfig /renew",
    "useFor": "Release and renew DHCP addresses on this computer.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Reset Tcp/Ip Stack": {
    "code": "netsh int ip reset",
    "useFor": "Reset the local TCP/IP configuration.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Reset Winsock": {
    "code": "netsh winsock reset",
    "useFor": "Reset the local Winsock catalog.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Restart Adapter": {
    "code": "Restart-NetAdapter -Name \"Ethernet\" -Confirm:$false",
    "useFor": "Restart the selected network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your network adapter name. Review all target values before running."
  },
  "Show Configured Windows Vpn Connections": {
    "code": "Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue |\n  Select-Object Name,ServerAddress,TunnelType,AuthenticationMethod,ConnectionStatus",
    "useFor": "Show VPN connections configured for all users.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Some read errors are suppressed. No output does not prove that nothing exists."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Wi-Fi Connection": {
    "code": "netsh wlan show interfaces",
    "useFor": "Show the current Wi-Fi connection details.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Saved Wi-Fi Profiles": {
    "code": "netsh wlan show profiles",
    "useFor": "List saved Wi-Fi profile names.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Problem Devices": {
    "code": "Get-PnpDevice -PresentOnly |\n  Where-Object Status -ne \"OK\" |\n  Select-Object Class,FriendlyName,InstanceId,Status",
    "useFor": "Show connected devices whose reported status is not OK.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Free Space": {
    "code": "Get-CimInstance Win32_LogicalDisk -Filter \"DriveType=3\" |\n  Select-Object DeviceID,\n    @{N=\"SizeGB\";E={[math]::Round($_.Size/1GB,1)}},\n    @{N=\"FreeGB\";E={[math]::Round($_.FreeSpace/1GB,1)}},\n    @{N=\"FreePct\";E={[math]::Round(($_.FreeSpace/$_.Size)*100,1)}}",
    "useFor": "Show total and free space on fixed local drives.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Physical Disk Health": {
    "code": "Get-PhysicalDisk |\n  Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus,Size",
    "useFor": "Show physical disk health and operating status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Find Files Modified In Last 24 Hours": {
    "code": "$Path = \"C:\\Temp\"\nGet-ChildItem $Path -File -Recurse -ErrorAction SilentlyContinue |\n  Where-Object LastWriteTime -ge (Get-Date).AddHours(-24) |\n  Select-Object FullName,Length,LastWriteTime",
    "useFor": "Find files changed in the last 24 hours within the selected folder and its subfolders.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Some read errors are suppressed. No output does not prove that nothing exists."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:."
  },
  "Show Computer Model And Serial Number": {
    "code": "$System = Get-CimInstance Win32_ComputerSystem\n$Bios = Get-CimInstance Win32_BIOS\n[pscustomobject]@{\n  Manufacturer = $System.Manufacturer\n  Model = $System.Model\n  SerialNumber = $Bios.SerialNumber\n}",
    "useFor": "Show this computer’s manufacturer, model, and serial number.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Hostname And Current User": {
    "code": "[pscustomobject]@{\n  ComputerName = $env:COMPUTERNAME\n  User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name\n}",
    "useFor": "Show the computer name and current Windows account.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Last Boot And Uptime": {
    "code": "$OS = Get-CimInstance Win32_OperatingSystem\n[pscustomobject]@{\n  LastBoot = $OS.LastBootUpTime\n  Uptime = (Get-Date) - $OS.LastBootUpTime\n}",
    "useFor": "Show the last Windows boot time and calculated uptime.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Os And Build": {
    "code": "Get-CimInstance Win32_OperatingSystem |\n  Select-Object Caption,Version,BuildNumber,OSArchitecture",
    "useFor": "Show the Windows version, build, and architecture.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Top Cpu Consumers": {
    "code": "Get-Process |\n  Sort-Object CPU -Descending |\n  Select-Object -First 15 Name,Id,CPU",
    "useFor": "List 15 processes with the most accumulated CPU time; this is not current CPU percentage.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Top Memory Consumers": {
    "code": "Get-Process |\n  Sort-Object WorkingSet64 -Descending |\n  Select-Object -First 15 Name,Id,@{N=\"MemoryMB\";E={[math]::Round($_.WorkingSet64/1MB,1)}}",
    "useFor": "List 15 processes using the most working-set memory.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Stop Process By Name": {
    "code": "$Name = \"notepad\"\nStop-Process -Name $Name -Force",
    "useFor": "Force-stop all processes with the selected name.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Can discard unsaved work in every matching process."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your process name. Review all target values before running."
  },
  "Show Whether Remote Desktop Is Enabled": {
    "code": "$Value = (Get-ItemProperty \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\" -Name fDenyTSConnections).fDenyTSConnections\n[pscustomobject]@{ RDPEnabled = ($Value -eq 0) }",
    "useFor": "Show whether the Remote Desktop registry setting allows connections.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "This registry setting alone does not confirm firewall access or a working remote connection."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Chkdsk Online Scan": {
    "code": "chkdsk C: /scan",
    "useFor": "Run an online file-system scan of C:.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Drive or file path shown in the command; change it if the target is not C:."
  },
  "Dism Component Store Scan": {
    "code": "DISM.exe /Online /Cleanup-Image /ScanHealth",
    "useFor": "Check the Windows component store for corruption.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Dism Restore Health": {
    "code": "DISM.exe /Online /Cleanup-Image /RestoreHealth",
    "useFor": "Repair the Windows component store.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "System File Checker": {
    "code": "sfc.exe /scannow",
    "useFor": "Scan and repair protected Windows system files.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Reboot Computer": {
    "code": "Restart-Computer -Force",
    "useFor": "Force an immediate restart of this computer.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Restarts immediately and can discard unsaved work."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Service Status": {
    "code": "Get-Service -Name \"Spooler\" |\n  Select-Object Name,DisplayName,Status,StartType",
    "useFor": "Show the selected service’s status and startup type.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your service name. Review all target values before running."
  },
  "Restart Service": {
    "code": "Restart-Service -Name \"Spooler\" -Force",
    "useFor": "Force-restart the selected Windows service.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your service name. Review all target values before running."
  },
  "Set Startup Type": {
    "code": "Set-Service -Name \"Spooler\" -StartupType Automatic",
    "useFor": "Set the selected service to start automatically.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your service name. Review all target values before running."
  },
  "Show Locally Logged-On Users": {
    "code": "quser",
    "useFor": "List users and sessions reported by Windows.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show SMB Sessions": {
    "code": "Get-SmbSession |\n  Select-Object ClientComputerName,ClientUserName,NumOpens,Dialect",
    "useFor": "List active SMB file-sharing sessions.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show SMB Shares": {
    "code": "Get-SmbShare |\n  Select-Object Name,Path,Description",
    "useFor": "List local SMB shares and their paths.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Scheduled Task": {
    "code": "Get-ScheduledTask -TaskName \"Task Name\" |\n  Select-Object TaskName,TaskPath,State",
    "useFor": "Show the selected scheduled task’s state and path.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running."
  },
  "Show Scheduled Task Last Run Result": {
    "code": "Get-ScheduledTaskInfo -TaskName \"Task Name\" |\n  Select-Object LastRunTime,LastTaskResult,NextRunTime,NumberOfMissedRuns",
    "useFor": "Show a task’s last run, result code, and next run time.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running."
  },
  "Check Common Pending Reboot Flags": {
    "code": "$Pending = $false\nif(Test-Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Component Based Servicing\\RebootPending\"){ $Pending = $true }\nif(Test-Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update\\RebootRequired\"){ $Pending = $true }\n[pscustomobject]@{ PendingReboot = $Pending }",
    "useFor": "Check two common registry flags for a pending Windows reboot.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Checks only the two registry locations shown; other reboot requirements may exist."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Installed Hotfixes": {
    "code": "Get-HotFix |\n  Sort-Object InstalledOn -Descending |\n  Select-Object HotFixID,Description,InstalledOn,InstalledBy",
    "useFor": "List installed hotfixes, newest first.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Recent Windows Update History": {
    "code": "Get-WinEvent -FilterHashtable @{LogName=\"System\";ProviderName=\"Microsoft-Windows-WindowsUpdateClient\";StartTime=(Get-Date).AddDays(-30)} -ErrorAction SilentlyContinue |\n  Select-Object TimeCreated,Id,LevelDisplayName,Message",
    "useFor": "Show Windows Update events recorded over 30 days.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Some read errors are suppressed. No output does not prove that nothing exists."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Add Calendar Permission": {
    "code": "$AccessRights = \"Reviewer\" # Reviewer or Editor\nAdd-MailboxFolderPermission -Identity \"owner@domain.com:\\Calendar\" -User \"user@domain.com\" -AccessRights $AccessRights",
    "useFor": "Grant the selected user Reviewer or Editor access to a mailbox calendar.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Remove Calendar Permission": {
    "code": "Remove-MailboxFolderPermission -Identity \"owner@domain.com:\\Calendar\" -User \"user@domain.com\" -Confirm:$false",
    "useFor": "Remove the selected user’s permission from a mailbox calendar.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Calendar Permissions": {
    "code": "Get-MailboxFolderPermission -Identity \"user@domain.com:\\Calendar\"",
    "useFor": "Show permissions on the selected mailbox’s Calendar folder.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Contacts Permissions": {
    "code": "Get-MailboxFolderPermission -Identity \"user@domain.com:\\Contacts\"",
    "useFor": "Show permissions on the selected mailbox’s Contacts folder.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Add Contacts Permission": {
    "code": "$AccessRights = \"Reviewer\" # Reviewer or Editor\nAdd-MailboxFolderPermission -Identity \"owner@domain.com:\\Contacts\" -User \"user@domain.com\" -AccessRights $AccessRights",
    "useFor": "Grant the selected user Reviewer or Editor access to mailbox contacts.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Show Send-To Restrictions / authOrig": {
    "code": "Get-ADGroup 'GroupName' -Properties authOrig | Select-Object -ExpandProperty authOrig",
    "useFor": "Show the group’s authOrig sender-restriction values.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name."
  },
  "Show Account Enabled": {
    "code": "Get-ADUser \"username\" -Properties Enabled | Select-Object SamAccountName,Enabled",
    "useFor": "Show whether an Active Directory account is enabled.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Show User Principal Name": {
    "code": "Get-ADUser -Identity \"username\" -Properties UserPrincipalName | Select-Object UserPrincipalName",
    "useFor": "Show the user’s Active Directory sign-in name (UPN).",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Show Password Last Set": {
    "code": "Get-ADUser -Identity \"username\" -Properties PasswordLastSet | Select-Object Name,PasswordLastSet",
    "useFor": "Show when the Active Directory password was last set.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Show Distinguished Name": {
    "code": "Get-ADUser -Identity \"username\" | Select-Object DistinguishedName",
    "useFor": "Show the user’s full Active Directory object path (distinguished name).",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Show Default Domain Password Policy": {
    "code": "Get-ADDefaultDomainPasswordPolicy",
    "useFor": "Show the domain’s default password policy; user-specific policies may differ.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Uses the domain available to your Windows account; no user or group name to enter."
  },
  "Force Group Policy Update": {
    "code": "gpupdate /force",
    "useFor": "Refresh Group Policy on this computer.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Group Policy Result": {
    "code": "gpresult /r",
    "useFor": "Show Group Policy results for the current context.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Disable Hibernation": {
    "code": "powercfg.exe /hibernate off",
    "useFor": "Disable Windows hibernation on this computer.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Domain Account Details": {
    "code": "net user username /domain",
    "useFor": "Show details for a domain account using net user.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Create Local User": {
    "code": "net user username /add",
    "useFor": "Create a local Windows account with the selected name.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Delete Local User": {
    "code": "net user username /delete",
    "useFor": "Delete the selected local Windows account.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Set Local User Password": {
    "code": "net user \"username\" \"temporary password\"",
    "useFor": "Set the selected local account’s password using a command-line value.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "The password is typed in plain text and may remain in command history or recordings."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your target account name. Review all target values before running. New password; replace the example value before running."
  },
  "Enable Local Account": {
    "code": "net user \"username\" /active:yes",
    "useFor": "Enable the selected local Windows account.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Open Local Users and Groups": {
    "code": "lusrmgr.msc",
    "useFor": "Open the Local Users and Groups management console.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Logged-On Users": {
    "code": "quser",
    "useFor": "List users and sessions reported by Windows.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Disable Network Adapter": {
    "code": "netsh interface set interface \"Wi-Fi\" admin=disabled",
    "useFor": "Disable the selected network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your network adapter name. Review all target values before running."
  },
  "Restart Network Adapter": {
    "code": "Restart-NetAdapter -Name \"Wi-Fi\"",
    "useFor": "Restart the selected network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your network adapter name. Review all target values before running."
  },
  "Isolate Device - Disable Enabled Adapters": {
    "code": "Get-NetAdapter | Where-Object Status -eq \"Up\" | Disable-NetAdapter -Confirm:$false",
    "useFor": "Disable every network adapter whose status is Up.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Resync Windows Time": {
    "code": "w32tm /resync /force",
    "useFor": "Request an immediate Windows time synchronization.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Open Windows Update": {
    "code": "start ms-settings:windowsupdate-action",
    "useFor": "Open Windows Update settings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Show Wi-Fi Interface": {
    "code": "netsh wlan show interfaces",
    "useFor": "Show Wi-Fi interface details.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Delete Wi-Fi Profile": {
    "code": "netsh wlan delete profile name=\"ProfileName\"",
    "useFor": "Delete the selected saved Wi-Fi profile.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Saved Wi-Fi profile name; replace ProfileName."
  },
  "DISM Analyze Component Store": {
    "code": "DISM /Online /Cleanup-Image /AnalyzeComponentStore",
    "useFor": "Analyze Windows component-store space use.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "DISM Component Store Cleanup": {
    "code": "DISM /Online /Cleanup-Image /StartComponentCleanup",
    "useFor": "Run Windows component-store cleanup.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Launch Disk Cleanup": {
    "code": "cleanmgr.exe",
    "useFor": "Open Disk Cleanup so you can choose what to remove.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Defragment Volume": {
    "code": "Optimize-Volume -DriveLetter C -Defrag -Verbose",
    "useFor": "Defragment the selected volume; the example uses C:.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Default target: C: drive. Change -DriveLetter before running if another volume is intended."
  },
  "Show Available WinGet Updates": {
    "code": "winget upgrade --accept-source-agreements",
    "useFor": "List available WinGet app updates and accept source agreements.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Accepts source agreements even though it does not install updates."
    ],
    "requires": "WinGet installed on the target Windows computer; access to its package sources. Some installers require administrator approval.",
    "input": "Uses the WinGet packages and sources configured on this Windows computer."
  },
  "Update All Eligible WinGet Packages": {
    "code": "winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity",
    "useFor": "Update all eligible WinGet packages silently and accept package/source agreements.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "WinGet installed on the target Windows computer; access to its package sources. Some installers require administrator approval.",
    "input": "Uses the WinGet packages and sources configured on this Windows computer."
  },
  "Show WinGet Package Information": {
    "code": "$PackageId = \"Package.Id\"\nwinget show --id $PackageId --exact",
    "useFor": "Show details for an exact WinGet package ID.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "WinGet installed on the target Windows computer; access to its package sources. Some installers require administrator approval.",
    "input": "Exact package ID from winget search. Replace \"Package.Id\" before running."
  },
  "Update Specific WinGet Package": {
    "code": "$PackageId = \"Package.Id\"\nwinget upgrade --id $PackageId --exact --accept-source-agreements --accept-package-agreements",
    "useFor": "Update one exact WinGet package and accept package/source agreements.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "WinGet installed on the target Windows computer; access to its package sources. Some installers require administrator approval.",
    "input": "Exact package ID from winget search. Replace \"Package.Id\" before running."
  },
  "Update WinGet Sources": {
    "code": "winget source update",
    "useFor": "Refresh WinGet package-source metadata.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "WinGet installed on the target Windows computer; access to its package sources. Some installers require administrator approval.",
    "input": "Uses the WinGet packages and sources configured on this Windows computer."
  },
  "Show PowerShell Version": {
    "code": "$PSVersionTable.PSVersion",
    "useFor": "Show the current PowerShell version.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer."
  },
  "Show Execution Policies": {
    "code": "Get-ExecutionPolicy -List",
    "useFor": "Show execution policy at every scope.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer."
  },
  "Set Current User Execution Policy - RemoteSigned": {
    "code": "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser",
    "useFor": "Set RemoteSigned execution policy for the current Windows user.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately.",
      "Does not override an organization-managed execution policy."
    ],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer."
  },
  "Show Installed Microsoft Graph Module Version": {
    "code": "Get-Module Microsoft.Graph.Authentication -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version,Path",
    "useFor": "Show the newest installed Microsoft Graph Authentication module version.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer."
  },
  "Show Installed ExchangeOnlineManagement Version": {
    "code": "Get-Module ExchangeOnlineManagement -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version,Path",
    "useFor": "Show the newest installed Exchange Online module version.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer."
  },
  "Show Graph Context": {
    "code": "Get-MgContext",
    "useFor": "Show the current Microsoft Graph connection and granted permissions.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Microsoft.Graph.Authentication module; uses the current PowerShell session.",
    "input": "Uses this PowerShell window’s Microsoft Graph connection; no user or group name to enter."
  },
  "Show Exchange Connection": {
    "code": "Get-ConnectionInformation",
    "useFor": "Show existing Exchange Online PowerShell connections.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter."
  },
  "Disconnect Microsoft Graph": {
    "code": "Disconnect-MgGraph",
    "useFor": "Disconnect Microsoft Graph in this PowerShell session.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Microsoft.Graph.Authentication module; uses the current PowerShell session.",
    "input": "Uses this PowerShell window’s Microsoft Graph connection; no user or group name to enter."
  },
  "Disconnect Exchange Online": {
    "code": "Disconnect-ExchangeOnline -Confirm:$false",
    "useFor": "Disconnect Exchange Online in this PowerShell session.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter."
  },
  "Show Activity From One IP": {
    "code": "$Ip = \"1.2.3.4\"\nGet-MgAuditLogSignIn -Filter \"ipAddress eq '$Ip'\" -Top 100 |\n  Select-Object CreatedDateTime,UserPrincipalName,AppDisplayName,IPAddress,ClientAppUsed,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed\"}}}",
    "useFor": "Show up to 100 sign-ins recorded from the selected IP address.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\",\"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Microsoft Graph PowerShell modules for the command, consent to the listed permissions, and an account allowed to access the target. Graph permissions: AuditLog.Read.All, User.Read.All. Tenant licensing and a role that can read these logs are also required.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Look Up ISP And Location": {
    "code": "$Ip = \"8.8.8.8\"\nInvoke-RestMethod \"https://ipinfo.io/$Ip/json\" |\n  Select-Object ip,city,region,country,org",
    "useFor": "Send an IP address to ipinfo.io for its reported ISP and location.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Sends the IP to an external service. Reported location is approximate."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "AD Group Memberships": {
    "code": "Get-ADPrincipalGroupMembership -Identity \"username\" | Select-Object Name",
    "useFor": "List the Active Directory groups reported for this user.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "AD Group Members": {
    "code": "Get-ADGroupMember -Identity \"GroupName\" | Select-Object Name,SamAccountName,ObjectClass",
    "useFor": "List direct members of the selected Active Directory group.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to read the selected objects.",
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name."
  },
  "Connect Exchange Online": {
    "code": "Connect-ExchangeOnline",
    "useFor": "Sign in to Exchange Online PowerShell.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "An authorized account for the intended tenant; select it during sign-in."
  },
  "Install Exchange Online Module": {
    "code": "Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber",
    "useFor": "Install ExchangeOnlineManagement for the current Windows user.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell. Internet access to PowerShell Gallery and permission to install modules for your user.",
    "input": "Installs ExchangeOnlineManagement from PowerShell Gallery for the current Windows user."
  },
  "Install Microsoft Graph Module": {
    "code": "Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force -AllowClobber",
    "useFor": "Install Microsoft Graph PowerShell for the current Windows user.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell. Internet access to PowerShell Gallery and permission to install modules for your user.",
    "input": "Installs Microsoft.Graph from PowerShell Gallery for the current Windows user."
  },
  "Show Hidden Inbox Rules": {
    "code": "Get-InboxRule -Mailbox \"user@domain.com\" -IncludeHidden",
    "useFor": "List inbox rules, including hidden rules, for the mailbox.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "Delete All Inbox Rules": {
    "code": "Get-InboxRule -Mailbox \"user@domain.com\" -IncludeHidden | Remove-InboxRule -Confirm:$true",
    "useFor": "Delete every inbox rule, including hidden rules, with PowerShell confirmation.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Review the target; PowerShell asks for confirmation before removal.",
      "Deletes rules, not email. Export or record rules first if you may need to restore them."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running."
  },
  "IP Configuration (ipconfig)": {
    "code": "ipconfig /all",
    "useFor": "Show detailed local IP configuration.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Flush DNS": {
    "code": "ipconfig /flushdns",
    "useFor": "Clear the local DNS resolver cache.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "DNS Lookup": {
    "code": "nslookup example.com",
    "useFor": "Look up a domain or host name with nslookup.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Continuous Ping": {
    "code": "ping -t example.com",
    "useFor": "Ping a host continuously; press Ctrl+C to stop.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Traceroute": {
    "code": "tracert example.com",
    "useFor": "Trace the network route to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Path Ping": {
    "code": "pathping example.com",
    "useFor": "Check the network route and packet loss to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running."
  },
  "Routing Table (route print)": {
    "code": "route print",
    "useFor": "Show the local IP routing table.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "ARP Cache": {
    "code": "arp -a",
    "useFor": "Show cached IPv4 address-to-hardware mappings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "TCP Connections (netstat)": {
    "code": "netstat -ano",
    "useFor": "Show network connections, listening ports, and process IDs.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Port 443 Connections": {
    "code": "netstat -ano | findstr :443",
    "useFor": "Show netstat lines containing :443; matches can be local or remote ports.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Local Account Details": {
    "code": "net user username",
    "useFor": "Show details for the selected local Windows account.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target account name. Review all target values before running."
  },
  "Windows Time Status": {
    "code": "w32tm /query /status",
    "useFor": "Show Windows time synchronization status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Windows Time Source": {
    "code": "w32tm /query /source",
    "useFor": "Show the configured Windows time source.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "WinHTTP Proxy": {
    "code": "netsh winhttp show proxy",
    "useFor": "Show the WinHTTP proxy setting.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Domain Trust Check": {
    "code": "Test-ComputerSecureChannel -Verbose",
    "useFor": "Check this computer’s secure channel to its Active Directory domain.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Printer Check": {
    "code": "Get-Printer | Select-Object Name,DriverName,PortName,PrinterStatus",
    "useFor": "List installed printers and their reported status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Open Storage Settings": {
    "code": "start ms-settings:storagesense",
    "useFor": "Open Windows storage settings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Clear Delivery Optimization Cache": {
    "code": "Delete-DeliveryOptimizationCache -Force",
    "useFor": "Delete cached Delivery Optimization downloads.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Identity and Privileges": {
    "code": "whoami /all",
    "useFor": "Show the current Windows identity, groups, and privileges.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Entra Join Status": {
    "code": "dsregcmd /status",
    "useFor": "Show this device’s domain and Entra join status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Mapped Drives": {
    "code": "net use",
    "useFor": "List network drive connections for the current user.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Network Profile": {
    "code": "Get-NetConnectionProfile",
    "useFor": "Show Windows network connection profiles.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Defender Status": {
    "code": "Get-MpComputerStatus | Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,QuickScanEndTime,FullScanEndTime",
    "useFor": "Show Microsoft Defender protection and scan status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Print Jobs": {
    "code": "Get-Printer | ForEach-Object { Get-PrintJob -PrinterName $_.Name -ErrorAction SilentlyContinue }",
    "useFor": "List print jobs from installed printers; inaccessible queues are skipped.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Some read errors are suppressed. No output does not prove that nothing exists."
    ],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Spooler Status": {
    "code": "Get-Service Spooler",
    "useFor": "Show the Print Spooler service status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter."
  },
  "Connect Microsoft Graph": {
    "code": "Connect-MgGraph -Scopes \"User.Read\" -ContextScope Process",
    "useFor": "Sign in to Microsoft Graph with permissions chosen for your task.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Microsoft.Graph.Authentication module and consent to the permissions selected for your task.",
    "input": "Delegated scopes required by your task. User.Read below is a basic signed-in-user example; use each task card's scopes for other operations."
  },
  "Show Code-Signing Certificates": {
    "code": "Get-ChildItem Cert:\\CurrentUser\\My -CodeSigningCert | Select-Object Subject,Thumbprint,NotAfter",
    "useFor": "List code-signing certificates installed for the current Windows user.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer."
  }
});
