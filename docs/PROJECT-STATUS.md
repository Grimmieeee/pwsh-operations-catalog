# FIELD // KIT — project status

Updated October 19, 2026. This is the current continuation checkpoint. Older
dated notes remain historical; they do not reopen accepted testing.

## Published and complete

- Batch 3 live license pair is complete: assignment and removal are VERIFIED at 1.0.2. Successful 1.0.1 client runs carry forward through the owner-accepted product-name-only update. See [evidence](qa/LICENSE-1.0.2-VERIFICATION.md). Batch 3 is closed per owner acceptance; its offline and live evidence retain their stated scopes.

- Batch 1 is closed: the main 28-script sampled read-only run plus its final
  report/export cleanup. No additional operator rerun is required to close it.
- Batch 2 is closed with eleven completed workflows accepted by the owner.
  Together with batch 1 and the IR trio, this brings the total to **69 VERIFIED
  tools**. Room/Resource Access remains unverified: its supplied security-group
  target was not an active resource mailbox. Only that successful path remains.
- The catalog contains 338 entries: 80 scripts, 235 commands, 12 references and
  11 source-pending entries. Catalog entries are not all standalone scripts.
- Batch 3 offline safety checks passed 85/85 on Windows PowerShell 5.1, matching
  the supplied package. This completes the synthetic safety stage; the license pair has since passed live testing. The owner closed batch 3;
  no repeat batch-3 run is queued. The catalog retains 69 VERIFIED
  releases. See [the batch-3 safety record](qa/BATCH-3-OFFLINE-RESULTS.md).
- The approved minimal design and card language are established: purpose,
  required input, checks, guards, requirements, clear start and completion steps.
  Version details stay in source; VERIFIED remains bound to exact release bytes.
- Release checks cover card/source alignment, integrity, safe rendering and
  parsing. The batch-2 site suite contains 38 tests. Static checks are not
  substitutes for operator acceptance.

## Verified releases

The unchanged IR trio is `ir-risk-assessment`, `ir-contain-eradicate` and
`ir-recover-validate`.

The eight newly accepted tools are:

- GET-QUARTERLY-CLEANUP-REVIEW
- GET-TENANT-GROUP-OWNERS
- GET-MAILBOX-PERMISSIONS
- GET-MAILBOX-SECURITY-SNAPSHOT
- IR-GET-TOKEN-REPLAY-CHECK
- GET-USER-PREDELETE-CHECK
- GET-USER-SECURITY-SNAPSHOT
- GET-TENANT-SECURITY-SNAPSHOT

See [read-only release evidence](qa/READONLY-REPORTS-1.0.0-VERIFICATION.md)
and [IR release evidence](qa/IR-1.0.0-VERIFICATION.md) for version/hash binding.
The read-only acceptance covers sampled runs and HTML exports. It does not
claim full pagination, every environment or that a client has no security issues.
Returned reports did not independently capture execution-source hashes; the
evidence records owner acceptance and the matching supplied release bundle.
Raw client reports and findings remain private.

Batch-2 implementation hashes match the returned runner metadata. The published
1.0.0 files add a version comment only. See [batch-2 release evidence](qa/BATCH-2-1.0.0-VERIFICATION.md)
for its eleven releases, exact source attribution and the resource exception.

## Current queue

Accepted-pass reconciliation is complete: **69 VERIFIED tools**, each with recorded scope. See [evidence](qa/ACCEPTED-TEST-RECONCILIATION.md). No repeat upload is needed for these accepted cases.

Deferred: six passing visual/theme tools for native local review; Rain; both certificate/signing wizards; Git Security; and Room/Resource Access with a valid mailbox target. That is 11 available tools, not missing downloads. Keep their current categories and return to them after operational passes are closed.

## Remaining known work

- IR application-name lookup has an unreleased candidate patch; preserve the
  accepted IR source until a deliberate revision is tested and accepted.
- License-name resolution is released in 1.0.2; remaining source-specific gaps are
  tracked in [CARD-VERIFICATION-GAPS.md](../CARD-VERIFICATION-GAPS.md).
- Eleven source-pending entries remain planned, not downloadable verified tools.
- Development candidates are separate from public main. Reconcile them before
  release; do not merge an entire older candidate branch indiscriminately.

## Standards to preserve

Follow [OPERATING-STANDARDS.md](../OPERATING-STANDARDS.md),
[DESIGN-LOCK.md](../DESIGN-LOCK.md) and the automated card contract. Card claims
must match actual inputs, prompts, connections, permissions and output. Keep
language simple without hiding safety requirements. Source changes invalidate
the old verification binding until the replacement is tested and accepted.
