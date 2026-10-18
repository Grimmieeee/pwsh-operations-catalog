# License removal and search safety follow-up

Owner authorized all fixes identified in the newcomer license-removal scenario.

## Changes

- License-removal source version 1.0.1 requires the expected tenant GUID. Healthy delegated/process-scoped sessions for that tenant are reused; a different tenant stops before data requests without replacing that session. Fresh sign-in is tenant-bound and validated afterward. Account/tenant context is rechecked before changes.
- All exact UPNs and assigned-license data must resolve before approval. No first-match email fallback or partial-target approval. The per-user lookup URI explicitly delimits the encoded identifier; the former interpolation dropped that identifier. Read only the properties this job uses.
- Show tenant ID, signed-in account, every target UPN and planned license before one typed REMOVE confirmation. No matching licenses are marked for skip.
- Failed requests and failed/unavailable post-change validation have separate visible counts. They produce Incomplete, never a green completion message. Unknown outcomes require review before retrying; no write is retried automatically. A changed user ID or missing license-state field cannot prove removal.
- Card input and guards match this exact source; connection/card review hashes are updated. The script does not earn operator verification from these tests.
- “employee left”, “departing employee”, “user leaving”, “leaver” and “offboarding” lead to read-only pre-delete preparation, with the unavailable offboarding workflow still labeled SOURCE PENDING. Explicit action searches retain their intent. No-result text suggests task names and browsing.

## Evidence and limits

`tests/license-removal.test.ps1` executes the real workflow/functions with fake module, Graph, context and prompt operations. Cases cover verified removal, remaining licenses, missing post-change state, changed target ID, failed request, changed context, no matches, cancellation, wrong tenant, invalid tenant, post-sign-in mismatch, new connection, current-user context conversion, missing scopes, missing initial state, inventory failure, unresolved user and wrong UPN. No real authentication, credentials, tenant requests or changes occur.

Microsoft Graph context/sign-in contract checked against official documentation:
- https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph
- https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/get-mgcontext

Native Windows PowerShell 5.1 and PowerShell 7 client runtime validation is still required. Existing verified IR sources remain unchanged. Do not interpret this patch as a complete offboarding workflow or as a review of every library script’s authentication model.
