# IR: Identity Risk Assessment — candidate 0.1.0

Status: development candidate. Not merged, linked for download, or approved for production use.

## Purpose

Review one M365 user and mailbox before choosing response actions. The script collects evidence; it does not contain, eradicate, recover, or declare an incident closed.

The canonical filename is `IR-GET-IDENTITY-RISK-ASSESSMENT.ps1`. This first standalone candidate adapts the v0.32 risk exposure snapshot. Its indicator rules and HIGH RISK / REVIEW REQUIRED / NO HIGH-RISK FINDINGS precedence are preserved. The original source and operational deployment copies are untouched.

## What changed

- Replaced RMM environment variables, client-secret Graph tokens, and Exchange PFX authentication with interactive delegated sign-in.
- Required an explicit tenant domain or GUID, validated Graph tenant/domain and scopes, and matched the Exchange tenant and mailbox object to Graph before mailbox collection.
- Used dedicated `IRAssessment`-prefixed Exchange commands so another open Exchange connection cannot supply the mailbox evidence. Only connections created by this run are disconnected.
- Removed automatic prerequisite installation, private branding, and host-closing `exit` calls. Added the script title, existing cyan/green/yellow/red output conventions, and Enter to exit (`-NoPause` when unnecessary).
- Removed the app-only Graph mailbox-rule fallback. Delegated Graph permissions do not offer equivalent cross-user coverage; Exchange is required for mailbox checks. Skipping or failing Exchange requires review.
- Made page-limit exhaustion an incomplete collection instead of successful coverage. Failed verified-domain collection stops assessment rather than treating every address as external.
- Printed collected data gaps next to the summary. No new exports or tenant-changing commands.

Authentication and coverage handling necessarily change behavior. This is a candidate requiring fresh operational validation, not a cosmetic sanitization claimed to be already proven.

## Start

Use a fresh Windows PowerShell window. The candidate targets Windows PowerShell 5.1 and PowerShell 7; Windows execution is not yet verified. PowerShell 7 on Linux was used only for parsing and mocked tests.

Required modules must already be installed:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -MinimumVersion 2.0.0
Install-Module ExchangeOnlineManagement -Scope CurrentUser -MinimumVersion 3.2.0
```

Those are separate setup commands for the operator, not commands run by the assessment.

```powershell
.\IR-GET-IDENTITY-RISK-ASSESSMENT.ps1
```

Enter the target UPN and the tenant's verified domain or tenant GUID. Sign in with an authorized operator account in that tenant for Graph and Exchange. The target UPN is not the operator login. Tenant selection is not inferred from a guest or alternate UPN domain.

Optional arguments:

```powershell
.\IR-GET-IDENTITY-RISK-ASSESSMENT.ps1 -UserPrincipalName 'user@example.invalid' -Tenant 'example.invalid' -NoPause
```

`-SkipExchange` deliberately yields an incomplete assessment. `-SessionStandardHours 24` supplies an operator-defined reauthentication standard; `NEVER` represents no enforced interval. Omitting it leaves that assessment unconfigured. This is not discovered Conditional Access policy and is not token age.

This release supports the global Microsoft cloud only. Use a fresh shell because explicit Graph sign-in replaces the current Graph context; it does not restore a previous operator session. The script does not close the PowerShell host. `-NoPause` is a convenience, not an unattended automation contract or machine-readable success signal.

## Permissions and coverage

Requested delegated scopes are read-only:

| Scope | Collection |
| --- | --- |
| User.Read.All | User properties and sign-in activity |
| Directory.Read.All | Directory roles, verified domains, service principals, delegated OAuth grants |
| UserAuthenticationMethod.Read.All | Target authentication methods |
| AuditLog.Read.All | Sign-in activity and sign-in logs |
| Policy.Read.All | Conditional Access policy visibility |

Scopes alone do not grant operator privileges. Admin consent, appropriate Entra roles, tenant licensing, log retention, and Exchange RBAC still apply. Authentication-method visibility can differ for privileged target accounts. Exchange requires access to Get-Mailbox, Get-CASMailbox, Get-InboxRule (including hidden rules), Get-MailboxPermission, and Get-RecipientPermission. A specific least-privilege combined operator role set remains to be validated in the test tenant; do not assume Global Administrator is required or request it by default.

Consent grants permissions to the Graph client; the assessment's tenant queries are read-only. No consent is silently approved by the script.

## Known interpretation limits carried from the source

- HIGH RISK is exposure/indicator classification, not proof of compromise. A privileged role or enabled move/delete/mark-read rule can trigger it.
- The inherited “Unapproved OAuth grant” label is based on publisher verification/Microsoft heuristics and failed app resolution. It does not consult an organizational approval list. This wording needs a separate decision before release.
- OAuth review is user-specific delegated grants, not a complete review of tenant-wide consent or application permissions.
- Sign-ins are the latest 25 records within 10 days, with a 48-hour display subset. This can omit older records within that window. Sign-in activity is not literal session/token age.
- Listed enabled Conditional Access policies are tenant policy names, not an evaluation of effective policies for the target user.
- SMTP exposure uses the inherited mailbox-level flag. Effective organization-level SMTP policy is not evaluated.
- Some noncritical gaps, including Conditional Access visibility, do not alter inherited summary precedence. They are now displayed explicitly. NO HIGH-RISK FINDINGS is not “all checks passed.”

These are review items, not silently changed detection rules.

## Verification completed

PowerShell 7.6.7 Linux, 2026-10-14. No actual Graph/Exchange sign-in or tenant query was performed.

Run the deterministic test harness in its own process:

```powershell
pwsh -NoProfile -File ./tests/Test-IdentityRiskAssessment.ps1
```

Passed: parser; complete benign fixture; privileged-role and hidden/delete-rule findings; declined Graph sign-in; missing module; missing scope; missing target; unreadable domains; Graph tenant mismatch; Exchange denial; Exchange tenant mismatch; mailbox object mismatch; MFA denial; inbox-rule denial; skipped Exchange; truncated OAuth pagination; foreign Graph endpoint rejection. Tests also check that invalid identity contexts stop further collection and cleanup does not disconnect unrelated Exchange sessions.

The harness replaces module/service commands with in-process fixtures. It does not exercise actual SDK authentication, Exchange command import, tenant permissions, licensing, or Windows host behavior.

## Next acceptance gate — controlled runtime

1. Launch the standalone download outside the repository in Windows PowerShell 5.1 and PowerShell 7. Verify title, readable colors, and Enter-to-exit on success and failure.
2. Validate module version compatibility, browser sign-in, MFA, consent handling, and correct operator/tenant display.
3. Run a known test user; compare each source with the portals, including a privileged test target where authorized.
4. Test missing target, cancelled authentication, insufficient roles/consent, missing modules, unavailable/licensing-limited sign-ins, and absent mailbox. None may look clean.
5. Test a second open Exchange connection in a different tenant. Check that only the explicitly validated tenant/object supplies evidence and unrelated sessions survive cleanup.
6. Compare findings against the original v0.32 script on the same authorized test identity, accounting for the deliberately changed auth/coverage paths.
7. Resolve the inherited wording/coverage limitations above, then decide whether to expose the download. Do not merge this candidate as a Ready tool before that gate.

The public catalog card remains Source pending until approval; the draft source exists only on the development branch.

## References

- [Microsoft Graph authentication](https://learn.microsoft.com/powershell/microsoftgraph/authentication-commands)
- [Delegated OAuth-grant permissions](https://learn.microsoft.com/graph/api/oauth2permissiongrant-list?view=graph-rest-1.0)
- [Authentication-method permissions](https://learn.microsoft.com/graph/api/authentication-list-methods?view=graph-rest-1.0)
- [Exchange connection metadata](https://learn.microsoft.com/powershell/module/exchangepowershell/get-connectioninformation?view=exchange-ps)
