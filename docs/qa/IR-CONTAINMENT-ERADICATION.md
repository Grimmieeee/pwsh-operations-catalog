# IR: Contain and Eradicate — candidate 0.1.1

Status: draft for controlled testing. Makes changes, including irreversible removal of selected rules and grants. Not linked from the live catalog and not approved for production.

## Scope

Adapted from response v1.1 into `IR-INVOKE-CONTAINMENT-ERADICATION.ps1`. Preserves the seven selectable jobs: revoke sessions, disable identity, reset password, remove rules/forwarding, remove user-specific OAuth grants, remove mailbox access, and disable mailbox legacy protocols. The source's item selection and target-bound action confirmations remain.

No automatic recovery, tenant-wide grant removal, password generation/export, execution-policy bypass, prerequisite installation, or private sync-server/runbook configuration.

## Intentional safety changes

- Graph requires an explicitly selected tenant, delegated process-scoped sign-in, and required scopes. The target must resolve uniquely. Graph tenant, object ID, identity authority, and synced SID are rechecked before writes.
- Exchange uses only dedicated `IRResponse`-prefixed cmdlets. Tenant and mailbox external-directory ID must match Graph. Each Exchange write rechecks this binding. Cleanup closes only owned Exchange connections.
- Synced AD identities resolve by `onPremisesSecurityIdentifier` against AD objectSid, not the first SAM/name/mail match. Missing SID, wrong domain, or ambiguous lookup blocks AD changes without a cloud fallback. SID is refreshed before writes.
- Hybrid disable/reset requires an explicit reachable Entra Connect server with ADSync available. No customer-specific server mapping remains. The operator must supply the correct server for that tenant; command availability does not independently establish connector-to-tenant ownership.
- `RESPOND <UPN>` authorizes the selected workflow. Selected containment runs first, with existing per-action confirmations. `ERADICATE <UPN>` is a separate gate for cleanup. A failed/unverified or declined selected containment operation, or an unsuccessful sync request, blocks cleanup. Cleanup-only selection is allowed when containment was completed separately; it still requires both workflow and cleanup gates.
- Cloud/AD disable checks the resulting disabled state. Session revocation requires a true acknowledgement; tokens may still take time to expire. Sync success means the cycle start was accepted, not that cloud convergence finished. AD-disabled/cloud-enabled is explicitly pending, not contained.
- OAuth deletion re-reads the selected grant and requires `consentType=Principal` and matching principalId. Tenant-wide and other-user grants cannot be deleted through this workflow.
- Collection-limit exhaustion is incomplete evidence. Data gaps prevent a confident containment/validation result. Observed counts are explicitly incomplete if coverage failed.
- Null rule target properties no longer masquerade as forwarding actions.
- Password errors omit sensitive response text. Passwords still necessarily exist briefly in memory for the API/AD calls; they are not printed, copied, logged, or exported by the script.
- Enter to exit and cleanup run on early failures as well as completion. Partial-action exceptions show recorded action results rather than implying rollback.

This changes operational safeguards, not just branding. It requires fresh runtime validation.

## Prerequisites

Use a fresh Windows PowerShell 5.1 or PowerShell 7 window. Global Microsoft cloud only. Requires Microsoft.Graph.Authentication 2.x and, for mailbox work, ExchangeOnlineManagement 3.2+. Missing modules produce separate installation guidance; nothing is installed automatically.

Requested scopes: User.Read.All, User.RevokeSessions.All, User.EnableDisableAccount.All, User-PasswordProfile.ReadWrite.All, Directory.Read.All, DelegatedPermissionGrant.ReadWrite.All. The full workflow requests these up front; declining consent stops authentication. Scope consent does not replace operator Entra roles or Exchange RBAC. Privileged targets may require stronger role assignments. A least-privilege combined operator role set still needs tenant validation.

Hybrid changes additionally require Windows AD connectivity, delegated AD account/password rights, PowerShell remoting to the operator-supplied Entra Connect host, and permission to start ADSync. The SID lookup searches the current AD naming context; it does not search all forests or guess another domain. Missing AD reachability blocks identity actions but does not invent a cloud fallback.

An explicitly selected tenant obtains a fresh Graph context; use a fresh shell rather than relying on an unrelated existing Graph session. Existing unrelated Exchange sessions are not disconnected.

## First controlled run

```powershell
.\IR-INVOKE-CONTAINMENT-ERADICATION.ps1
```

1. Enter the authorized test user's UPN and expected tenant domain/GUID. Sign in as the operator.
2. First choose `N` at the action menu. Check displayed identity, source, rules, forwarding, and permissions against the portals. Confirm no changes occur.
3. For a planted-rule test, rerun and select only `4`. Enter the exact RESPOND and ERADICATE phrases when prompted, select only the planted rules, then confirm REMOVE RULES. Mailbox-level forwarding has a separate choice and typed confirmation.
4. Rerun Step 1 and compare with Exchange to confirm the intended test rules are absent. Avoid selecting unrelated password/identity actions to test mailbox cleanup.
5. Test session revocation, cloud disable/reset, each permission type, legacy protocols, and hybrid identity changes separately with authorized disposable test objects before broader use.

`-SyncServer 'sync.example.invalid'` supplies the operator-verified sync host; otherwise hybrid identity selection prompts for it. Blank leaves those actions blocked. `-SkipExchange` disables mailbox operations and leaves validation incomplete. `-NoPause` only suppresses the ending pause, never confirmations.

## Automated verification

PowerShell 7.6.7 Linux, 2026-10-14. Parser plus 34 mocked cases/checks passed. Tests are isolated from real modules and tenants:

```powershell
pwsh -NoProfile -File ./tests/Test-ContainmentEradication.ps1
```

Coverage includes no-change and cancellation paths, explicit rule/forwarding/access/protocol removal, cloud reset/mismatch/failure without password disclosure, revoke true/false/failure, disable read-back mismatch, selected-containment gate enforcement, missing hybrid SID/server, wrong Graph tenant/Exchange tenant/mailbox, declined authentication, missing module/user, inaccessible rule/OAuth evidence, foreign endpoint rejection, duplicate/invalid selections, user-owned versus tenant-wide/other-user grants, and accepted/busy/failed sync requests.

No Graph/Exchange/AD mutation was executed against any real environment by these tests. Actual browser/WAM authentication, Exchange command import, Windows ADSI/SID binding, real password policy, all mailbox permission variants, remote ADSync, licensing, and cross-service convergence remain runtime gates. Tests do not prove these integrations work.

## Remaining release gates

- Run no-change/cancel paths in Windows PowerShell 5.1 and 7, including File Explorer launch and Enter-to-exit.
- Validate correct tenant/object identity and role scope with real module versions; confirm unrelated Exchange connections survive.
- Validate each selected write and its read-back on test objects, including deliberate denial and partial failure.
- Validate SID binding on the correct/wrong AD domain and server-unavailable paths. Confirm no cloud identity fallback.
- Check sync acceptance separately from successful connector export/cloud state. Password-hash synchronization and force-change behavior depend on deployment configuration and require separate verification.
- Compare action output and post-state with portals and Step 1; do not treat command acceptance as proof all persistence or live tokens are gone.
- Tighten per-item post-change verification where only request acceptance plus the final refreshed inventory is available. Rule removal can also remove Outlook client-side rule data; retain the warning and selected-rule confirmation.
- Review inherited heuristics: publisher verification does not establish app approval, rule action patterns do not prove compromise, and mailbox protocol flags do not evaluate every organization-level policy.
- Resolve the runtime checklist before exposing the catalog download. Step 3 remains separately authorized.

## Step 1 evidence

On 2026-10-14 the operator reported a completed live test-account run of Identity Risk Assessment. Graph and Exchange collection completed, the target was identified as AD-synced, and planted forwarding/delete-rule indicators produced HIGH RISK. No failures were shown in the supplied output. This confirms one success path, not every permission, host version, or failure mode. Tenant/user addresses and policy names are intentionally excluded from repository records.

## Controlled-run feedback and prompt fix — 0.1.1

The operator reported successful tenant, mailbox, and SID-bound AD resolution. The sync-server input was blank and the workflow confirmation omitted its target UPN. No response actions or sync were attempted. This is a cancellation/preflight-input observation, not a demonstrated sync-engine failure.

Compared the supplied working smoke test: it also requires an explicit server hostname and invokes Start-ADSyncSyncCycle remotely on that server. The supplied dirty-state setup script does not implement AD synchronization. Neither private upload was copied into this repository.

A blank server now explicitly reports that no connection was attempted. Actual remoting/module failures retain a short diagnostic. Incomplete typed confirmations retry until the full target-bound phrase is entered, or Enter/N cancels; partial confirmation never authorizes an action. No changes to mutation or synchronization commands.
