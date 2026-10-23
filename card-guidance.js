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
    "sourceSha256": "adebcd1ba46cb0e58a7ac4381547d2aa7f501a906b5c521d27ca0ac9121b6555",
    "objective": "Find Conditional Access settings and exclusions that need review.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Policy.Read.ConditionalAccess, Directory.Read.All, User.Read.All.",
    "notes": "Read-only Conditional Access posture review that flags disabled/report-only policies, exclusions, device-code gaps, location conditions, and other weak-coverage indicators.",
    "startMode": "right-click",
    "completion": {
      "result": "Policy settings and possible protection gaps are listed.",
      "next": "Review how the policies apply to the affected users; configuration flags alone do not prove effective coverage.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
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
    "sourceSha256": "b41987e2a5912652d1e01a953a7dea402c7c49e24d20fade2fddb9f9696478be",
    "objective": "Assign a selected Microsoft 365 license to approved users.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.ReadWrite.All, Directory.Read.All, Organization.Read.All.",
    "notes": "Shows available tenant SKUs, previews the selected license operation, optionally sets missing UsageLocation, requires typed ASSIGN confirmation, and re-reads each user to verify the selected SKU is present.",
    "startMode": "right-click",
    "completion": {
      "result": "Each user’s selected license and any approved country/region change are checked again.",
      "next": "Review failed or unconfirmed users; a successful license assignment does not prove every service is ready.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. Defaults offered: group name Dynamic-Group-AnyLicense and alias DG_AnyLicense; change them before approval if needed.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Group.ReadWrite.All, Directory.Read.All.",
    "guards": [
      "Checks the tenant and signed-in account",
      "Stops creation if an existing-group lookup fails or has more than one match",
      "Type CREATE to approve the displayed group and membership rule"
    ],
    "sourceSha256": "7ed4b8f50be401d4004b6ff4672d19bcad5ab6e7f47cf7bc3d0a3e144290f83d",
    "objective": "Create a group that automatically includes users with assigned licenses.",
    "notes": "Creates one Entra dynamic security group for enabled users with an active license/service plan. Shows the membership rule, requires typed CREATE confirmation, and re-reads the group to verify its dynamic configuration.",
    "startMode": "right-click",
    "completion": {
      "result": "The new group’s dynamic membership settings are checked after creation.",
      "next": "Check membership processing in Entra ID. Creating this group does not assign a license to it.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
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
    "sourceSha256": "0fb9b390bdc16c4e677661003145ac9ab7718c2abedf0f6b44f303971bee2e2c",
    "objective": "Remove selected Microsoft 365 licenses from approved users.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.ReadWrite.All, Directory.Read.All, Organization.Read.All.",
    "notes": "Validates the expected tenant, previews each exact target UPN and planned license, requires one typed REMOVE approval, and re-reads each user. Failed or unverified results remain incomplete. License removal alone is not offboarding.",
    "startMode": "right-click",
    "completion": {
      "result": "Each user’s licenses are checked again after the approved removal.",
      "next": "Review failed or unconfirmed users. License removal alone does not complete offboarding.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "input": "Tenant domain (for example, contoso.com). Default inactivity threshold: 90 days.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ExchangeOnlineManagement + ActiveDirectory. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, AuditLog.Read.All, Group.Read.All.",
    "checks": [
      "Enabled users with old or missing sign-in records",
      "Active admin roles and cloud groups with no owner",
      "External mailbox forwarding"
    ],
    "guards": [
      "Shows failed checks; exports only when requested",
      "Desktop HTML report is optional; keep exported client information private"
    ],
    "sourceSha256": "df729d70508b81bf0328f0313d0de406e56f4204c3dc8460ef0ea8bb4eb91606",
    "objective": "Review accounts, mailbox access, and licenses for cleanup.",
    "notes": "Periodic read-only tenant hygiene review covering stale enabled users, active admin-role counts, ownerless cloud-manageable groups, and external mailbox forwarding.",
    "startMode": "right-click",
    "completion": {
      "result": "Findings for old sign-ins, admin roles, groups without owners, and external forwarding; failed checks remain gaps.",
      "next": "Review each finding before planning cleanup. This tool makes no tenant changes. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
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
    "sourceSha256": "c91680865f7bc992c7638f1a5c3e371a281ed52100a2a3fc979b87d8321af676",
    "objective": "List direct members of selected Exchange distribution groups.",
    "input": "Distribution group names or email addresses, entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and permission to read the target client tenant. Technical requirements: ExchangeOnlineManagement",
    "notes": "Focused Exchange Online lookup for one or more distribution groups. Accepts a direct group name/address or TXT/CSV input and can export verified member detail.",
    "startMode": "right-click",
    "completion": {
      "result": "Direct members of the requested distribution groups, with lookup problems shown.",
      "next": "Review unresolved group names; nested groups require their own membership review.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "INVOKE-REMOVE-USER-GROUPS.ps1": {
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ActiveDirectory. Requested delegated Graph scopes: User.Read.All, Group.Read.All, GroupMember.ReadWrite.All.",
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
    "sourceSha256": "8bc820639a1d6e1479e0b1c7a2a1f58953fb0eb5396f922628a73855b0e3fc54",
    "objective": "Remove selected users from eligible AD and Entra groups.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional sync server if you request an immediate sync.",
    "notes": "Offboarding-style cleanup for one or many users. Shows Active Directory and Entra memberships independently, keeps synced Entra observations visible, acts once at the authoritative source, skips dynamic/role-assignable/Exchange-managed memberships, requires typed REMOVE GROUPS confirmation, and validates removals.",
    "startMode": "right-click",
    "completion": {
      "result": "Removal results and remaining memberships for the approved users.",
      "next": "Review failed and skipped memberships. Check synchronized changes in Entra ID before closing the work.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
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
    "sourceSha256": "23a9db7bcacb8f388d2e71b3cc54b720a00b9d377af7c10bac263b32f0008b62",
    "objective": "Require per-user MFA for selected accounts after approval.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Policy.ReadWrite.AuthenticationMethod, UserAuthenticationMethod.Read.All, User.Read.All.",
    "notes": "Uses the Microsoft Graph beta authentication requirements endpoint. Per-user MFA is separate from Conditional Access and Security Defaults. Shows all target states first, requires typed ENFORCE confirmation, and re-reads each user to verify the resulting MFA state.",
    "startMode": "right-click",
    "completion": {
      "result": "Each approved user’s per-user MFA setting is checked again.",
      "next": "Confirm the intended sign-in experience. This legacy setting does not replace Conditional Access or Security Defaults.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement; rights to read recipient, mailbox configuration, inbox rules and mailbox permissions. Microsoft Graph is not used.",
    "sourceSha256": "e9e75ef77efeb81017c8dcc6f3f05cd5deb4fb8eba90890560808406762f7fda",
    "objective": "Review one mailbox for unexpected access, forwarding, and suspicious rules.",
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
    ],
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "BEC-INVOKE-EMAIL-RECOVERY.ps1": {
    "input": "Mailbox sign-in name (UPN). Defaults: move from RSS Subscriptions to Restored Messages, looking back 24 hours. Review or change the folders before approving moves.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Mail.ReadWrite.Shared.",
    "checks": [
      "Folders selected for the email move",
      "Message preview and selected move results",
      "Checks both folders after moving email"
    ],
    "guards": [
      "Preview and typed MOVE confirmation",
      "Target folder creation requires approval"
    ],
    "sourceSha256": "bbbe2551ba6054995d4caa517e23a32711c0afbd4b7becbf2a5575662409482f",
    "objective": "Restore previously moved email to the selected mailbox.",
    "notes": "Moves messages back from attacker-hidden or incorrect folders.",
    "startMode": "right-click",
    "completion": {
      "result": "Selected email moves and checks of the source and recovery folders.",
      "next": "Have the user confirm the recovered messages are in the expected place. Review any failed moves before retrying.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "BEC-RISK-ASSESSMENT.ps1": {
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
    "sourceSha256": "94526ec8ea67e88d9373d1cdb9beadf7ec4992b80cafcd4a97797c2a10c488f4",
    "objective": "Review one user's account and mailbox before choosing a response.",
    "input": "User sign-in address and Microsoft 365 domain or tenant ID",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ExchangeOnlineManagement. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, UserAuthenticationMethod.Read.All, AuditLog.Read.All, Policy.Read.All, User.RevokeSessions.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All.",
    "notes": "Makes no tenant changes. Conditional Access is an enabled-policy inventory, not proof of user coverage. User-tested on a client jumpbox; module versions, tenant policy and AD/cloud synchronization still need environment-specific validation. Keep all three files together and launch in one existing PowerShell window. No automatic delta sync, exports, module installs or execution-policy changes. Read the IR workflow guide before use.",
    "details": "Keep all three scripts in one folder and use the same PowerShell window. Sign-in requests permissions for all three steps; assessment makes no tenant changes. There is no automatic sync, export, module install, or execution-policy change. Module compatibility, local AD permissions, and synchronization must be checked for the client. The policy list does not prove that Conditional Access protects this user.",
    "startMode": "workflow",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Shared-session exception: all three BEC phases request the same read AND response scopes at the first sign-in. Assessment is read-only but its token is write-capable; containment and recovery can make approved changes. Approve the whole response scope set before starting; authentication separation is deferred to the lifecycle wave.",
      "BEC platform: approved Windows jumpbox, Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+; AD actions require delegated Windows AD rights.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "BEC-CONTAIN-ERADICATE.ps1": {
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
    "sourceSha256": "c8b857d6191a6bceecb651413552cad0bbc8a421046bfe2a95390728cb89ce10",
    "objective": "Contain and clean up one compromised account after approval.",
    "input": "User sign-in address and Microsoft 365 domain or tenant ID",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ExchangeOnlineManagement + ActiveDirectory. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, UserAuthenticationMethod.Read.All, AuditLog.Read.All, Policy.Read.All, User.RevokeSessions.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All.",
    "notes": "Revocation, sign-in block, password reset and selected persistence deletion require explicit approvals. Synced AD changes use a SID-matched account. MFA is operator-confirmed, not independently enforced by the script. A temporary password can appear in terminal capture/transcripts; no automatic export or clipboard copy. User-tested on a client jumpbox; module versions, tenant policy and AD/cloud synchronization still need environment-specific validation. Keep all three files together and launch in one existing PowerShell window. No automatic delta sync, exports, module installs or execution-policy changes. Read the IR workflow guide before use.",
    "details": "Keep all three scripts in one folder and use the same PowerShell window. Sign-in requests permissions for all three steps; assessment makes no tenant changes. There is no automatic sync, export, module install, or execution-policy change. Module compatibility, local AD permissions, and synchronization must be checked for the client. You confirm trusted MFA methods; the script does not enforce them. A temporary password can remain in terminal capture/transcripts even after its variable is cleared.",
    "startMode": "workflow",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Shared-session exception: all three BEC phases request the same read AND response scopes at the first sign-in. Assessment is read-only but its token is write-capable; containment and recovery can make approved changes. Approve the whole response scope set before starting; authentication separation is deferred to the lifecycle wave.",
      "BEC platform: approved Windows jumpbox, Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+; AD actions require delegated Windows AD rights.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
  },
  "BEC-RECOVER-VALIDATE.ps1": {
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
    "sourceSha256": "1b21a21f15d6618c0964c37ab21e0c167cfba5616efe8d108dbb18ac1aa0ce4e",
    "objective": "Check recovery readiness and restore approved account access.",
    "input": "User sign-in address and Microsoft 365 domain or tenant ID",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ExchangeOnlineManagement + ActiveDirectory. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, UserAuthenticationMethod.Read.All, AuditLog.Read.All, Policy.Read.All, User.RevokeSessions.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All.",
    "notes": "RECOVER attests user identity, remediation, trusted MFA methods and owner approval. Rechecks available evidence; does not reset a password. User sign-in with MFA and monitoring remain required. User-tested on a client jumpbox; module versions, tenant policy and AD/cloud synchronization still need environment-specific validation. Keep all three files together and launch in one existing PowerShell window. No automatic delta sync, exports, module installs or execution-policy changes. Read the IR workflow guide before use.",
    "details": "Keep all three scripts in one folder and use the same PowerShell window. Sign-in requests permissions for all three steps; assessment makes no tenant changes. There is no automatic sync, export, module install, or execution-policy change. Module compatibility, local AD permissions, and synchronization must be checked for the client. Recovery does not reset passwords or remove unwanted access. Verify user sign-in with MFA and complete the follow-up monitoring.",
    "startMode": "workflow",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Shared-session exception: all three BEC phases request the same read AND response scopes at the first sign-in. Assessment is read-only but its token is write-capable; containment and recovery can make approved changes. Approve the whole response scope set before starting; authentication separation is deferred to the lifecycle wave.",
      "BEC platform: approved Windows jumpbox, Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+; AD actions require delegated Windows AD rights.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
  },
  "BEC-GET-DATA-EXFIL-ACTIVITY.ps1": {
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
    "sourceSha256": "1fa5c320ff44327b602d61a94ba5a76b9571b51fdbf36c77be0c59e34795fad1",
    "objective": "Review a user's file activity for possible data exposure.",
    "notes": "Reviews SharePoint/OneDrive activity for possible download, sharing, or exfiltration behavior.",
    "startMode": "right-click",
    "completion": {
      "result": "Available file-download and sharing events, plus download-burst indicators.",
      "next": "Investigate unusual events using the original records; the flags do not prove that data was stolen.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "BEC-GET-IP-TRACE.ps1": {
    "input": "Suspect IP; lookback days (default 7, maximum 90).",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement; permission to run Search-UnifiedAuditLog.",
    "checks": [
      "Unified Audit Log activity for the source IP",
      "Daily search windows and optional CSV"
    ],
    "guards": [
      "Shows failed search periods and results cut short by limits"
    ],
    "sourceSha256": "a97b049fad9c2a2f7f4344bc90a68689d1e1d5c4f720f2b6533b5106ae69970a",
    "objective": "Find tenant audit activity associated with a selected IP address.",
    "notes": "Pivots on a source IP across tenant audit activity.",
    "startMode": "right-click",
    "completion": {
      "result": "Available audit events for the IP, with failed search periods and limits reported.",
      "next": "Review the events in context and resolve gaps before describing the search as complete.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "BEC-GET-TENANT-EMAIL-SEARCH.ps1": {
    "input": "Sender, recipient or source IP; lookback days (default 7, maximum 90).",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement with Get-MessageTraceV2; message-trace read rights.",
    "checks": [
      "Message traces matching supplied indicators",
      "Search windows and optional CSV"
    ],
    "guards": [
      "Searches in periods of up to 10 days; reports results cut short by limits"
    ],
    "sourceSha256": "3a78895cbec147f408f82929e720c7e527c8bd3f18dad6d86c1e31ee1c868043",
    "objective": "Find email delivery records by sender, recipient, or IP address.",
    "notes": "Searches tenant message trace by sender, recipient, source IP, or combination.",
    "startMode": "right-click",
    "completion": {
      "result": "Matching email delivery records, with search periods and result limits shown.",
      "next": "Review recipients and delivery status; use a separate content-search tool when message content is needed.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "BEC-GET-THREAT-INTEL-ACTIVITY.ps1": {
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
    "sourceSha256": "e0864cdd7dd81324a3b1a71fbf80841c14d3bd86d0ca7abb100416b4a243461e",
    "objective": "Check selected public IP addresses against external reputation services.",
    "notes": "Adds reputation context to suspicious IP addresses.",
    "startMode": "right-click",
    "completion": {
      "result": "Reputation results from the enabled providers, or their lookup errors.",
      "next": "Compare reputation with client evidence. A clean reputation result does not prove an IP is safe.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
  },
  "BEC-GET-TIMELINE-BUILDER.ps1": {
    "input": "Local case folder or manual event entries; optional search text.",
    "checks": [
      "Events sorted by time from JSON, text, log, and Markdown files",
      "Optional manual events and TXT timeline"
    ],
    "guards": [
      "Labels events that use a file modification time instead of an event time",
      "Source evidence is never modified"
    ],
    "sourceSha256": "a80ca2ee465da49ebb7d38b6728265be427d93a4aa7eb129d3e18f202a4b5ecf",
    "objective": "Combine supplied incident evidence into a timeline.",
    "requires": "Local case outputs",
    "notes": "Builds a simple chronology from IR notes, logs, JSON, or manual entries.",
    "startMode": "right-click",
    "completion": {
      "result": "Events sorted by time and an optional saved timeline.",
      "next": "Check event time zones and entries based on file modification times before sharing the timeline.",
      "blocked": "If input cannot be read, check its path or format. Keep the original evidence unchanged."
    },
    "permissionNotes": []
  },
  "BEC-GET-TOKEN-DECODE.ps1": {
    "checks": [
      "Decodes the token header and contents on this computer"
    ],
    "guards": [
      "No network or export",
      "Does not check whether the token is signed, trusted, or usable"
    ],
    "sourceSha256": "809933ffd6759b71b20324825887e7d5b1530e1eecce8d8d0cd92c3ce5a57742",
    "objective": "Read a token's contents locally without sending it online.",
    "input": "JWT token",
    "requires": "PowerShell on this computer.",
    "notes": "Decodes JWT header/payload locally for claim inspection.",
    "startMode": "right-click",
    "completion": {
      "result": "The token’s decoded header and contents are shown locally.",
      "next": "Inspect the claims without treating decoding as proof of a valid or trusted token. Keep the token private.",
      "blocked": "If input cannot be read, check its path or format. Keep the original evidence unchanged."
    },
    "permissionNotes": []
  },
  "BEC-GET-TOKEN-REPLAY-CHECK.ps1": {
    "input": "Target UPN; lookback hours (default 48); expected country/region (default US).",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, AuditLog.Read.All, IdentityRiskEvent.Read.All.",
    "checks": [
      "Entra sign-ins and Identity Protection risk detections",
      "Risk signals related to stolen tokens, plus sign-in locations"
    ],
    "guards": [
      "Unavailable data remains a limitation",
      "An unexpected location alone does not prove a stolen session",
      "Desktop HTML report is optional; keep exported client information private"
    ],
    "sourceSha256": "aacd5c9a0c91ecbd16ceedaa14b433aba25f882f3752efd903996bfc95dbfbde",
    "objective": "Review sign-ins for indicators of token replay or session theft.",
    "notes": "Looks for suspicious sign-in patterns consistent with token replay/AiTM.",
    "startMode": "right-click",
    "completion": {
      "result": "Available sign-in and risk records for the user and selected time period.",
      "next": "Review token-specific signals and missing data; an unexpected location alone does not prove a stolen session. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, Application.Read.All.",
    "checks": [
      "App permissions approved by guest users",
      "App and service names when they can be found",
      "Granted app permissions that may create risk"
    ],
    "sourceSha256": "0e9676a036af440268ac33d3007fa34c05505e2765462a7143b2caa208585721",
    "objective": "Review guest users and their app permissions.",
    "notes": "Reviews guest/application consent exposure.",
    "startMode": "right-click",
    "completion": {
      "result": "Guest-approved app permissions and the permissions flagged for review.",
      "next": "Confirm the guest, app, and business need before revoking access.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default sign-in review period: 72 hours.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ExchangeOnlineManagement. Requested delegated Graph scopes: AuditLog.Read.All, User.Read.All, Directory.Read.All.",
    "sourceSha256": "3f365d6e8677b2f59f1e3fba81f038c6645dd0e1e3a95b28c95804b161f06009",
    "objective": "Find sign-in activity associated with shared mailboxes.",
    "notes": "Finds shared mailboxes with direct sign-in exposure.",
    "startMode": "right-click",
    "completion": {
      "result": "Shared-mailbox sign-in records for the selected period.",
      "next": "Investigate unexpected direct sign-ins and confirm that log access covered the period needed.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "GET-APP-REGISTRATION-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default credential-expiry warning: within 30 days.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Application.Read.All, Directory.Read.All.",
    "sourceSha256": "76613d8367421f66d7c546b3543168109eadfec80618fa46905ad3a2b3403a5d",
    "objective": "Review registered apps, ownership, and credential expiry dates.",
    "notes": "Reviews app registrations and related security posture.",
    "startMode": "right-click",
    "completion": {
      "result": "App credentials, permission flags, and owner findings.",
      "next": "Confirm an app’s purpose and owner before changing permissions or rotating credentials.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-DEVICE-CODE-EXPOSURE.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Default sign-in review period: 72 hours.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Policy.Read.ConditionalAccess, AuditLog.Read.All, Directory.Read.All.",
    "sourceSha256": "9595b261ea55f5fc61dd562df2e5297cd8d3fa8bf587d0d61cce5535df93e27b",
    "objective": "Review policies for gaps in device-code sign-in protection.",
    "notes": "Reviews device-code authentication exposure.",
    "startMode": "right-click",
    "completion": {
      "result": "Device-code policy settings and recent device-code sign-ins.",
      "next": "Check whether each sign-in is expected before planning policy changes.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-MFA-SECURITY-AUDIT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, AuditLog.Read.All, UserAuthenticationMethod.Read.All, Policy.Read.ConditionalAccess.",
    "sourceSha256": "da69d7308448b31477b9de6ff104257a891562902ec0142a5b053b70482d73a5",
    "objective": "Review MFA registration and the policies intended to protect sign-ins.",
    "notes": "Reviews MFA coverage and security gaps.",
    "details": "Default review covers MFA registration and methods. To include Conditional Access policy review, launch in a terminal with -IncludeConditionalAccess. Policy settings alone do not prove protection for every user.",
    "startMode": "right-click",
    "completion": {
      "result": "MFA registration and method findings; policy review is included only when requested.",
      "next": "Check users with missing or weaker methods. Registration does not prove MFA is enforced for every sign-in.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Policy.Read.ConditionalAccess is requested only when Conditional Access review is selected. Registration reporting requires a supported Reports Reader / Security Reader role (or equivalent); the beta report excludes disabled users and can change."
    ]
  },
  "GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain. Optional previous JSON snapshot for comparison.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: SecurityEvents.Read.All, SecurityActions.Read.All, Directory.Read.All.",
    "sourceSha256": "bf4d87b38d221c5e6b86fef69b10a1cb7c4d75e6fe8c5abe64ec5c99993f3e5d",
    "objective": "Show the tenant's latest Microsoft Secure Score.",
    "notes": "Captures Microsoft Secure Score posture.",
    "startMode": "right-click",
    "completion": {
      "result": "Current Secure Score data and a comparison when a previous snapshot is supplied.",
      "next": "Prioritize controls that fit the client; the score is not proof that the tenant is secure.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. This script requires the ID, not just a domain.",
    "guards": [
      "Checks the tenant and signed-in account before reading data",
      "Stops if required data cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Application.Read.All, Directory.Read.All, User.Read.All.",
    "sourceSha256": "7f300774005a7ba46d354c17b02cec9f09ca34863edaf8b057159cca7bef5885",
    "objective": "List enterprise app owners and identify apps without an owner.",
    "notes": "Reviews enterprise/service principal ownership.",
    "startMode": "right-click",
    "completion": {
      "result": "Enterprise app owners and apps with no recorded owner.",
      "next": "Confirm who manages each app before assigning or removing owners.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-SIGNIN-ANOMALIES.ps1": {
    "input": "Tenant ID (GUID) from Entra admin center > Overview. Defaults: last 24 hours, expected country US, up to five pages of results. Optional user sign-in name (UPN) filter.",
    "guards": [
      "Shows expected countries before flagging sign-ins from elsewhere",
      "Marks the review incomplete when the page limit is reached",
      "Stops if required data is missing or cannot be read"
    ],
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: AuditLog.Read.All, User.Read.All, Directory.Read.All.",
    "sourceSha256": "dcde2b39589b9c740a7a9c20ff17cc59d8752cc555a9359f9d0210e18fa053b1",
    "objective": "Find unusual sign-in activity that needs investigation.",
    "notes": "Reviews suspicious or anomalous tenant sign-ins.",
    "startMode": "right-click",
    "completion": {
      "result": "Sign-ins flagged against the selected countries and time period, with page-limit gaps shown.",
      "next": "Review flagged events and any incomplete coverage before deciding the activity is expected or suspicious.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
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
    "sourceSha256": "231cef1b8c4ca32837fa4ece5cc04162eb1de0371f3fd69a6fd7aa839bd6f147",
    "objective": "Join the current computer to the selected AD domain.",
    "input": "Target domain and domain-join credentials. Optional organizational-unit path (OU) and ticket number.",
    "requires": "Local administrator + domain join credentials",
    "notes": "Runs admin, hostname, current-domain, DNS, and reachability checks before Add-Computer.",
    "startMode": "terminal-admin",
    "completion": {
      "result": "The approved domain join reports its result; a restart occurs only if approved.",
      "next": "Restart when required, then confirm domain membership and a permitted domain sign-in.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
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
    "sourceSha256": "adcb0d7445bbc847c2f1d7a22dcf5c12c645a68a81036c38dd510c67bd3821d1",
    "objective": "Install a network printer using its address and selected driver.",
    "input": "Printer display name and IP address or host name. Select an installed driver by its exact name; the script can list drivers.",
    "requires": "An installed printer driver and Windows permission to manage printers. The script does not download a driver.",
    "notes": "Creates the TCP/IP port when needed, adds the printer, and can set default or print a test page.",
    "startMode": "right-click",
    "completion": {
      "result": "The printer and TCP/IP port are created or their existing state is reported.",
      "next": "Print a test page and confirm the intended default printer with the user.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "BACKUP-USER-PROFILE.ps1": {
    "checks": [
      "Common profile folders and optional Downloads",
      "Dated destination folder and local copy log"
    ],
    "guards": [
      "Typed BACKUP confirmation before copying profile data"
    ],
    "sourceSha256": "dd1d1e62acc1343f0c5010dc93ebd5cf29671ff42d9876580c3f1ef7b285988d",
    "objective": "Copy selected user-profile folders to a backup location.",
    "input": "Profile folder to back up (blank uses your profile), backup destination, and whether to include Downloads.",
    "requires": "Read access to the profile folders and write access to the backup destination.",
    "notes": "Backs up Desktop, Documents, Pictures, Favorites, Signatures, Templates, and optionally Downloads.",
    "startMode": "right-click",
    "completion": {
      "result": "A dated backup folder and a copy log for the selected profile folders.",
      "next": "Review copy errors and open representative backed-up files before removing the original data.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "GET-USER-PREDELETE-CHECK.ps1": {
    "input": "One exact user sign-in name (UPN). Access to the user’s Active Directory domain is needed for local AD checks.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ActiveDirectory + ExchangeOnlineManagement. Requested delegated Graph scopes: User.Read.All, Group.Read.All, Directory.Read.All.",
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
    "sourceSha256": "4ae5545f73829374e5b1500bd3ba8cc029e3f095e700e9ce76bf835d8a034107",
    "objective": "Review a user's mailbox, memberships, and access before deletion.",
    "notes": "Read-only dependency review before deleting an on-premises AD user object; does not prove third-party or local-system dependencies are safe.",
    "startMode": "right-click",
    "completion": {
      "result": "Available identity, mailbox, ownership, app, license, and retention dependencies are listed.",
      "next": "Resolve dependencies and missing checks before deleting the account. Third-party and local-system dependencies still need separate review. Save the optional Desktop HTML report if you need a record.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "details": " At the end, choose Y to save an HTML report to your Desktop; otherwise no HTML report is saved. Reports can contain client information.",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
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
    "sourceSha256": "764cf4825fa98591a0ab0bde803f96568e1a1c2d8ed4585095eda2460a04aa6c",
    "objective": "List tenant admin-role assignments for review.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Directory.Read.All, RoleManagement.Read.Directory, User.Read.All, AuditLog.Read.All.",
    "notes": "Reviews active Entra admin-role assignments with account state, hybrid status, and recent sign-in context.",
    "startMode": "right-click",
    "completion": {
      "result": "Active admin-role assignments with account status and available sign-in context.",
      "next": "Confirm whether the roles are still needed; this is not a complete review of eligible roles available through PIM.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
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
    "sourceSha256": "3f18ee0289321bc6b7cb226c08f33c79c0e4844bc03884ea24a99180699f4251",
    "objective": "Review app permissions granted in the tenant.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Application.Read.All, Directory.Read.All.",
    "notes": "Reviews delegated OAuth grants, resolves application/resource names, and flags high-risk scopes.",
    "startMode": "right-click",
    "completion": {
      "result": "App permissions approved on behalf of users, with higher-risk permissions flagged.",
      "next": "Confirm the app and business need before revoking grants; this does not cover every form of app access.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
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
    "sourceSha256": "641555328872d02331f3153eb686b48bf4cf5b21f67c7a9919c0bbef0d75da61",
    "objective": "Find guest accounts that need an ownership or activity review.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, AuditLog.Read.All.",
    "notes": "Reviews guest accounts for disabled state, stale/no sign-in, and unaccepted invitations.",
    "startMode": "right-click",
    "completion": {
      "result": "Guest status, invitation state, and available sign-in history.",
      "next": "Confirm the sponsor and business need before removing guests. Missing history does not prove that a guest was never used.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
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
    "sourceSha256": "d9d7da1dc4f720953848f56fa4c68ae594c7b183ed3f07f623d511321a2aae07",
    "objective": "Review Microsoft 365 license capacity and user assignments.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, Organization.Read.All.",
    "notes": "Reviews subscribed SKUs and user license assignments, including disabled licensed users and enabled unlicensed users.",
    "startMode": "right-click",
    "completion": {
      "result": "License totals and user assignments, including disabled licensed and enabled unlicensed users.",
      "next": "Confirm business and retention needs before changing licenses.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "checks": [
      "Tenant mailbox rules and optional shared mailboxes",
      "Forward, redirect, delete, move and hidden-rule indicators",
      "Optional suspicious-only results and CSV"
    ],
    "sourceSha256": "c0a1a2459471df298746940de9a997ee60514cbec0bb11a821f4c7e2233c66f6",
    "objective": "Find mailbox inbox rules that need review across the tenant.",
    "input": "Defaults: user mailboxes only and all rules, not just flagged rules. Use -IncludeShared or -SuspiciousOnly in a terminal to change the review scope.",
    "requires": "Exchange Online read access",
    "notes": "Reviews inbox rules across user mailboxes, optionally includes shared mailboxes, and can limit output to suspicious behavior.",
    "startMode": "right-click",
    "completion": {
      "result": "Inbox rules for the chosen mailbox scope, or only flagged rules when requested.",
      "next": "Confirm whether flagged rules are approved and follow up on mailboxes that could not be read.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
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
    "sourceSha256": "7af474157506fd00c85b064ec037e09286c7776e4b088b28e8af36d6f3cbc85d",
    "input": "Default scan: this Windows computer, C: drive, 10 largest files. Use -ComputerName, -DriveLetter, or -TopFiles in a terminal to change the target or count.",
    "requires": "PowerShell 5.1+ | Remote targets: PowerShell remoting / WinRM",
    "notes": "Full-drive largest-file scan is read-only but can take several minutes. Largest files are review evidence, not automatic deletion candidates.",
    "objective": "Find Windows storage that may be reclaimable without deleting files.",
    "startMode": "right-click",
    "completion": {
      "result": "Drive usage, measured cleanup locations, and largest-file findings; scan failures remain visible.",
      "next": "Review candidate files before any separate cleanup. Large files are not automatically safe to delete.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
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
    "sourceSha256": "40abec4baa9461a7ce2f60159d747340023985fe505191d1d7e530873d7b674a",
    "input": "Cloud-only user sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional tenant domain. Default generated password: 20 characters; the script asks whether to require a change at next sign-in (default Yes).",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, User-PasswordProfile.ReadWrite.All.",
    "notes": "Refuses synced users so Active Directory remains authoritative. Generated passwords are never exported.",
    "objective": "Reset passwords for selected cloud-only users after approval.",
    "startMode": "right-click",
    "completion": {
      "result": "Each approved cloud-only user has a reset result; temporary passwords appear only after successful resets.",
      "next": "Deliver each password through the approved secure channel, confirm delivery at the pause, then verify the user’s next sign-in.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
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
    "sourceSha256": "0cdf541f4222218c359dddc9e441343d37ee7ad745cfe5588e06a9a45ad42316",
    "objective": "Check a toolkit folder against the expected files and setup.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "This checks a fixed toolkit layout, not just PowerShell. Review $ExpectedFolders and $ExpectedFiles for your installation. Missing layout files are reported as failures. Root defaults to C:\\Field-Kit and can be changed at the prompt.",
    "startMode": "right-click",
    "completion": {
      "result": "Findings compare the chosen folder with the script’s fixed expected kit layout.",
      "next": "Check whether reported missing files are actually required for your installation before changing the layout.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
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
    "sourceSha256": "ea3b5ee21dbd384d7107ec1458be968d7c7c5c00c9998a4dcc2f89856a8372a4",
    "objective": "Show the folder structure and files beneath a selected location.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Uses root detection or -RootPath; confirms the selected folder. Reports naming and file-extension warnings, not a full secret scan. Does not enforce a fixed layout or export files.",
    "startMode": "right-click",
    "completion": {
      "result": "A folder map with counts, signature status, and available Git indicators.",
      "next": "Review naming and file warnings manually; this is not a complete secret scan.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
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
    "sourceSha256": "2fa5b247f31b2dfe29bbed17ec9ffe576e53dbe3ce3e7ffb03f8328c7843dc07",
    "objective": "Clear supported service connections from the current PowerShell session.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Run in the terminal you want to reset. Asks before cleanup; can clear the optional JumpboxSessionPassword profile variable and open a fresh PowerShell 7 window. Does not change tenant settings.",
    "input": "No account list needed. Use the PowerShell window whose connections you want to close.",
    "startMode": "terminal",
    "completion": {
      "result": "Graph/Exchange cleanup results for this window; optional variable cleanup or a new window only when requested.",
      "next": "Reconnect to the intended tenant when ready. Review cleanup failures instead of assuming every connection closed.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "SET-THEME-BASIC.ps1": {
    "checks": [
      "Plain-text status and field-output examples"
    ],
    "guards": [
      "Does not change the terminal; output is demonstration data"
    ],
    "sourceSha256": "9dc01f2210cf808379be2770450283f0d44be72c4d3cae3f9a0087c2f15e98f2",
    "objective": "Show a plain PowerShell output style without color.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Prints example messages and waits for Enter. No persistent theme changes. Example output is demonstration data.",
    "startMode": "terminal",
    "input": "Prints examples in this PowerShell window; no startup profile changes or settings to enter.",
    "completion": {
      "result": "Example terminal messages are printed; no persistent theme is installed.",
      "next": "Use the examples as a reference; their output is demonstration data.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    },
    "permissionNotes": []
  },
  "SET-THEME-COBALT.ps1": {
    "checks": [
      "Cobalt palette and status-output preview"
    ],
    "guards": [
      "Changes this terminal and its execution policy; does not install a startup theme"
    ],
    "sourceSha256": "602ddcb368e716ca73ced3b799d847262faca237ee43b63a7070596ce37d9d2b",
    "objective": "Preview a blue PowerShell theme and output helpers.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Changes this terminal’s appearance and sets Process execution policy to Bypass. Prints a palette reference; does not install a persistent theme. Requires an ANSI-capable terminal.",
    "changeNote": "Changes this terminal and sets Process execution policy to Bypass; no profile installation.",
    "startMode": "terminal",
    "input": "Applies to this PowerShell window only, including its Process execution policy; no startup profile is installed.",
    "completion": {
      "result": "This terminal displays the Cobalt palette; no startup theme is installed.",
      "next": "Close the terminal to end session-only changes. Review the reported Process execution-policy change.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    },
    "permissionNotes": []
  },
  "SET-THEME-SEAGLASS.ps1": {
    "checks": [
      "Sea Glass console colors and syntax highlighting"
    ],
    "guards": [
      "Writes a startup theme to your PowerShell profile",
      "Changes execution policy for this PowerShell window"
    ],
    "sourceSha256": "629b919cea8aabd890151a2402241e426a4c0c331a9a4d5861bd9aaa340e888e",
    "objective": "Install a sea-green PowerShell theme in your startup profile.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Writes CurrentUserAllHosts profile and replaces recognized theme blocks. Also sets Process execution policy to Bypass. Review your profile before running; remove the SEA GLASS THEME block to undo persistence.",
    "changeNote": "Writes CurrentUserAllHosts profile and replaces recognized theme blocks. Also sets Process execution policy to Bypass. Review your profile before running; remove the SEA GLASS THEME block to undo persistence.",
    "startMode": "terminal",
    "input": "Applies to this window and your current-user PowerShell startup profile. Review the existing profile before running.",
    "completion": {
      "result": "The theme is applied and its startup block is written to your PowerShell profile.",
      "next": "Open a new PowerShell window to confirm startup. Review the profile if other customizations changed.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "SET-THEME-SILICON-VALLEY.ps1": {
    "checks": [
      "Silicon Valley console and syntax colors"
    ],
    "guards": [
      "Writes a startup theme to your PowerShell profile"
    ],
    "sourceSha256": "aab04649707578c0c57a9602b80cdae04465bff529fae0373d46f1aa2bc43739",
    "objective": "Install a green PowerShell theme in your startup profile.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Rewrites recognized theme blocks in CurrentUserAllHosts profile. Also installs and displays a date-seeded daily password generator. Its output is predictable: do not use it as a password. Remove the SILICON VALLEY THEME block to undo persistence.",
    "changeNote": "Rewrites recognized theme blocks in CurrentUserAllHosts profile. Also installs and displays a date-seeded daily password generator. Its output is predictable: do not use it as a password. Remove the SILICON VALLEY THEME block to undo persistence.",
    "startMode": "terminal",
    "input": "Writes to your current-user PowerShell startup profile. Review the existing profile before running; the displayed daily password is predictable.",
    "completion": {
      "result": "The profile theme and startup banner are installed.",
      "next": "Open a new PowerShell window to confirm startup. Never use the predictable date-based password output as a real password.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "GET-STALE-SIGNIN-REVIEW.ps1": {
    "sourceSha256": "27e94610728226f9c43f44631b4c9921fc6412ddf8d79f2e2617a7725c1a4fa6",
    "objective": "Find enabled accounts with old or unavailable Entra sign-in activity.",
    "input": "No user list needed. Reviews enabled member accounts in the signed-in tenant; default inactivity threshold: 90 days. Use -Days in a terminal to change it.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, AuditLog.Read.All.",
    "notes": "Tenant-wide review of enabled Entra member accounts. Missing sign-in activity is reported separately and is never classified as inactivity.",
    "startMode": "right-click",
    "completion": {
      "result": "Enabled users with sign-in records older than the threshold, with missing records listed separately.",
      "next": "Confirm whether each account is still needed before proposing changes.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "INVOKE-DISABLE-ACCOUNTS.ps1": {
    "sourceSha256": "a123394ca9a041cb7f49225b334ce6fe02637038c554944d1c222d325fa72287",
    "objective": "Disable selected user accounts in AD or Entra after approval.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional sync server if you request an immediate sync.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ActiveDirectory. Requested delegated Graph scopes: User.ReadWrite.All, Directory.Read.All.",
    "notes": "Guarded account-disable workflow for one or many users. Uses Active Directory for synced users and Entra ID for cloud-only users, requires typed DISABLE confirmation, validates post-change state, and can optionally revoke sessions and request Entra Connect delta sync.",
    "startMode": "right-click",
    "completion": {
      "result": "A result for each approved account, including whether the disabled state was confirmed.",
      "next": "Check any failed account and confirm synced changes reach Entra ID. Session revocation is a separate optional action.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
  },
  "INVOKE-DELETE-ACCOUNTS.ps1": {
    "sourceSha256": "0831cf439bc477cae85d6b6a4f2e2eb1043d4e61d5d4e65964eaa7de658c0eef",
    "objective": "Delete approved user accounts from their authoritative directory.",
    "input": "Exact user sign-in names (UPNs), entered directly or in a TXT/CSV file. Optional sync server if you request an immediate sync.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ActiveDirectory + Microsoft.Graph.Users + Microsoft.Graph.Identity.DirectoryManagement. Requested delegated Graph scopes: User.ReadWrite.All, Organization.Read.All.",
    "notes": "Destructive identity deletion workflow for one or many explicitly approved users. Resolves exact UPNs, uses Active Directory for synced users and Entra ID for cloud-only/guest identities, shows a full plan, requires typed DELETE confirmation, and validates absence at the same authoritative source.",
    "startMode": "right-click",
    "completion": {
      "result": "A result for each approved deletion, checked in the system where the user was removed.",
      "next": "Keep failed deletions and pending synchronization open. Follow the separate mailbox and retention plan.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
  },
  "RESOLVE-NAMES-TO-UPNS.ps1": {
    "sourceSha256": "8b150fd6e093ecf1a4b2b77cc5856f18de47a0f101a8f7257f0eea4742d12f8d",
    "objective": "Find user sign-in names from names, email addresses, or a list.",
    "input": "Tenant domain, plus names, email addresses, or sign-in names (UPNs). Direct entries and TXT/CSV lists are supported.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All.",
    "notes": "Tenant-targeted identity resolver for direct values or TXT/CSV input with exact/likely/multiple/no-match decisions plus verified review CSV and exact-match UPN TXT exports.",
    "startMode": "right-click",
    "completion": {
      "result": "Matches are separated into exact, likely, multiple, or no match.",
      "next": "Resolve uncertain matches before using the names in another tool. Export the exact-match list only when needed.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-ACCOUNT-STATUS.ps1": {
    "sourceSha256": "94258427439cc292f33bd76e835b10a407218bc9136537874a9cd267f2e20b75",
    "objective": "Show whether selected accounts are enabled and when they last signed in.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file. The script uses their shared domain unless a tenant domain is supplied.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, AuditLog.Read.All.",
    "notes": "Checks exact UPN account state and recorded Entra sign-in activity. Missing sign-in data and query failures remain explicit and are never treated as inactivity.",
    "startMode": "right-click",
    "completion": {
      "result": "Account status and available sign-in records for the requested users.",
      "next": "Follow up on failed lookups or missing history before deciding an account is inactive.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-GROUP-MEMBERS.ps1": {
    "sourceSha256": "5c7baa7d0551de2eb0c21650bb8943ca198697c94cef2f556a5ab458f7916d67",
    "objective": "List direct members of selected groups.",
    "input": "Group names or email addresses, entered directly or in a TXT/CSV file.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + Microsoft.Graph.Groups + ExchangeOnlineManagement + ActiveDirectory. Requested delegated Graph scopes: Group.Read.All, User.Read.All.",
    "notes": "General group-to-members review for one or many groups. Resolution order is Exchange distribution group, Entra ID group, then Active Directory group.",
    "startMode": "right-click",
    "completion": {
      "result": "Direct members of each group found in Exchange, Entra ID, or Active Directory.",
      "next": "Confirm the resolved group and system. Nested memberships are not a complete access review.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
  },
  "GET-USER-GROUPS.ps1": {
    "sourceSha256": "d0b71178ddca2eb793610f21d5f52266d454360ca848d7257ebb3347d6ec9bdd",
    "objective": "List the selected users' direct groups in AD and Entra.",
    "input": "User sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ActiveDirectory. Requested delegated Graph scopes: User.Read.All, Group.Read.All.",
    "notes": "User-to-groups review that independently checks Active Directory and Entra ID. Synced groups remain visible in Entra as [Synced] even when the same group is also observed in AD.",
    "startMode": "right-click",
    "completion": {
      "result": "Direct memberships shown separately for AD and Entra, with missing users and unavailable or failed checks clearly identified.",
      "next": "Follow up on systems that could not be checked. A synced group appearing in both systems is expected.",
      "blocked": "Review any partial or unsuccessful outcome. A missing user is different from a user with no groups."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
  },
  "GET-TENANT-GROUP-OWNERS.ps1": {
    "sourceSha256": "dc04a5c13230de80a767d325a6739c3df6240618d20e6419315cb96a43f224b0",
    "objective": "List group owners and identify groups without an assigned owner.",
    "input": "No group list needed. Reviews groups in the tenant you sign in to.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + Microsoft.Graph.Groups + ExchangeOnlineManagement. Requested delegated Graph scopes: Group.Read.All, User.Read.All.",
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
    ],
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "GET-MAILBOX-PERMISSIONS.ps1": {
    "sourceSha256": "76535edd6d3e922cc44decedba707203716788afa4bdabbf68579549a57752e6",
    "objective": "Review forwarding, delegated access, and inbox rules for selected mailboxes.",
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
    ],
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "GET-MAILBOX-FORWARDING.ps1": {
    "sourceSha256": "0e184a41bd351c391985118eb128eaefad0311ec691abe4933868e6af5a88d91",
    "objective": "Show where selected mailboxes forward incoming email.",
    "input": "Mailbox sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Focused read-only forwarding review for direct mailbox input or TXT/CSV lists. Checks mailbox-level forwarding plus visible/hidden inbox-rule forwarding and keeps query failures visible.",
    "startMode": "right-click",
    "completion": {
      "result": "Mailbox-level and inbox-rule forwarding for the requested mailboxes.",
      "next": "Confirm whether destinations are approved. A failed rule or mailbox query leaves the review incomplete.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "INVOKE-LITIGATION-HOLD.ps1": {
    "sourceSha256": "1ea2ff740e1f5eb24ba4aafa92636fce025ed90ffbc4050e80ce5aedcb3568fe",
    "objective": "Enable an unlimited litigation hold on approved mailboxes.",
    "input": "Mailbox sign-in names (UPNs), entered directly or in a TXT/CSV file.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement + rights to read and set mailbox Litigation Hold",
    "notes": "Reviews one or many mailboxes and changes only those not already compliant with LitigationHoldEnabled=True and Unlimited duration. Shows a full preview, requires typed HOLD confirmation, re-reads changed mailboxes, and can export evidence.",
    "startMode": "right-click",
    "completion": {
      "result": "Hold settings are read again for mailboxes changed to the requested unlimited hold.",
      "next": "Review failed or unconfirmed mailboxes and record the approved retention decision.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "GET-TRANSPORT-RULES-AUDIT.ps1": {
    "sourceSha256": "7c4ff63bee17b5669a05a76657f3cca0b5b3674b102ead014df742ae720c62ae",
    "objective": "Review mail flow rules for settings that need attention.",
    "input": "No rule list needed. Reviews mail-flow rules in the tenant you sign in to.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Tenant-wide read-only review of transport rules with flags for BCC, redirect, delete, quarantine, moderation, and other actions that can persist beyond mailbox remediation.",
    "startMode": "right-click",
    "completion": {
      "result": "Mail-flow rules with actions such as forwarding, redirection, deletion, or moderation.",
      "next": "Confirm the purpose of flagged rules before changing them; a flagged action can be legitimate.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "TEST-POWERSHELL-READINESS.ps1": {
    "sourceSha256": "fee19c4cac0b5638a8f6515eb4be8734135c997d63c4b21e7f71b33a8a21e314",
    "objective": "Check this computer for Microsoft 365 PowerShell prerequisites.",
    "input": "Checks the Windows computer and PowerShell session where you run it. No target list or tenant ID is needed.",
    "requires": "PowerShell 5.1+",
    "notes": "Checks PowerShell, execution policy, elevation, Git, WinGet, PowerShellGet, Graph, Exchange Online, optional AD tooling, and active M365 sessions.",
    "startMode": "right-click",
    "completion": {
      "result": "Readiness findings for this computer’s shell, modules, tools, and connections.",
      "next": "Fix the requirements needed by your selected script; a readiness pass does not verify that script’s runtime behavior.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
  },
  "GET-FOLDER-INVENTORY.ps1": {
    "sourceSha256": "218d4e788913c6a6d8d6578d8b1912cf7f68a8c4687ecaf6d557bbd4ea26cd60",
    "objective": "Review a folder's files, script signatures, and Git status.",
    "input": "Confirm the detected folder or enter a folder/repository path. Default folder depth: 10; includes files and signature checks.",
    "requires": "PowerShell 5.1+",
    "notes": "Maps any selected folder or repository without enforcing a fixed structure.",
    "startMode": "right-click",
    "completion": {
      "result": "A folder map, file counts, signatures, and available Git status.",
      "next": "Review warnings before cleanup. This tool does not reorganize files or enforce a kit layout.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
  },
  "INSTALL-M365-MODULES.ps1": {
    "sourceSha256": "6c5fb208fea47d9588354590817362336e644bc4887127f317d4816161c0b4a2",
    "objective": "Install or update the selected Microsoft 365 PowerShell modules.",
    "input": "Choose Graph, Exchange Online, or both when prompted.",
    "requires": "PowerShellGet / PSGallery",
    "notes": "Installs or updates Microsoft Graph and ExchangeOnlineManagement in CurrentUser scope. Does not connect to a tenant.",
    "startMode": "right-click",
    "completion": {
      "result": "Installation or update results for the selected PowerShell modules.",
      "next": "Resolve failed installs before running dependent tools. Tenant sign-in is still a separate step.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "TEST-SENSITIVE-DATA.ps1": {
    "sourceSha256": "594d18150acb832080f13776581f6d8d8d21d3addc7e14aa8aea017b76e9b69e",
    "objective": "Scan selected files for potentially sensitive information before sharing.",
    "input": "Enter a file or folder path; blank uses the current PowerShell working folder. Optional extra search terms.",
    "requires": "PowerShell 5.1+",
    "notes": "Checks source for information you may not want to publish. Reports only; never edits or sanitizes files.",
    "startMode": "right-click",
    "completion": {
      "result": "Files and text matching the selected sensitive-data patterns.",
      "next": "Review each match and the files themselves before sharing; no matches does not guarantee that all sensitive data was found.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
  },
  "RESET-M365-SESSION.ps1": {
    "sourceSha256": "a08270181dc4ac7ac0cb78fd8f651701a40ce25b668342a4e0a829fb09246809",
    "objective": "Disconnect Microsoft 365 services in the current PowerShell window.",
    "input": "No account list needed. Use the PowerShell window whose connections you want to close.",
    "requires": "Optional Microsoft.Graph / ExchangeOnlineManagement",
    "notes": "Disconnects Graph and Exchange Online, removes legacy Exchange PSSessions, and clears the local PowerShell error buffer.",
    "startMode": "terminal",
    "completion": {
      "result": "Graph/Exchange connections and stored errors are cleared in this PowerShell session where possible.",
      "next": "Reconnect in the intended tenant when ready. A new window does not inherit authenticated sessions.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "UPDATE-WINDOWS-APPS.ps1": {
    "sourceSha256": "32fcfc1c298460301dc5fe7841bb5bddb768691e23f7c9f28270c5396349c3c3",
    "objective": "Review and update installed applications using WinGet.",
    "input": "Choose review-only mode or approve updates to eligible apps on this computer.",
    "requires": "WinGet",
    "notes": "Reviews available WinGet upgrades, confirms before changes, updates normally eligible packages, then shows remaining updates.",
    "startMode": "right-click",
    "completion": {
      "result": "Available updates are listed; approved updates run and remaining upgrades are shown.",
      "next": "Review failed or remaining upgrades and check the affected applications with the user.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "GET-USER-SECURITY-SNAPSHOT.ps1": {
    "sourceSha256": "b9d8d41d6fe83eb0c5b3c8cb6d71989719d8622bc359116fc20618814399cff6",
    "objective": "Review one user's account, authentication, access, and recent sign-ins.",
    "input": "One user sign-in name (UPN).",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: User.Read.All, Directory.Read.All, UserAuthenticationMethod.Read.All, AuditLog.Read.All.",
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
    ],
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "sourceSha256": "342829ae9c8df76225bdee4e0c76776aabb76a43a3c5756363a6add984ca0666",
    "objective": "Get a broad overview of the tenant's security settings and review areas.",
    "input": "Reviews the tenant you sign in to; no user list needed. Default old-sign-in threshold: 90 days.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Organization.Read.All, User.Read.All, AuditLog.Read.All, Directory.Read.All, RoleManagement.Read.Directory, Policy.Read.ConditionalAccess, DelegatedPermissionGrant.Read.All.",
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
    ],
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "GET-ROOM-RESOURCE-ACCESS.ps1": {
    "sourceSha256": "476e8e8458b73432ec3c1e5d90be596b6472cece0e43c79cddc4b1de1693e1ad",
    "objective": "Review delegated access and booking permissions for resource mailboxes.",
    "input": "A real room or equipment mailbox address in the client tenant; separate multiple addresses with commas. A security group is not a mailbox.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Focused review of room and equipment mailbox Full Access, in-policy booking principals, and resource delegates.",
    "startMode": "right-click",
    "completion": {
      "result": "Mailbox access, automatic booking permissions, and booking approvers are listed.",
      "next": "Confirm access and booking behavior with the resource owner before changing permissions.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "sourceSha256": "90eadb894e2aa8ac36f62047a4c4aadcac67aa468c8bbbf583ec0992e6fc6e9c",
    "objective": "Review mailbox forwarding and delegated access across the tenant.",
    "input": "No mailbox list needed. Reviews user and shared mailboxes in the tenant you sign in to.",
    "requires": "Exchange Online PowerShell and access to the mailbox or tenant settings being reviewed. Technical requirements: ExchangeOnlineManagement",
    "notes": "Tenant-wide review of user/shared mailbox forwarding, Full Access, Send As, and Send on Behalf with query failures kept visible.",
    "startMode": "right-click",
    "completion": {
      "result": "Forwarding and supported mailbox-access permissions across user and shared mailboxes.",
      "next": "Review unexpected access and failed mailbox queries; findings alone do not authorize removal.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": [
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights."
    ]
  },
  "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "sourceSha256": "c50e6a31dbf37dea44f651d4cfdced99ba4f3ce053a8ec3e75edb1a8f4fb504d",
    "objective": "Remove approved mailbox access held by one disabled user.",
    "input": "The disabled user’s exact sign-in name (UPN).",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication + ExchangeOnlineManagement + ActiveDirectory. Requested delegated Graph scopes: User.Read.All, Directory.Read.All.",
    "notes": "Post-offboarding cleanup that validates disabled state at the authoritative identity source, scans Exchange recipients for direct Full Access, Send As, and Send on Behalf rights, shows the exact removal plan, requires typed approval, and verifies each requested removal.",
    "startMode": "right-click",
    "completion": {
      "result": "Selected Full Access, Send As, and Send on Behalf removals are checked after approval.",
      "next": "Review each failed removal and remaining access before closing offboarding.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.",
      "Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights.",
      "AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights."
    ]
  },
  "GET-TENANT-DRIFT-REVIEW.ps1": {
    "sourceSha256": "f5f1fdd5b2d6739ecc07989244e5da3f36811d1589109d4e7892609e937abfc2",
    "objective": "Compare tenant settings with a saved baseline and review changes.",
    "input": "Optional local JSON comparison file (baseline). By default, uses a tenant-specific file in the script’s BASELINES folder; offers to create one when missing.",
    "requires": "Modules used (depending on selected branch): Microsoft.Graph.Authentication. Requested delegated Graph scopes: Directory.Read.All, Application.Read.All, Policy.Read.All, RoleAssignmentSchedule.Read.Directory, RoleEligibilitySchedule.Read.Directory.",
    "notes": "Tenant configuration drift detector. Tenant operations are read-only; the only state change is creating or replacing a local JSON baseline after explicit approval, with readback verification.",
    "startMode": "right-click",
    "completion": {
      "result": "Changes from the saved tenant baseline, or a newly approved local baseline, are reported.",
      "next": "Investigate differences before replacing the baseline; saving current settings does not make them approved.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result."
    ]
  },
  "connection-patterns.md": {
    "sourceSha256": "f186db47a6da071169e2ea0c1213a527f2f9eebbc78a4da2d1121db9fa387bc6",
    "notes": "Reusable Graph, Exchange Online, and hybrid connection guidance without environment-specific identifiers.",
    "objective": "Choose the right Graph, Exchange Online, or hybrid connection approach.",
    "permissionNotes": []
  },
  "OPERATING-STANDARDS.md": {
    "sourceSha256": "d8da345212ab7c9b4801b9e5255930b34651d33bc41dab6f6d37881baf617815",
    "notes": "Top-level project decision contract for canonical sources, 1-to-N input, safety, authentication, QA, release, and handoff/rebuild decisions.",
    "objective": "Read the project rules for building, reviewing, and releasing tools.",
    "permissionNotes": []
  },
  "field-kit-build-standard.md": {
    "sourceSha256": "b6efdedf97856b7c96c51e73ccd5ee29ffecd6ea68c4b15895b70bb07eb244fa",
    "notes": "Locked baseline for FIELD // KIT visual design, navigation, sorting, card behavior, source publication, and release validation.",
    "objective": "Read the agreed site layout, card, and publishing standards.",
    "permissionNotes": []
  },
  "lessons-learned.md": {
    "sourceSha256": "f6bc6f62b00d32ef007589d931d6ee05e63944738a5df3d57a01344193c7e00f",
    "notes": "Small reusable rules captured from recurring PowerShell, authentication, hybrid, output, and publishing failures.",
    "objective": "Check lessons from earlier scripting and publishing problems.",
    "permissionNotes": []
  },
  "powershell-standards.md": {
    "sourceSha256": "1b431435c30764ca2ff5e0bdbf81deed62d0fcd0bbd5cd6b5ba3a51b8e514fd0",
    "notes": "Script implementation baseline for interactive FIELD // KIT PowerShell tools.",
    "objective": "Read the coding, safety, and output standards for these PowerShell tools.",
    "permissionNotes": []
  },
  "publishing-checklist.md": {
    "sourceSha256": "7823173f60c3567e9dcb2da26a8a021f4c23b23d9279223a93910153e99c24bc",
    "notes": "Final public-release gate for source, secrets, proprietary context, operational behavior, and catalog metadata.",
    "objective": "Check source, sensitive data, behavior, and card details before release.",
    "permissionNotes": []
  },
  "script-review-checklist.md": {
    "sourceSha256": "8ad6e773bf7edd85abc81a3f24ecd674c7a0ffc8d72e2638b3aafe6a9a98155e",
    "notes": "Reusable pre-approval review covering syntax, structure, authentication, data handling, safety, output, and publication.",
    "objective": "Review a script’s syntax, access, safety, and output before approval.",
    "permissionNotes": []
  },
  "skills.md": {
    "sourceSha256": "69280cbd4203c3d96717d7f0f2343ed0566eb8ea2d5c9e2222eb6b7441217f92",
    "notes": "Repeatable workflows for building, reviewing, aligning, troubleshooting, publishing, and handing off FIELD // KIT work.",
    "objective": "Find repeatable steps for building, reviewing, troubleshooting, and publishing tools.",
    "permissionNotes": []
  },
  "script-template-guide.md": {
    "sourceSha256": "49204f5c543f7a3a7a3ac0372d6d8e9111666b2d20824b68ff544c030f70ab30",
    "notes": "Structural guide for single-objective tools, multi-section reviews, and connected workflows.",
    "objective": "Choose a script structure and follow the input and output patterns.",
    "permissionNotes": []
  },
  "nato-phonetic-alphabet.md": {
    "sourceSha256": "c9dec1a66a3530972991663504e4c54e895e87093a43081404edfdf3da7288c7",
    "notes": "A-to-Z NATO spelling alphabet reference for clear verbal communication.",
    "objective": "Use standard spelling words for clear verbal communication.",
    "permissionNotes": []
  },
  "git-handoff.ps1": {
    "sourceSha256": "de09cbd42d120d932969dc229fa5437c7770fcdf6aed331f364acf6bec6c6531",
    "objective": "Save a screened snapshot of the current Git project for handoff.",
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
    },
    "permissionNotes": []
  },
  "PROJECT-HANDOFF.md": {
    "sourceSha256": "b750357e69da53ab3c14380334b2ec38670b3ea04d20144681dfd8a0fe24708c",
    "notes": "Canonical project handoff template for source of truth, local/remote state, locked decisions, validation status, limitations, and next-session startup.",
    "objective": "Find the current project state, decisions, limits, and next steps.",
    "permissionNotes": []
  },
  "git-repo.ps1": {
    "sourceSha256": "3bcd5f6b61c9b5b24d3d8adcaa22f584e80bdfe0b612c9a53cacf9d03125b78c",
    "objective": "Review, pull, or push changes in the selected Git repository.",
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
    },
    "permissionNotes": []
  },
  "git-security.ps1": {
    "sourceSha256": "8082019f51b75c2184dcf74985cc73c80eb31135e8cd2ad3b9aaab5a73ea8352",
    "objective": "Review a GitHub security-log export for unfamiliar access and activity.",
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
    },
    "permissionNotes": []
  },
  "set-execution.ps1": {
    "sourceSha256": "4379e986662f2a80092938916ac5d2509fc5b01cb391d95e20b58c91b16ad294",
    "objective": "Set local execution policy and unblock scripts beside this file.",
    "notes": "Explicit local setup utility. Checks effective execution policy, sets CurrentUser RemoteSigned only when needed and not managed, and unblocks adjacent .ps1 files. Run only in a folder of scripts you have reviewed. Does not sign files or install modules. Colored result; Enter to exit.",
    "input": "Place this file beside only the reviewed .ps1 files you intend to unblock.",
    "startMode": "right-click",
    "requires": "PowerShell on this computer.",
    "completion": {
      "result": "A local setup result reports policy or unblock problems for adjacent scripts.",
      "next": "Resolve managed-policy blocks through the approved process; do not bypass them or unblock unreviewed files.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "git-tools.md": {
    "sourceSha256": "5aa1d822aa27dd41c43bab2554b87d925b1e1eb5fd41fc22f44c12d4cbfae21a",
    "notes": "Commands and operating boundaries for the standalone repository, security, handoff and execution-setup helpers.",
    "permissionNotes": []
  },
  "attractor.ps1": {
    "sourceSha256": "1268680342075976f80599213dd97d25abc2af741a07a7f5de2ceab2c2ba4cc6",
    "objective": "Run a floating fractal animation with a clock.",
    "notes": "Slowly evolving Clifford attractor with floating branding and a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "input": "No input needed. Use an interactive terminal; Ctrl+C stops the animation.",
    "startMode": "terminal",
    "requires": "PowerShell on this computer; an interactive terminal for the display.",
    "completion": {
      "result": "The terminal animation runs until stopped.",
      "next": "Press Ctrl+C to stop. It is a display effect, not a screen lock.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    },
    "permissionNotes": []
  },
  "rain.ps1": {
    "sourceSha256": "f793a1a68a8245527597522077f40dda3eeb209bf9c6ad1164f0dde5ef9daf96",
    "objective": "Run animated terminal rain with a floating label and clock.",
    "notes": "Dense neon character rain, intermittent signal effects and a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "input": "No input needed. Use an interactive terminal; Ctrl+C stops the animation.",
    "startMode": "terminal",
    "requires": "PowerShell on this computer; an interactive terminal for the display.",
    "completion": {
      "result": "The terminal rain animation runs until stopped.",
      "next": "Press Ctrl+C to stop. It is a display effect, not a screen lock.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    },
    "permissionNotes": []
  },
  "static.ps1": {
    "sourceSha256": "4aa3ae630d9631f11d110f78925c6e112508b3ccc7ba703f833537bb3c9394e0",
    "objective": "Run animated terminal static with a floating label and clock.",
    "notes": "Sparse pulsing dots, subtle static and drifting branding with a 24-hour clock. Run in an interactive terminal, ideally 60 columns by 22 rows or larger. Ctrl+C stops it. Cosmetic terminal effects only; no network access or file writes. Not a screen lock.",
    "input": "No input needed. Use an interactive terminal; Ctrl+C stops the animation.",
    "startMode": "terminal",
    "requires": "PowerShell on this computer; an interactive terminal for the display.",
    "completion": {
      "result": "The terminal dots/static animation runs until stopped.",
      "next": "Press Ctrl+C to stop. It is a display effect, not a screen lock.",
      "blocked": "If the display fails, check PowerShell and terminal support before trying again."
    },
    "permissionNotes": []
  },
  "SIGN-FOLDER-SCRIPTS.ps1": {
    "sourceSha256": "2890218ee6951f81e46e0dd5cbc5b4ed38b80ccce031d0b04ad9c3561e654851",
    "objective": "Sign scripts in a selected folder with a code-signing certificate.",
    "input": "Folder of reviewed scripts and a signing certificate; the script can offer to create a self-signed certificate.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Uses an existing certificate or creates a local self-signed certificate. Optional trust adds it to the current-user TrustedPublisher and Root stores. Shows files and asks before signing; -ForceResign replaces existing signatures.",
    "startMode": "right-click",
    "completion": {
      "result": "Signing results are reported for the selected scripts.",
      "next": "Review failed signatures and verify trust on the computer that will run the scripts; signing does not prove code is safe.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "INVOKE-FILE-INVENTORY.ps1": {
    "sourceSha256": "435f354240c3178c5def5a4b2faaaaa013a7ef0d99f07fcf9170e69801b13279",
    "objective": "Compare script versions, signatures, and duplicate content in a folder.",
    "requires": "Windows PowerShell 5.1+ or PowerShell 7",
    "notes": "Groups files into Active, Testing, and Archive; compares duplicate filenames by SHA256. Optional CSV export includes local paths and signer details. Root defaults to C:\\Field-Kit; keep reports private.",
    "input": "Working folder path; default C:\\Field-Kit. Choose an output folder only if exporting.",
    "startMode": "right-click",
    "completion": {
      "result": "Duplicate-name, content-hash, signature, and working-copy findings; optional CSV files are saved when requested.",
      "next": "Review file differences before deleting duplicates; keep exported local paths and signer information private.",
      "blocked": "Resolve failed or unavailable checks before treating the review as complete."
    },
    "permissionNotes": []
  },
  "MANAGE-CERT-SIGNATURES.ps1": {
    "sourceSha256": "d28176159f671ed1fe1e521f422a89f8de92f5ec032067e16f46156549d683fb",
    "objective": "Create, review, export, import, or trust script-signing certificates.",
    "input": "Choose a certificate action. Have the certificate/file path and password ready when importing or exporting a private key.",
    "requires": "Windows PowerShell 5.1 or later",
    "notes": "Public .cer files share trust. Private .pfx files include the signing key and require explicit confirmation and a password. Lists certificates installed for the current user; select your own signing identity.",
    "startMode": "right-click",
    "completion": {
      "result": "The selected certificate action reports its result and any output path.",
      "next": "Check the intended store or output file. Keep PFX files and their passwords private; trust changes need separate review.",
      "blocked": "A cancelled, failed, or unconfirmed action is not complete. Review the results before retrying."
    },
    "permissionNotes": []
  },
  "PREPARE-FIELD-KIT.ps1": {
    "sourceSha256": "8b555611dffc223f909b9e13fa158f0daf472703ac9d42dc8d72d161cd430372",
    "objective": "Check this computer and install missing Microsoft 365 PowerShell modules.",
    "input": "Current Windows account; Graph, Exchange or both",
    "requires": "Windows PowerShell 5.1 or PowerShell 7.4+; PowerShellGet for installation.",
    "startMode": "right-click",
    "completion": {
      "result": "READY, NOT READY or CANCELLED for the selected local prerequisites.",
      "next": "Close setup and start one selected tool in a fresh PowerShell window under the same Windows account and edition.",
      "blocked": "Resolve missing or incompatible prerequisites before running dependent tools. Setup does not prove customer access."
    },
    "checks": [
      "Checks selected module versions",
      "Verifies module imports",
      "Offers missing prerequisites only",
      "No customer sign-in"
    ],
    "permissionNotes": []
  },
  "START-HERE.md": {
    "sourceSha256": "ceaa8b9219d977a88e2f45f3af18c160671fb76812ba714a4dc437e51e9171f0",
    "objective": "Prepare the support computer and run one approved workflow at a time.",
    "input": "Customer support computer and approved operator account",
    "requires": "Access to the approved customer support computer.",
    "permissionNotes": []
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-GROUPS.ps1"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
  },
  "Find User By Exact Display Name": {
    "code": "$Name = \"Jane Doe\"\nGet-MgUser -Filter \"displayName eq '$Name'\" -Property Id,DisplayName,UserPrincipalName,AccountEnabled |\n  Select-Object Id,DisplayName,UserPrincipalName,AccountEnabled",
    "useFor": "Find Entra users with the exact display name you enter; more than one match is possible.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.Read.All.",
    "input": "Replace command examples with your exact display name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Cloud account review",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an approved member account with directory-read access; tenant restrictions can require a supported reader/custom role."
    ]
  },
  "Get User By Upn": {
    "code": "Get-MgUser -UserId \"user@domain.com\" -Property Id,DisplayName,UserPrincipalName,AccountEnabled,OnPremisesSyncEnabled |\n  Select-Object Id,DisplayName,UserPrincipalName,AccountEnabled,OnPremisesSyncEnabled",
    "useFor": "Show the selected Entra user’s account status and sync setting.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Cloud account review",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an approved member account with directory-read access; tenant restrictions can require a supported reader/custom role."
    ]
  },
  "Show Assigned Licenses": {
    "code": "Get-MgUserLicenseDetail -UserId \"user@domain.com\" |\n  Select-Object SkuPartNumber,SkuId",
    "useFor": "Show the user’s assigned license codes and IDs.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"LicenseAssignment.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: LicenseAssignment.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Cloud account review",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Directory Readers, License Administrator, or another supported role/custom equivalent."
    ]
  },
  "Show Manager": {
    "code": "Invoke-MgGraphRequest -Method GET -Uri \"https://graph.microsoft.com/v1.0/users/user@domain.com/manager?`$select=displayName,userPrincipalName\" |\n  Select-Object displayName,userPrincipalName",
    "useFor": "Show the user’s recorded manager.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication. Delegated Graph scopes: User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Cloud account review",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an approved member account with directory-read access; tenant restrictions can require a supported reader/custom role."
    ]
  },
  "Show Password Last Changed And Age": {
    "code": "$u = Get-MgUser -UserId \"user@domain.com\" -Property UserPrincipalName,LastPasswordChangeDateTime\n[pscustomobject]@{\n  User = $u.UserPrincipalName\n  LastPasswordChange = $u.LastPasswordChangeDateTime\n  PasswordAgeDays = if($u.LastPasswordChangeDateTime){ [math]::Floor(((Get-Date) - $u.LastPasswordChangeDateTime).TotalDays) } else { $null }\n}",
    "useFor": "Show the recorded password change date and calculated age.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Cloud account review",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an approved member account with directory-read access; tenant restrictions can require a supported reader/custom role."
    ]
  },
  "Show Sync Source": {
    "code": "Get-MgUser -UserId \"user@domain.com\" -Property UserPrincipalName,OnPremisesSyncEnabled,OnPremisesLastSyncDateTime,OnPremisesDomainName,OnPremisesSamAccountName |\n  Select-Object UserPrincipalName,OnPremisesSyncEnabled,OnPremisesLastSyncDateTime,OnPremisesDomainName,OnPremisesSamAccountName",
    "useFor": "Show whether the user is synced from Active Directory and the last recorded sync.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Cloud account review",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an approved member account with directory-read access; tenant restrictions can require a supported reader/custom role."
    ]
  },
  "Delete Cloud User": {
    "code": "& {\n    $Target = (Read-Host 'Exact cloud user UPN; blank cancels').Trim()\n    if (-not $Target) { return }\n    $User = Get-MgUser -UserId $Target -ErrorAction Stop\n    $User | Format-List Id,DisplayName,UserPrincipalName | Out-Host\n    if ((Read-Host \"Type DELETE $($User.UserPrincipalName) to approve\").Trim() -cne \"DELETE $($User.UserPrincipalName)\") { Write-Host 'Cancelled; no changes.'; return }\n    Remove-MgUser -UserId $User.Id -ErrorAction Stop\n    Write-Host 'Deletion request completed; independently verify absence and retention requirements.'\n}",
    "useFor": "Delete the selected Entra user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification."
    ],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.ReadWrite.All.",
    "input": "Exact cloud user UPN at the prompt; review the resolved user, then type DELETE followed by the displayed UPN.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Cloud account review",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: User Administrator or another supported role/custom equivalent; privileged target restrictions apply.",
      "This preparation does not authorize privileged administrator deletion. That scenario additionally requires Directory.AccessAsUser.All and a higher supported operator role; do not add those rights by default."
    ]
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
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.EnableDisableAccount.All, User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: User Administrator for supported targets; privileged target accounts require a higher supported role. Do not assume consent alone authorizes the target."
    ]
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
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.EnableDisableAccount.All, User.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: User Administrator for supported targets; privileged target accounts require a higher supported role. Do not assume consent alone authorizes the target."
    ]
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
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users.Actions. Delegated Graph scopes: User.RevokeSessions.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use a role permitted to revoke sessions for the target; privileged targets have additional role restrictions."
    ]
  },
  "Show Cached Tickets": {
    "code": "klist",
    "useFor": "Show cached Kerberos tickets for the current Windows session.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Locally Logged-On Users",
      "command:Show SMB Sessions",
      "command:Show SMB Shares"
    ],
    "relationshipFamily": "Windows sessions and shares",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Locally Logged-On Users",
      "command:Show SMB Sessions",
      "command:Show SMB Shares"
    ],
    "relationshipFamily": "Windows sessions and shares",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Local Users",
      "command:Identity and Privileges",
      "command:Local Account Details"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
  },
  "Show Local Users": {
    "code": "Get-LocalUser |\n  Select-Object Name,Enabled,LastLogon,PasswordExpires,UserMayChangePassword",
    "useFor": "List local Windows users and their account settings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Local Administrators",
      "command:Identity and Privileges",
      "command:Local Account Details"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
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
    "input": "Account to add or remove; replace DOMAIN\\User.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
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
    "input": "Account to add or remove; replace DOMAIN\\User.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
  },
  "Show All Authentication Methods For One User": {
    "code": "Get-MgUserAuthenticationMethod -UserId \"user@domain.com\" |\n  Select-Object Id,@{N=\"Type\";E={$_.AdditionalProperties.'@odata.type'}}",
    "useFor": "List the user’s registered authentication methods and IDs.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"UserAuthenticationMethod.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Identity.SignIns. Delegated Graph scopes: UserAuthenticationMethod.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1",
      "command:Show Registration Status For One User"
    ],
    "relationshipFamily": "MFA methods",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reading another user’s methods requires Global Reader, Authentication Administrator, or Privileged Authentication Administrator (or supported custom equivalent). Target-role restrictions apply; phone numbers may be masked."
    ]
  },
  "Show Microsoft Authenticator Methods": {
    "code": "Get-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId \"user@domain.com\" |\n  Select-Object Id,DisplayName,DeviceTag,PhoneAppVersion",
    "useFor": "List the user’s registered Microsoft Authenticator methods.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"UserAuthMethod-MicrosoftAuthApp.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Identity.SignIns. Delegated Graph scopes: UserAuthMethod-MicrosoftAuthApp.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1",
      "command:Show All Authentication Methods For One User"
    ],
    "relationshipFamily": "MFA methods",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reading another user’s methods requires Global Reader, Authentication Administrator, or Privileged Authentication Administrator (or supported custom equivalent). Target-role restrictions apply; phone numbers may be masked."
    ]
  },
  "Show Phone Methods": {
    "code": "Get-MgUserAuthenticationPhoneMethod -UserId \"user@domain.com\" |\n  Select-Object Id,PhoneNumber,PhoneType,SmsSignInState",
    "useFor": "List the user’s registered phone authentication methods.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"UserAuthMethod-Phone.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Identity.SignIns. Delegated Graph scopes: UserAuthMethod-Phone.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1",
      "command:Show All Authentication Methods For One User"
    ],
    "relationshipFamily": "MFA methods",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reading another user’s methods requires Global Reader, Authentication Administrator, or Privileged Authentication Administrator (or supported custom equivalent). Target-role restrictions apply; phone numbers may be masked."
    ]
  },
  "Show Registration Status For One User": {
    "code": "Get-MgReportAuthenticationMethodUserRegistrationDetail -Filter \"userPrincipalName eq 'user@domain.com'\" |\n  Select-Object UserPrincipalName,IsMfaRegistered,IsMfaCapable,DefaultMfaMethod,MethodsRegistered",
    "useFor": "Show the user’s MFA registration report.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Reports. Delegated Graph scopes: AuditLog.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1",
      "command:Show All Authentication Methods For One User"
    ],
    "relationshipFamily": "MFA methods",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result.",
      "The registration report does not support disabled users."
    ]
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
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Identity.SignIns. Delegated Graph scopes: UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; record ID from a prior lookup. Review all target values before running. Method ID from the user’s authentication-method lookup; choose the matching method type.",
    "related": [
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1",
      "command:Show All Authentication Methods For One User"
    ],
    "relationshipFamily": "MFA methods",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Authentication Administrator for supported nonprivileged targets; Privileged Authentication Administrator for privileged targets. Confirm the target-role restrictions before removal."
    ]
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
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Identity.SignIns. Delegated Graph scopes: UserAuthenticationMethod.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; record ID from a prior lookup. Review all target values before running. Method ID from the user’s authentication-method lookup; choose the matching method type.",
    "related": [
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1",
      "command:Show All Authentication Methods For One User"
    ],
    "relationshipFamily": "MFA methods",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Authentication Administrator for supported nonprivileged targets; Privileged Authentication Administrator for privileged targets. Confirm the target-role restrictions before removal."
    ]
  },
  "Show Delegated Grants For One User": {
    "code": "Get-MgUserOauth2PermissionGrant -UserId \"user@domain.com\" -All |\n  Select-Object Id,ClientId,ConsentType,Scope",
    "useFor": "List app permissions approved on behalf of this user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"Directory.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: Directory.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-SERVICE-PRINCIPAL-OWNERS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "App access",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Directory Readers or another supported reader/custom role.",
      "Lists this user’s grants, not tenant-wide consent grants."
    ]
  },
  "Show Potentially High-Impact Delegated Scopes": {
    "code": "Get-MgUserOauth2PermissionGrant -UserId \"user@domain.com\" -All |\n  Where-Object {\n    $_.Scope -match '(^| )(offline_access|User.ReadWrite|Mail\\.|MailboxSettings\\.|Files\\.|Sites\\.|Calendars\\.|Contacts\\.|Directory\\.)' -or\n    $_.Scope -match '\\.All($| )'\n  } |\n  Select-Object Id,ClientId,ConsentType,Scope",
    "useFor": "Find this user’s approved app permissions that match the listed high-impact patterns.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"Directory.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: Directory.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-SERVICE-PRINCIPAL-OWNERS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "App access",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Directory Readers or another supported reader/custom role.",
      "Lists this user’s grants, not tenant-wide consent grants."
    ]
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
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Applications. Delegated Graph scopes: DelegatedPermissionGrant.ReadWrite.All.",
    "input": "Replace command examples with your record ID from a prior lookup. Review all target values before running. Grant ID from the app-permission lookup, not the app ID.",
    "related": [
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-SERVICE-PRINCIPAL-OWNERS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "App access",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Cloud Application Administrator, Application Administrator, or another supported role/custom equivalent."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-DISTRIBUTION-GROUP-MEMBERS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1",
      "command:Show Distribution Group Owners"
    ],
    "relationshipFamily": "Distribution groups",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-DISTRIBUTION-GROUP-MEMBERS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1",
      "GET-GROUP-MEMBERS.ps1"
    ],
    "relationshipFamily": "Distribution groups",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-DISTRIBUTION-GROUP-MEMBERS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1",
      "command:Show Distribution Group Owners"
    ],
    "relationshipFamily": "Distribution groups",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Remove Distribution Group Member": {
    "code": "$Group = \"group@domain.com\"\n$Member = \"user@domain.com\"\nRemove-DistributionGroupMember -Identity $Group -Member $Member -Confirm:$true",
    "useFor": "Remove one user from the selected distribution group.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Requests native confirmation before the selected change. Review the actual target in the command and confirmation prompt.",
      "Command completion alone does not verify the resulting state."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-DISTRIBUTION-GROUP-MEMBERS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1",
      "command:Show Distribution Group Owners"
    ],
    "relationshipFamily": "Distribution groups",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name.",
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "command:Show AD User Group Memberships"
    ],
    "relationshipFamily": "AD groups",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "command:Show AD Group Members"
    ],
    "relationshipFamily": "AD groups",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name; group name or object ID. Review all target values before running. Exact target group name.",
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "command:Show AD Group Members"
    ],
    "relationshipFamily": "AD groups",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
  },
  "Remove User from AD Group": {
    "code": "$Group = \"Group Name\"\nRemove-ADGroupMember -Identity $Group -Members \"username\" -Confirm:$true",
    "useFor": "Remove the user from the selected Active Directory group.",
    "connectFirst": [
      "Import-Module ActiveDirectory"
    ],
    "checks": [],
    "guards": [
      "Requests native confirmation before the selected change. Review the actual target in the command and confirmation prompt.",
      "Command completion alone does not verify the resulting state."
    ],
    "requires": "ActiveDirectory PowerShell module and a connection to the domain. Your Windows account needs permission to change the selected objects.",
    "input": "Replace command examples with your target account name; group name or object ID. Review all target values before running. Exact target group name.",
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "command:Show AD Group Members"
    ],
    "relationshipFamily": "AD groups",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
  },
  "Find Exact Group": {
    "code": "$GroupName = \"Group Name\"\nGet-MgGroup -Filter \"displayName eq '$GroupName'\" -Property Id,DisplayName,Mail,GroupTypes,SecurityEnabled,MailEnabled |\n  Select-Object Id,DisplayName,Mail,GroupTypes,SecurityEnabled,MailEnabled",
    "useFor": "Find Entra groups with the exact display name; more than one match is possible.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"GroupMember.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Groups. Delegated Graph scopes: GroupMember.Read.All.",
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name.",
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "relationshipFamily": "Entra groups",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an approved member account with directory-read access; tenant restrictions can require a supported reader/custom role."
    ]
  },
  "Show Entra Group Direct Members": {
    "code": "Get-MgGroupMember -GroupId \"GROUP-OBJECT-ID\" -All |\n  Select-Object Id,@{N=\"Type\";E={$_.AdditionalProperties.'@odata.type'}},@{N=\"DisplayName\";E={$_.AdditionalProperties.displayName}},@{N=\"UPN\";E={$_.AdditionalProperties.userPrincipalName}}",
    "useFor": "List direct members of an Entra group by its object ID.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"GroupMember.Read.All\",\"User.ReadBasic.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Groups. Delegated Graph scopes: GroupMember.Read.All, User.ReadBasic.All.",
    "input": "Replace command examples with your group name or object ID; target user UPN. Review all target values before running. Group object ID from the group lookup.",
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "relationshipFamily": "Entra groups",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an authorized group owner/member or a supported directory-reader/custom role. Hidden memberships require separately approved Member.Read.Hidden access; do not add it by default. Non-user objects can return limited properties.",
      "GroupMember.Read.All is retained as a documented read-only permission; User.ReadBasic.All supplies user names and UPNs."
    ]
  },
  "Show Entra Group Owners": {
    "code": "Get-MgGroupOwner -GroupId \"GROUP-OBJECT-ID\" -All |\n  Select-Object Id,@{N=\"DisplayName\";E={$_.AdditionalProperties.displayName}},@{N=\"UPN\";E={$_.AdditionalProperties.userPrincipalName}}",
    "useFor": "List owners of an Entra group by its object ID.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"GroupMember.Read.All\",\"User.ReadBasic.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Groups. Delegated Graph scopes: GroupMember.Read.All, User.ReadBasic.All.",
    "input": "Replace command examples with your group name or object ID; target user UPN. Review all target values before running. Group object ID from the group lookup.",
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "relationshipFamily": "Entra groups",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an authorized group owner/member or a supported directory-reader/custom role. Hidden memberships require separately approved Member.Read.Hidden access; do not add it by default. Non-user objects can return limited properties."
    ]
  },
  "Show Entra User Group Memberships": {
    "code": "Get-MgUserMemberOf -UserId \"user@domain.com\" -All |\n  Select-Object Id,@{N=\"Type\";E={$_.AdditionalProperties.'@odata.type'}},@{N=\"DisplayName\";E={$_.AdditionalProperties.displayName}}",
    "useFor": "List the Entra directory objects this user belongs to.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.Read.All\",\"GroupMember.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Users. Delegated Graph scopes: User.Read.All, GroupMember.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "relationshipFamily": "Entra groups",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Use an authorized group owner/member or a supported directory-reader/custom role. Hidden memberships require separately approved Member.Read.Hidden access; do not add it by default. Non-user objects can return limited properties.",
      "Cloud-only lookup: the ActiveDirectory module is not required."
    ]
  },
  "Add User to Entra Group": {
    "code": "$UserId = (Get-MgUser -UserId \"user@domain.com\").Id\nNew-MgGroupMemberByRef -GroupId \"GROUP-OBJECT-ID\" -OdataId \"https://graph.microsoft.com/v1.0/directoryObjects/$UserId\"",
    "useFor": "Add the user to the selected Entra group.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.ReadBasic.All\",\"GroupMember.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Groups + Microsoft.Graph.Users. Delegated Graph scopes: User.ReadBasic.All, GroupMember.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; group name or object ID. Review all target values before running. Group object ID from the group lookup.",
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "relationshipFamily": "Entra groups",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Authorized group owner or Groups Administrator (or supported custom equivalent).",
      "Role-assignable groups additionally require RoleManagement.ReadWrite.Directory and Privileged Role Administrator; not requested by default. Dynamic membership cannot be managed as direct membership."
    ]
  },
  "Remove User from Entra Group": {
    "code": "$UserId = (Get-MgUser -UserId \"user@domain.com\").Id\nRemove-MgGroupMemberByRef -GroupId \"GROUP-OBJECT-ID\" -DirectoryObjectId $UserId",
    "useFor": "Remove the user’s direct membership from the selected Entra group.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.ReadBasic.All\",\"GroupMember.ReadWrite.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [
      "Review the full command and target before pasting; it can make changes immediately."
    ],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Groups + Microsoft.Graph.Users. Delegated Graph scopes: User.ReadBasic.All, GroupMember.ReadWrite.All.",
    "input": "Replace command examples with your target user, mailbox or group address; group name or object ID. Review all target values before running. Group object ID from the group lookup.",
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "relationshipFamily": "Entra groups",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Authorized group owner or Groups Administrator (or supported custom equivalent).",
      "Role-assignable groups additionally require RoleManagement.ReadWrite.Directory and Privileged Role Administrator; not requested by default. Dynamic membership cannot be managed as direct membership."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "command:Show Mailbox Summary",
      "GET-MAILBOX-PERMISSIONS.ps1"
    ],
    "relationshipFamily": "Mailbox protocols",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "command:Show Mailbox Protocol State",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "command:Show Mailbox Summary"
    ],
    "relationshipFamily": "Mailbox protocols",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "command:Show Mailbox Protocol State",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "command:Show Mailbox Summary"
    ],
    "relationshipFamily": "Mailbox protocols",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Remove Mailbox Full Access Delegate": {
    "code": "$Delegate = \"delegate@domain.com\"\nRemove-MailboxPermission -Identity \"user@domain.com\" -User $Delegate -AccessRights FullAccess -Confirm:$true",
    "useFor": "Remove the selected delegate’s Full Access permission.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Requests native confirmation before the selected change. Review the actual target in the command and confirmation prompt.",
      "Command completion alone does not verify the resulting state."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Remove Mailbox Send As Delegate": {
    "code": "$Delegate = \"delegate@domain.com\"\nRemove-RecipientPermission -Identity \"user@domain.com\" -Trustee $Delegate -AccessRights SendAs -Confirm:$true",
    "useFor": "Remove the selected delegate’s Send As permission.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Requests native confirmation before the selected change. Review the actual target in the command and confirmation prompt.",
      "Command completion alone does not verify the resulting state."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "Mailbox access and forwarding",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running.",
    "related": [
      "GET-TRANSPORT-RULES-AUDIT.ps1",
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1"
    ],
    "relationshipFamily": "Mail transport",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter.",
    "related": [
      "GET-TRANSPORT-RULES-AUDIT.ps1",
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1"
    ],
    "relationshipFamily": "Mail transport",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-FORWARDING.ps1"
    ],
    "relationshipFamily": "Inbox rules",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-FORWARDING.ps1"
    ],
    "relationshipFamily": "Inbox rules",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Remove All Inbox Rules": {
    "code": "& {\n    $Mailbox = (Read-Host 'Exact mailbox UPN; blank cancels').Trim()\n    if (-not $Mailbox) { return }\n    $Rules = @(Get-InboxRule -Mailbox $Mailbox -IncludeHidden -ErrorAction Stop)\n    $Rules | Format-Table Name,Identity,Enabled -AutoSize | Out-Host\n    if (-not $Rules.Count) { Write-Host 'No rules found; no changes.'; return }\n    Write-Warning \"Deletes ALL $($Rules.Count) visible and hidden rules from $Mailbox. Legitimate rules are included.\"\n    if ((Read-Host \"Type DELETE $Mailbox to approve\").Trim() -cne \"DELETE $Mailbox\") { Write-Host 'Cancelled; no changes.'; return }\n    foreach ($Rule in $Rules) {\n        Remove-InboxRule -Mailbox $Mailbox -Identity $Rule.Identity -Confirm:$false -ErrorAction Stop\n    }\n    $Remaining = @(Get-InboxRule -Mailbox $Mailbox -IncludeHidden -ErrorAction Stop)\n    if ($Remaining.Count) { throw \"$($Remaining.Count) rules remain; review partial results.\" }\n    Write-Host \"Verified: no inbox rules remain in $Mailbox.\"\n}",
    "useFor": "Delete all visible and hidden inbox rules from one explicitly approved mailbox.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Includes legitimate rules. Stops on errors and rechecks remaining rules; cancellation does not delete rules.",
      "Deletes rules, not email. Export or record rules first if you may need to restore them."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Exact mailbox UPN at the prompt, then DELETE followed by that UPN after reviewing every returned rule.",
    "related": [
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-FORWARDING.ps1"
    ],
    "relationshipFamily": "Inbox rules",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Remove Specific Inbox Rule": {
    "code": "$Rule = \"Rule Name\"\nRemove-InboxRule -Mailbox \"user@domain.com\" -Identity $Rule -Confirm:$true",
    "useFor": "Delete one selected inbox rule.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Requests native confirmation before the selected change. Review the actual target in the command and confirmation prompt.",
      "Command completion alone does not verify the resulting state.",
      "Deletes rules, not email. Export or record rules first if you may need to restore them."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address; target search, rule, task or subject. Review all target values before running.",
    "related": [
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-FORWARDING.ps1"
    ],
    "relationshipFamily": "Inbox rules",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "command:Show BitLocker Status",
      "command:Show Physical Disk Health",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Endpoint protection",
    "permissionNotes": []
  },
  "Show BitLocker Status": {
    "code": "Get-BitLockerVolume |\n  Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionPercentage,EncryptionMethod",
    "useFor": "Show BitLocker protection and encryption status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show BitLocker Recovery Protectors",
      "command:Show Physical Disk Health",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Endpoint protection",
    "permissionNotes": []
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
    "input": "Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "command:Show BitLocker Status",
      "command:Show BitLocker Recovery Protectors",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Endpoint protection",
    "permissionNotes": []
  },
  "Suspend For One Reboot": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Suspend For One Reboot\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Suspend-BitLocker -MountPoint \"C:\" -RebootCount 1\n}",
    "useFor": "Suspend BitLocker protection on C: for one reboot.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "command:Show BitLocker Status",
      "command:Show BitLocker Recovery Protectors",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Endpoint protection",
    "permissionNotes": []
  },
  "Find By Thumbprint": {
    "code": "Get-ChildItem Cert:\\CurrentUser\\My,Cert:\\LocalMachine\\My |\n  Where-Object Thumbprint -eq \"THUMBPRINT\" |\n  Select-Object Subject,Thumbprint,NotBefore,NotAfter,HasPrivateKey",
    "useFor": "Find a certificate by its thumbprint in the current-user and computer stores.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your certificate thumbprint. Review all target values before running.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
  },
  "Show Expiring Certificates": {
    "code": "Get-ChildItem Cert:\\LocalMachine\\My |\n  Where-Object { $_.NotAfter -le (Get-Date).AddDays(30) } |\n  Select-Object Subject,Thumbprint,NotAfter",
    "useFor": "List computer certificates that expire within 30 days, including already expired ones.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
  },
  "Verify Script Signature": {
    "code": "$Path = \"C:\\Scripts\\script.ps1\"\nGet-AuthenticodeSignature -FilePath $Path |\n  Select-Object Status,StatusMessage,SignerCertificate",
    "useFor": "Show a script’s signature status and signing certificate.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Show Code-Signing Certificates"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
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
    "input": "Replace command examples with your certificate subject name. Review all target values before running.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
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
    "input": "Replace command examples with your certificate thumbprint; local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
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
    "input": "Replace command examples with your certificate thumbprint; local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
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
    "input": "Replace command examples with your certificate thumbprint; local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
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
    "input": "Replace command examples with your record ID from a prior lookup. Review all target values before running. Application (client) ID of the app to find.",
    "related": [
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-SERVICE-PRINCIPAL-OWNERS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "relationshipFamily": "App access",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Calculate Sha256 Hash": {
    "code": "$Path = \"C:\\Temp\\file.exe\"\nGet-FileHash -Path $Path -Algorithm SHA256",
    "useFor": "Calculate a file’s SHA-256 hash for comparison with a trusted value.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
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
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running.",
    "related": [
      "command:Show Exchange Connection",
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "command:Show Message Trace Search Jobs"
    ],
    "relationshipFamily": "Content search",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running.",
    "related": [
      "command:Show Compliance Search Status",
      "command:Show Exchange Connection",
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1"
    ],
    "relationshipFamily": "Content search",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Hard-Delete Search Results": {
    "code": "& {\n    $SearchName = (Read-Host 'Exact completed compliance search name; blank cancels').Trim()\n    if (-not $SearchName) { return }\n    $Search = Get-ComplianceSearch -Identity $SearchName -ErrorAction Stop\n    $Search | Format-List Name,Status,Items,Size,ExchangeLocation,ContentMatchQuery | Out-Host\n    if ($Search.Status -ne 'Completed') { throw 'Search must be completed before purge.' }\n    Write-Warning 'Hard-delete the matching search results. Confirm the query and mailbox scope above.'\n    if ((Read-Host \"Type PURGE $SearchName to approve\").Trim() -cne \"PURGE $SearchName\") { Write-Host 'Cancelled; no changes.'; return }\n    New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete -ErrorAction Stop\n    Write-Host 'Purge submitted; check compliance action status and service purge limits before claiming completion.'\n}",
    "useFor": "Request hard deletion of the selected completed search’s results.",
    "connectFirst": [
      "Connect-IPPSSession"
    ],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Permanent deletion request. Review the completed search and obtain approval before running."
    ],
    "requires": "ExchangeOnlineManagement module and Purview roles for this search or purge action. Your tenant must support the command shown.",
    "input": "Exact completed compliance search name; review query and mailbox scope, then type PURGE followed by that search name.",
    "related": [
      "command:Show Compliance Search Status",
      "command:Show Exchange Connection",
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1"
    ],
    "relationshipFamily": "Content search",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running.",
    "related": [
      "command:Show Compliance Search Status",
      "command:Show Exchange Connection",
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1"
    ],
    "relationshipFamily": "Content search",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Defender Status",
      "command:Show Recent Windows Update History",
      "command:Show Service Status"
    ],
    "relationshipFamily": "Antivirus",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Defender Status",
      "command:Show Recent Windows Update History",
      "command:Show Service Status"
    ],
    "relationshipFamily": "Antivirus",
    "permissionNotes": []
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "relationshipFamily": "Mail investigation",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "relationshipFamily": "Mail investigation",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "relationshipFamily": "Mail investigation",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "relationshipFamily": "Mail investigation",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "relationshipFamily": "Mail investigation",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "relationshipFamily": "Mail investigation",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Show Risk Detections For One User": {
    "code": "$UserId = (Get-MgUser -UserId \"user@domain.com\").Id\nGet-MgRiskDetection -Filter \"userId eq '$UserId'\" -All |\n  Select-Object ActivityDateTime,RiskEventType,RiskLevel,RiskState,IPAddress,Location,Source",
    "useFor": "Show Identity Protection risk detections for one user.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"User.ReadBasic.All\",\"IdentityRiskEvent.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Identity.SignIns + Microsoft.Graph.Users. Delegated Graph scopes: User.ReadBasic.All, IdentityRiskEvent.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Security Reader or another supported risk-reader/custom role. Identity Protection licensing and data availability apply."
    ]
  },
  "Show Risky User State": {
    "code": "Get-MgRiskyUser -Filter \"userPrincipalName eq 'user@domain.com'\" |\n  Select-Object UserPrincipalName,RiskLevel,RiskState,RiskDetail,RiskLastUpdatedDateTime",
    "useFor": "Show the user’s current Identity Protection risk status.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"IdentityRiskyUser.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Identity.SignIns. Delegated Graph scopes: IdentityRiskyUser.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Security Reader or another supported risk-reader/custom role. Identity Protection licensing and data availability apply."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "command:Show Message Trace Events",
      "command:Show Message Trace Search Jobs"
    ],
    "relationshipFamily": "Mail delivery",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "command:Show Message Trace Events",
      "command:Show Message Trace Search Jobs"
    ],
    "relationshipFamily": "Mail delivery",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address; record ID from a prior lookup. Review all target values before running. Message trace ID from a trace search and the exact recipient address.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "command:Show Message Trace Search Jobs",
      "command:Who Received Mail From Suspicious Sender"
    ],
    "relationshipFamily": "Mail delivery",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "command:Show Message Trace Events",
      "command:Who Received Mail From Suspicious Sender"
    ],
    "relationshipFamily": "Mail delivery",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your suspect sender address. Review all target values before running.",
    "related": [
      "BEC-GET-TENANT-EMAIL-SEARCH.ps1",
      "command:Show Message Trace Events",
      "command:Show Message Trace Search Jobs"
    ],
    "relationshipFamily": "Mail delivery",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Show Failed Sign-Ins": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddHours(-48).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Where-Object { $_.Status.ErrorCode -ne 0 } |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,\n    @{N=\"ErrorCode\";E={$_.Status.ErrorCode}},\n    @{N=\"FailureReason\";E={$_.Status.FailureReason}}",
    "useFor": "Show failed sign-ins for one user over 48 hours.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Reports. Delegated Graph scopes: AuditLog.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result."
    ]
  },
  "Show Last 10 Entra Sign-Ins": {
    "code": "Get-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com'\" -Top 10 -Sort \"createdDateTime desc\" |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,ConditionalAccessStatus,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed: $($_.Status.ErrorCode)\"}}},\n    @{N=\"Location\";E={\"$($_.Location.City), $($_.Location.State), $($_.Location.CountryOrRegion)\"}}",
    "useFor": "Show the user’s 10 most recent Entra sign-ins.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Reports. Delegated Graph scopes: AuditLog.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result."
    ]
  },
  "Show Entra Sign-ins - Last 48 Hours": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddHours(-48).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,ConditionalAccessStatus,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed: $($_.Status.ErrorCode)\"}}}",
    "useFor": "Show the user’s Entra sign-ins over 48 hours.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Reports. Delegated Graph scopes: AuditLog.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result."
    ]
  },
  "Show Legacy / Other-client Sign-ins": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddDays(-7).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Where-Object { $_.ClientAppUsed -eq \"Other clients\" } |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed\"}}}",
    "useFor": "Show sign-ins classified as Other clients over seven days; this is not proof of legacy authentication.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Reports. Delegated Graph scopes: AuditLog.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result."
    ]
  },
  "Show Successful Sign-Ins": {
    "code": "$Since = (Get-Date).ToUniversalTime().AddHours(-48).ToString(\"yyyy-MM-ddTHH:mm:ssZ\")\nGet-MgAuditLogSignIn -Filter \"userPrincipalName eq 'user@domain.com' and createdDateTime ge $Since\" -All |\n  Where-Object { $_.Status.ErrorCode -eq 0 } |\n  Select-Object CreatedDateTime,AppDisplayName,IPAddress,ClientAppUsed,ConditionalAccessStatus",
    "useFor": "Show successful sign-ins for one user over 48 hours.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\" -ContextScope Process"
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Reports. Delegated Graph scopes: AuditLog.Read.All.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result."
    ]
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Recent System Errors",
      "command:Show Last Boot And Uptime",
      "command:Show Service Status"
    ],
    "relationshipFamily": "Windows event review",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Recent Application Errors",
      "command:Show Last Boot And Uptime",
      "command:Show Service Status"
    ],
    "relationshipFamily": "Windows event review",
    "permissionNotes": []
  },
  "Resolve Name": {
    "code": "$Name = \"example.com\"\nResolve-DnsName $Name",
    "useFor": "Look up DNS records for a domain or host name.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Configured Dns Servers",
      "command:DNS Lookup",
      "command:Show Ip Configuration"
    ],
    "relationshipFamily": "DNS",
    "permissionNotes": []
  },
  "Show Configured Dns Servers": {
    "code": "Get-DnsClientServerAddress -AddressFamily IPv4 |\n  Select-Object InterfaceAlias,ServerAddresses",
    "useFor": "Show configured IPv4 DNS servers for each network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:DNS Lookup",
      "command:Show Ip Configuration",
      "command:Resolve Name"
    ],
    "relationshipFamily": "DNS",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Configured Dns Servers",
      "command:DNS Lookup",
      "command:Show Ip Configuration"
    ],
    "relationshipFamily": "DNS",
    "permissionNotes": []
  },
  "Show Windows Firewall Profiles": {
    "code": "Get-NetFirewallProfile |\n  Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction",
    "useFor": "Show Windows Firewall profile status and default actions.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Windows Firewall Rules by Name",
      "command:Show Listening Tcp Ports",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Firewall and remote access",
    "permissionNotes": []
  },
  "Show Windows Firewall Rules by Name": {
    "code": "$Name = \"*Remote Desktop*\"\nGet-NetFirewallRule -DisplayName $Name |\n  Select-Object DisplayName,Enabled,Direction,Action,Profile",
    "useFor": "Find firewall rules whose display names match the supplied filter.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your firewall rule display-name filter. Review all target values before running.",
    "related": [
      "command:Show Windows Firewall Profiles",
      "command:Show Listening Tcp Ports",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Firewall and remote access",
    "permissionNotes": []
  },
  "Ping Host": {
    "code": "Test-Connection -ComputerName \"server01\" -Count 4",
    "useFor": "Send four ping tests to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Show Active Adapters": {
    "code": "Get-NetAdapter |\n  Where-Object Status -eq \"Up\" |\n  Select-Object Name,InterfaceDescription,MacAddress,LinkSpeed",
    "useFor": "List network adapters whose status is Up.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Network Profile"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
  },
  "Show Arp Neighbor Cache": {
    "code": "Get-NetNeighbor -AddressFamily IPv4 |\n  Select-Object IPAddress,LinkLayerAddress,State,InterfaceAlias",
    "useFor": "Show cached IPv4 neighbors and their hardware addresses.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Show Established Tcp Connections": {
    "code": "Get-NetTCPConnection -State Established |\n  Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,OwningProcess",
    "useFor": "List established TCP connections and their owning process IDs.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Show Ip Configuration": {
    "code": "Get-NetIPConfiguration |\n  Select-Object InterfaceAlias,IPv4Address,IPv4DefaultGateway,DNSServer",
    "useFor": "Show local IP addresses, gateways, and DNS servers.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Routing Table",
      "command:Test Tcp Port",
      "command:Ping Host"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Show Listening Tcp Ports": {
    "code": "Get-NetTCPConnection -State Listen |\n  Sort-Object LocalPort |\n  Select-Object LocalAddress,LocalPort,OwningProcess",
    "useFor": "List listening TCP ports and their owning process IDs.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Show Routing Table": {
    "code": "Get-NetRoute -AddressFamily IPv4 |\n  Sort-Object RouteMetric |\n  Select-Object DestinationPrefix,NextHop,InterfaceAlias,RouteMetric",
    "useFor": "Show IPv4 routes sorted by route metric.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Test Tcp Port",
      "command:Ping Host"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Test Tcp Port": {
    "code": "Test-NetConnection -ComputerName \"server01\" -Port 443",
    "useFor": "Test a host’s TCP port; the example uses port 443.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Ping Host"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Trace Route": {
    "code": "Test-NetConnection -ComputerName \"example.com\" -TraceRoute",
    "useFor": "Trace the network path to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Release And Renew Dhcp": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Release And Renew Dhcp\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    ipconfig /release\n    ipconfig /renew\n}",
    "useFor": "Release and renew DHCP addresses on this computer.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Active Adapters",
      "command:Show Ip Configuration",
      "command:Show Routing Table"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
  },
  "Reset Tcp/Ip Stack": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Reset Tcp/Ip Stack\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    netsh int ip reset\n}",
    "useFor": "Reset the local TCP/IP configuration.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Active Adapters",
      "command:Show Ip Configuration",
      "command:Show Routing Table"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
  },
  "Reset Winsock": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Reset Winsock\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    netsh winsock reset\n}",
    "useFor": "Reset the local Winsock catalog.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Active Adapters",
      "command:Show Ip Configuration",
      "command:Show Routing Table"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
  },
  "Restart Adapter": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Restart Adapter\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Restart-NetAdapter -Name \"Ethernet\" -Confirm:$true\n}",
    "useFor": "Restart the selected network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your network adapter name. Review all target values before running.",
    "related": [
      "command:Show Active Adapters",
      "command:Show Ip Configuration",
      "command:Show Routing Table"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Show Wi-Fi Connection": {
    "code": "netsh wlan show interfaces",
    "useFor": "Show the current Wi-Fi connection details.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Saved Wi-Fi Profiles",
      "command:Network Profile",
      "command:Show Active Adapters"
    ],
    "relationshipFamily": "Wi-Fi",
    "permissionNotes": []
  },
  "Show Saved Wi-Fi Profiles": {
    "code": "netsh wlan show profiles",
    "useFor": "List saved Wi-Fi profile names.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Wi-Fi Connection",
      "command:Network Profile",
      "command:Show Active Adapters"
    ],
    "relationshipFamily": "Wi-Fi",
    "permissionNotes": []
  },
  "Show Problem Devices": {
    "code": "Get-PnpDevice -PresentOnly |\n  Where-Object Status -ne \"OK\" |\n  Select-Object Class,FriendlyName,InstanceId,Status",
    "useFor": "Show connected devices whose reported status is not OK.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Computer Model And Serial Number",
      "command:Show Os And Build",
      "command:Show Last Boot And Uptime"
    ],
    "relationshipFamily": "Computer information",
    "permissionNotes": []
  },
  "Show Free Space": {
    "code": "Get-CimInstance Win32_LogicalDisk -Filter \"DriveType=3\" |\n  Select-Object DeviceID,\n    @{N=\"SizeGB\";E={[math]::Round($_.Size/1GB,1)}},\n    @{N=\"FreeGB\";E={[math]::Round($_.FreeSpace/1GB,1)}},\n    @{N=\"FreePct\";E={[math]::Round(($_.FreeSpace/$_.Size)*100,1)}}",
    "useFor": "Show total and free space on fixed local drives.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Physical Disk Health",
      "command:Open Storage Settings"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
  },
  "Show Physical Disk Health": {
    "code": "Get-PhysicalDisk |\n  Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus,Size",
    "useFor": "Show physical disk health and operating status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Free Space",
      "command:Open Storage Settings"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
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
    "input": "Replace command examples with your local file or folder path. Review all target values before running. Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Free Space",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
  },
  "Show Computer Model And Serial Number": {
    "code": "$System = Get-CimInstance Win32_ComputerSystem\n$Bios = Get-CimInstance Win32_BIOS\n[pscustomobject]@{\n  Manufacturer = $System.Manufacturer\n  Model = $System.Model\n  SerialNumber = $Bios.SerialNumber\n}",
    "useFor": "Show this computer’s manufacturer, model, and serial number.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Os And Build",
      "command:Show Last Boot And Uptime",
      "command:Show Problem Devices"
    ],
    "relationshipFamily": "Computer information",
    "permissionNotes": []
  },
  "Show Hostname And Current User": {
    "code": "[pscustomobject]@{\n  ComputerName = $env:COMPUTERNAME\n  User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name\n}",
    "useFor": "Show the computer name and current Windows account.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Computer Model And Serial Number",
      "command:Show Os And Build",
      "command:Show Last Boot And Uptime"
    ],
    "relationshipFamily": "Computer information",
    "permissionNotes": []
  },
  "Show Last Boot And Uptime": {
    "code": "$OS = Get-CimInstance Win32_OperatingSystem\n[pscustomobject]@{\n  LastBoot = $OS.LastBootUpTime\n  Uptime = (Get-Date) - $OS.LastBootUpTime\n}",
    "useFor": "Show the last Windows boot time and calculated uptime.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Computer Model And Serial Number",
      "command:Show Os And Build",
      "command:Show Problem Devices"
    ],
    "relationshipFamily": "Computer information",
    "permissionNotes": []
  },
  "Show Os And Build": {
    "code": "Get-CimInstance Win32_OperatingSystem |\n  Select-Object Caption,Version,BuildNumber,OSArchitecture",
    "useFor": "Show the Windows version, build, and architecture.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Computer Model And Serial Number",
      "command:Show Last Boot And Uptime",
      "command:Show Problem Devices"
    ],
    "relationshipFamily": "Computer information",
    "permissionNotes": []
  },
  "Show Top Cpu Consumers": {
    "code": "Get-Process |\n  Sort-Object CPU -Descending |\n  Select-Object -First 15 Name,Id,CPU",
    "useFor": "List 15 processes with the most accumulated CPU time; this is not current CPU percentage.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Top Memory Consumers",
      "command:Show Service Status",
      "command:Recent Application Errors"
    ],
    "relationshipFamily": "Performance",
    "permissionNotes": []
  },
  "Show Top Memory Consumers": {
    "code": "Get-Process |\n  Sort-Object WorkingSet64 -Descending |\n  Select-Object -First 15 Name,Id,@{N=\"MemoryMB\";E={[math]::Round($_.WorkingSet64/1MB,1)}}",
    "useFor": "List 15 processes using the most working-set memory.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Top Cpu Consumers",
      "command:Show Service Status",
      "command:Recent Application Errors"
    ],
    "relationshipFamily": "Performance",
    "permissionNotes": []
  },
  "Stop Process By Name": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Stop Process By Name\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    $Name = \"notepad\"\n    Stop-Process -Name $Name -Force\n}",
    "useFor": "Force-stop all processes with the selected name.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work.",
      "Can discard unsaved work in every matching process."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your process name. Review all target values before running.",
    "related": [
      "command:Show Top Cpu Consumers",
      "command:Show Top Memory Consumers",
      "command:Show Service Status"
    ],
    "relationshipFamily": "Performance",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Windows Firewall Profiles",
      "command:Show Windows Firewall Rules by Name",
      "command:Show Listening Tcp Ports"
    ],
    "relationshipFamily": "Firewall and remote access",
    "permissionNotes": []
  },
  "Chkdsk Online Scan": {
    "code": "chkdsk C: /scan",
    "useFor": "Run an online file-system scan of C:.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Drive or file path shown in the command; change it if the target is not C:.",
    "related": [
      "command:Dism Component Store Scan",
      "command:DISM Analyze Component Store",
      "command:Recent System Errors"
    ],
    "relationshipFamily": "Windows repair",
    "permissionNotes": []
  },
  "Dism Component Store Scan": {
    "code": "DISM.exe /Online /Cleanup-Image /ScanHealth",
    "useFor": "Check the Windows component store for corruption.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:DISM Analyze Component Store",
      "command:Recent System Errors",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Windows repair",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Dism Component Store Scan",
      "command:DISM Analyze Component Store",
      "command:Recent System Errors"
    ],
    "relationshipFamily": "Windows repair",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Dism Component Store Scan",
      "command:DISM Analyze Component Store",
      "command:Recent System Errors"
    ],
    "relationshipFamily": "Windows repair",
    "permissionNotes": []
  },
  "Reboot Computer": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Reboot Computer\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Restart-Computer -Force\n}",
    "useFor": "Force an immediate restart of this computer.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work.",
      "Restarts immediately and can discard unsaved work."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
  },
  "Show Service Status": {
    "code": "Get-Service -Name \"Spooler\" |\n  Select-Object Name,DisplayName,Status,StartType",
    "useFor": "Show the selected service’s status and startup type.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your service name. Review all target values before running.",
    "related": [
      "command:Show Scheduled Task",
      "command:Show Scheduled Task Last Run Result",
      "command:Recent System Errors"
    ],
    "relationshipFamily": "Services and scheduled tasks",
    "permissionNotes": []
  },
  "Restart Service": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Restart Service\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Restart-Service -Name \"Spooler\" -Force\n}",
    "useFor": "Force-restart the selected Windows service.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your service name. Review all target values before running.",
    "related": [
      "command:Show Service Status",
      "command:Show Scheduled Task",
      "command:Show Scheduled Task Last Run Result"
    ],
    "relationshipFamily": "Services and scheduled tasks",
    "permissionNotes": []
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
    "input": "Replace command examples with your service name. Review all target values before running.",
    "related": [
      "command:Show Service Status",
      "command:Show Scheduled Task",
      "command:Show Scheduled Task Last Run Result"
    ],
    "relationshipFamily": "Services and scheduled tasks",
    "permissionNotes": []
  },
  "Show Locally Logged-On Users": {
    "code": "quser",
    "useFor": "List users and sessions reported by Windows.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show SMB Sessions",
      "command:Show SMB Shares",
      "command:Show Hostname And Current User"
    ],
    "relationshipFamily": "Windows sessions and shares",
    "permissionNotes": []
  },
  "Show SMB Sessions": {
    "code": "Get-SmbSession |\n  Select-Object ClientComputerName,ClientUserName,NumOpens,Dialect",
    "useFor": "List active SMB file-sharing sessions.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Locally Logged-On Users",
      "command:Show SMB Shares",
      "command:Mapped Drives"
    ],
    "relationshipFamily": "Windows sessions and shares",
    "permissionNotes": []
  },
  "Show SMB Shares": {
    "code": "Get-SmbShare |\n  Select-Object Name,Path,Description",
    "useFor": "List local SMB shares and their paths.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Locally Logged-On Users",
      "command:Show SMB Sessions",
      "command:Mapped Drives"
    ],
    "relationshipFamily": "Windows sessions and shares",
    "permissionNotes": []
  },
  "Show Scheduled Task": {
    "code": "Get-ScheduledTask -TaskName \"Task Name\" |\n  Select-Object TaskName,TaskPath,State",
    "useFor": "Show the selected scheduled task’s state and path.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running.",
    "related": [
      "command:Show Service Status",
      "command:Show Scheduled Task Last Run Result",
      "command:Recent System Errors"
    ],
    "relationshipFamily": "Services and scheduled tasks",
    "permissionNotes": []
  },
  "Show Scheduled Task Last Run Result": {
    "code": "Get-ScheduledTaskInfo -TaskName \"Task Name\" |\n  Select-Object LastRunTime,LastTaskResult,NextRunTime,NumberOfMissedRuns",
    "useFor": "Show a task’s last run, result code, and next run time.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target search, rule, task or subject. Review all target values before running.",
    "related": [
      "command:Show Service Status",
      "command:Show Scheduled Task",
      "command:Recent System Errors"
    ],
    "relationshipFamily": "Services and scheduled tasks",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Show Installed Hotfixes"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
  },
  "Show Installed Hotfixes": {
    "code": "Get-HotFix |\n  Sort-Object InstalledOn -Descending |\n  Select-Object HotFixID,Description,InstalledOn,InstalledBy",
    "useFor": "List installed hotfixes, newest first.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Check Common Pending Reboot Flags",
      "command:Show Installed Hotfixes"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "command:Show Calendar Permissions",
      "command:Show Contacts Permissions",
      "GET-MAILBOX-PERMISSIONS.ps1"
    ],
    "relationshipFamily": "Calendar and contacts",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Remove Calendar Permission": {
    "code": "Remove-MailboxFolderPermission -Identity \"owner@domain.com:\\Calendar\" -User \"user@domain.com\" -Confirm:$true",
    "useFor": "Remove the selected user’s permission from a mailbox calendar.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Requests native confirmation before the selected change. Review the actual target in the command and confirmation prompt.",
      "Command completion alone does not verify the resulting state."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "command:Show Calendar Permissions",
      "command:Show Contacts Permissions",
      "GET-MAILBOX-PERMISSIONS.ps1"
    ],
    "relationshipFamily": "Calendar and contacts",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "command:Show Contacts Permissions",
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-ROOM-RESOURCE-ACCESS.ps1"
    ],
    "relationshipFamily": "Calendar and contacts",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "command:Show Calendar Permissions",
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-ROOM-RESOURCE-ACCESS.ps1"
    ],
    "relationshipFamily": "Calendar and contacts",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "command:Show Calendar Permissions",
      "command:Show Contacts Permissions",
      "GET-MAILBOX-PERMISSIONS.ps1"
    ],
    "relationshipFamily": "Calendar and contacts",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name.",
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "command:Show AD Group Members"
    ],
    "relationshipFamily": "AD groups",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Uses the domain available to your Windows account; no user or group name to enter.",
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "command:Get User"
    ],
    "relationshipFamily": "AD account review",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Domain Trust Check",
      "command:Entra Join Status",
      "command:Show Group Policy Result"
    ],
    "relationshipFamily": "Domain and device identity",
    "permissionNotes": []
  },
  "Show Group Policy Result": {
    "code": "gpresult /r",
    "useFor": "Show Group Policy results for the current context.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Domain Trust Check",
      "command:Entra Join Status",
      "command:Show Configured Dns Servers"
    ],
    "relationshipFamily": "Domain and device identity",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Free Space",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
  },
  "Show Domain Account Details": {
    "code": "net user username /domain",
    "useFor": "Show details for a domain account using net user.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "command:Domain Trust Check",
      "command:Entra Join Status",
      "command:Show Group Policy Result"
    ],
    "relationshipFamily": "Domain and device identity",
    "permissionNotes": []
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
  },
  "Delete Local User": {
    "code": "& {\n    $Target = (Read-Host 'Exact local account name; blank cancels').Trim()\n    if (-not $Target) { return }\n    $User = Get-LocalUser -Name $Target -ErrorAction Stop\n    $User | Format-List Name,SID,Enabled | Out-Host\n    if ((Read-Host \"Type DELETE $($User.Name) to approve\").Trim() -cne \"DELETE $($User.Name)\") { Write-Host 'Cancelled; no changes.'; return }\n    Remove-LocalUser -SID $User.SID -ErrorAction Stop\n    Write-Host 'Deletion request completed; independently verify the local account is absent.'\n}",
    "useFor": "Delete the selected local Windows account.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Exact local username at the prompt; review the resolved SID, then type DELETE followed by the displayed username.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
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
    "input": "Replace command examples with your target account name. Review all target values before running. New password; replace the example value before running.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
  },
  "Open Local Users and Groups": {
    "code": "lusrmgr.msc",
    "useFor": "Open the Local Users and Groups management console.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
  },
  "Show Logged-On Users": {
    "code": "quser",
    "useFor": "List users and sessions reported by Windows.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show SMB Sessions",
      "command:Show SMB Shares",
      "command:Mapped Drives"
    ],
    "relationshipFamily": "Windows sessions and shares",
    "permissionNotes": []
  },
  "Disable Network Adapter": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Disable Network Adapter\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    netsh interface set interface \"Wi-Fi\" admin=disabled\n}",
    "useFor": "Disable the selected network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your network adapter name. Review all target values before running.",
    "related": [
      "command:Show Active Adapters",
      "command:Show Ip Configuration",
      "command:Show Routing Table"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
  },
  "Restart Network Adapter": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Restart Network Adapter\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Restart-NetAdapter -Name \"Wi-Fi\"\n}",
    "useFor": "Restart the selected network adapter.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Replace command examples with your network adapter name. Review all target values before running.",
    "related": [
      "command:Show Active Adapters",
      "command:Show Ip Configuration",
      "command:Show Routing Table"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
  },
  "Isolate Device - Disable Enabled Adapters": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Isolate Device - Disable Enabled Adapters\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    Get-NetAdapter | Where-Object Status -eq \"Up\" | Disable-NetAdapter -Confirm:$true\n}",
    "useFor": "Disable every network adapter whose status is Up.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work.",
      "Can disconnect your remote session. Have another way to reach the device."
    ],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Active Adapters",
      "command:Show Ip Configuration",
      "command:Show Routing Table"
    ],
    "relationshipFamily": "Network changes",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Windows Time Status",
      "command:Windows Time Source",
      "command:Show Last Boot And Uptime"
    ],
    "relationshipFamily": "Windows time",
    "permissionNotes": []
  },
  "Open Windows Update": {
    "code": "start ms-settings:windowsupdate-action",
    "useFor": "Open Windows Update settings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
  },
  "Show Wi-Fi Interface": {
    "code": "netsh wlan show interfaces",
    "useFor": "Show Wi-Fi interface details.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Wi-Fi Connection",
      "command:Show Saved Wi-Fi Profiles",
      "command:Network Profile"
    ],
    "relationshipFamily": "Wi-Fi",
    "permissionNotes": []
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
    "input": "Saved Wi-Fi profile name; replace ProfileName.",
    "related": [
      "command:Show Wi-Fi Connection",
      "command:Show Saved Wi-Fi Profiles",
      "command:Network Profile"
    ],
    "relationshipFamily": "Wi-Fi",
    "permissionNotes": []
  },
  "DISM Analyze Component Store": {
    "code": "DISM /Online /Cleanup-Image /AnalyzeComponentStore",
    "useFor": "Analyze Windows component-store space use.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Dism Component Store Scan",
      "command:Recent System Errors",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Windows repair",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Dism Component Store Scan",
      "command:DISM Analyze Component Store",
      "command:Recent System Errors"
    ],
    "relationshipFamily": "Windows repair",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Free Space",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
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
    "input": "Default target: C: drive. Change -DriveLetter before running if another volume is intended.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Free Space",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
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
    "input": "Uses the WinGet packages and sources configured on this Windows computer.",
    "related": [
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags",
      "command:Show Installed Hotfixes"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
  },
  "Update All Eligible WinGet Packages": {
    "code": "& {\n    Write-Warning \"May interrupt connectivity, active work, protection or installed applications. Review the command and arrange recovery before approving.\"\n    if ((Read-Host \"Type APPLY to approve: Update All Eligible WinGet Packages\").Trim() -cne 'APPLY') { Write-Host 'Cancelled; no changes.'; return }\n    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity\n}",
    "useFor": "Update all eligible WinGet packages silently and accept package/source agreements.",
    "connectFirst": [],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Review the command target before pasting. Type APPLY only after arranging for any interrupted connectivity or work."
    ],
    "requires": "WinGet installed on the target Windows computer; access to its package sources. Some installers require administrator approval.",
    "input": "Uses the WinGet packages and sources configured on this Windows computer.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
  },
  "Show WinGet Package Information": {
    "code": "$PackageId = \"Package.Id\"\nwinget show --id $PackageId --exact",
    "useFor": "Show details for an exact WinGet package ID.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "WinGet installed on the target Windows computer; access to its package sources. Some installers require administrator approval.",
    "input": "Exact package ID from winget search. Replace \"Package.Id\" before running.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
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
    "input": "Exact package ID from winget search. Replace \"Package.Id\" before running.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
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
    "input": "Uses the WinGet packages and sources configured on this Windows computer.",
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show Recent Windows Update History",
      "command:Check Common Pending Reboot Flags"
    ],
    "relationshipFamily": "Apps and updates",
    "permissionNotes": []
  },
  "Show PowerShell Version": {
    "code": "$PSVersionTable.PSVersion",
    "useFor": "Show the current PowerShell version.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "command:Show Execution Policies"
    ],
    "relationshipFamily": "PowerShell setup",
    "permissionNotes": []
  },
  "Show Execution Policies": {
    "code": "Get-ExecutionPolicy -List",
    "useFor": "Show execution policy at every scope.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "command:Show PowerShell Version"
    ],
    "relationshipFamily": "PowerShell setup",
    "permissionNotes": []
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
    "input": "Uses this Windows user and PowerShell session on the current computer.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "command:Show Execution Policies"
    ],
    "relationshipFamily": "PowerShell setup",
    "permissionNotes": []
  },
  "Show Installed Microsoft Graph Module Version": {
    "code": "Get-Module Microsoft.Graph.Authentication -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version,Path",
    "useFor": "Show the newest installed Microsoft Graph Authentication module version.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "command:Show Execution Policies"
    ],
    "relationshipFamily": "PowerShell setup",
    "permissionNotes": []
  },
  "Show Installed ExchangeOnlineManagement Version": {
    "code": "Get-Module ExchangeOnlineManagement -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version,Path",
    "useFor": "Show the newest installed Exchange Online module version.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "command:Show Execution Policies"
    ],
    "relationshipFamily": "PowerShell setup",
    "permissionNotes": []
  },
  "Show Graph Context": {
    "code": "Get-MgContext",
    "useFor": "Show the current Microsoft Graph connection and granted permissions.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Microsoft.Graph.Authentication module; uses the current PowerShell session.",
    "input": "Uses this PowerShell window’s Microsoft Graph connection; no user or group name to enter.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "RESET-M365-SESSION.ps1",
      "command:Get User By Upn"
    ],
    "relationshipFamily": "Graph connection",
    "permissionNotes": []
  },
  "Show Exchange Connection": {
    "code": "Get-ConnectionInformation",
    "useFor": "Show existing Exchange Online PowerShell connections.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "RESET-M365-SESSION.ps1",
      "command:Show Mailbox Summary"
    ],
    "relationshipFamily": "Exchange connection",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Uses this PowerShell window’s Microsoft Graph connection; no user or group name to enter.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "RESET-M365-SESSION.ps1",
      "command:Show Graph Context"
    ],
    "relationshipFamily": "Graph connection",
    "permissionNotes": []
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
    "input": "Uses the tenant in this PowerShell window’s Exchange Online connection; no mailbox or rule name to enter.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "RESET-M365-SESSION.ps1",
      "command:Show Exchange Connection"
    ],
    "relationshipFamily": "Exchange connection",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Show Activity From One IP": {
    "code": "$Ip = \"1.2.3.4\"\nGet-MgAuditLogSignIn -Filter \"ipAddress eq '$Ip'\" -Top 100 |\n  Select-Object CreatedDateTime,UserPrincipalName,AppDisplayName,IPAddress,ClientAppUsed,\n    @{N=\"Status\";E={if($_.Status.ErrorCode -eq 0){\"Success\"}else{\"Failed\"}}}",
    "useFor": "Show up to 100 sign-ins recorded from the selected IP address.",
    "connectFirst": [
      "Connect-MgGraph -Scopes \"AuditLog.Read.All\""
    ],
    "checks": [],
    "guards": [],
    "requires": "Modules: Microsoft.Graph.Authentication + Microsoft.Graph.Reports. Delegated Graph scopes: AuditLog.Read.All.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-IP-TRACE.ps1"
    ],
    "relationshipFamily": "Sign-in investigation",
    "permissionNotes": [
      "Delegated consent: these tenant-read/change scopes require administrator consent. Consent does not assign an Entra role or authorize a target. Use the approved tenant account; do not grant Global Administrator merely to run this task. Existing sessions may already hold broader permissions; this setup does not downgrade an existing token.",
      "Role / target authority: Reports Reader or Security Reader (or another supported role). Tenant licensing, retention and log availability also apply; unavailable data is not a clean result."
    ]
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
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
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
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "command:Show AD Group Members"
    ],
    "relationshipFamily": "AD groups",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
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
    "input": "Replace command examples with your group name or object ID. Review all target values before running. Exact target group name.",
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "command:Show AD Group Members"
    ],
    "relationshipFamily": "AD groups",
    "permissionNotes": [
      "AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights."
    ]
  },
  "Connect Exchange Online": {
    "code": "Connect-ExchangeOnline",
    "useFor": "Sign in to Exchange Online PowerShell.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to read the selected data.",
    "input": "An authorized account for the intended tenant; select it during sign-in.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "RESET-M365-SESSION.ps1",
      "command:Show Exchange Connection"
    ],
    "relationshipFamily": "Exchange connection",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
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
    "input": "Installs ExchangeOnlineManagement from PowerShell Gallery for the current Windows user.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "command:Show Execution Policies"
    ],
    "relationshipFamily": "PowerShell setup",
    "permissionNotes": []
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
    "input": "Installs Microsoft.Graph from PowerShell Gallery for the current Windows user.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "command:Show Execution Policies"
    ],
    "relationshipFamily": "PowerShell setup",
    "permissionNotes": []
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
    "input": "Replace command examples with your target user, mailbox or group address. Review all target values before running.",
    "related": [
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-FORWARDING.ps1"
    ],
    "relationshipFamily": "Inbox rules",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "Delete All Inbox Rules": {
    "code": "& {\n    $Mailbox = (Read-Host 'Exact mailbox UPN; blank cancels').Trim()\n    if (-not $Mailbox) { return }\n    $Rules = @(Get-InboxRule -Mailbox $Mailbox -IncludeHidden -ErrorAction Stop)\n    $Rules | Format-Table Name,Identity,Enabled -AutoSize | Out-Host\n    if (-not $Rules.Count) { Write-Host 'No rules found; no changes.'; return }\n    Write-Warning \"Deletes ALL $($Rules.Count) visible and hidden rules from $Mailbox. Legitimate rules are included.\"\n    if ((Read-Host \"Type DELETE $Mailbox to approve\").Trim() -cne \"DELETE $Mailbox\") { Write-Host 'Cancelled; no changes.'; return }\n    foreach ($Rule in $Rules) {\n        Remove-InboxRule -Mailbox $Mailbox -Identity $Rule.Identity -Confirm:$false -ErrorAction Stop\n    }\n    $Remaining = @(Get-InboxRule -Mailbox $Mailbox -IncludeHidden -ErrorAction Stop)\n    if ($Remaining.Count) { throw \"$($Remaining.Count) rules remain; review partial results.\" }\n    Write-Host \"Verified: no inbox rules remain in $Mailbox.\"\n}",
    "useFor": "Delete all visible and hidden inbox rules from one explicitly approved mailbox.",
    "connectFirst": [
      "Connect-ExchangeOnline"
    ],
    "checks": [],
    "guards": [
      "Requires explicit typed approval; blank or unmatched confirmation cancels before changes.",
      "A command error can leave partial work; do not assume rollback or successful verification.",
      "Includes legitimate rules. Stops on errors and rechecks remaining rules; cancellation does not delete rules.",
      "Review the target; PowerShell asks for confirmation before removal.",
      "Deletes rules, not email. Export or record rules first if you may need to restore them."
    ],
    "requires": "ExchangeOnlineManagement module and an Exchange role allowed to change the selected settings.",
    "input": "Exact mailbox UPN at the prompt, then DELETE followed by that UPN after reviewing every returned rule.",
    "related": [
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-FORWARDING.ps1"
    ],
    "relationshipFamily": "Inbox rules",
    "permissionNotes": [
      "Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement."
    ]
  },
  "IP Configuration (ipconfig)": {
    "code": "ipconfig /all",
    "useFor": "Show detailed local IP configuration.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Configured Dns Servers",
      "command:DNS Lookup",
      "command:Show Ip Configuration"
    ],
    "relationshipFamily": "DNS",
    "permissionNotes": []
  },
  "DNS Lookup": {
    "code": "nslookup example.com",
    "useFor": "Look up a domain or host name with nslookup.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Configured Dns Servers",
      "command:Show Ip Configuration",
      "command:Resolve Name"
    ],
    "relationshipFamily": "DNS",
    "permissionNotes": []
  },
  "Continuous Ping": {
    "code": "ping -t example.com",
    "useFor": "Ping a host continuously; press Ctrl+C to stop.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Traceroute": {
    "code": "tracert example.com",
    "useFor": "Trace the network route to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Path Ping": {
    "code": "pathping example.com",
    "useFor": "Check the network route and packet loss to a host.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target IP address, domain or host. Review all target values before running.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Routing Table (route print)": {
    "code": "route print",
    "useFor": "Show the local IP routing table.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "ARP Cache": {
    "code": "arp -a",
    "useFor": "Show cached IPv4 address-to-hardware mappings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "TCP Connections (netstat)": {
    "code": "netstat -ano",
    "useFor": "Show network connections, listening ports, and process IDs.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Port 443 Connections": {
    "code": "netstat -ano | findstr :443",
    "useFor": "Show netstat lines containing :443; matches can be local or remote ports.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Local Account Details": {
    "code": "net user username",
    "useFor": "Show details for the selected local Windows account.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Replace command examples with your target account name. Review all target values before running.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Identity and Privileges"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
  },
  "Windows Time Status": {
    "code": "w32tm /query /status",
    "useFor": "Show Windows time synchronization status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Windows Time Source",
      "command:Show Last Boot And Uptime",
      "command:Domain Trust Check"
    ],
    "relationshipFamily": "Windows time",
    "permissionNotes": []
  },
  "Windows Time Source": {
    "code": "w32tm /query /source",
    "useFor": "Show the configured Windows time source.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Windows Time Status",
      "command:Show Last Boot And Uptime",
      "command:Domain Trust Check"
    ],
    "relationshipFamily": "Windows time",
    "permissionNotes": []
  },
  "WinHTTP Proxy": {
    "code": "netsh winhttp show proxy",
    "useFor": "Show the WinHTTP proxy setting.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Domain Trust Check": {
    "code": "Test-ComputerSecureChannel -Verbose",
    "useFor": "Check this computer’s secure channel to its Active Directory domain.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell running as administrator on the target computer.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Entra Join Status",
      "command:Show Group Policy Result",
      "command:Show Configured Dns Servers"
    ],
    "relationshipFamily": "Domain and device identity",
    "permissionNotes": []
  },
  "Printer Check": {
    "code": "Get-Printer | Select-Object Name,DriverName,PortName,PrinterStatus",
    "useFor": "List installed printers and their reported status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "DEPLOY-TCPIP-PRINTER.ps1",
      "command:Print Jobs",
      "command:Spooler Status"
    ],
    "relationshipFamily": "Printing",
    "permissionNotes": []
  },
  "Open Storage Settings": {
    "code": "start ms-settings:storagesense",
    "useFor": "Open Windows storage settings.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Free Space",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "command:Show Free Space",
      "command:Show Physical Disk Health"
    ],
    "relationshipFamily": "Storage",
    "permissionNotes": []
  },
  "Identity and Privileges": {
    "code": "whoami /all",
    "useFor": "Show the current Windows identity, groups, and privileges.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Local Users",
      "command:Show Local Administrators",
      "command:Local Account Details"
    ],
    "relationshipFamily": "Local accounts",
    "permissionNotes": []
  },
  "Entra Join Status": {
    "code": "dsregcmd /status",
    "useFor": "Show this device’s domain and Entra join status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Domain Trust Check",
      "command:Show Group Policy Result",
      "command:Show Configured Dns Servers"
    ],
    "relationshipFamily": "Domain and device identity",
    "permissionNotes": []
  },
  "Mapped Drives": {
    "code": "net use",
    "useFor": "List network drive connections for the current user.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Locally Logged-On Users",
      "command:Show SMB Sessions",
      "command:Show SMB Shares"
    ],
    "relationshipFamily": "Windows sessions and shares",
    "permissionNotes": []
  },
  "Network Profile": {
    "code": "Get-NetConnectionProfile",
    "useFor": "Show Windows network connection profiles.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Ip Configuration",
      "command:Show Routing Table",
      "command:Test Tcp Port"
    ],
    "relationshipFamily": "Network paths",
    "permissionNotes": []
  },
  "Defender Status": {
    "code": "Get-MpComputerStatus | Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,QuickScanEndTime,FullScanEndTime",
    "useFor": "Show Microsoft Defender protection and scan status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "command:Show Recent Windows Update History",
      "command:Show Service Status",
      "command:Show Problem Devices"
    ],
    "relationshipFamily": "Antivirus",
    "permissionNotes": []
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
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "DEPLOY-TCPIP-PRINTER.ps1",
      "command:Printer Check",
      "command:Spooler Status"
    ],
    "relationshipFamily": "Printing",
    "permissionNotes": []
  },
  "Spooler Status": {
    "code": "Get-Service Spooler",
    "useFor": "Show the Print Spooler service status.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell on the computer being checked.",
    "input": "Uses this Windows computer; no target values to enter.",
    "related": [
      "DEPLOY-TCPIP-PRINTER.ps1",
      "command:Printer Check",
      "command:Print Jobs"
    ],
    "relationshipFamily": "Printing",
    "permissionNotes": []
  },
  "Connect Microsoft Graph": {
    "code": "Connect-MgGraph -Scopes \"User.Read\" -ContextScope Process",
    "useFor": "Sign in to Microsoft Graph with permissions chosen for your task.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Microsoft.Graph.Authentication module and consent to the permissions selected for your task.",
    "input": "Delegated scopes required by your task. User.Read below is a basic signed-in-user example; use each task card's scopes for other operations.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "RESET-M365-SESSION.ps1",
      "command:Show Graph Context"
    ],
    "relationshipFamily": "Graph connection",
    "permissionNotes": [
      "This generic connection requests only User.Read for your own profile. It does not prepare tenant-wide tasks; use the selected task’s DETAILS for its exact scopes, roles and consent."
    ]
  },
  "Show Code-Signing Certificates": {
    "code": "Get-ChildItem Cert:\\CurrentUser\\My -CodeSigningCert | Select-Object Subject,Thumbprint,NotAfter",
    "useFor": "List code-signing certificates installed for the current Windows user.",
    "connectFirst": [],
    "checks": [],
    "guards": [],
    "requires": "Windows PowerShell. ",
    "input": "Uses this Windows user and PowerShell session on the current computer.",
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1",
      "command:Verify Script Signature"
    ],
    "relationshipFamily": "Signing and certificates",
    "permissionNotes": []
  }
});

// Approved compact operator cards. Generated from operator-card-specs.json.
window.FIELD_KIT_OPERATOR_CARDS = Object.freeze({
  "GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "name": "Review Account Cleanup",
    "scope": "TENANT",
    "input": "Tenant domain",
    "details": [
      "A review list, not approval to delete accounts or remove access.",
      "Missing checks remain unresolved."
    ],
    "family": "accounts",
    "sourceSha256": "df729d70508b81bf0328f0313d0de406e56f4204c3dc8460ef0ea8bb4eb91606",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review accounts, mailbox access, and licenses for cleanup.",
    "preparation": [
      "Requires Microsoft Graph and Exchange Online PowerShell with authorized tenant access."
    ],
    "related": [
      "GET-STALE-SIGNIN-REVIEW.ps1",
      "GET-TENANT-LICENSING-AUDIT.ps1",
      "GET-USER-PREDELETE-CHECK.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "GET-STALE-SIGNIN-REVIEW.ps1": {
    "name": "Review Stale Sign-ins",
    "scope": "TENANT",
    "input": "Signed-in tenant",
    "details": [
      "Uses recorded Entra activity, not proof that an account is unused.",
      "Missing sign-in history stays unknown."
    ],
    "family": "accounts",
    "sourceSha256": "27e94610728226f9c43f44631b4c9921fc6412ddf8d79f2e2617a7725c1a4fa6",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Find enabled accounts with old or unavailable Entra sign-in activity.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-GUEST-USER-AUDIT.ps1",
      "INVOKE-DISABLE-ACCOUNTS.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "a123394ca9a041cb7f49225b334ce6fe02637038c554944d1c222d325fa72287",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Disable selected user accounts in AD or Entra after approval.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1",
      "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session."
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
    "sourceSha256": "0831cf439bc477cae85d6b6a4f2e2eb1043d4e61d5d4e65964eaa7de658c0eef",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Delete approved user accounts from their authoritative directory.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-ACCOUNT-STATUS.ps1",
      "INVOKE-DISABLE-ACCOUNTS.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "b41987e2a5912652d1e01a953a7dea402c7c49e24d20fade2fddb9f9696478be",
    "presentationRevision": true,
    "releaseVersion": "1.0.4",
    "objective": "Assign a selected Microsoft 365 license to approved users.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-TENANT-LICENSING-AUDIT.ps1",
      "INVOKE-REMOVE-LICENSES.ps1",
      "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session."
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
    "sourceSha256": "0fb9b390bdc16c4e677661003145ac9ab7718c2abedf0f6b44f303971bee2e2c",
    "presentationRevision": true,
    "releaseVersion": "1.0.4",
    "objective": "Remove selected Microsoft 365 licenses from approved users.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-TENANT-LICENSING-AUDIT.ps1",
      "INVOKE-ASSIGN-LICENSES.ps1",
      "GET-USER-PREDELETE-CHECK.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session."
  },
  "RESOLVE-NAMES-TO-UPNS.ps1": {
    "name": "Find User UPNs",
    "scope": "SINGLE or MULTI-USER",
    "input": "Name / email / CSV / TXT",
    "details": [
      "Review ambiguous or missing matches before using the list in another tool."
    ],
    "family": "accounts",
    "sourceSha256": "8b150fd6e093ecf1a4b2b77cc5856f18de47a0f101a8f7257f0eea4742d12f8d",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Find user sign-in names from names, email addresses, or a list.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session."
  },
  "GET-ACCOUNT-STATUS.ps1": {
    "name": "Get User Account Status",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Missing sign-in history does not mean an account is inactive."
    ],
    "family": "accounts",
    "sourceSha256": "94258427439cc292f33bd76e835b10a407218bc9136537874a9cd267f2e20b75",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Show whether selected accounts are enabled and when they last signed in.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-STALE-SIGNIN-REVIEW.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "INVOKE-DISABLE-ACCOUNTS.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "name": "Get Distribution Group Members",
    "scope": "SINGLE or MULTI-GROUP",
    "input": "Group name / email / CSV / TXT",
    "details": [
      "For distribution groups in Exchange Online.",
      "Nested groups are not a complete access review."
    ],
    "family": "groups",
    "sourceSha256": "c91680865f7bc992c7638f1a5c3e371a281ed52100a2a3fc979b87d8321af676",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "List direct members of selected Exchange distribution groups.",
    "preparation": [
      "Requires ExchangeOnlineManagement and an account authorized to read the selected distribution groups."
    ],
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1",
      "GET-USER-GROUPS.ps1"
    ],
    "inputExample": {
      "header": "Group",
      "values": [
        "Finance",
        "Support"
      ]
    },
    "finishPrompt": "Press Enter to close session."
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
    "sourceSha256": "5c7baa7d0551de2eb0c21650bb8943ca198697c94cef2f556a5ab458f7916d67",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "List direct members of selected groups.",
    "preparation": [
      "Requires Exchange Online PowerShell; Entra or AD results also need access to that directory."
    ],
    "related": [
      "GET-USER-GROUPS.ps1",
      "INVOKE-REMOVE-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "inputExample": {
      "header": "Group",
      "values": [
        "Finance",
        "Support"
      ]
    },
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "GET-USER-GROUPS.ps1": {
    "name": "Get User Groups",
    "scope": "SINGLE or MULTI-USER",
    "input": "UPN / CSV / TXT",
    "details": [
      "Lists direct groups, not every source of access.",
      "AD and Entra results are separate; failed coverage stays unresolved."
    ],
    "family": "groups",
    "sourceSha256": "d0b71178ddca2eb793610f21d5f52266d454360ca848d7257ebb3347d6ec9bdd",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "List the selected users' direct groups in AD and Entra.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant.",
      "For AD results, use a domain-connected Windows computer with the AD tools installed."
    ],
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "INVOKE-REMOVE-USER-GROUPS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "8bc820639a1d6e1479e0b1c7a2a1f58953fb0eb5396f922628a73855b0e3fc54",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Remove selected users from eligible AD and Entra groups.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-USER-GROUPS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "GET-TENANT-GROUP-OWNERS.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session."
  },
  "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "name": "Create Dynamic License Group",
    "scope": "SINGLE-GROUP",
    "input": "Tenant and group settings + tenant ID",
    "details": [
      "Creates membership based on assigned licenses; does not assign licenses to the group.",
      "Review the membership rule before creating the group."
    ],
    "family": "licenses",
    "sourceSha256": "7ed4b8f50be401d4004b6ff4672d19bcad5ab6e7f47cf7bc3d0a3e144290f83d",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Create a group that automatically includes users with assigned licenses.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-TENANT-LICENSING-AUDIT.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "INVOKE-ASSIGN-LICENSES.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TENANT-GROUP-OWNERS.ps1": {
    "name": "Get Group Owners",
    "scope": "TENANT",
    "input": "Signed-in tenant",
    "details": [
      "Missing owners and failed checks are different findings."
    ],
    "family": "groups",
    "sourceSha256": "dc04a5c13230de80a767d325a6739c3df6240618d20e6419315cb96a43f224b0",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "List group owners and identify groups without an assigned owner.",
    "preparation": [
      "Requires Microsoft Graph and Exchange Online PowerShell with authorized tenant access."
    ],
    "related": [
      "GET-GROUP-MEMBERS.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-DISTRIBUTION-GROUP-MEMBERS.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "GET-MAILBOX-PERMISSIONS.ps1": {
    "name": "Get Mailbox Permissions",
    "scope": "SINGLE or MULTI-MAILBOX",
    "input": "Mailbox UPN / CSV / TXT",
    "details": [
      "Reviews forwarding, delegates and inbox rules.",
      "Investigate unexpected access before removing it."
    ],
    "family": "mail",
    "sourceSha256": "76535edd6d3e922cc44decedba707203716788afa4bdabbf68579549a57752e6",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Review forwarding, delegated access, and inbox rules for selected mailboxes.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session."
  },
  "GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "name": "Get Mailbox Security",
    "scope": "SINGLE-MAILBOX",
    "input": "Mailbox UPN",
    "details": [
      "Use for a focused review of one mailbox.",
      "Unresolved checks are not evidence that the mailbox is clear."
    ],
    "family": "mail",
    "sourceSha256": "e9e75ef77efeb81017c8dcc6f3f05cd5deb4fb8eba90890560808406762f7fda",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review one mailbox for unexpected access, forwarding, and suspicious rules.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-TENANT-INBOX-RULES-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-MAILBOX-FORWARDING.ps1": {
    "name": "Get Mailbox Forwarding",
    "scope": "SINGLE or MULTI-MAILBOX",
    "input": "Mailbox UPN / CSV / TXT",
    "details": [
      "Unexpected forwarding needs investigation before changes."
    ],
    "family": "mail",
    "sourceSha256": "0e184a41bd351c391985118eb128eaefad0311ec691abe4933868e6af5a88d91",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Show where selected mailboxes forward incoming email.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-TRANSPORT-RULES-AUDIT.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "INVOKE-LITIGATION-HOLD.ps1": {
    "name": "Set Litigation Hold",
    "scope": "SINGLE or MULTI-MAILBOX",
    "input": "Mailbox UPN / CSV / TXT",
    "details": [
      "Confirm the retention decision and required licensing first.",
      "Applies an unlimited hold after review."
    ],
    "family": "mail",
    "sourceSha256": "1ea2ff740e1f5eb24ba4aafa92636fce025ed90ffbc4050e80ce5aedcb3568fe",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Enable an unlimited litigation hold on approved mailboxes.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-USER-PREDELETE-CHECK.ps1",
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-ACCOUNT-STATUS.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session."
  },
  "BEC-INVOKE-EMAIL-RECOVERY.ps1": {
    "name": "BEC: Restore Email",
    "scope": "SINGLE-MAILBOX",
    "input": "Mailbox + source and destination folders",
    "details": [
      "Moves messages between folders in a mailbox you can access.",
      "Delivery-trace exports are not recovery sources. Review the source folder before confirming."
    ],
    "family": "ir-mail",
    "sourceSha256": "bbbe2551ba6054995d4caa517e23a32711c0afbd4b7becbf2a5575662409482f",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Restore previously moved email to the selected mailbox.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant.",
      "You need access to the target mailbox and folders; an admin role alone is not enough."
    ],
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-INVOKE-EMAIL-RECOVERY.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-INVOKE-EMAIL-RECOVERY.ps1",
      "Incident Response: Restore Email"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-RISK-ASSESSMENT.ps1": {
    "name": "BEC: Assess User Risk",
    "scope": "SINGLE-USER",
    "input": "User sign-in address and Microsoft 365 domain or tenant ID",
    "details": [
      "Use the approved support computer and keep the workflow in one PowerShell window.",
      "Review findings and unavailable checks before deciding on containment."
    ],
    "family": "ir-workflow",
    "sourceSha256": "94526ec8ea67e88d9373d1cdb9beadf7ec4992b80cafcd4a97797c2a10c488f4",
    "presentationRevision": false,
    "releaseVersion": "1.0.3",
    "objective": "Review one user's account and mailbox before choosing a response.",
    "preparation": [
      "Use the approved Windows support computer with Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+."
    ],
    "related": [
      "BEC-CONTAIN-ERADICATE.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "workflowReview": {
      "kind": "bec-naming",
      "version": "1.0.3",
      "sourceSha256": "94526ec8ea67e88d9373d1cdb9beadf7ec4992b80cafcd4a97797c2a10c488f4",
      "baselineVerification": {
        "version": "1.0.0",
        "sha256": "07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b",
        "operatorTested": true,
        "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
      },
      "nonPresentationSha256": "ff31eb0a23789f8c987a4518eed398728639f25d7201bcd4db925a2b80e4b227",
      "evidence": "docs/qa/BEC-NAMING-REVIEW.json",
      "priorReview": {
        "kind": "uri-boundary-fix",
        "version": "1.0.2",
        "sourceSha256": "8e89a03bcf61addd53da9b3e43b4517e89a609db434151832ac7625cb7c4c791",
        "baselineVerification": {
          "version": "1.0.0",
          "sha256": "07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b",
          "operatorTested": true,
          "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
        },
        "nonPresentationSha256": "75bf88444949d04fb4b4e8b32d661ea082e8eb084bc24fa8740249ea332c2a80",
        "evidence": "docs/qa/BEC-APP-LOOKUP-FIX.md"
      },
      "priorSourceSha256": "8e89a03bcf61addd53da9b3e43b4517e89a609db434151832ac7625cb7c4c791"
    },
    "operationalRevision": true,
    "legacyFiles": [
      "ir-risk-assessment.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "ir-risk-assessment.ps1",
      "BEC: Assess User Risk"
    ]
  },
  "BEC-CONTAIN-ERADICATE.ps1": {
    "name": "BEC: Contain and Clean Up",
    "scope": "SINGLE-USER",
    "input": "User sign-in address and Microsoft 365 domain or tenant ID",
    "details": [
      "Use the same PowerShell window as assessment.",
      "Maintain containment until cleanup and recovery are approved.",
      "Temporary passwords can remain in terminal capture/transcripts. The operator confirms trusted MFA methods."
    ],
    "family": "ir-workflow",
    "sourceSha256": "c8b857d6191a6bceecb651413552cad0bbc8a421046bfe2a95390728cb89ce10",
    "presentationRevision": false,
    "releaseVersion": "1.0.3",
    "objective": "Contain and clean up one compromised account after approval.",
    "preparation": [
      "Use the approved Windows support computer with Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+."
    ],
    "related": [
      "BEC-RISK-ASSESSMENT.ps1",
      "BEC-RECOVER-VALIDATE.ps1",
      "GET-TRANSPORT-RULES-AUDIT.ps1"
    ],
    "workflowReview": {
      "kind": "bec-naming",
      "version": "1.0.3",
      "sourceSha256": "c8b857d6191a6bceecb651413552cad0bbc8a421046bfe2a95390728cb89ce10",
      "baselineVerification": {
        "version": "1.0.0",
        "sha256": "e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb",
        "operatorTested": true,
        "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
      },
      "nonPresentationSha256": "eb522ff1bde245fc1b18884bb21039f5e2267930d9e31d35c9f504590a94c64b",
      "evidence": "docs/qa/BEC-NAMING-REVIEW.json",
      "priorReview": {
        "kind": "presentation-only",
        "version": "1.0.2",
        "sourceSha256": "be8b1fd589c6225bd44ad6317e173c06a3d54ba2720223d397ea24d5bb4043da",
        "baselineVerification": {
          "version": "1.0.0",
          "sha256": "e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb",
          "operatorTested": true,
          "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
        },
        "nonPresentationSha256": "a51b84573ab23050cf3e5352680c36b069ae0529eb75f81e215f914809823198",
        "evidence": "docs/qa/RELATIONSHIP-ALIGNMENT-REVIEW.md"
      },
      "priorSourceSha256": "be8b1fd589c6225bd44ad6317e173c06a3d54ba2720223d397ea24d5bb4043da"
    },
    "operationalRevision": true,
    "legacyFiles": [
      "ir-contain-eradicate.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "ir-contain-eradicate.ps1",
      "BEC: Contain and Clean Up"
    ]
  },
  "BEC-GET-DATA-EXFIL-ACTIVITY.ps1": {
    "name": "BEC: Review File Activity",
    "scope": "SINGLE-USER",
    "input": "UPN and time range",
    "details": [
      "Activity can suggest exposure; it does not prove data theft.",
      "Log availability limits the review."
    ],
    "family": "ir-investigate",
    "sourceSha256": "1fa5c320ff44327b602d61a94ba5a76b9571b51fdbf36c77be0c59e34795fad1",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Review a user's file activity for possible data exposure.",
    "preparation": [
      "Requires Exchange Online PowerShell and permission to read the requested records."
    ],
    "related": [
      "BEC-GET-TIMELINE-BUILDER.ps1",
      "BEC-GET-IP-TRACE.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-GET-DATA-EXFIL-ACTIVITY.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-GET-DATA-EXFIL-ACTIVITY.ps1",
      "Incident Response: Review File Activity"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-GET-IP-TRACE.ps1": {
    "name": "BEC: Trace IP Activity",
    "scope": "TENANT",
    "input": "IP address and time range",
    "details": [
      "An IP match needs context before attributing activity to a person."
    ],
    "family": "ir-investigate",
    "sourceSha256": "a97b049fad9c2a2f7f4344bc90a68689d1e1d5c4f720f2b6533b5106ae69970a",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Find tenant audit activity associated with a selected IP address.",
    "preparation": [
      "Requires Exchange Online PowerShell and permission to read the requested records."
    ],
    "related": [
      "GET-SIGNIN-ANOMALIES.ps1",
      "BEC-GET-THREAT-INTEL-ACTIVITY.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-GET-IP-TRACE.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-GET-IP-TRACE.ps1",
      "Incident Response: Trace IP Activity"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-GET-TENANT-EMAIL-SEARCH.ps1": {
    "name": "BEC: Trace Email Delivery",
    "scope": "TENANT",
    "input": "Sender / recipient / IP + time range",
    "details": [
      "Searches delivery records, not message bodies or attachments.",
      "Does not create a recovery folder or restore email."
    ],
    "family": "ir-mail",
    "sourceSha256": "3a78895cbec147f408f82929e720c7e527c8bd3f18dad6d86c1e31ee1c868043",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Find email delivery records by sender, recipient, or IP address.",
    "preparation": [
      "Requires Exchange Online PowerShell and permission to read the requested records."
    ],
    "related": [
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-TRANSPORT-RULES-AUDIT.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-GET-TENANT-EMAIL-SEARCH.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-GET-TENANT-EMAIL-SEARCH.ps1",
      "Incident Response: Trace Email Delivery"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "name": "BEC: Check IP Reputation",
    "scope": "SINGLE or MULTI-IP",
    "input": "Public IP / TXT + provider API keys",
    "details": [
      "Sends selected public IPs to VirusTotal or AbuseIPDB.",
      "Reputation is context, not a verdict on compromise."
    ],
    "family": "ir-investigate",
    "sourceSha256": "e0864cdd7dd81324a3b1a71fbf80841c14d3bd86d0ca7abb100416b4a243461e",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Check selected public IP addresses against external reputation services.",
    "preparation": [
      "Have an API key for each provider you enable."
    ],
    "related": [
      "BEC-GET-IP-TRACE.ps1",
      "GET-SIGNIN-ANOMALIES.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-GET-THREAT-INTEL-ACTIVITY.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-GET-THREAT-INTEL-ACTIVITY.ps1",
      "Incident Response: Check IP Reputation"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-GET-TIMELINE-BUILDER.ps1": {
    "name": "BEC: Build Incident Timeline",
    "scope": "LOCAL",
    "input": "Evidence files",
    "details": [
      "Combines supplied evidence; it does not collect missing events.",
      "When event time is unavailable, labels the file’s modified time separately. Check time zones and gaps before drawing conclusions."
    ],
    "family": "ir-investigate",
    "sourceSha256": "a80ca2ee465da49ebb7d38b6728265be427d93a4aa7eb129d3e18f202a4b5ecf",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Combine supplied incident evidence into a timeline.",
    "preparation": [],
    "related": [
      "BEC-GET-IP-TRACE.ps1",
      "BEC-GET-DATA-EXFIL-ACTIVITY.ps1",
      "BEC-GET-TOKEN-REPLAY-CHECK.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-GET-TIMELINE-BUILDER.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-GET-TIMELINE-BUILDER.ps1",
      "Incident Response: Build Incident Timeline"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-GET-TOKEN-DECODE.ps1": {
    "name": "BEC: Decode Token",
    "scope": "LOCAL",
    "input": "Token",
    "details": [
      "Decodes locally without sending the token to a service.",
      "A decoded token is not proof of authenticity or current access."
    ],
    "family": "ir-investigate",
    "sourceSha256": "809933ffd6759b71b20324825887e7d5b1530e1eecce8d8d0cd92c3ce5a57742",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Read a token's contents locally without sending it online.",
    "preparation": [],
    "related": [
      "BEC-GET-TOKEN-REPLAY-CHECK.ps1",
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-SIGNIN-ANOMALIES.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-GET-TOKEN-DECODE.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-GET-TOKEN-DECODE.ps1",
      "Incident Response: Decode Token"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-GET-TOKEN-REPLAY-CHECK.ps1": {
    "name": "BEC: Review Token Replay",
    "scope": "SINGLE-USER",
    "input": "UPN and time range",
    "details": [
      "Looks for indicators that need investigation, not a definitive compromise verdict.",
      "Missing logs limit the result."
    ],
    "family": "ir-investigate",
    "sourceSha256": "aacd5c9a0c91ecbd16ceedaa14b433aba25f882f3752efd903996bfc95dbfbde",
    "presentationRevision": false,
    "releaseVersion": "1.0.4",
    "objective": "Review sign-ins for indicators of token replay or session theft.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-SIGNIN-ANOMALIES.ps1",
      "BEC-GET-IP-TRACE.ps1",
      "BEC-GET-TIMELINE-BUILDER.ps1"
    ],
    "operationalRevision": true,
    "legacyFiles": [
      "IR-GET-TOKEN-REPLAY-CHECK.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "IR-GET-TOKEN-REPLAY-CHECK.ps1",
      "Incident Response: Review Token Replay"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "name": "Audit Shared Mailbox Sign-ins",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review unexpected direct sign-ins separately from delegated mailbox use."
    ],
    "family": "mail-audit",
    "sourceSha256": "3f365d6e8677b2f59f1e3fba81f038c6645dd0e1e3a95b28c95804b161f06009",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Find sign-in activity associated with shared mailboxes.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1",
      "GET-SIGNIN-ANOMALIES.ps1",
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-APP-REGISTRATION-AUDIT.ps1": {
    "name": "Audit App Registrations",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review unfamiliar apps and expiring credentials with their owners."
    ],
    "family": "apps",
    "sourceSha256": "76613d8367421f66d7c546b3543168109eadfec80618fa46905ad3a2b3403a5d",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review registered apps, ownership, and credential expiry dates.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-SERVICE-PRINCIPAL-OWNERS.ps1",
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-GUEST-APP-CONSENT-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
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
    "sourceSha256": "adebcd1ba46cb0e58a7ac4381547d2aa7f501a906b5c521d27ca0ac9121b6555",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Find Conditional Access settings and exclusions that need review.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MFA-SECURITY-AUDIT.ps1",
      "GET-DEVICE-CODE-EXPOSURE.ps1",
      "GET-SIGNIN-ANOMALIES.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-DEVICE-CODE-EXPOSURE.ps1": {
    "name": "Review Device Code Exposure",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Reviews policy exposure rather than proving an attack occurred."
    ],
    "family": "security",
    "sourceSha256": "9595b261ea55f5fc61dd562df2e5297cd8d3fa8bf587d0d61cce5535df93e27b",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review policies for gaps in device-code sign-in protection.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-CONDITIONAL-ACCESS-GAPS.ps1",
      "GET-SIGNIN-ANOMALIES.ps1",
      "GET-OAUTH-CONSENT-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "name": "Audit Guest App Consent",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review permissions with an owner before removing consent."
    ],
    "family": "apps",
    "sourceSha256": "0e9676a036af440268ac33d3007fa34c05505e2765462a7143b2caa208585721",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review guest users and their app permissions.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-GUEST-USER-AUDIT.ps1",
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-SERVICE-PRINCIPAL-OWNERS.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
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
    "sourceSha256": "da69d7308448b31477b9de6ff104257a891562902ec0142a5b053b70482d73a5",
    "presentationRevision": false,
    "releaseVersion": "1.0.3",
    "objective": "Review MFA registration and the policies intended to protect sign-ins.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-CONDITIONAL-ACCESS-GAPS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-ADMIN-ROLE-AUDIT.ps1"
    ],
    "operationalRevision": true,
    "finishPrompt": "Press Enter to close session."
  },
  "GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "name": "Get Secure Score",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "A score is a prioritization aid, not proof that the tenant is secure."
    ],
    "family": "security",
    "sourceSha256": "bf4d87b38d221c5e6b86fef69b10a1cb7c4d75e6fe8c5abe64ec5c99993f3e5d",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Show the tenant's latest Microsoft Secure Score.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-TENANT-SECURITY-SNAPSHOT.ps1",
      "GET-CONDITIONAL-ACCESS-GAPS.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "name": "Get Enterprise App Owners",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Ownerless apps need an accountable owner before changes."
    ],
    "family": "apps",
    "sourceSha256": "7f300774005a7ba46d354c17b02cec9f09ca34863edaf8b057159cca7bef5885",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "List enterprise app owners and identify apps without an owner.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-APP-REGISTRATION-AUDIT.ps1",
      "GET-OAUTH-CONSENT-AUDIT.ps1",
      "GET-GUEST-APP-CONSENT-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-SIGNIN-ANOMALIES.ps1": {
    "name": "Review Sign-in Anomalies",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review unusual activity in context before containment."
    ],
    "family": "security",
    "sourceSha256": "dcde2b39589b9c740a7a9c20ff17cc59d8752cc555a9359f9d0210e18fa053b1",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Find unusual sign-in activity that needs investigation.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "BEC-GET-IP-TRACE.ps1",
      "BEC-GET-TOKEN-REPLAY-CHECK.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TRANSPORT-RULES-AUDIT.ps1": {
    "name": "Audit Mail Flow Rules",
    "scope": "TENANT",
    "input": "Signed-in tenant",
    "details": [
      "Review rule intent and business impact before making changes."
    ],
    "family": "mail-audit",
    "sourceSha256": "7c4ff63bee17b5669a05a76657f3cca0b5b3674b102ead014df742ae720c62ae",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review mail flow rules for settings that need attention.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1",
      "GET-MAILBOX-FORWARDING.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "name": "Join Computer to Domain",
    "scope": "LOCAL",
    "input": "Domain + join credentials",
    "details": [
      "Run as administrator; the computer must reach the domain.",
      "Plan for restart and sign-in changes."
    ],
    "family": "endpoint",
    "sourceSha256": "231cef1b8c4ca32837fa4ece5cc04162eb1de0371f3fd69a6fd7aa839bd6f147",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Join the current computer to the selected AD domain.",
    "preparation": [],
    "related": [
      "command:Domain Trust Check",
      "command:DNS Lookup",
      "BACKUP-USER-PROFILE.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "DEPLOY-TCPIP-PRINTER.ps1": {
    "name": "Install Network Printer",
    "scope": "LOCAL",
    "input": "Printer address and driver",
    "details": [
      "Have the printer address ready."
    ],
    "family": "endpoint",
    "sourceSha256": "adcb0d7445bbc847c2f1d7a22dcf5c12c645a68a81036c38dd510c67bd3821d1",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Install a network printer using its address and selected driver.",
    "preparation": [
      "Have the approved printer driver installed and permission to add printers."
    ],
    "related": [
      "command:Printer Check",
      "command:Print Jobs",
      "command:Spooler Status"
    ],
    "finishPrompt": "Press Enter to close session."
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
    "sourceSha256": "dd1d1e62acc1343f0c5010dc93ebd5cf29671ff42d9876580c3f1ef7b285988d",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Copy selected user-profile folders to a backup location.",
    "preparation": [],
    "related": [
      "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
      "GET-FOLDER-INVENTORY.ps1",
      "TEST-SENSITIVE-DATA.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "TEST-POWERSHELL-READINESS.ps1": {
    "name": "Check M365 PowerShell Readiness",
    "scope": "LOCAL",
    "input": "Current computer",
    "details": [
      "Reviews prerequisites without installing them."
    ],
    "family": "setup",
    "sourceSha256": "fee19c4cac0b5638a8f6515eb4be8734135c997d63c4b21e7f71b33a8a21e314",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Check this computer for Microsoft 365 PowerShell prerequisites.",
    "preparation": [],
    "related": [
      "INSTALL-M365-MODULES.ps1",
      "RESET-M365-SESSION.ps1",
      "GET-TERMINAL-READINESS-CHECK.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "GET-FOLDER-INVENTORY.ps1": {
    "name": "Review Folder Contents",
    "scope": "LOCAL",
    "input": "Folder",
    "details": [
      "Shows files, signatures and available Git indicators in the chosen folder.",
      "Does not compare content hashes to find duplicate files."
    ],
    "family": "files",
    "sourceSha256": "218d4e788913c6a6d8d6578d8b1912cf7f68a8c4687ecaf6d557bbd4ea26cd60",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Review a folder's files, script signatures, and Git status.",
    "preparation": [],
    "related": [
      "INVOKE-FILE-INVENTORY.ps1",
      "INVOKE-MAP-KIT.ps1",
      "TEST-SENSITIVE-DATA.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "6c5fb208fea47d9588354590817362336e644bc4887127f317d4816161c0b4a2",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Install or update the selected Microsoft 365 PowerShell modules.",
    "preparation": [],
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "RESET-M365-SESSION.ps1",
      "GET-TERMINAL-READINESS-CHECK.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "TEST-SENSITIVE-DATA.ps1": {
    "name": "Check Sensitive Data",
    "scope": "LOCAL",
    "input": "Files or folder",
    "details": [
      "Findings need review; a clean scan is not proof that all sensitive information is absent."
    ],
    "family": "files",
    "sourceSha256": "594d18150acb832080f13776581f6d8d8d21d3addc7e14aa8aea017b76e9b69e",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Scan selected files for potentially sensitive information before sharing.",
    "preparation": [],
    "related": [
      "git-handoff.ps1",
      "INVOKE-FILE-INVENTORY.ps1",
      "SIGN-FOLDER-SCRIPTS.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "a08270181dc4ac7ac0cb78fd8f651701a40ce25b668342a4e0a829fb09246809",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Disconnect Microsoft 365 services in the current PowerShell window.",
    "preparation": [],
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INVOKE-SESSION-RESET.ps1",
      "INSTALL-M365-MODULES.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "UPDATE-WINDOWS-APPS.ps1": {
    "name": "Update Windows Apps",
    "scope": "LOCAL",
    "input": "Current computer",
    "details": [
      "Review available updates and allow for app restarts."
    ],
    "family": "endpoint",
    "sourceSha256": "32fcfc1c298460301dc5fe7841bb5bddb768691e23f7c9f28270c5396349c3c3",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review and update installed applications using WinGet.",
    "preparation": [],
    "related": [
      "command:Show Available WinGet Updates",
      "command:Show WinGet Package Information",
      "command:Update Specific WinGet Package"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "4ae5545f73829374e5b1500bd3ba8cc029e3f095e700e9ce76bf835d8a034107",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review a user's mailbox, memberships, and access before deletion.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "INVOKE-LITIGATION-HOLD.ps1",
      "INVOKE-DELETE-ACCOUNTS.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "23a9db7bcacb8f388d2e71b3cc54b720a00b9d377af7c10bac263b32f0008b62",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Require per-user MFA for selected accounts after approval.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MFA-SECURITY-AUDIT.ps1",
      "GET-CONDITIONAL-ACCESS-GAPS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "GET-ADMIN-ROLE-AUDIT.ps1": {
    "name": "Audit Admin Roles",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review privileged assignments and their business owners."
    ],
    "family": "security",
    "sourceSha256": "764cf4825fa98591a0ab0bde803f96568e1a1c2d8ed4585095eda2460a04aa6c",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "List tenant admin-role assignments for review.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "GET-MFA-SECURITY-AUDIT.ps1",
      "GET-CONDITIONAL-ACCESS-GAPS.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-OAUTH-CONSENT-AUDIT.ps1": {
    "name": "Audit App Consent",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Review granted access and app ownership before removing consent."
    ],
    "family": "apps",
    "sourceSha256": "3f18ee0289321bc6b7cb226c08f33c79c0e4844bc03884ea24a99180699f4251",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review app permissions granted in the tenant.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-APP-REGISTRATION-AUDIT.ps1",
      "GET-SERVICE-PRINCIPAL-OWNERS.ps1",
      "GET-GUEST-APP-CONSENT-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
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
    "sourceSha256": "641555328872d02331f3153eb686b48bf4cf5b21f67c7a9919c0bbef0d75da61",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Find guest accounts that need an ownership or activity review.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-GUEST-APP-CONSENT-AUDIT.ps1",
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-GROUPS.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TENANT-LICENSING-AUDIT.ps1": {
    "name": "Audit Tenant Licenses",
    "scope": "TENANT",
    "input": "Tenant ID",
    "details": [
      "Reviews assignments and capacity; does not change licenses."
    ],
    "family": "licenses",
    "sourceSha256": "d9d7da1dc4f720953848f56fa4c68ae594c7b183ed3f07f623d511321a2aae07",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review Microsoft 365 license capacity and user assignments.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "INVOKE-ASSIGN-LICENSES.ps1",
      "INVOKE-REMOVE-LICENSES.ps1",
      "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "name": "Audit Tenant Inbox Rules",
    "scope": "TENANT",
    "input": "Signed-in tenant",
    "details": [
      "Defaults to user mailboxes and all rules.",
      "Use -IncludeShared to include shared mailboxes or -SuspiciousOnly to show flagged rules; these options require a terminal.",
      "Investigate suspicious rules before removing them."
    ],
    "family": "mail-audit",
    "sourceSha256": "c0a1a2459471df298746940de9a997ee60514cbec0bb11a821f4c7e2233c66f6",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Find mailbox inbox rules that need review across the tenant.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-MAILBOX-FORWARDING.ps1",
      "GET-TRANSPORT-RULES-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-USER-SECURITY-SNAPSHOT.ps1": {
    "name": "Get User Security",
    "scope": "SINGLE-USER",
    "input": "UPN",
    "details": [
      "A starting point for investigation, not an all-clear verdict."
    ],
    "family": "security",
    "sourceSha256": "b9d8d41d6fe83eb0c5b3c8cb6d71989719d8622bc359116fc20618814399cff6",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review one user's account, authentication, access, and recent sign-ins.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
      "GET-USER-GROUPS.ps1",
      "GET-ACCOUNT-STATUS.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "name": "Get Tenant Security",
    "scope": "TENANT",
    "input": "Signed-in tenant",
    "details": [
      "A broad starting point; use focused audits for follow-up."
    ],
    "family": "security",
    "sourceSha256": "342829ae9c8df76225bdee4e0c76776aabb76a43a3c5756363a6add984ca0666",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Get a broad overview of the tenant's security settings and review areas.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MFA-SECURITY-AUDIT.ps1",
      "GET-CONDITIONAL-ACCESS-GAPS.ps1",
      "GET-OAUTH-CONSENT-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-ROOM-RESOURCE-ACCESS.ps1": {
    "name": "Get Resource Mailbox Access",
    "scope": "SINGLE or MULTI-MAILBOX",
    "input": "Resource mailbox names or addresses",
    "details": [
      "Use an actual room or equipment mailbox, not a security group.",
      "Enter one or more mailbox names or addresses, separated by commas. File input is not supported."
    ],
    "family": "mail",
    "sourceSha256": "476e8e8458b73432ec3c1e5d90be596b6472cece0e43c79cddc4b1de1693e1ad",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review delegated access and booking permissions for resource mailboxes.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-GROUP-MEMBERS.ps1",
      "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "name": "Audit Tenant Mailbox Access",
    "scope": "TENANT",
    "input": "Signed-in tenant",
    "details": [
      "Review unexpected forwarding or delegated access before changes."
    ],
    "family": "mail-audit",
    "sourceSha256": "90eadb894e2aa8ac36f62047a4c4aadcac67aa468c8bbbf583ec0992e6fc6e9c",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review mailbox forwarding and delegated access across the tenant.",
    "preparation": [
      "Requires Exchange Online PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-TENANT-INBOX-RULES-AUDIT.ps1",
      "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "name": "Remove Disabled User Mailbox Access",
    "scope": "SINGLE-USER",
    "input": "Disabled user UPN",
    "details": [
      "Checks one disabled user across mailboxes; does not process a list of users.",
      "Review the removal plan before confirming."
    ],
    "family": "mail",
    "sourceSha256": "c50e6a31dbf37dea44f651d4cfdced99ba4f3ce053a8ec3e75edb1a8f4fb504d",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Remove approved mailbox access held by one disabled user.",
    "preparation": [
      "Requires Microsoft Graph and Exchange Online PowerShell with authorized tenant access."
    ],
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-MAILBOX-PERMISSIONS.ps1",
      "GET-USER-PREDELETE-CHECK.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TENANT-DRIFT-REVIEW.ps1": {
    "name": "Review Tenant Changes",
    "scope": "TENANT",
    "input": "Signed-in tenant + optional saved baseline",
    "details": [
      "If no baseline exists, asks before saving the current settings as a local baseline.",
      "Investigate differences before replacing an existing baseline; a changed setting is not automatically an incident."
    ],
    "family": "security",
    "sourceSha256": "f5f1fdd5b2d6739ecc07989244e5da3f36811d1589109d4e7892609e937abfc2",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Compare tenant settings with a saved baseline and review changes.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-TENANT-SECURITY-SNAPSHOT.ps1",
      "GET-CONDITIONAL-ACCESS-GAPS.ps1",
      "GET-OAUTH-CONSENT-AUDIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "name": "Review Windows Storage",
    "scope": "LOCAL",
    "input": "This computer; C: drive by default",
    "details": [
      "Defaults to C: and the ten largest files; no files are deleted.",
      "Use -ComputerName, -DriveLetter or -TopFiles in a terminal to change the scan. Remote scans require PowerShell remoting."
    ],
    "family": "endpoint",
    "sourceSha256": "7af474157506fd00c85b064ec037e09286c7776e4b088b28e8af36d6f3cbc85d",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Find Windows storage that may be reclaimable without deleting files.",
    "preparation": [],
    "related": [
      "BACKUP-USER-PROFILE.ps1",
      "INVOKE-FILE-INVENTORY.ps1",
      "INVOKE-MAP-KIT.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "40abec4baa9461a7ce2f60159d747340023985fe505191d1d7e530873d7b674a",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Reset passwords for selected cloud-only users after approval.",
    "preparation": [
      "Requires Microsoft Graph PowerShell and authorized access to the target tenant."
    ],
    "related": [
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1",
      "INVOKE-ENFORCE-PER-USER-MFA.ps1"
    ],
    "inputExample": {
      "header": "UPN",
      "values": [
        "alex@example.com",
        "sam@example.com"
      ]
    },
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "BEC-RECOVER-VALIDATE.ps1": {
    "name": "BEC: Restore and Validate",
    "scope": "SINGLE-USER",
    "input": "User sign-in address and Microsoft 365 domain or tenant ID",
    "details": [
      "Use the same workflow window and approved recovery decision.",
      "Confirm sign-in and MFA before closing the incident."
    ],
    "family": "ir-workflow",
    "sourceSha256": "1b21a21f15d6618c0964c37ab21e0c167cfba5616efe8d108dbb18ac1aa0ce4e",
    "presentationRevision": false,
    "releaseVersion": "1.0.3",
    "objective": "Check recovery readiness and restore approved account access.",
    "preparation": [
      "Use the approved Windows support computer with Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+."
    ],
    "related": [
      "BEC-CONTAIN-ERADICATE.ps1",
      "GET-ACCOUNT-STATUS.ps1",
      "GET-USER-SECURITY-SNAPSHOT.ps1"
    ],
    "workflowReview": {
      "kind": "bec-naming",
      "version": "1.0.3",
      "sourceSha256": "1b21a21f15d6618c0964c37ab21e0c167cfba5616efe8d108dbb18ac1aa0ce4e",
      "baselineVerification": {
        "version": "1.0.0",
        "sha256": "c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04",
        "operatorTested": true,
        "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
      },
      "nonPresentationSha256": "c78fa6007c42f723a7a6be832dadb46253a4f693e4576d970725e66be9741995",
      "evidence": "docs/qa/BEC-NAMING-REVIEW.json",
      "priorReview": {
        "kind": "presentation-only",
        "version": "1.0.2",
        "sourceSha256": "b803ac263f92bb2133711ca7a3b7237bb8ac187930365f71392624a8ab995de5",
        "baselineVerification": {
          "version": "1.0.0",
          "sha256": "c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04",
          "operatorTested": true,
          "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
        },
        "nonPresentationSha256": "141be9986ae42e052f08c0768c107a6f6542c8085836cd01e530847dbe386a6f",
        "evidence": "docs/qa/RELATIONSHIP-ALIGNMENT-REVIEW.md"
      },
      "priorSourceSha256": "b803ac263f92bb2133711ca7a3b7237bb8ac187930365f71392624a8ab995de5"
    },
    "operationalRevision": true,
    "legacyFiles": [
      "ir-recover-validate.ps1"
    ],
    "searchAliases": [
      "IR",
      "incident response",
      "ir-recover-validate.ps1",
      "BEC: Restore and Validate"
    ]
  },
  "git-handoff.ps1": {
    "name": "Save Project Handoff",
    "scope": "LOCAL",
    "input": "Repository",
    "details": [
      "Creates a screened project snapshot; review it before sharing."
    ],
    "family": "git",
    "sourceSha256": "de09cbd42d120d932969dc229fa5437c7770fcdf6aed331f364acf6bec6c6531",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Save a screened snapshot of the current Git project for handoff.",
    "preparation": [
      "Install Git for Windows before running."
    ],
    "related": [
      "TEST-SENSITIVE-DATA.ps1",
      "git-repo.ps1",
      "git-security.ps1"
    ],
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "git-repo.ps1": {
    "name": "Manage Git Repository",
    "scope": "LOCAL",
    "input": "Repository + Check / Pull / Push",
    "details": [
      "Choose Check, Pull or Push when the launch command asks.",
      "Check uses last-known remote state; it does not refresh it. Review the full diff before publishing."
    ],
    "family": "git",
    "sourceSha256": "3bcd5f6b61c9b5b24d3d8adcaa22f584e80bdfe0b612c9a53cacf9d03125b78c",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Review, pull, or push changes in the selected Git repository.",
    "preparation": [
      "Install Git for Windows before running."
    ],
    "related": [
      "TEST-SENSITIVE-DATA.ps1",
      "git-handoff.ps1",
      "git-security.ps1"
    ],
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "git-security.ps1": {
    "name": "Review GitHub Security",
    "scope": "LOCAL",
    "input": "GitHub account + security-log export",
    "details": [
      "Reviews a downloaded JSON, JSON.GZ or ZIP export; does not sign in to GitHub.",
      "A full review with no flags saves a local checkpoint. No findings is not an account-security verdict."
    ],
    "family": "git",
    "sourceSha256": "8082019f51b75c2184dcf74985cc73c80eb31135e8cd2ad3b9aaab5a73ea8352",
    "presentationRevision": true,
    "releaseVersion": "1.0.1",
    "objective": "Review a GitHub security-log export for unfamiliar access and activity.",
    "preparation": [],
    "related": [
      "git-repo.ps1",
      "git-handoff.ps1",
      "TEST-SENSITIVE-DATA.ps1"
    ],
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "set-execution.ps1": {
    "name": "Set Up Script Execution",
    "scope": "LOCAL",
    "input": "Folder of reviewed .ps1 files",
    "details": [
      "Place it beside only the reviewed scripts you intend to unblock.",
      "Managed policies still apply.",
      "Review the folder plan and type SETUP before policy or file changes; blank cancels."
    ],
    "family": "setup",
    "sourceSha256": "4379e986662f2a80092938916ac5d2509fc5b01cb391d95e20b58c91b16ad294",
    "presentationRevision": false,
    "releaseVersion": "1.0.3",
    "objective": "Set local execution policy and unblock scripts beside this file.",
    "notice": "May change your current-user execution policy. Unblocks every .ps1 file beside this file.",
    "preparation": [],
    "related": [
      "SIGN-FOLDER-SCRIPTS.ps1",
      "MANAGE-CERT-SIGNATURES.ps1",
      "TEST-POWERSHELL-READINESS.ps1"
    ],
    "operationalRevision": true,
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "attractor.ps1": {
    "name": "Attractor",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Run in an existing terminal; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "1268680342075976f80599213dd97d25abc2af741a07a7f5de2ceab2c2ba4cc6",
    "presentationRevision": true,
    "releaseVersion": "1.0.1",
    "objective": "Run a floating fractal animation with a clock.",
    "preparation": [],
    "related": [
      "rain.ps1",
      "static.ps1",
      "SET-THEME-COBALT.ps1"
    ]
  },
  "rain.ps1": {
    "name": "Rain",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Run in an existing terminal; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "f793a1a68a8245527597522077f40dda3eeb209bf9c6ad1164f0dde5ef9daf96",
    "presentationRevision": true,
    "releaseVersion": "1.0.1",
    "objective": "Run animated terminal rain with a floating label and clock.",
    "preparation": [],
    "related": [
      "attractor.ps1",
      "static.ps1",
      "SET-THEME-COBALT.ps1"
    ]
  },
  "static.ps1": {
    "name": "Static",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Run in an existing terminal; use its own exit controls."
    ],
    "family": "terminal",
    "sourceSha256": "4aa3ae630d9631f11d110f78925c6e112508b3ccc7ba703f833537bb3c9394e0",
    "presentationRevision": true,
    "releaseVersion": "1.0.1",
    "objective": "Run animated terminal static with a floating label and clock.",
    "preparation": [],
    "related": [
      "attractor.ps1",
      "rain.ps1",
      "SET-THEME-COBALT.ps1"
    ]
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
    "sourceSha256": "2890218ee6951f81e46e0dd5cbc5b4ed38b80ccce031d0b04ad9c3561e654851",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Sign scripts in a selected folder with a code-signing certificate.",
    "preparation": [
      "Have a usable code-signing certificate or approve creating one when prompted."
    ],
    "related": [
      "MANAGE-CERT-SIGNATURES.ps1",
      "TEST-SENSITIVE-DATA.ps1",
      "set-execution.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "GET-TERMINAL-READINESS-CHECK.ps1": {
    "name": "Check Toolkit Setup",
    "scope": "LOCAL",
    "input": "Toolkit folder",
    "details": [
      "Uses a fixed expected toolkit layout; a different layout can be intentional.",
      "Reports missing prerequisites without repairing them."
    ],
    "family": "setup",
    "sourceSha256": "0cdf541f4222218c359dddc9e441343d37ee7ad745cfe5588e06a9a45ad42316",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Check a toolkit folder against the expected files and setup.",
    "preparation": [],
    "related": [
      "INVOKE-MAP-KIT.ps1",
      "GET-FOLDER-INVENTORY.ps1",
      "TEST-POWERSHELL-READINESS.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "INVOKE-FILE-INVENTORY.ps1": {
    "name": "Compare Script Files",
    "scope": "LOCAL",
    "input": "Folder",
    "details": [
      "Compares file names and content hashes; does not delete duplicates.",
      "Optional exports contain local paths and signer details. Review before sharing."
    ],
    "family": "files",
    "sourceSha256": "435f354240c3178c5def5a4b2faaaaa013a7ef0d99f07fcf9170e69801b13279",
    "presentationRevision": true,
    "releaseVersion": "1.0.3",
    "objective": "Compare script versions, signatures, and duplicate content in a folder.",
    "preparation": [],
    "related": [
      "GET-FOLDER-INVENTORY.ps1",
      "INVOKE-MAP-KIT.ps1",
      "TEST-SENSITIVE-DATA.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "INVOKE-MAP-KIT.ps1": {
    "name": "Map Folder Structure",
    "scope": "LOCAL",
    "input": "Folder",
    "details": [
      "Shows folders and files up to the chosen depth.",
      "Reports structure; does not enforce a layout or provide a complete secret scan."
    ],
    "family": "files",
    "sourceSha256": "ea3b5ee21dbd384d7107ec1458be968d7c7c5c00c9998a4dcc2f89856a8372a4",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Show the folder structure and files beneath a selected location.",
    "preparation": [],
    "related": [
      "GET-FOLDER-INVENTORY.ps1",
      "INVOKE-FILE-INVENTORY.ps1",
      "GET-TERMINAL-READINESS-CHECK.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "INVOKE-SESSION-RESET.ps1": {
    "name": "Reset Terminal Session",
    "scope": "LOCAL",
    "input": "Current PowerShell window",
    "details": [
      "Run in the session you want to reset."
    ],
    "family": "setup",
    "sourceSha256": "2fa5b247f31b2dfe29bbed17ec9ffe576e53dbe3ce3e7ffb03f8328c7843dc07",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Clear supported service connections from the current PowerShell session.",
    "preparation": [],
    "related": [
      "RESET-M365-SESSION.ps1",
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "SET-THEME-BASIC.ps1": {
    "name": "Preview Plain Output",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Prints demonstration messages, not real connection or task results.",
      "No startup theme is installed."
    ],
    "family": "terminal",
    "sourceSha256": "9dc01f2210cf808379be2770450283f0d44be72c4d3cae3f9a0087c2f15e98f2",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Show a plain PowerShell output style without color.",
    "preparation": [],
    "related": [
      "SET-THEME-COBALT.ps1",
      "SET-THEME-SEAGLASS.ps1",
      "SET-THEME-SILICON-VALLEY.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "SET-THEME-COBALT.ps1": {
    "name": "Preview Cobalt Theme",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "No startup profile is installed. Close this PowerShell window to end session-only changes."
    ],
    "family": "terminal",
    "sourceSha256": "602ddcb368e716ca73ced3b799d847262faca237ee43b63a7070596ce37d9d2b",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Preview a blue PowerShell theme and output helpers.",
    "notice": "Changes this session’s appearance and sets Process execution policy to Bypass.",
    "preparation": [],
    "related": [
      "SET-THEME-BASIC.ps1",
      "SET-THEME-SEAGLASS.ps1",
      "SET-THEME-SILICON-VALLEY.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "SET-THEME-SEAGLASS.ps1": {
    "name": "Install Sea Glass Theme",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Changes the current-user PowerShell profile and sets Process execution policy to Bypass.",
      "Review the profile first. Remove the SEA GLASS THEME block to undo startup changes."
    ],
    "family": "terminal",
    "sourceSha256": "629b919cea8aabd890151a2402241e426a4c0c331a9a4d5861bd9aaa340e888e",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Install a sea-green PowerShell theme in your startup profile.",
    "notice": "Installs a startup theme, replaces recognized theme blocks, and changes this session’s execution setting.",
    "preparation": [],
    "related": [
      "SET-THEME-COBALT.ps1",
      "SET-THEME-BASIC.ps1",
      "SET-THEME-SILICON-VALLEY.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
  },
  "SET-THEME-SILICON-VALLEY.ps1": {
    "name": "Install Silicon Valley Theme",
    "scope": "LOCAL",
    "input": "Current terminal",
    "details": [
      "Writes the current-user PowerShell profile.",
      "Review the profile first. Remove the SILICON VALLEY THEME block to undo startup changes."
    ],
    "family": "terminal",
    "sourceSha256": "aab04649707578c0c57a9602b80cdae04465bff529fae0373d46f1aa2bc43739",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Install a green PowerShell theme in your startup profile.",
    "notice": "Rewrites startup theme blocks and installs a predictable daily password generator. Never use its output as a password.",
    "preparation": [],
    "related": [
      "SET-THEME-COBALT.ps1",
      "SET-THEME-BASIC.ps1",
      "SET-THEME-SEAGLASS.ps1"
    ],
    "finishPrompt": "Press Enter to close session.",
    "runtimeRequirement": "PowerShell 5.1 or later."
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
    "sourceSha256": "d28176159f671ed1fe1e521f422a89f8de92f5ec032067e16f46156549d683fb",
    "presentationRevision": true,
    "releaseVersion": "1.0.2",
    "objective": "Create, review, export, import, or trust script-signing certificates.",
    "preparation": [],
    "related": [
      "SIGN-FOLDER-SCRIPTS.ps1",
      "set-execution.ps1",
      "TEST-SENSITIVE-DATA.ps1"
    ],
    "finishPrompt": "Press Enter to close session."
  },
  "PREPARE-FIELD-KIT.ps1": {
    "name": "Prepare FIELD KIT",
    "scope": "LOCAL",
    "input": "Current Windows account; Graph, Exchange or both",
    "details": [
      "Installs missing selected modules for this Windows account and PowerShell edition after approval.",
      "CheckOnly makes no installation or repository/provider changes.",
      "AD checks report missing local tools or a domain connection; setup does not install RSAT.",
      "READY verifies selected local prerequisites; each job still needs customer access."
    ],
    "family": "setup",
    "sourceSha256": "8b555611dffc223f909b9e13fa158f0daf472703ac9d42dc8d72d161cd430372",
    "presentationRevision": false,
    "releaseVersion": "1.0.1",
    "objective": "Check this computer and install missing Microsoft 365 PowerShell modules.",
    "preparation": [
      "Use the approved customer-side Windows support computer and the same account you will use for jobs."
    ],
    "notice": "After approval, installs missing local prerequisites. No customer tenant sign-in or permission grants.",
    "related": [
      "TEST-POWERSHELL-READINESS.ps1",
      "INSTALL-M365-MODULES.ps1",
      "START-HERE.md"
    ],
    "runtimeRequirement": "PowerShell 5.1 or later."
  }
});
