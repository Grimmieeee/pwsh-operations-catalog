# Permissions wave — 2026-10-22

Scope: all 329 active entries screened together (81 scripts, 235 quick commands,
13 references). Permission/module/role/consent copy and quick-command connection
preparation now live in DETAILS. Task impact and input warnings remain visible.

## Corrections

- Removed write scopes from preparation for all 13 read-only commands that inherited
  change-capable family profiles. All 33 task-specific Graph preparations now have
  explicit reviewed profiles, including required user-property lookups.
- Registration reporting uses AuditLog.Read.All, not Reports.Read.All. Corrected
  the quick command and GET-MFA-SECURITY-AUDIT.ps1 1.0.3. The latter changes only
  that literal scope and the version; inverse reconstruction checks exact prior
  bytes. Historical acceptance and original source hashes remain historical.
- Removed ActiveDirectory preparation from the cloud-only membership lookup.
- Removed unrelated risk/sign-in scopes, and narrowed ID-only user lookups to
  User.ReadBasic.All. Group member/owner reads retain GroupMember.Read.All plus
  User.ReadBasic.All for displayed user properties. Missing non-user properties
  and hidden membership are disclosed instead of silently requesting more access.
- Replaced stale script scope prose with actual source-declared scopes, including
  the Conditional Access review's Policy.Read.ConditionalAccess requirement.
- Distinguished delegated consent, Entra roles, Exchange/Purview RBAC and Windows
  AD delegation. No blanket Global/Domain Administrator prerequisite is introduced.

## Deliberate boundaries

The BEC trio still requests the common nine-scope response token at initial sign-in.
Assessment and recovery are read-only operations but use a write-capable token.
Each DETAILS section explicitly discloses this exception. Existing sessions can
also hold broader permissions than a newly selected read task requests.

No process-scope, disconnect, token-lifetime, shared-session or authentication-flow
changes belong to this release. Existing process-scope flags are preserved. This
is a permissions/preparation screen, not proof every script uses the absolute
minimum permission possible. Script scope declarations other than the confirmed
registration-report defect remain unchanged. No live tenant/runtime acceptance
or effective-permission guarantee is claimed.

## Drift prevention

`PERMISSIONS-REVIEW.json` binds every active entry's source/command bytes and
effective requirements, connection commands, role/consent notes and preparation.
`tools/check-site.mjs` gates both PR validation and publishing on that register.
Changes require review of equivalent tasks before refreshing affected entries.
`tools/permission-profiles.mjs` is the reviewed Graph preparation source;
`tools/build-permission-guidance.mjs` materializes copy but cannot approve a new
register. The old overlapping quick-command scope map is removed.

Tests check scope/profile parity, absence of write requests on read-only quick
commands, placement inside DETAILS, source-declared script scopes and explicit
BEC exceptions. Native alignment tests prove the registration patch contains no
other source edits. Existing safety and objective checks remain enforced.

Local validation: 76 JavaScript tests passed; 98 PowerShell files and 316 inline
command blocks parsed; all native CI offline suites passed, including both
license modes and all batch-four/batch-five focuses. No live tenant calls were
made. Local Chromium was unavailable; DOM visibility/placement assertions passed.

## Primary references checked

Permission mappings are tied to the exact API, not a broad family scope list.
Every command profile records its Microsoft Learn endpoint URL. Key references:

- [Get user](https://learn.microsoft.com/en-us/graph/api/user-get?view=graph-rest-1.0)
- [License details](https://learn.microsoft.com/en-us/graph/api/user-list-licensedetails?view=graph-rest-1.0)
- [Authentication methods](https://learn.microsoft.com/en-us/graph/api/authentication-list-methods?view=graph-rest-1.0)
- [Authenticator methods](https://learn.microsoft.com/en-us/graph/api/microsoftauthenticatorauthenticationmethod-list?view=graph-rest-1.0)
- [Phone methods](https://learn.microsoft.com/en-us/graph/api/authentication-list-phonemethods?view=graph-rest-1.0)
- [Registration report, v1.0](https://learn.microsoft.com/en-us/graph/api/authenticationmethodsroot-list-userregistrationdetails?view=graph-rest-1.0)
- [Registration report, beta used by MFA audit](https://learn.microsoft.com/en-us/graph/api/authenticationmethodsroot-list-userregistrationdetails?view=graph-rest-beta)
- [User grants](https://learn.microsoft.com/en-us/graph/api/user-list-oauth2permissiongrants?view=graph-rest-1.0)
- [Group members](https://learn.microsoft.com/en-us/graph/api/group-list-members?view=graph-rest-1.0)
- [Group owners](https://learn.microsoft.com/en-us/graph/api/group-list-owners?view=graph-rest-1.0)
- [User memberships](https://learn.microsoft.com/en-us/graph/api/user-list-memberof?view=graph-rest-1.0)
- [Sign-ins](https://learn.microsoft.com/en-us/graph/api/signin-list?view=graph-rest-1.0)
- [Risk detections](https://learn.microsoft.com/en-us/graph/api/riskdetection-list?view=graph-rest-1.0)
- [Risky users](https://learn.microsoft.com/en-us/graph/api/riskyuser-list?view=graph-rest-1.0)
- [Exchange cmdlet/parameter RBAC](https://learn.microsoft.com/en-us/powershell/exchange/find-exchange-cmdlet-permissions?view=exchange-ps)

Microsoft tables sometimes list newly introduced scopes in surprising privilege
order. This release uses supported read permissions, not write scopes selected
merely because a table places them first. GroupMember.Read.All is intentionally
retained as a documented read-only group permission.
