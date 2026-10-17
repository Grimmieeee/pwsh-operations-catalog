# User read-only batch 0.1.0 validation

The runner executes the three manifest-pinned 0.1.0 formatting candidates without rewriting their files. It adapts console presentation, routine closing prompts and CSV declines in invocation-local functions. Authentication and service reads are real when the operator runs the package.

Isolated PowerShell 7 tests passed for input deduplication, TXT/CSV input, approved manifest paths/hashes, healthy-session reuse, initial authentication once per service, wrong-tenant rejection, all three exact candidate scripts, explicit operator verdicts, denied-read handling, unexpected prompts, changed-source rejection, missing completion, warning streams, privacy fields, report readback/overwrite protection and the full runner entry point. Fixtures use example.invalid and make no service calls. The existing ten site security tests and catalog integrity check also passed locally.

The CI workflow runs Test-UserReadOnlyBatch.ps1 with isolated fixtures. These results do not constitute Windows PowerShell 5.1, real-tenant, standalone interactive-launch or operator verification. No new VERIFIED stamp is warranted by this harness alone.

Build with `node tools/build-user-readonly-batch.mjs /absolute/output/directory`. This copies the exact three sources, manifest, runner and instructions into one ZIP. Run the extracted runner outside the repository for operator testing. Keep real reports local and send the compact JSON through the testing conversation; do not commit client output or reports.
