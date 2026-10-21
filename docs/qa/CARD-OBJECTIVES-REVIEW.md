# Current card and script objectives

Updated October 21, 2026. Supersedes the earlier objective-only snapshot. All 80 purposes below exactly match their current source objectives. The latest scope, launch and relationship review is in [RELATIONSHIP-ALIGNMENT-REVIEW.md](RELATIONSHIP-ALIGNMENT-REVIEW.md).

77 scripts display their objective in the console. Three animations keep it in source notes so their display remains immersive. BEC controls remain unchanged; their display revisions and prior accepted runtime evidence are separately recorded.

| Script | Card title | Objective |
|---|---|---|
| GET-QUARTERLY-CLEANUP-REVIEW.ps1 | Review Account Cleanup | Review accounts, mailbox access, and licenses for cleanup. |
| GET-STALE-SIGNIN-REVIEW.ps1 | Review Stale Sign-ins | Find enabled accounts with old or unavailable Entra sign-in activity. |
| INVOKE-DISABLE-ACCOUNTS.ps1 | Disable User Accounts | Disable selected user accounts in AD or Entra after approval. |
| INVOKE-DELETE-ACCOUNTS.ps1 | Delete User Accounts | Delete approved user accounts from their authoritative directory. |
| INVOKE-ASSIGN-LICENSES.ps1 | Assign User Licenses | Assign a selected Microsoft 365 license to approved users. |
| INVOKE-REMOVE-LICENSES.ps1 | Remove User Licenses | Remove selected Microsoft 365 licenses from approved users. |
| RESOLVE-NAMES-TO-UPNS.ps1 | Find User UPNs | Find user sign-in names from names, email addresses, or a list. |
| GET-ACCOUNT-STATUS.ps1 | Get User Account Status | Show whether selected accounts are enabled and when they last signed in. |
| GET-DISTRIBUTION-GROUP-MEMBERS.ps1 | Get Distribution Group Members | List direct members of selected Exchange distribution groups. |
| GET-GROUP-MEMBERS.ps1 | Get Group Members | List direct members of selected groups. |
| GET-USER-GROUPS.ps1 | Get User Groups | List the selected users' direct groups in AD and Entra. |
| INVOKE-REMOVE-USER-GROUPS.ps1 | Remove User Groups | Remove selected users from eligible AD and Entra groups. |
| INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1 | Create Dynamic License Group | Create a group that automatically includes users with assigned licenses. |
| GET-TENANT-GROUP-OWNERS.ps1 | Get Group Owners | List group owners and identify groups without an assigned owner. |
| GET-MAILBOX-PERMISSIONS.ps1 | Get Mailbox Permissions | Review forwarding, delegated access, and inbox rules for selected mailboxes. |
| GET-MAILBOX-SECURITY-SNAPSHOT.ps1 | Get Mailbox Security | Review one mailbox for unexpected access, forwarding, and suspicious rules. |
| GET-MAILBOX-FORWARDING.ps1 | Get Mailbox Forwarding | Show where selected mailboxes forward incoming email. |
| INVOKE-LITIGATION-HOLD.ps1 | Set Litigation Hold | Enable an unlimited litigation hold on approved mailboxes. |
| IR-INVOKE-EMAIL-RECOVERY.ps1 | Incident Response: Restore Email | Restore previously moved email to the selected mailbox. |
| ir-risk-assessment.ps1 | BEC: Assess User Risk | Review one user's account and mailbox before choosing a response. |
| ir-contain-eradicate.ps1 | BEC: Contain and Clean Up | Contain and clean up one compromised account after approval. |
| IR-GET-DATA-EXFIL-ACTIVITY.ps1 | Incident Response: Review File Activity | Review a user's file activity for possible data exposure. |
| IR-GET-IP-TRACE.ps1 | Incident Response: Trace IP Activity | Find tenant audit activity associated with a selected IP address. |
| IR-GET-TENANT-EMAIL-SEARCH.ps1 | Incident Response: Trace Email Delivery | Find email delivery records by sender, recipient, or IP address. |
| IR-GET-THREAT-INTEL-ACTIVITY.ps1 | Incident Response: Check IP Reputation | Check selected public IP addresses against external reputation services. |
| IR-GET-TIMELINE-BUILDER.ps1 | Incident Response: Build Incident Timeline | Combine supplied incident evidence into a timeline. |
| IR-GET-TOKEN-DECODE.ps1 | Incident Response: Decode Token | Read a token's contents locally without sending it online. |
| IR-GET-TOKEN-REPLAY-CHECK.ps1 | Incident Response: Review Token Replay | Review sign-ins for indicators of token replay or session theft. |
| GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1 | Audit Shared Mailbox Sign-ins | Find sign-in activity associated with shared mailboxes. |
| GET-APP-REGISTRATION-AUDIT.ps1 | Audit App Registrations | Review registered apps, ownership, and credential expiry dates. |
| GET-CONDITIONAL-ACCESS-GAPS.ps1 | Review Conditional Access | Find Conditional Access settings and exclusions that need review. |
| GET-DEVICE-CODE-EXPOSURE.ps1 | Review Device Code Exposure | Review policies for gaps in device-code sign-in protection. |
| GET-GUEST-APP-CONSENT-AUDIT.ps1 | Audit Guest App Consent | Review guest users and their app permissions. |
| GET-MFA-SECURITY-AUDIT.ps1 | Audit MFA Security | Review MFA registration and the policies intended to protect sign-ins. |
| GET-SECURE-SCORE-SNAPSHOT.ps1 | Get Secure Score | Show the tenant's latest Microsoft Secure Score. |
| GET-SERVICE-PRINCIPAL-OWNERS.ps1 | Get Enterprise App Owners | List enterprise app owners and identify apps without an owner. |
| GET-SIGNIN-ANOMALIES.ps1 | Review Sign-in Anomalies | Find unusual sign-in activity that needs investigation. |
| GET-TRANSPORT-RULES-AUDIT.ps1 | Audit Mail Flow Rules | Review mail flow rules for settings that need attention. |
| JOIN-COMPUTER-TO-DOMAIN.ps1 | Join Computer to Domain | Join the current computer to the selected AD domain. |
| DEPLOY-TCPIP-PRINTER.ps1 | Install Network Printer | Install a network printer using its address and selected driver. |
| BACKUP-USER-PROFILE.ps1 | Back Up User Profile | Copy selected user-profile folders to a backup location. |
| TEST-POWERSHELL-READINESS.ps1 | Check M365 PowerShell Readiness | Check this computer for Microsoft 365 PowerShell prerequisites. |
| GET-FOLDER-INVENTORY.ps1 | Review Folder Contents | Review a folder's files, script signatures, and Git status. |
| INSTALL-M365-MODULES.ps1 | Install M365 Modules | Install or update the selected Microsoft 365 PowerShell modules. |
| TEST-SENSITIVE-DATA.ps1 | Check Sensitive Data | Scan selected files for potentially sensitive information before sharing. |
| RESET-M365-SESSION.ps1 | Reset M365 Session | Disconnect Microsoft 365 services in the current PowerShell window. |
| UPDATE-WINDOWS-APPS.ps1 | Update Windows Apps | Review and update installed applications using WinGet. |
| GET-USER-PREDELETE-CHECK.ps1 | Check User Before Deletion | Review a user's mailbox, memberships, and access before deletion. |
| INVOKE-ENFORCE-PER-USER-MFA.ps1 | Set Per-user MFA | Require per-user MFA for selected accounts after approval. |
| GET-ADMIN-ROLE-AUDIT.ps1 | Audit Admin Roles | List tenant admin-role assignments for review. |
| GET-OAUTH-CONSENT-AUDIT.ps1 | Audit App Consent | Review app permissions granted in the tenant. |
| GET-GUEST-USER-AUDIT.ps1 | Review Guest Users | Find guest accounts that need an ownership or activity review. |
| GET-TENANT-LICENSING-AUDIT.ps1 | Audit Tenant Licenses | Review Microsoft 365 license capacity and user assignments. |
| GET-TENANT-INBOX-RULES-AUDIT.ps1 | Audit Tenant Inbox Rules | Find mailbox inbox rules that need review across the tenant. |
| GET-USER-SECURITY-SNAPSHOT.ps1 | Get User Security | Review one user's account, authentication, access, and recent sign-ins. |
| GET-TENANT-SECURITY-SNAPSHOT.ps1 | Get Tenant Security | Get a broad overview of the tenant's security settings and review areas. |
| GET-ROOM-RESOURCE-ACCESS.ps1 | Get Resource Mailbox Access | Review delegated access and booking permissions for resource mailboxes. |
| GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1 | Audit Tenant Mailbox Access | Review mailbox forwarding and delegated access across the tenant. |
| CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1 | Remove Disabled User Mailbox Access | Remove approved mailbox access held by one disabled user. |
| GET-TENANT-DRIFT-REVIEW.ps1 | Review Tenant Changes | Compare tenant settings with a saved baseline and review changes. |
| GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1 | Review Windows Storage | Find Windows storage that may be reclaimable without deleting files. |
| INVOKE-RESET-CLOUD-USER-PASSWORD.ps1 | Reset Cloud User Password | Reset passwords for selected cloud-only users after approval. |
| ir-recover-validate.ps1 | BEC: Restore and Validate | Check recovery readiness and restore approved account access. |
| git-handoff.ps1 | Save Project Handoff | Save a screened snapshot of the current Git project for handoff. |
| git-repo.ps1 | Manage Git Repository | Review, pull, or push changes in the selected Git repository. |
| git-security.ps1 | Review GitHub Security | Review a GitHub security-log export for unfamiliar access and activity. |
| set-execution.ps1 | Set Up Script Execution | Set local execution policy and unblock scripts beside this file. |
| attractor.ps1 | Attractor | Run a floating fractal animation with a clock. |
| rain.ps1 | Rain | Run animated terminal rain with a floating label and clock. |
| static.ps1 | Static | Run animated terminal static with a floating label and clock. |
| SIGN-FOLDER-SCRIPTS.ps1 | Sign Scripts | Sign scripts in a selected folder with a code-signing certificate. |
| GET-TERMINAL-READINESS-CHECK.ps1 | Check Toolkit Setup | Check a toolkit folder against the expected files and setup. |
| INVOKE-FILE-INVENTORY.ps1 | Compare Script Files | Compare script versions, signatures, and duplicate content in a folder. |
| INVOKE-MAP-KIT.ps1 | Map Folder Structure | Show the folder structure and files beneath a selected location. |
| INVOKE-SESSION-RESET.ps1 | Reset Terminal Session | Clear supported service connections from the current PowerShell session. |
| SET-THEME-BASIC.ps1 | Preview Plain Output | Show a plain PowerShell output style without color. |
| SET-THEME-COBALT.ps1 | Preview Cobalt Theme | Preview a blue PowerShell theme and output helpers. |
| SET-THEME-SEAGLASS.ps1 | Install Sea Glass Theme | Install a sea-green PowerShell theme in your startup profile. |
| SET-THEME-SILICON-VALLEY.ps1 | Install Silicon Valley Theme | Install a green PowerShell theme in your startup profile. |
| MANAGE-CERT-SIGNATURES.ps1 | Manage Signing Certificates | Create, review, export, import, or trust script-signing certificates. |
