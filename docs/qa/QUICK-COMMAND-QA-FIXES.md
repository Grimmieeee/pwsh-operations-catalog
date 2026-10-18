# Quick-command QA fixes — October 17, 2026

The second catalog pass identified executable snippet issues that the original file-only PowerShell parser did not cover. This release extends the gate to the effective catalog's inline command text.

## Corrected findings

- Removed unmatched trailing braces from Show Delegated Grants For One User and Unified Audit Log For One User.
- Removed decorative separator lines from six copied snippets: delegated-grant removal, Entra group-member removal, inbox-rule removal, signature updates, recent System errors and saved Wi-Fi profiles.
- Marked AD user deletion, cloud user deletion and compliance-search hard-delete commands DESTRUCTIVE alongside MAKES CHANGES. Existing local-user deletion labeling is preserved.
- Added explicit delegated Graph scopes to fourteen task-command preparations. Scope choices follow the Microsoft Graph API documentation below; consent, supported administrator roles and tenant licensing still apply. No tenant connections or grants are performed by this catalog change.
- Context inspection and Graph disconnect no longer ask the operator to connect first. The general Graph connector uses an explicit User.Read example and explains that task-specific scopes must come from the selected task.
- Replaced WinGet angle-bracket placeholders with a quoted package-ID variable and exact matching. INPUT directs the operator to obtain the ID from winget search. Fixed the quick-command data adapter to preserve supplied INPUT fields.
- Marked eleven cards without published source or inline code SOURCE PENDING; no speculative launch preparation is shown. Source code is not invented or substituted.

## Gates and evidence

The PowerShell gate statically parses all 83 tracked .ps1 files and all 235 effective quick commands, and rejects decorative separator lines. It does not execute their contents. Catalog checks and regression tests cover destructive labels, scoped Graph preparation, pending-source readiness and WinGet inputs. All 19 node tests pass locally. The 234-item Quick Commands navigation count is correct: one additional atomic command, Revoke Active Sessions, belongs to Incident Response.

All 80 PowerShell download hashes and all three exact-version IR verification records remain unchanged. Updated documentation receives refreshed checksums. No published .ps1 source changes are included. Client Windows/tenant runtime testing remains separate.

## Microsoft permission references

- [Delete users](https://learn.microsoft.com/en-us/graph/api/user-delete?view=graph-rest-1.0): delegated User.ReadWrite.All and supported role requirements.
- [Update users](https://learn.microsoft.com/en-us/graph/api/user-update?view=graph-rest-1.0): accountEnabled uses User.EnableDisableAccount.All with User.Read.All.
- [Revoke sessions](https://learn.microsoft.com/en-us/graph/api/user-revokesigninsessions?view=graph-rest-1.0): User.RevokeSessions.All.
- [Delete Authenticator methods](https://learn.microsoft.com/en-us/graph/api/microsoftauthenticatorauthenticationmethod-delete?view=graph-rest-1.0) and [phone methods](https://learn.microsoft.com/en-us/graph/api/phoneauthenticationmethod-delete?view=graph-rest-1.0): method-management permissions and supported authentication administrator roles.
- [Delete delegated grants](https://learn.microsoft.com/en-us/graph/api/oauth2permissiongrant-delete?view=graph-rest-1.0): DelegatedPermissionGrant.ReadWrite.All.
- [Manage group membership](https://learn.microsoft.com/en-us/graph/api/group-post-members?view=graph-rest-1.0): GroupMember.ReadWrite.All; user lookup additionally uses User.Read.All. Role-assignable groups have extra requirements and are outside the generic example's permissions.
- [Read sign-ins](https://learn.microsoft.com/en-us/graph/api/signin-list?view=graph-rest-1.0): AuditLog.Read.All plus supported role and log availability.
