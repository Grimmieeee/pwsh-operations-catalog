# Catalog card language review

Reviewed all 338 entries: 80 published PowerShell scripts, 235 quick commands, 12 references, and 11 source-pending tools. This review covers card copy and launch directions; it does not certify new runtime behavior.

## Shared wording contract

- USE FOR explains the specific job and result in one short sentence.
- INPUT says what to bring, what the script asks for, and which choices it supplies. Distinguish a domain from a tenant GUID, a user sign-in name (UPN) from a display name, and an app ID from a permission-grant or authentication-method ID.
- CHECKS describes actual reads or result checks. GUARDS describes actual approvals, limits, or required operator care. A raw command is not credited with a preview or confirmation it does not implement.
- REQUIRES starts with software and access in plain language. Keep exact module, permission, version, and parameter names where needed to troubleshoot or run the tool.
- START matches the released source. Use an existing terminal for session resets, terminal displays, and helpers that require a path or account parameter. Domain join starts in an administrator PowerShell window. Keep the coupled IR scripts in one existing window.
- Keep investigative limits: missing data is not a clean result; capped searches are incomplete; unusual activity is not proof of compromise. Keep password, private-key, remote-disconnection, and persistent-profile caveats.
- Source-pending tools are explicitly planned. Do not invent final inputs, prerequisites, checks, or launch steps for missing source.
- Apply script copy only to the reviewed source hash. Apply quick-command copy only when the executable example matches exactly. Re-review affected copy after a source change.

## Corrections

- Removed unrelated Graph/Exchange connection requirements from local commands, including cached-ticket and file-hash checks.
- Separated readable prerequisite descriptions from connection commands. Added missing service preparation for applicable Exchange/Purview commands without adding cloud sign-in to local commands or context/disconnect helpers.
- Added task-specific purposes and input explanations to quick commands; kept their executable bytes unchanged.
- Corrected IP reputation wording: external reputation queries, not tenant activity collection.
- Corrected email-search wording: sender, recipient, or source IP; not subject search.
- Kept absent guest sign-in history separate from a claim that a guest has never signed in.
- Corrected terminal-dependent tools and added path/account prompts to Git helper launch blocks.
- Simplified the IR handoffs while preserving cleanup, approval, sync, MFA sign-in, and follow-up requirements.

## Validation

- All 338 cards rendered through the DOM fixture and reviewed as a complete inventory.
- 33 site/security tests pass, including new cross-catalog wording/connection/launch checks.
- All 80 generated launch blocks parsed in PowerShell; none executed.
- All 92 downloadable source hashes match the published source manifest. All 235 executable quick commands match their pre-review versions.
- Catalog integrity, source loading, checksum gates, clipboard handling, source-pending behavior, dialog accessibility, and verification eligibility checks pass.

## Limits and continuation

No client or Windows authentication tests were performed in this wording pass. Existing exact-version verification is unchanged. The 13 tenant audit scripts that require a tenant GUID still require it; cards now explain where to find it. The separate domain-only batch runner is a different workflow. Known app-name resolution limits in the IR assessment remain visible. No claim of full-tenant pagination or comprehensive incident clearance was added.

The separate candidate report-export changes and read-only validation runner remain outside this UI release.
