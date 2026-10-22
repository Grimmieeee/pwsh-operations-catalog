# Stage 1: impact and authorization

October 22, 2026. Stage 1 release candidate, prepared separately after PR #87 scope correction.

## Changes

Screened the effective 329-entry catalog (81 scripts, 235 quick commands, 13 references). This is static impact/authorization screening and targeted control-path review, not execution or certification of every tool.

Changed 23 quick commands:

- Both all-inbox-rule deletion entries now use identical code and Destructive classification. The command resolves the mailbox's rules, displays visible and hidden rules, requires `DELETE <mailbox>`, stops on errors and queries remaining rules. Legitimate rules are included; a failure can leave partial deletion. Both discovery names remain available pending the later relationship/alias stage.
- Cloud-user and local-user deletion resolve and display the selected object before target-bound typed approval. The local path uses the resolved SID. Completion messages explicitly require independent state verification.
- Hard purge displays the completed compliance search, query and mailbox scope, then requires `PURGE <search name>`. Submission is distinguished from purge completion.
- Six bounded removal commands now request native confirmation: distribution group, AD group, Full Access delegate, Send As delegate, selected inbox rule and calendar permission.
- Twelve disruptive examples now require typed APPLY approval: reboot, process stop, DHCP renewal, TCP/IP reset, Winsock reset, two adapter restarts, service restart, BitLocker suspension, broad application updates, adapter disable and device isolation. Existing remote-session warnings remain.

Script Setup now displays its policy/folder plan and requires SETUP before changing execution policy or unblocking files. Cancellation returns through its existing finally block. Version 1.0.3 retains its old operational body; regression comparisons explicitly bound the added block against the previous source hash. The offline Execution test now includes a no-writes/no-unblocks cancellation case.

Updated source-bound card copy, related-command records, current source checksums and review metadata. Prior test evidence is retained; it is not promoted to runtime evidence for the changed source.

## Drift prevention

`IMPACT-REVIEW.json` records every active entry's identity, impact, source hash, safety-copy hash, disposition and rationale. A stale entry, changed classification, new/removed entry or altered safety copy fails the normal site check and the dedicated regression suite. This also runs in the publication preflight through `check-site.mjs`.

The register deliberately has no automatic refresh command. Before editing a record:

1. Review the operational change and its impact.
2. Find equivalent jobs and implementations across scripts and commands.
3. Carry the fix to affected peers or record a concrete exception.
4. Update relevant tests, card copy and current source bindings.
5. Update the reviewed register and run checks.

A hash enforces the review checkpoint. It cannot prove reviewer judgment or permission to perform customer work. `screened` is not a runtime support or verification badge. The existing operating standard remains authoritative; this report does not create another competing standard.

Local report writes, optional exports and explicitly invoked theme changes remain distinct from customer-state mutation. Routine commands such as DNS cache flush do not acquire a new confirmation prompt. Quick commands remain bounded techniques; they do not acquire the full guided workflow contract in this stage.

## Validation

- 65 Node checks passed: 58 existing site/theme tests and seven impact/authorization regressions.
- Catalog integrity, paths, source hashes, rendered-card contract and impact register passed for 329 entries and 94 downloadable sources.
- Source safety inventory freshness and whitespace checks passed.
- The exact setup-only insertion was checked against the previous source bytes.
- Stage 1 is isolated from the original worktree. PR #87 was independently repaired, checked and merged first; its corrected comparison baselines are retained.
- A reusable PowerShell 7.6.0 runtime was located after the initial report. Parsing, all 81 source/objective comparisons, 26 offline command-authorization cases and six setup Execution cases passed. Command cases cover blank/wrong approval, disruptive-action cancellation, successful rule deletion and partial failure. No real customer changes were performed. Windows/customer acceptance remains separate; no new runtime badge is claimed.
- Browser visual QA was not run. No layout changes were made.

## Stage boundary

Do not start the permissions pass. Publish this as its own reviewed wave after remote CI passes. Windows-specific acceptance is not represented by Linux/offline fixtures.
