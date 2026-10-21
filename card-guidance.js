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
    "sourceSha256": "7baf885bdbe28cdbc46d90929aee6ace804a31466ac65fd7a03000ad631e3d76",
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
    "sourceSha256": "5757f3d963128d81f078295d3e38ed0db237bac34a867821cfbadd134afda330",
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
    "sourceSha256": "d163c3acd3603d42f0b637337d6fc61f98e464dc14c84f81677b7c3ecc38c9b8",
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
    "sourceSha256": "b65296af7b9d7681acd091ba30d70127a67989bfc4844af4977396a164b6316d",
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
    "sourceSha256": "47731f7015c3a846cbd100667adaacbb34b4f7b79b6cefec7bf7674527c173ce",
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
    "sourceSha256": "98af58ff264c5f41bd9de530fd4dc62c13bd967466c778a43fe90cc1b8091142",
    "objective": "Shows who belongs to one or more Exchange Online distribution groups.",
    "input": "Distribution group names or email addresses, entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and permission to read the target client tenant. Technical requirements: ExchangeOnlineManagement",
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
    "sourceSha256": "6c7b4c60cd9368a3bd5bb652eade3a4ed642f83b5f8c3759548f2d64d8eea7e7",
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
    "sourceSha256": "80679840ee2878dcb54a795395ed169065c82d21d1c54f16f16fffeee614c51d",
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
    "sourceSha256": "0775c2c7d1db0a3ad095a93667a0dac8189ed7b4f22a582d7c03e9fa59ae5aac",
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
    "sourceSha256": "42d6400dc9381a7be3e14573bd5ca60199b099224853cf49e7bb410dc42fb829",
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
    "sourceSha256": "ac7647ebb8f82cc31637c5a03c22847ce6082ec94a63df995f0e6243156f0e1a",
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
    "sourceSha256": "bc20f462ee16d7df2fd70f7984c2503acfa823c2bb5a6d482305e00ef0f3eeaa",
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
    "sourceSha256": "609adcefda10bc1f02fc040141a11cabc494dd8b78c795b36b1d050b939e5edd",
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
    "sourceSha256": "c7cafb2a070acf00512356ec7adf9567ccb21523fd6f9bf6966e5f97fc7519fe",
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
    "sourceSha256": "9c0121dff77342f37c68d80f73304fe1c472c11f5251f8912d67519c1f892ec2",
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
    "sourceSha256": "f5272d98b5bc1532832215237c10822c22ca7e21833be0175623ce4e9a49de2c",
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
    "sourceSha256": "d7f15be210646268958f8e0bd78c1c1a72c4bf92fe24883d10a9f27bc57a4646",
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
    "sourceSha256": "cccfbe64f94ede1520f9a67dfd3a62f8e5e9aa8b82a79687adb0cf7b19a893c3",
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
    "sourceSha256": "4cdd1a7ef3130cb0db8d79257ea95fd39ad7ed090c46cb023b256738ff8819d5",
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
    "sourceSha256": "1e1707ca192fb4695f4b0cf80c31da1b38481b454e398d5ca4bceacdd903aa1d",
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
    "sourceSha256": "4a75fa6452ec104be4beeedcb89d43262b4edba1e97f49ffa332f81e139f53c7",
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
    "sourceSha256": "23d724f8a7af9c0effb335631381db8c5f6728939a047586b278168fe9bf2039",
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
    "sourceSha256": "7bb0c0de4206333cdf515673dc2014c491191659a061857fe3ea714a69b16d02",
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
    "sourceSha256": "de1a1370e57e2248196830cba2c5d5e4b7103d9da61e1e560fbbac230e60025c",
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
    "sourceSha256": "d681d0a569702c878e6e1eea8af913601b54b076aecfd1e2b77956ea15ccd19c",
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
    "sourceSha256": "e7cdcd69eace3e60055d20b4fadf550b0920052accb36e2cd2bb478b68f024d0",
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
    "sourceSha256": "abe2a9fdfdaf6e7f3e6c8a65213c069c4d298264bd56c8dc427c48f8d28a0b89",
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
    "sourceSha256": "e5505021367ca5ae1730c1de17e8a9a285a0fc12e28bbf0481362498e3b92758",
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
    "sourceSha256": "3ab4f2a30234e2d7203284a30d304b22c9bc7c1c33ffae53b3e2710b2ea33218",
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
    "sourceSha256": "bdcc51ac5be6599d8a00f53350811a8a737b9fce65f824ccb9efdceb5ea9918e",
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
    "sourceSha256": "47416bc77a4929fc831d3381de9f2ff53996d7921eee9c029e015eaf3100d4b0",
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
    "sourceSha256": "ca493f98fe2b1648a7df775901bbce1eb43aec61d63b226c242b5560b7ac8ada",
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
    "sourceSha256": "82e09267477c193402c915065d659989568816d22169cc29562fab854a45814b",
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
    "sourceSha256": "2a4d6cf0b770833b64ddb23034ca1ca6f9e8c76678fd059a0bc654f263166234",
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
    "sourceSha256": "222ef1c7705b65c13a31fe2eb5c5ded11e34ecc156fdcf8c38a061eb805eb250",
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
    "sourceSha256": "5280fbfc9f059ebbe072d3a4f6b03e323b2f031daeb362dd0eab6f37953debf8",
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
    "sourceSha256": "1c0b4e564cf6f8fa821fbe76e632c7bf9d2e1e8269f107f54d646b8680bc8164",
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
    "sourceSha256": "330fb1fc8cc144b3f9cd23a0e3399a2f69d168b31b6a9fe27c255e0c77ffdf2b",
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
    "sourceSha256": "3b15375fe2f05b1543e5f90e081cd6d8c28360cf1eaa3423b60ef5498e7f0af8",
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
    "sourceSha256": "82ddf2ed63914b6a1eb40664f486783e59690799b8df19bf9f00fbd3dc142756",
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
    "sourceSha256": "3d0dbac577cce716e5427a9b2635ee6cefe29a45955bc632cb8b4f2dd48fe343",
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
    "sourceSha256": "16153f1c1989834f659ec7c08546c454dd95bdc51abebb2f7afb684b70964fdf",
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
    "sourceSha256": "1c732aa6c82182265dc02019c9805a7ac9faec56e7b3312e8d7b00c7d66dd60d",
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
    "sourceSha256": "21b5e4be1b126e6a91fad89a4d15221a9d12e098dceee501823f535490216b35",
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
    "sourceSha256": "af846df0d2aa709adfcbb9cfa0329d1b7552718d248edae9e42d1a63bbf79754",
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
    "sourceSha256": "05ad7fed05ef0422196bd61d31e723360bdf1af19b2fba4b05132fa71b62e720",
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
    "sourceSha256": "2cfff044c55146afc4d6d69605504071410ded8f1707189baec249079df12c47",
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
    "sourceSha256": "65499c4b3bb05cca720af589ca8f9c85c3ad5e5c1edeff0d2115c53935c45222",
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
    "sourceSha256": "8d2da056b964bc7d1a14feec61d902cdf909be08f108a297efdcafcc55e3baac",
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
    "sourceSha256": "4c473ca51503dac84b65a460879c38b46622813a1eb2f33aeb117abe15fc80b3",
    "objective": "Find a user's direct group memberships in AD and Entra ID.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Access to read users and groups in the connected tenant. For AD results, run on a domain-connected computer with RSAT. Technical requirements: Microsoft.Graph.Authentication + User.Read.All + Group.Read.All + ActiveDirectory module / domain reachability for AD coverage",
    "notes": "User-to-groups review that independently checks Active Directory and Entra ID. Synced groups remain visible in Entra as [Synced] even when the same group is also observed in AD.",
    "startMode": "right-click",
    "completion": {
      "result": "Direct memberships shown separately for AD and Entra, with missing users and unavailable or failed checks clearly identified.",
      "next": "Follow up on systems that could not be checked. A synced group appearing in both systems is expected.",
      "blocked": "Review any partial or unsuccessful outcome. A missing user is different from a user with no groups."
    }
  },
  "GET-TENANT-GROUP-OWNERS.ps1": {
    "sourceSha256": "61d7d424bf8a4277659b56c59157790b12189385855e1387c2720bf11dd76136",
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
    "sourceSha256": "47f0c28a851d611edafcf3e32f3053b09c48276243507c10d7929ee49feeeb78",
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
    "sourceSha256": "d965c3eee6703d8860961fe4aae0c5afcc3ec0ec0941cbde7d5ba987f607f14f",
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
    "sourceSha256": "047a46e0ecb0161f052c9a2db4753d48b11a15d9df9e09a4895129d818652b62",
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
    "sourceSha256": "b2c9088c8fd4b5757d17c24c8f53a65589fbb2dbfc79df771aad16e60ddbb79f",
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
    "sourceSha256": "d04e3adc34ea8392a2e66fc8f5b79a47773ae607f4f38cb2a15de6182851e097",
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
    "sourceSha256": "c5a171de8d48e5c23d9489e5179c2fd61db009f4f464a4ea59236cfd0239c2a9",
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
    "sourceSha256": "e1654925ffe80c15c498ae3b50553231dafc5997f3233d073fa46b6366bff224",
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
    "sourceSha256": "ddf10651da76431b41222e3dbb9ced0f87c787852e620b849677ea1651944690",
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
    "sourceSha256": "ccc759664b198a2c535c2cdbfbbeb3c6123aedd6d13a63664d050c330710e5b0",
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
    "sourceSha256": "147336249dc84badc6e3730c6d2347869c9f9fe6e23b0916fa4474211e5a9316",
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
    "sourceSha256": "547c6c06988c6d2a4b3c5e7953379b89b5706db4d198b3b41cd9ec02f943917c",
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
    "sourceSha256": "43eb5cb87621630ed3f0dee9dd03b083fc833f5e965ec87e73433fca3d96f9e5",
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
    "sourceSha256": "331f661fb28bef543096f26ca763db3ad2758353e8312bd56f3a410698281e3b",
    "objective": "Shows who can access or book one or more room and equipment mailboxes.",
    "input": "A real room or equipment mailbox address in the client tenant; separate multiple addresses with commas. A security group is not a mailbox.",
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
    "sourceSha256": "0bdb156a9bf30fdfaae95c41fc7a81aa656b5d98e036af0625bc718e25e0854f",
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
    "sourceSha256": "8e6724f1831c5733335665c46b2efc04a7eaed40aaeb134f8f11276e5b48ddf6",
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
    "sourceSha256": "8cacff71acc3a4a9f359f4fe419ec7170829857a59b26d39a8bd6124b91e0403",
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
    "sourceSha256": "dd8eddd73faba6dac8d4c9953436c54cbd13bb288848844e22534653d1262cef",
    "notes": "Top-level project decision contract for canonical sources, 1-to-N input, safety, authentication, QA, release, and handoff/rebuild decisions.",
    "objective": "Read the project rules for building, reviewing, and releasing tools."
  },
  "field-kit-build-standard.md": {
    "sourceSha256": "57764518fe2aaa5798d824a775e271fcf6e744500026febdaa41f9231efa0d1c",
    "notes": "Locked baseline for FIELD // KIT visual design, navigation, sorting, card behavior, source publication, and release validation.",
    "objective": "Read the agreed site layout, card, and publishing standards."
  },
  "lessons-learned.md": {
    "sourceSha256": "f6bc6f62b00d32ef007589d931d6ee05e63944738a5df3d57a01344193c7e00f",
    "notes": "Small reusable rules captured from recurring PowerShell, authentication, hybrid, output, and publishing failures.",
    "objective": "Check lessons from earlier scripting and publishing problems."
  },
  "powershell-standards.md": {
    "sourceSha256": "4b19a55bdf61eb195b10abfe178363de97140fb1a156019b28d4aafaa03891e6",
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
    "sourceSha256": "886a5782009fc8abf4825f997ccab38c0c1679a32b6653596089e038cf3ba22c",
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
    "sourceSha256": "dbe0182fa8563b8bd01262cdd53da2b84134c13adb6c76d2871d47b3fa6ac7b9",
    "notes": "Canonical project handoff template for source of truth, local/remote state, locked decisions, validation status, limitations, and next-session startup.",
    "objective": "Find the current project state, decisions, limits, and next steps."
  },
  "git-repo.ps1": {
    "sourceSha256": "cd0c87313d27c17cd79a82f470991aad016583781066f856841cc251f245afdd",
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
    "sourceSha256": "90464f2b844266bdf88c5956fc44dd34939cf7c8664ac19c90f4be4defec2bc4",
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
    "sourceSha256": "62820d67085b65d230bb28c4954259bd32bffd29f30aee8a6f9a2cdfcdfdc5aa",
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
    "sourceSha256": "67ff5ccad0eb69510576920fd8b36accfb606a2b1cd3ddeb1ae75f021fda9bc9",
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
    "sourceSha256": "75f06611710a84f21522226fffebb3bf2e6a6b5d58383baf507ba6c69ddf19ca",
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
    "sourceSha256": "997cabfc93947e35b80e99d11053ce3f704b0e0a44fb30524606ed49b0f87b86",
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
    "sourceSha256": "ad5af3b5f30146d26ae6a94c11da242d49960fe622f7bac6c8123fbfbc1795e3",
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
    "sourceSha256": "2728fc9d57cc00b334db1f60c9fd3e6fdf84f5a090ea3a2434a94ee206fe9407",
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

// Approved compact operator cards. Generated from operator-card-specs.json.
window.FIELD_KIT_OPERATOR_CARDS = Object.freeze({
  "GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "name": "Review Account Cleanup",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "A review list, not approval to delete accounts or remove access.",
      "Missing checks remain unresolved."
    ],
    "family": "accounts",
    "sourceSha256": "47731f7015c3a846cbd100667adaacbb34b4f7b79b6cefec7bf7674527c173ce",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-STALE-SIGNIN-REVIEW.ps1": {
    "name": "Review Stale Sign-ins",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "Uses recorded Entra activity, not proof that an account is unused.",
      "Missing sign-in history stays unknown."
    ],
    "family": "accounts",
    "sourceSha256": "21b5e4be1b126e6a91fad89a4d15221a9d12e098dceee501823f535490216b35",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-DISABLE-ACCOUNTS.ps1": {
    "name": "Disable User Accounts",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Synced accounts are disabled in AD; cloud accounts in Entra.",
      "Review the targets before confirming."
    ],
    "family": "accounts",
    "sourceSha256": "af846df0d2aa709adfcbb9cfa0329d1b7552718d248edae9e42d1a63bbf79754",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-DELETE-ACCOUNTS.ps1": {
    "name": "Delete User Accounts",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Review dependencies and retention before deleting an account.",
      "Deletion requires explicit confirmation."
    ],
    "family": "accounts",
    "sourceSha256": "05ad7fed05ef0422196bd61d31e723360bdf1af19b2fba4b05132fa71b62e720",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-ASSIGN-LICENSES.ps1": {
    "name": "Assign User Licenses",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT + tenant ID",
    "details": [
      "Choose a license and review the affected users before confirming.",
      "Review failed assignments separately."
    ],
    "family": "licenses",
    "sourceSha256": "5757f3d963128d81f078295d3e38ed0db237bac34a867821cfbadd134afda330",
    "presentationRevision": true,
    "releaseVersion": "1.0.3"
  },
  "INVOKE-REMOVE-LICENSES.ps1": {
    "name": "Remove User Licenses",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT + tenant ID",
    "details": [
      "License removal can affect services and retained data.",
      "Review the selected licenses and users before confirming."
    ],
    "family": "licenses",
    "sourceSha256": "b65296af7b9d7681acd091ba30d70127a67989bfc4844af4977396a164b6316d",
    "presentationRevision": true,
    "releaseVersion": "1.0.3"
  },
  "RESOLVE-NAMES-TO-UPNS.ps1": {
    "name": "Find User UPNs",
    "scope": "SINGLE or MULTI-USER",
    "input": "Name / email / CSV / TXT",
    "details": [
      "Review ambiguous or missing matches before using the list in another tool."
    ],
    "family": "accounts",
    "sourceSha256": "2cfff044c55146afc4d6d69605504071410ded8f1707189baec249079df12c47",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-ACCOUNT-STATUS.ps1": {
    "name": "Get User Account Status",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Missing sign-in history does not mean an account is inactive."
    ],
    "family": "accounts",
    "sourceSha256": "65499c4b3bb05cca720af589ca8f9c85c3ad5e5c1edeff0d2115c53935c45222",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "name": "Get Distribution Group Members",
    "scope": "SINGLE or MULTI-GROUP",
    "input": "Group / CSV / TXT",
    "details": [
      "For distribution groups in Exchange Online.",
      "Nested groups are not a complete access review."
    ],
    "family": "groups",
    "sourceSha256": "98af58ff264c5f41bd9de530fd4dc62c13bd967466c778a43fe90cc1b8091142",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-GROUP-MEMBERS.ps1": {
    "name": "Get Group Members",
    "scope": "SINGLE or MULTI-GROUP",
    "input": "Group / CSV / TXT",
    "details": [
      "Checks the group in Exchange, Entra or AD.",
      "Shows direct members, not a complete access review."
    ],
    "family": "groups",
    "sourceSha256": "8d2da056b964bc7d1a14feec61d902cdf909be08f108a297efdcafcc55e3baac",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-USER-GROUPS.ps1": {
    "name": "Get User Groups",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "For AD results, use a computer connected to the user's domain.",
      "Lists direct groups, not every source of access."
    ],
    "family": "groups",
    "sourceSha256": "4c473ca51503dac84b65a460879c38b46622813a1eb2f33aeb117abe15fc80b3",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-REMOVE-USER-GROUPS.ps1": {
    "name": "Remove User Groups",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Removes memberships, not the groups themselves.",
      "Some managed or protected memberships must be handled separately."
    ],
    "family": "groups",
    "sourceSha256": "6c7b4c60cd9368a3bd5bb652eade3a4ed642f83b5f8c3759548f2d64d8eea7e7",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "name": "Create Dynamic License Group",
    "scope": "SINGLE-GROUP",
    "input": "Tenant and group settings + tenant ID",
    "details": [
      "Creates a group whose membership follows a rule.",
      "Review the rule before creating the group."
    ],
    "family": "licenses",
    "sourceSha256": "d163c3acd3603d42f0b637337d6fc61f98e464dc14c84f81677b7c3ecc38c9b8",
    "presentationRevision": true,
    "releaseVersion": "1.0.2"
  },
  "GET-TENANT-GROUP-OWNERS.ps1": {
    "name": "Get Group Owners",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "Missing owners and failed checks are different findings."
    ],
    "family": "groups",
    "sourceSha256": "61d7d424bf8a4277659b56c59157790b12189385855e1387c2720bf11dd76136",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-MAILBOX-PERMISSIONS.ps1": {
    "name": "Get Mailbox Permissions",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Reviews forwarding, delegates and inbox rules.",
      "Investigate unexpected access before removing it."
    ],
    "family": "mail",
    "sourceSha256": "47f0c28a851d611edafcf3e32f3053b09c48276243507c10d7929ee49feeeb78",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "name": "Get Mailbox Security",
    "scope": "SINGLE-USER",
    "input": "UPN",
    "details": [
      "Use for a focused review of one mailbox.",
      "Unresolved checks are not evidence that the mailbox is clear."
    ],
    "family": "mail",
    "sourceSha256": "0775c2c7d1db0a3ad095a93667a0dac8189ed7b4f22a582d7c03e9fa59ae5aac",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-MAILBOX-FORWARDING.ps1": {
    "name": "Get Mailbox Forwarding",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Unexpected forwarding needs investigation before changes."
    ],
    "family": "mail",
    "sourceSha256": "d965c3eee6703d8860961fe4aae0c5afcc3ec0ec0941cbde7d5ba987f607f14f",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-LITIGATION-HOLD.ps1": {
    "name": "Set Litigation Hold",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Confirm the retention decision and required licensing first.",
      "Applies an unlimited hold after review."
    ],
    "family": "mail",
    "sourceSha256": "047a46e0ecb0161f052c9a2db4753d48b11a15d9df9e09a4895129d818652b62",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "IR-INVOKE-EMAIL-RECOVERY.ps1": {
    "name": "Restore Email",
    "scope": "SINGLE-USER",
    "input": "Mailbox and recovery source",
    "details": [
      "Review the mailbox and recovery source before restoring messages.",
      "Use a recovery source produced by the supported search workflow."
    ],
    "family": "ir-mail",
    "sourceSha256": "42d6400dc9381a7be3e14573bd5ca60199b099224853cf49e7bb410dc42fb829",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "ir-risk-assessment.ps1": {
    "name": "IR: Assess User Risk",
    "scope": "SINGLE-USER",
    "input": "UPN and tenant",
    "details": [
      "Use the approved jumpbox and keep the workflow in one PowerShell window.",
      "Review findings and unavailable checks before deciding on containment."
    ],
    "family": "ir-workflow",
    "sourceSha256": "07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "ir-contain-eradicate.ps1": {
    "name": "IR: Contain and Clean Up",
    "scope": "SINGLE-USER",
    "input": "UPN and tenant",
    "details": [
      "Use the same PowerShell window as assessment.",
      "Maintain containment until cleanup and recovery are approved.",
      "Temporary passwords can remain in terminal capture/transcripts. The operator confirms trusted MFA methods."
    ],
    "family": "ir-workflow",
    "sourceSha256": "e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "IR-GET-DATA-EXFIL-ACTIVITY.ps1": {
    "name": "IR: Review File Activity",
    "scope": "SINGLE-USER",
    "input": "UPN and time range",
    "details": [
      "Activity can suggest exposure; it does not prove data theft.",
      "Log availability limits the review."
    ],
    "family": "ir-investigate",
    "sourceSha256": "ac7647ebb8f82cc31637c5a03c22847ce6082ec94a63df995f0e6243156f0e1a",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "IR-GET-IP-TRACE.ps1": {
    "name": "IR: Trace IP Activity",
    "scope": "TENANT",
    "input": "IP address and time range",
    "details": [
      "An IP match needs context before attributing activity to a person."
    ],
    "family": "ir-investigate",
    "sourceSha256": "bc20f462ee16d7df2fd70f7984c2503acfa823c2bb5a6d482305e00ef0f3eeaa",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "IR-GET-TENANT-EMAIL-SEARCH.ps1": {
    "name": "IR: Search Tenant Email",
    "scope": "TENANT",
    "input": "Search terms and time range",
    "details": [
      "Review the search scope before collecting results.",
      "Search results do not remove or restore messages."
    ],
    "family": "ir-mail",
    "sourceSha256": "609adcefda10bc1f02fc040141a11cabc494dd8b78c795b36b1d050b939e5edd",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "IR-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "name": "IR: Check IP Reputation",
    "scope": "SINGLE-IP",
    "input": "IP address",
    "details": [
      "Sends the selected public IP to external reputation services.",
      "Reputation is context, not a verdict on compromise."
    ],
    "family": "ir-investigate",
    "sourceSha256": "c7cafb2a070acf00512356ec7adf9567ccb21523fd6f9bf6966e5f97fc7519fe",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "IR-GET-TIMELINE-BUILDER.ps1": {
    "name": "IR: Build Incident Timeline",
    "scope": "LOCAL",
    "input": "Evidence files",
    "details": [
      "Combines supplied evidence; it does not collect missing events.",
      "Check time zones and gaps before drawing conclusions."
    ],
    "family": "ir-investigate",
    "sourceSha256": "9c0121dff77342f37c68d80f73304fe1c472c11f5251f8912d67519c1f892ec2",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "IR-GET-TOKEN-DECODE.ps1": {
    "name": "IR: Decode Token",
    "scope": "LOCAL",
    "input": "Token",
    "details": [
      "Decodes locally without sending the token to a service.",
      "A decoded token is not proof of authenticity or current access."
    ],
    "family": "ir-investigate",
    "sourceSha256": "f5272d98b5bc1532832215237c10822c22ca7e21833be0175623ce4e9a49de2c",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "IR-GET-TOKEN-REPLAY-CHECK.ps1": {
    "name": "IR: Review Token Replay",
    "scope": "SINGLE-USER",
    "input": "UPN and time range",
    "details": [
      "Looks for indicators that need investigation, not a definitive compromise verdict.",
      "Missing logs limit the result."
    ],
    "family": "ir-investigate",
    "sourceSha256": "d7f15be210646268958f8e0bd78c1c1a72c4bf92fe24883d10a9f27bc57a4646",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "name": "Audit Shared Mailbox Sign-ins",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review unexpected direct sign-ins separately from delegated mailbox use."
    ],
    "family": "mail-audit",
    "sourceSha256": "4cdd1a7ef3130cb0db8d79257ea95fd39ad7ed090c46cb023b256738ff8819d5",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-APP-REGISTRATION-AUDIT.ps1": {
    "name": "Audit App Registrations",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review unfamiliar apps and expiring credentials with their owners."
    ],
    "family": "apps",
    "sourceSha256": "1e1707ca192fb4695f4b0cf80c31da1b38481b454e398d5ca4bceacdd903aa1d",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "name": "Review Conditional Access",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Use the tenant ID requested by the script, not just a domain name.",
      "Findings identify review areas; they do not prove policy coverage."
    ],
    "family": "security",
    "sourceSha256": "7baf885bdbe28cdbc46d90929aee6ace804a31466ac65fd7a03000ad631e3d76",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-DEVICE-CODE-EXPOSURE.ps1": {
    "name": "Review Device Code Exposure",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Reviews policy exposure rather than proving an attack occurred."
    ],
    "family": "security",
    "sourceSha256": "4a75fa6452ec104be4beeedcb89d43262b4edba1e97f49ffa332f81e139f53c7",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "name": "Audit Guest App Consent",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review permissions with an owner before removing consent."
    ],
    "family": "apps",
    "sourceSha256": "cccfbe64f94ede1520f9a67dfd3a62f8e5e9aa8b82a79687adb0cf7b19a893c3",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-MFA-SECURITY-AUDIT.ps1": {
    "name": "Audit MFA Security",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review registration and policy findings together.",
      "Missing evidence is not a clean MFA result."
    ],
    "family": "security",
    "sourceSha256": "23d724f8a7af9c0effb335631381db8c5f6728939a047586b278168fe9bf2039",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "name": "Get Secure Score",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "A score is a prioritization aid, not proof that the tenant is secure."
    ],
    "family": "security",
    "sourceSha256": "7bb0c0de4206333cdf515673dc2014c491191659a061857fe3ea714a69b16d02",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "name": "Get App Owners",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Ownerless apps need an accountable owner before changes."
    ],
    "family": "apps",
    "sourceSha256": "de1a1370e57e2248196830cba2c5d5e4b7103d9da61e1e560fbbac230e60025c",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-SIGNIN-ANOMALIES.ps1": {
    "name": "Review Sign-in Anomalies",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review unusual activity in context before containment."
    ],
    "family": "security",
    "sourceSha256": "d681d0a569702c878e6e1eea8af913601b54b076aecfd1e2b77956ea15ccd19c",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-TRANSPORT-RULES-AUDIT.ps1": {
    "name": "Audit Mail Flow Rules",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "Review rule intent and business impact before making changes."
    ],
    "family": "mail-audit",
    "sourceSha256": "b2c9088c8fd4b5757d17c24c8f53a65589fbb2dbfc79df771aad16e60ddbb79f",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "name": "Join Computer to Domain",
    "scope": "LOCAL",
    "input": "Computer and domain",
    "details": [
      "Run as administrator; the computer must reach the domain.",
      "Plan for restart and sign-in changes."
    ],
    "family": "endpoint",
    "sourceSha256": "e7cdcd69eace3e60055d20b4fadf550b0920052accb36e2cd2bb478b68f024d0",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "DEPLOY-TCPIP-PRINTER.ps1": {
    "name": "Install Network Printer",
    "scope": "LOCAL",
    "input": "Printer address and driver",
    "details": [
      "Have the approved driver and printer address ready."
    ],
    "family": "endpoint",
    "sourceSha256": "abe2a9fdfdaf6e7f3e6c8a65213c069c4d298264bd56c8dc427c48f8d28a0b89",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "BACKUP-USER-PROFILE.ps1": {
    "name": "Back Up User Profile",
    "scope": "LOCAL",
    "input": "Profile and backup location",
    "details": [
      "Check the destination and available space before starting.",
      "Review skipped and failed copies before relying on the backup."
    ],
    "family": "endpoint",
    "sourceSha256": "e5505021367ca5ae1730c1de17e8a9a285a0fc12e28bbf0481362498e3b92758",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "TEST-POWERSHELL-READINESS.ps1": {
    "name": "Check PowerShell Readiness",
    "scope": "LOCAL",
    "input": "Current computer",
    "details": [
      "Reviews prerequisites without installing them."
    ],
    "family": "setup",
    "sourceSha256": "d04e3adc34ea8392a2e66fc8f5b79a47773ae607f4f38cb2a15de6182851e097",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-FOLDER-INVENTORY.ps1": {
    "name": "Get Folder Inventory",
    "scope": "LOCAL",
    "input": "Folder",
    "details": [
      "Reports the selected folder; does not enforce a structure."
    ],
    "family": "files",
    "sourceSha256": "c5a171de8d48e5c23d9489e5179c2fd61db009f4f464a4ea59236cfd0239c2a9",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INSTALL-M365-MODULES.ps1": {
    "name": "Install M365 Modules",
    "scope": "LOCAL",
    "input": "Module selection",
    "details": [
      "Installs or updates modules for the current Windows user.",
      "No tenant configuration is changed."
    ],
    "family": "setup",
    "sourceSha256": "e1654925ffe80c15c498ae3b50553231dafc5997f3233d073fa46b6366bff224",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "TEST-SENSITIVE-DATA.ps1": {
    "name": "Check Sensitive Data",
    "scope": "LOCAL",
    "input": "Files or folder",
    "details": [
      "Findings need review; a clean scan is not proof that all sensitive information is absent."
    ],
    "family": "files",
    "sourceSha256": "ddf10651da76431b41222e3dbb9ced0f87c787852e620b849677ea1651944690",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "RESET-M365-SESSION.ps1": {
    "name": "Reset M365 Session",
    "scope": "LOCAL",
    "input": "Current PowerShell window",
    "details": [
      "Run in the session you want to disconnect.",
      "Tenant configuration is not changed."
    ],
    "family": "setup",
    "sourceSha256": "ccc759664b198a2c535c2cdbfbbeb3c6123aedd6d13a63664d050c330710e5b0",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "UPDATE-WINDOWS-APPS.ps1": {
    "name": "Update Windows Apps",
    "scope": "LOCAL",
    "input": "Current computer",
    "details": [
      "Review available updates and allow for app restarts."
    ],
    "family": "endpoint",
    "sourceSha256": "147336249dc84badc6e3730c6d2347869c9f9fe6e23b0916fa4474211e5a9316",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-USER-PREDELETE-CHECK.ps1": {
    "name": "Check User Before Deletion",
    "scope": "SINGLE-USER",
    "input": "UPN",
    "details": [
      "Collects dependencies to review before deletion.",
      "Does not authorize or perform deletion."
    ],
    "family": "accounts",
    "sourceSha256": "3ab4f2a30234e2d7203284a30d304b22c9bc7c1c33ffae53b3e2710b2ea33218",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "name": "Set Per-user MFA",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Per-user MFA is separate from Conditional Access.",
      "Review the tenant's MFA approach before changing it."
    ],
    "family": "security",
    "sourceSha256": "80679840ee2878dcb54a795395ed169065c82d21d1c54f16f16fffeee614c51d",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-ADMIN-ROLE-AUDIT.ps1": {
    "name": "Audit Admin Roles",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review privileged assignments and their business owners."
    ],
    "family": "security",
    "sourceSha256": "bdcc51ac5be6599d8a00f53350811a8a737b9fce65f824ccb9efdceb5ea9918e",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-OAUTH-CONSENT-AUDIT.ps1": {
    "name": "Audit App Consent",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review granted access and app ownership before removing consent."
    ],
    "family": "apps",
    "sourceSha256": "47416bc77a4929fc831d3381de9f2ff53996d7921eee9c029e015eaf3100d4b0",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-GUEST-USER-AUDIT.ps1": {
    "name": "Review Guest Users",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Confirm the business relationship before removing a guest.",
      "Missing activity is not proof that access is unused."
    ],
    "family": "accounts",
    "sourceSha256": "ca493f98fe2b1648a7df775901bbce1eb43aec61d63b226c242b5560b7ac8ada",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-TENANT-LICENSING-AUDIT.ps1": {
    "name": "Audit Tenant Licenses",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Reviews assignments and capacity; does not change licenses."
    ],
    "family": "licenses",
    "sourceSha256": "82e09267477c193402c915065d659989568816d22169cc29562fab854a45814b",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "name": "Audit Tenant Inbox Rules",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "Investigate suspicious rules before removing them."
    ],
    "family": "mail-audit",
    "sourceSha256": "2a4d6cf0b770833b64ddb23034ca1ca6f9e8c76678fd059a0bc654f263166234",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-USER-SECURITY-SNAPSHOT.ps1": {
    "name": "Get User Security",
    "scope": "SINGLE-USER",
    "input": "UPN",
    "details": [
      "A starting point for investigation, not an all-clear verdict."
    ],
    "family": "security",
    "sourceSha256": "547c6c06988c6d2a4b3c5e7953379b89b5706db4d198b3b41cd9ec02f943917c",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "name": "Get Tenant Security",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "A broad starting point; use focused audits for follow-up."
    ],
    "family": "security",
    "sourceSha256": "43eb5cb87621630ed3f0dee9dd03b083fc833f5e965ec87e73433fca3d96f9e5",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-ROOM-RESOURCE-ACCESS.ps1": {
    "name": "Get Resource Mailbox Access",
    "scope": "SINGLE or MULTI-MAILBOX",
    "input": "Resource mailbox / CSV / TXT",
    "details": [
      "Use an actual room or equipment mailbox, not a security group."
    ],
    "family": "mail",
    "sourceSha256": "331f661fb28bef543096f26ca763db3ad2758353e8312bd56f3a410698281e3b",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "name": "Audit Tenant Mailbox Access",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "Review unexpected forwarding or delegated access before changes."
    ],
    "family": "mail-audit",
    "sourceSha256": "0bdb156a9bf30fdfaae95c41fc7a81aa656b5d98e036af0625bc718e25e0854f",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "name": "Remove Disabled User Mailbox Access",
    "scope": "TENANT",
    "input": "Tenant",
    "details": [
      "Review the removal plan before confirming.",
      "Disabled accounts can still have access that needs separate review."
    ],
    "family": "mail",
    "sourceSha256": "8e6724f1831c5733335665c46b2efc04a7eaed40aaeb134f8f11276e5b48ddf6",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-TENANT-DRIFT-REVIEW.ps1": {
    "name": "Review Tenant Changes",
    "scope": "TENANT",
    "input": "Tenant and saved baseline",
    "details": [
      "Compare with the approved baseline before accepting a new one.",
      "A changed setting is not automatically an incident."
    ],
    "family": "security",
    "sourceSha256": "8cacff71acc3a4a9f359f4fe419ec7170829857a59b26d39a8bd6124b91e0403",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "name": "Review Windows Storage",
    "scope": "LOCAL",
    "input": "Current computer",
    "details": [
      "Review only; no files are deleted."
    ],
    "family": "endpoint",
    "sourceSha256": "222ef1c7705b65c13a31fe2eb5c5ded11e34ecc156fdcf8c38a061eb805eb250",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "name": "Reset Cloud User Password",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Cloud-only accounts; synced accounts require their own identity process.",
      "Handle temporary passwords securely; terminal recording may capture them."
    ],
    "family": "accounts",
    "sourceSha256": "5280fbfc9f059ebbe072d3a4f6b03e323b2f031daeb362dd0eab6f37953debf8",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "ir-recover-validate.ps1": {
    "name": "IR: Restore and Validate",
    "scope": "SINGLE-USER",
    "input": "UPN and tenant",
    "details": [
      "Use the same workflow window and approved recovery decision.",
      "Confirm sign-in and MFA before closing the incident."
    ],
    "family": "ir-workflow",
    "sourceSha256": "c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "git-handoff.ps1": {
    "name": "Save Project Handoff",
    "scope": "LOCAL",
    "input": "Repository",
    "details": [
      "Creates a screened project snapshot; review it before sharing."
    ],
    "family": "git",
    "sourceSha256": "886a5782009fc8abf4825f997ccab38c0c1679a32b6653596089e038cf3ba22c",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "git-repo.ps1": {
    "name": "Manage Git Repository",
    "scope": "LOCAL",
    "input": "Repository",
    "details": [
      "Review the repository and selected action before changes."
    ],
    "family": "git",
    "sourceSha256": "cd0c87313d27c17cd79a82f470991aad016583781066f856841cc251f245afdd",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "git-security.ps1": {
    "name": "Review GitHub Security",
    "scope": "LOCAL",
    "input": "Repository and exported security log",
    "details": [
      "Reviews supplied GitHub evidence; missing evidence stays unknown."
    ],
    "family": "git",
    "sourceSha256": "3cba00d77603ffe94401fbda18953579b90492012be0446b08c6de806d5fe1e8",
    "presentationRevision": false,
    "releaseVersion": ""
  },
  "set-execution.ps1": {
    "name": "Set Up Script Execution",
    "scope": "LOCAL",
    "input": "Current computer",
    "details": [
      "Changes local execution settings and unblocks selected files.",
      "Managed policies still apply."
    ],
    "family": "setup",
    "sourceSha256": "90464f2b844266bdf88c5956fc44dd34939cf7c8664ac19c90f4be4defec2bc4",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "attractor.ps1": {
    "name": "Attractor",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Run in an existing terminal; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "62820d67085b65d230bb28c4954259bd32bffd29f30aee8a6f9a2cdfcdfdc5aa",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "rain.ps1": {
    "name": "Rain",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Run in an existing terminal; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "67ff5ccad0eb69510576920fd8b36accfb606a2b1cd3ddeb1ae75f021fda9bc9",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "static.ps1": {
    "name": "Static",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Run in an existing terminal; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "75f06611710a84f21522226fffebb3bf2e6a6b5d58383baf507ba6c69ddf19ca",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "SIGN-FOLDER-SCRIPTS.ps1": {
    "name": "Sign Scripts",
    "scope": "LOCAL",
    "input": "Folder and signing certificate",
    "details": [
      "Review the selected certificate and files before signing.",
      "A signature identifies the signer; it is not a code review."
    ],
    "family": "signing",
    "sourceSha256": "997cabfc93947e35b80e99d11053ce3f704b0e0a44fb30524606ed49b0f87b86",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "GET-TERMINAL-READINESS-CHECK.ps1": {
    "name": "Check Terminal Readiness",
    "scope": "LOCAL",
    "input": "Current computer",
    "details": [
      "Reviews local terminal requirements without repairing them."
    ],
    "family": "setup",
    "sourceSha256": "1c0b4e564cf6f8fa821fbe76e632c7bf9d2e1e8269f107f54d646b8680bc8164",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-FILE-INVENTORY.ps1": {
    "name": "Get File Inventory",
    "scope": "LOCAL",
    "input": "Folder",
    "details": [
      "Reviews files and versions without changing them."
    ],
    "family": "files",
    "sourceSha256": "ad5af3b5f30146d26ae6a94c11da242d49960fe622f7bac6c8123fbfbc1795e3",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "INVOKE-MAP-KIT.ps1": {
    "name": "Map Folders",
    "scope": "LOCAL",
    "input": "Folder",
    "details": [
      "Reports the selected folder structure without enforcing a baseline."
    ],
    "family": "files",
    "sourceSha256": "330fb1fc8cc144b3f9cd23a0e3399a2f69d168b31b6a9fe27c255e0c77ffdf2b",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "INVOKE-SESSION-RESET.ps1": {
    "name": "Reset Terminal Session",
    "scope": "LOCAL",
    "input": "Current PowerShell window",
    "details": [
      "Run in the session you want to reset."
    ],
    "family": "setup",
    "sourceSha256": "3b15375fe2f05b1543e5f90e081cd6d8c28360cf1eaa3423b60ef5498e7f0af8",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  },
  "SET-THEME-BASIC.ps1": {
    "name": "Basic Theme",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Applies a terminal style; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "82ddf2ed63914b6a1eb40664f486783e59690799b8df19bf9f00fbd3dc142756",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "SET-THEME-COBALT.ps1": {
    "name": "Cobalt Theme",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Changes this session and its process execution setting."
    ],
    "family": "terminal",
    "sourceSha256": "3d0dbac577cce716e5427a9b2635ee6cefe29a45955bc632cb8b4f2dd48fe343",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "SET-THEME-SEAGLASS.ps1": {
    "name": "Sea Glass Theme",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Applies a terminal style; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "16153f1c1989834f659ec7c08546c454dd95bdc51abebb2f7afb684b70964fdf",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "SET-THEME-SILICON-VALLEY.ps1": {
    "name": "Silicon Valley Theme",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Applies a terminal style; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "1c732aa6c82182265dc02019c9805a7ac9faec56e7b3312e8d7b00c7d66dd60d",
    "presentationRevision": false,
    "releaseVersion": "1.0.0"
  },
  "MANAGE-CERT-SIGNATURES.ps1": {
    "name": "Manage Signing Certificates",
    "scope": "LOCAL",
    "input": "Certificate selection",
    "details": [
      "Manages current-user signing certificates and related files.",
      "Review the certificate before removal or export."
    ],
    "family": "signing",
    "sourceSha256": "2728fc9d57cc00b334db1f60c9fd3e6fdf84f5a090ea3a2434a94ee206fe9407",
    "presentationRevision": true,
    "releaseVersion": "1.0.1"
  }
});
