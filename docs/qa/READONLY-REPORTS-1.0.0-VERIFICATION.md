# Read-only reports 1.0.0 — owner-accepted verification

The owner reported successful testing of this eight-script report batch, supplied all eight HTML outputs, and explicitly accepted these tests as sufficient for the catalog VERIFIED mark. This acceptance includes the sampled read-only workflow and HTML export. No additional standalone or full-tenant rerun is required by this release decision.

The released bytes below match the embedded sources in the test bundle supplied to the owner. The returned HTML files do not contain executable source hashes, and no validation JSON was returned. Version attribution therefore relies on owner confirmation of the supplied batch, not an independently captured execution manifest. The release hashes identify and protect the published artifacts.

| Script | Version | Release SHA-256 |
|---|---|---|
| GET-QUARTERLY-CLEANUP-REVIEW.ps1 | 1.0.0 | dfc7e8526aea4a3bfd36d934dad90378fde0800514fd597aa6ad6e2da6288093 |
| GET-TENANT-GROUP-OWNERS.ps1 | 1.0.0 | 830e2ed189de399a7f3813a021446ae68cba5c9c4e810b69cf41e5698751d786 |
| GET-MAILBOX-PERMISSIONS.ps1 | 1.0.0 | 793bdd06ff9adadcae9312e8614513d7c6440f507858593a35eb05469fe43620 |
| GET-MAILBOX-SECURITY-SNAPSHOT.ps1 | 1.0.0 | 10e8a2aae2fff3b4a3708510008ac6a1f9b7892358256480c7a57d6a8dfabe2c |
| IR-GET-TOKEN-REPLAY-CHECK.ps1 | 1.0.0 | 5b2d89608eb132a45412260ed831f4c17030ea00b073f80789b5b5dcd4cb3d52 |
| GET-USER-PREDELETE-CHECK.ps1 | 1.0.0 | e7e86d7ae9e59ba32a7752feb55562b782fc5cf6623b3f33d7c584ef6d945f0f |
| GET-USER-SECURITY-SNAPSHOT.ps1 | 1.0.0 | 52ac45625a7a12b01d9f1a27d34636423b791ec78d77ea7640d86edb66af2ff6 |
| GET-TENANT-SECURITY-SNAPSHOT.ps1 | 1.0.0 | b4fbb3ad10dcde3e5beb1c414890597de2fd969a4e9fe4149f70b7bea2c5f44c |

## Scope

The batch was adapted to reuse Graph/Exchange authentication and process at most ten records per collection. HTML reports retain the sample label, warnings, gaps, and incomplete or inconclusive findings. Reports were inspected for readable sections, escaped content, and absence of executable or remote content. Offline reporting checks additionally exercise decline/save, safe filenames, no overwrite, full-byte readback and source parsing.

Standalone launch, every failure path, pagination, every possible object, and compatibility across all tenants were not established by this run. VERIFIED is an owner-accepted operator-test release marker, not a claim of complete tenant coverage, independent certification, or a clean security verdict. An inconclusive investigation result does not fail the tool when it correctly reports absent evidence.

The existing three IR release verifications remain unchanged. Raw reports and client findings are not published. A changed source invalidates this release mark until the owner accepts testing for the new revision.
