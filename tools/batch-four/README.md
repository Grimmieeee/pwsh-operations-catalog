# Batch 4 — one offline upload

Build with `node tools/batch-four/build.mjs <output.ps1>` and right-click the
resulting file → Run with PowerShell. Type RUN. No tenant, UPN, API key, module
installation or administrator access is needed. The runner saves one small JSON
under Desktop/FIELD-KIT-TESTS. Raw details stay in the window; D 1 and D1 both work.
ENTER finishes review and the closing prompt exits.

Sixteen exact published sources receive 103 behavioral cases. The builder lists
the source path, case count and scope of every suite. Existing batches and license
tools are not repeated. Batch 3 is closed per owner acceptance; its separate live
and offline evidence remains intact. This package adds no VERIFIED badge itself.

Coverage is deliberately specific:

- Disable, per-user MFA, hold enforcement, module setup, both session-reset tools
  and execution-policy setup: source main workflow with simulated dependencies.
- Account deletion, group removal, mailbox-access cleanup and email recovery:
  targeted request, identity matching and readback functions. Full workflows,
  authentication and AD paths remain outside this package's claims.
- Drift: synthetic comparisons plus temporary baseline JSON write/read.
- Threat intelligence: public/private IP input guards; no provider calls.
- Git security: classification and temporary JSON/JSON-lines parsing.
- Map kit: actual workflow over a small disposable folder; signatures skipped.
- Storage: synthetic disk/files, bounded largest-file ranking and skip behavior.

No tenant commands, policy changes, module installs, session disconnections,
password resets, trust-store changes, domain joins or real drive scans execute.
Fixtures are removed. The results contain exact source hashes, scope, pass counts,
PowerShell version and error type; no user, tenant, machine or secret values.

`-InventoryOnly -NoPause` verifies embedded hashes and parser compatibility without
running tests. `-ReportPath <new-file> -NoPause` supports unattended local QA after
RUN is supplied. A partial failure does not prevent later suites from running.
Reports are saved after each suite, and a failed case cannot count as a pass.

Operator acceptance of this report must preserve the recorded scope. Passing an
offline fixture is not evidence of successful live permissions or real changes.
