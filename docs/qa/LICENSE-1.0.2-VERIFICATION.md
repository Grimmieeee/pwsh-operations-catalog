# License workflows 1.0.2 — verification provenance

The owner successfully ran assignment and removal 1.0.1 on the client jumpbox, with original operator approvals. Both result exports contain one Verified result. The owner accepted the Microsoft product-name display update retroactively and explicitly waived a repeat live run for that change.

Release 1.0.2 adds an embedded Microsoft product-name reference, name-based menu ordering, readable plan/result/export labels, and a version bump. Authentication, approvals, Graph writes and final-state checks are unchanged. Unknown products remain explicitly named unavailable; no guessed names or new runtime network dependency. The exact released bytes were covered by offline regression checks. This evidence covers the live pair, not all remaining batch 3 workflows or every tenant configuration.

| Script | Live-tested 1.0.1 SHA-256 | Released 1.0.2 SHA-256 |
|---|---|---|
| INVOKE-ASSIGN-LICENSES.ps1 | f5585715db56fc58a71cc518221eeb367eb6e143e90df9a50259f9b07455312e | 289d921e47af9ba0d05c0ecaef218a25101c704529e9aa31c85e4aa5d1e158b5 |
| INVOKE-REMOVE-LICENSES.ps1 | 4ca7d831f460991251a5a0fe980b17e537f96e48df906c4db576f3f43e623928 | eedbc44f46a0078347ebe4b7ac414b197ba47e6449a7ee8162b40ba9aeb13450 |

Sanitized report and export hashes are recorded in the adjacent JSON. Client identifiers and raw findings are excluded.
