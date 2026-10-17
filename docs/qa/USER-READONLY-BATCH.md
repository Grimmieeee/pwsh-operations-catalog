# User read-only test batch

Extract the entire ZIP to a folder. Keep its files together. Right-click Invoke-UserReadOnlyBatch.ps1 and Run with PowerShell, or run it from your existing jumpbox terminal:

```powershell
& .\Invoke-UserReadOnlyBatch.ps1
```

Enter a test UPN, comma-separated UPNs, or an approved TXT/CSV list. TXT accepts one UPN per line and # comments; CSV requires UPN, UserPrincipalName or Email. Supply the expected tenant GUID from Entra Overview. This extra check prevents silently reusing another client's session.

The first batch contains the exact formatting candidates for GET-MAILBOX-FORWARDING, GET-MAILBOX-PERMISSIONS and GET-USER-GROUPS. It excludes the two known-defect tools and all change/destructive workflows. It runs sequentially in one session. Existing valid service sessions are reused; missing authentication is requested. The original scripts retain their own connection checks, so a connection failing during a run can still cause a reconnect. The runner never installs modules or changes execution policy.

Graph needs Microsoft.Graph.Authentication with User.Read.All and Group.Read.All. Exchange needs ExchangeOnlineManagement and permission to read the selected mailboxes/rules/delegation. The runner validates the connection's TenantID using Get-ConnectionInformation, as documented at https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-connectioninformation. Use a fresh test window if your existing IR session uses prefixed Exchange commands; this batch requires the candidates' normal unprefixed commands. AD group coverage depends on the jumpbox's AD access. An unavailable source remains Incomplete, even if that failure was expected.

Confirm the displayed tenant, targets and tools once. Review each tool's normal output, then choose Pass, Fail or Incomplete. Known findings are not automatically failures: compare them with what you deliberately configured on your test account. Check that the correct sources were queried, expected findings appear and denied reads are not shown as empty.

The runner adapts only each tool's CSV and closing prompts. CSV is declined, closing prompts return automatically, and any unexpected prompt fails that tool rather than answering blindly. The files execute unchanged and their hashes are checked. A successful invocation is only Completed; Passed also requires your explicit verdict and no observed warning/failure or missing completion marker. A warning cannot be overridden to Passed.

One JSON report is written under Documents\FIELD-KIT-TESTS (temporary-directory fallback if Documents is unavailable). The write is read back and checked. Send that single report back. It records versions, exact hashes, environment/module versions, test-case category, counts and verdicts. It does not store UPNs, tenant IDs, output, exception messages or transcripts. Existing terminal transcription, if enabled on your machine, is outside this runner's control. Do not upload client screenshots or transcripts with the report.

For mixed lists, Fail/Incomplete applies to the entire tool run; a Pass attests all selected targets. Use a focused rerun to isolate a failed target. For example:

```powershell
& .\Invoke-UserReadOnlyBatch.ps1 -InputObject 'test@example.invalid' -TenantId '00000000-0000-0000-0000-000000000000' -Tools Forwarding,Permissions
```

Use a clean account and an account with known forwarding/rules/delegation/group memberships. Where practical, run an unavailable-source case too. Batch testing does not validate standalone right-click prompts, normal CSV export or fresh-session authentication for each individual script; those remain separate targeted checks. No VERIFIED stamp is assigned automatically.
