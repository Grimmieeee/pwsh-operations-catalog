# First-run setup — October 22, 2026

## Delivered

- Start Here navigation with four operator steps: confirm context, prepare PowerShell, run one job, review and close.
- Checksum-verified first-run ZIP containing PREPARE-FIELD-KIT.ps1, START-HERE.md and SHA256SUMS.txt. Changed or unreviewed source blocks the entire download.
- Local preflight for Microsoft Graph, Exchange Online or both. Compatible modules are kept; approved missing modules use CurrentUser and the official PSGallery. No execution-policy changes, repository-trust changes, tenant sign-in or permission grants.
- Optional local AD prerequisite checks; RSAT installation and domain joining remain with the support-computer owner.
- RMM CheckOnly / InstallMissing / NoPause modes with UTC timestamps, computer/account context, result object and failure reporting. RMM activity/ticket records identify the technician when the Windows account is shared.
- Source-bound connection and sign-in notes in script card Details. Existing 80 operational scripts are unchanged.
- New setup card follows the matching objective, scope, steps, completion and three-related-items standards. No operator-verified badge is assigned from offline tests.

## Validation

First-run standard: confirm customer/computer/operator, prepare the current account and PowerShell edition, choose one job, then review and close. Check before installing; require explicit approval for changes; distinguish local readiness from customer access. RMM checks must remain noninteractive and fail when prerequisites are unmet. Keep same-window BEC handoffs and describe actual connection/sign-out behavior.

Offline PowerShell fixtures cover compatible/old/conflicting modules, supported host baseline, AD dependencies, retained modules, approved installation, check-only, cancellation, unattended failure, installation/import failures, repository substitution and installation source/scope/version bounds. Browser-unit tests cover the four-step page, exact ZIP bytes/checksums, fail-closed packaging and source-bound connection context. Catalog integrity, PowerShell parsing, objective/source parity and safety inventory checks cover all 81 downloadable scripts and 94 sources.

## Follow-ups and limits

- Validate an actual approved Windows jump box in Windows PowerShell 5.1 and PowerShell 7.4+, including missing modules, managed execution policy, Gallery/network restrictions and a failed dependency installation. Offline fixtures do not certify those environments.
- Validate the approved RMM component under its intended run-as account. SYSTEM installation does not prepare an interactive account's module context. Use operator/time/customer/device/activity data from the RMM or ticket.
- Existing script authentication lifecycles vary. A future source review should standardize process-scoped Graph connections, explicit disconnect in finally blocks and verified account/tenant context, preserving the sequential BEC workflow. This release does not claim to enforce reauthentication across the existing tools.
- Closing a dedicated PowerShell process is not a security sandbox and does not revoke all credentials or browser/Windows broker state. Same-window Reset M365 Session is documented for existing-window reuse; follow the organization's shared-computer sign-out process.
- The 11 previously unpublished planned tools remain unimplemented and excluded from working searches.
