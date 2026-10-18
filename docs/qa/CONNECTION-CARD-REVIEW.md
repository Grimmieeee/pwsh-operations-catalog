# Connection guidance and card review — October 17, 2026

Scope: 338 catalog entries, including 80 published PowerShell sources. No tenant scripts were executed or changed during this UI/source review.

## Findings

PowerShell AST parsing and local function-call traversal found reachable built-in cloud connection commands in 49 sources. Thirty sources have no cloud connection step. One source has a parser error and receives review guidance rather than an AUTO-CONNECT claim.

`connection-guidance.js` records the reviewed path, SHA-256, mode and services for each published PowerShell source. UI guidance applies only while the source manifest hash matches that record. Tests reject stale or missing records when source is revised. This is static source evidence, not proof that authentication or permissions will succeed in every environment.

The IR trio connects Graph and Exchange itself and validates reusable workflow sessions. Risk Assessment uses Graph and Exchange; AD is relevant to the later hybrid change steps. The cards retain directions to keep the three files together and run them in one PowerShell window.

Quick commands use their existing preparation commands with CONNECT FIRST, unless the selected command already performs the connection/import. Scripts with no cloud connection step do not acquire an AUTO-CONNECT label. Unpublished or unreviewed sources get no speculative connection commands.

## Source review item

`published-source/tenant/GET-TENANT-GROUP-OWNERS.ps1` has a pre-existing PowerShell parser error: a colon follows an unbraced variable reference. This release does not modify that script or award verification. Review/correct the source and retest before treating it as ready. Its connection section explicitly says review is needed.

## UI acceptance

- Plain read/change/destructive labels across rows and selected cards, including hover states; retain readable coral destructive text.
- Small raised, evidence-bound circled V beside the title; meaning in About, no duplicate version/verification paragraph or global legend.
- Modules boxed in small mint text beneath the connection heading; AUTO-CONNECT scripts do not show manual connection commands.
- Download and View Code remain available. Script copy appears only in the source box after successful integrity validation; hiding source removes the control.
- Quick command COPY remains within its own code box; manual connection COPY remains with the connection code.
- Existing exact-source verification and byte-preserving download behavior remain intact. UI versions are hidden, while existing source headers and internal version checks are preserved.

Run the site suite and required GitHub checks, then inspect live selected-card, About, source, quick-command and hover states. Operator testing remains pending for the unverified script library and draft PR #19.
