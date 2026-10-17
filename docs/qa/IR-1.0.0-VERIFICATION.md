# IR workflow 1.0.0 verification

The owner explicitly confirmed that all three scripts in
FIELD-KIT-IR-1.0.0.zip ran successfully on the client jumpbox. The public
copies are byte-identical to those confirmed files. No client transcript,
temporary password, tenant identifier, or incident evidence is published.

| File | Version | SHA-256 |
| --- | --- | --- |
| ir-risk-assessment.ps1 | 1.0.0 | 07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b |
| ir-contain-eradicate.ps1 | 1.0.0 | e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb |
| ir-recover-validate.ps1 | 1.0.0 | c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04 |

Parser and isolated mocked checks additionally covered authentication reuse,
target/tenant binding, approvals and cancellation, rule mutation checks,
recovery evidence, AD flag preservation, reset failure output, navigation,
missing-file handling, and final loop completion. Mocks are not tenant tests.

VERIFIED means: Operator tested. Download integrity checked. Applies to this
version only. It is a FIELD // KIT release marker, not Authenticode signing,
an independent certification, or a promise of compatibility with every tenant.

Change any source byte or version: remove its verification record until that
exact replacement is operator tested. CI rejects stale records; the UI also
withholds the stamp if version or manifest checksum differs.
