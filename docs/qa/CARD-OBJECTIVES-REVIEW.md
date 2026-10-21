# Card and script objectives — all 80 reviewed

Updated October 21, 2026. Base release: e41cd6966efb7334e9a34a1ad8c30a42f2284de6.

## Result

Every script card has a visible purpose sentence directly below its title. Each sentence is identical to the script objective. Sentences describe the specific job in plain language; scope, launch instructions, warnings and operational limits stay in their existing places.

- 80 purpose statements reviewed against the existing tool descriptions, notes and source.
- 77 source files receive documentation and, where present, console-objective wording updates. Non-presentation tokens compare unchanged.
- The three coupled IR scripts already have concise metadata descriptions. Those exact sentences are reused without changing their accepted source bytes or breaking their workflow-package release gate.
- Names, input scope, service calls, prompts for changes, results, exports and exit controls are preserved. No new operational capability or fresh client runtime testing is claimed.

## Validation

All 80 source-objective comparisons and non-presentation fingerprints passed. All 45 site/theme tests passed, including visible purpose text before scope and steps. Required parser, integrity and offline suites are checked before publication. No fresh tenant execution is claimed.

## Safeguards

The shared objective lives in operator-card-specs.json. The metadata builder copies it into the source-bound card record. A release check rejects mismatched card records; a PowerShell test reads the actual source objective for all 80 scripts. A site test confirms the purpose is visible before scope and steps.

## Every objective

| Tool | Shared card/script objective | Source treatment |
|---|---|---|
| Review Account Cleanup | Review accounts, mailbox access, and licenses for cleanup. | Documentation / display only |
| Review Stale Sign-ins | Find enabled accounts with old or unavailable Entra sign-in activity. | Documentation / display only |
| Disable User Accounts | Disable selected user accounts in AD or Entra after approval. | Documentation / display only |
| Delete User Accounts | Delete approved user accounts from their authoritative directory. | Documentation / display only |
| Assign User Licenses | Assign a selected Microsoft 365 license to approved users. | Documentation / display only |
| Remove User Licenses | Remove selected Microsoft 365 licenses from approved users. | Documentation / display only |
| Find User UPNs | Find user sign-in names from names, email addresses, or a list. | Documentation / display only |
| Get User Account Status | Show whether selected accounts are enabled and when they last signed in. | Documentation / display only |
| Get Distribution Group Members | List direct members of selected Exchange distribution groups. | Documentation / display only |
| Get Group Members | List direct members of selected groups. | Documentation / display only |
| Get User Groups | List the selected users' direct groups in AD and Entra. | Documentation / display only |
| Remove User Groups | Remove selected users from eligible AD and Entra groups. | Documentation / display only |
| Create Dynamic License Group | Create a group that automatically includes users with assigned licenses. | Documentation / display only |
| Get Group Owners | List group owners and identify groups without an assigned owner. | Documentation / display only |
| Get Mailbox Permissions | Review mailbox forwarding, delegated access, and inbox rules for selected users. | Documentation / display only |
| Get Mailbox Security | Review one mailbox for unexpected access, forwarding, and suspicious rules. | Documentation / display only |
| Get Mailbox Forwarding | Show where selected mailboxes forward incoming email. | Documentation / display only |
| Set Litigation Hold | Enable an unlimited litigation hold on approved mailboxes. | Documentation / display only |
| Restore Email | Restore previously moved email to the selected mailbox. | Documentation / display only |
| IR: Assess User Risk | Read-only identity risk assessment for the operator-guided IR workflow. | Existing IR metadata reused |
| IR: Contain and Clean Up | Selective containment and eradication workflow for operator-approved response. | Existing IR metadata reused |
| IR: Review File Activity | Review a user's file activity for possible data exposure. | Documentation / display only |
| IR: Trace IP Activity | Find tenant audit activity associated with a selected IP address. | Documentation / display only |
| IR: Search Tenant Email | Search tenant email using the selected criteria and time range. | Documentation / display only |
| IR: Check IP Reputation | Check a public IP address against external reputation services. | Documentation / display only |
| IR: Build Incident Timeline | Combine supplied incident evidence into a timeline. | Documentation / display only |
| IR: Decode Token | Read a token's contents locally without sending it online. | Documentation / display only |
| IR: Review Token Replay | Review sign-ins for indicators of token replay or session theft. | Documentation / display only |
| Audit Shared Mailbox Sign-ins | Find sign-in activity associated with shared mailboxes. | Documentation / display only |
| Audit App Registrations | Review registered apps, ownership, and credential expiry dates. | Documentation / display only |
| Review Conditional Access | Find Conditional Access settings and exclusions that need review. | Documentation / display only |
| Review Device Code Exposure | Review policies for gaps in device-code sign-in protection. | Documentation / display only |
| Audit Guest App Consent | Review guest users and their app permissions. | Documentation / display only |
| Audit MFA Security | Review MFA registration and the policies intended to protect sign-ins. | Documentation / display only |
| Get Secure Score | Show the tenant's latest Microsoft Secure Score. | Documentation / display only |
| Get App Owners | Identify enterprise apps without an assigned owner. | Documentation / display only |
| Review Sign-in Anomalies | Find unusual sign-in activity that needs investigation. | Documentation / display only |
| Audit Mail Flow Rules | Review mail flow rules for settings that need attention. | Documentation / display only |
| Join Computer to Domain | Join the current computer to the selected AD domain. | Documentation / display only |
| Install Network Printer | Install a network printer using its address and selected driver. | Documentation / display only |
| Back Up User Profile | Copy selected user-profile folders to a backup location. | Documentation / display only |
| Check PowerShell Readiness | Check whether this computer has the PowerShell tools needed to proceed. | Documentation / display only |
| Get Folder Inventory | Review a folder's files, script signatures, and Git status. | Documentation / display only |
| Install M365 Modules | Install or update the selected Microsoft 365 PowerShell modules. | Documentation / display only |
| Check Sensitive Data | Scan selected files for potentially sensitive information before sharing. | Documentation / display only |
| Reset M365 Session | Disconnect Microsoft 365 services in the current PowerShell window. | Documentation / display only |
| Update Windows Apps | Review and update installed applications using WinGet. | Documentation / display only |
| Check User Before Deletion | Review a user's mailbox, memberships, and access before deletion. | Documentation / display only |
| Set Per-user MFA | Require per-user MFA for selected accounts after approval. | Documentation / display only |
| Audit Admin Roles | List tenant admin-role assignments for review. | Documentation / display only |
| Audit App Consent | Review app permissions granted in the tenant. | Documentation / display only |
| Review Guest Users | Find guest accounts that need an ownership or activity review. | Documentation / display only |
| Audit Tenant Licenses | Review Microsoft 365 license capacity and user assignments. | Documentation / display only |
| Audit Tenant Inbox Rules | Find mailbox inbox rules that need review across the tenant. | Documentation / display only |
| Get User Security | Review one user's account, authentication, access, and recent sign-ins. | Documentation / display only |
| Get Tenant Security | Get a broad overview of the tenant's security settings and review areas. | Documentation / display only |
| Get Resource Mailbox Access | Review delegated access and booking permissions for resource mailboxes. | Documentation / display only |
| Audit Tenant Mailbox Access | Review mailbox forwarding and delegated access across the tenant. | Documentation / display only |
| Remove Disabled User Mailbox Access | Remove approved mailbox access held by disabled users. | Documentation / display only |
| Review Tenant Changes | Compare tenant settings with a saved baseline and review changes. | Documentation / display only |
| Review Windows Storage | Find Windows storage that may be reclaimable without deleting files. | Documentation / display only |
| Reset Cloud User Password | Reset passwords for selected cloud-only users after approval. | Documentation / display only |
| IR: Restore and Validate | Verify response readiness and restore one approved identity. | Existing IR metadata reused |
| Save Project Handoff | Save a screened snapshot of the current Git project for handoff. | Documentation / display only |
| Manage Git Repository | Review, pull, or push changes in the selected Git repository. | Documentation / display only |
| Review GitHub Security | Review a GitHub security-log export for unfamiliar access and activity. | Documentation / display only |
| Set Up Script Execution | Prepare selected scripts to run under local execution settings. | Documentation / display only |
| Attractor | Run a floating fractal animation with a clock. | Documentation / display only |
| Rain | Run animated terminal rain with a floating label and clock. | Documentation / display only |
| Static | Run animated terminal static with a floating label and clock. | Documentation / display only |
| Sign Scripts | Sign scripts in a selected folder with a code-signing certificate. | Documentation / display only |
| Check Terminal Readiness | Check this computer against the expected terminal and toolkit setup. | Documentation / display only |
| Get File Inventory | Review files, script versions, and signatures in the selected folder. | Documentation / display only |
| Map Folders | Show the folder structure and files beneath a selected location. | Documentation / display only |
| Reset Terminal Session | Clear supported service connections from the current PowerShell session. | Documentation / display only |
| Basic Theme | Show a plain PowerShell output style without color. | Documentation / display only |
| Cobalt Theme | Preview a blue PowerShell theme and output helpers. | Documentation / display only |
| Sea Glass Theme | Preview a sea-green PowerShell theme and output helpers. | Documentation / display only |
| Silicon Valley Theme | Preview a green PowerShell theme and output helpers. | Documentation / display only |
| Manage Signing Certificates | Create, review, export, import, or trust script-signing certificates. | Documentation / display only |

## Follow-ups

- Keep exact-version runtime acceptance separate from wording checks; original operational acceptance remains preserved.
- Twelve specialized terminal/command sources gain objective comments only; their interactive controls remain intact.
- The existing three IR metadata sentences retain their established terminology to preserve the coupled accepted release.
- Live visual/phone inspection remains the previously recorded follow-up; no browser inspection is claimed by the source and DOM tests.
