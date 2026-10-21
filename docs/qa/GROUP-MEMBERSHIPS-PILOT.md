# Group Memberships pilot — 1.0.1 candidate

This is an unpublished candidate based on main 70bf66c. The accepted 1.0.0 runtime evidence remains historical evidence for that source. The owner confirmed existing launch behavior works, including a clear user-not-found error with right-click > Run with PowerShell. That confirmation does not validate these new bytes.

## Agreed operator contract

Matching catalog/terminal title, one objective, clear source results, a neutral SESSION COMPLETE marker paired with the actual result, then Press Enter to exit session. No mandatory next-tool navigation or host-closing exit command. Pilot first; no bulk rewrite.

## Changes

- Catalog and terminal both use Group Memberships.
- Each source distinguishes checked membership (including an empty result), user not found, unavailable, and failed. Console and CSV use the same source states; errors retain their actual messages.
- Overall result is SUCCESS, PARTIAL, USER NOT FOUND, or UNSUCCESSFUL. Skipped invalid inputs and requested export failure prevent success. Export failure preserves the directory findings.
- One final pause runs from finally, after completion reporting.
- AD resolution retains exact UPN, mail and proxy matches with ambiguity checks. Uncorroborated SAM-only matches were removed to avoid resolving a same-named local account in an unrelated domain. This can now require a corrected UPN/address where earlier guessing returned a user.
- Optional CSV defaults to Desktop where available, displays any fallback path, and compares field values as well as row count after reading back.
- Source version is 1.0.1. The candidate does not inherit the old VERIFIED mark. No live site change has been published.

## Offline evidence and limits

`tests/group-memberships.test.ps1` exercises real main-flow reporting with synthetic directory/authentication mocks: successful and empty sources; missing users; unavailable and failed sources; a group 404 after successful user resolution; invalid/bulk input; export failure. Separate checks exercise the real AD result wrapper, exact-identity resolver, TXT/CSV input, real CSV write/read and detection of altered export fields.

Local validation passed: 90 PowerShell files and 315 inline blocks parsed; 338 catalog entries and 92 download checksums checked; 44 JavaScript tests passed; the required offline PowerShell suites and the new pilot regression suite passed. None of these establish live tenant execution, Windows PowerShell 5.1 behavior, right-click host behavior for this revision, or full pagination.

## Runtime acceptance for this candidate

Run the exact 1.0.1 candidate on Windows from outside the repository using right-click > Run with PowerShell. Check a known user, a missing user, source-unavailable behavior and optional CSV output. Confirm the resolved identities, both source results, completion state and final prompt. Do not attach the old source's acceptance to this candidate.

The simplified card layout remains the next design task after pilot runtime acceptance. This change only aligns its title, objective and accuracy.
