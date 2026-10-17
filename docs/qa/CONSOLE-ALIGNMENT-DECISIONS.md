# Console alignment candidates

This draft contains 64 presentation candidates, each with source version 0.1.0. They are not operator-verified releases. Card release versions and VERIFIED records remain unchanged until exact candidate bytes are tested. The source-integrity manifest identifies the draft downloads.

## Completed

- All 80 downloadable PowerShell sources have a recorded disposition in CONSOLE-ALIGNMENT-REPORT.json.
- 64 candidates use a common title, objective, timestamp, restrained status colors, section headings and closing prompt. Five identity/mailbox scripts also have tailored, mocked output checks.
- Entry parameters and non-presentation command/method fingerprints match their original sources. Authentication, scopes, service calls, confirmations and exports were preserved. This is a structural check, not proof of runtime equivalence.
- The three VERIFIED IR releases and seven theme/animation scripts remain byte-identical.
- The 235 inline commands, 12 documentation downloads and 11 reference/planned entries were inventoried; their content was not rewritten or runtime-certified in this pass.

## Consolidated exceptions

| Source | Finding | Disposition |
| --- | --- | --- |
| GET-ACCOUNT-STATUS | Missing accountEnabled can be classified as Disabled. | Formatting candidate held from release; behavior correction needs a separate change. |
| GET-GROUP-MEMBERS | A denied membership read can appear empty; duplicate Entra display names silently select the first match. | Formatting candidate held from release; behavior correction needs a separate change. |
| GET-TENANT-GROUP-OWNERS | Existing `$Name:` string interpolation fails parsing. | Original source retained; fix interpolation and test before release. |
| git-handoff, git-repo, git-security, set-execution | Custom interactive menus and handoff flows need individual treatment. | Original sources retained; no generic menu rewrite. |
| INVOKE-MAP-KIT | Custom map layout needs individual treatment. | Original source retained. |

## Validation evidence and limits

- Test-ConsoleAlignment.ps1: 64 candidate sources parse; original entry parameters, required-host declarations and non-presentation command/method fingerprints match; 16 retained files match byte-for-byte.
- Test-Batch1-Formatting.ps1: 11 mocked flows cover clean and denied reads, forwarding, group-source coverage, delegated permissions, bulk input, verified CSV export and one closing prompt per run. These mocks do not contact a tenant.
- Test-Batch1-Review.ps1: the three known behavior defects still reproduce. Formatting did not silently change them.
- Existing site security tests remain required. No Windows PowerShell 5.1, real tenant, endpoint-change or phone display validation is claimed.

## Operator test order

1. Test the three unheld first-batch candidates: GET-MAILBOX-FORWARDING, GET-USER-GROUPS, GET-MAILBOX-PERMISSIONS. Check output with clean, populated and unavailable sources, then confirm the closing prompt returns correctly.
2. Test remaining read-only identity/mailbox/IR tools, followed by tenant audits. Check empty versus unavailable results and requested exports.
3. Test local utilities in a disposable Windows environment. Check both an existing terminal and right-click launch; include PowerShell 5.1 and 7 where supported.
4. Test change/destructive workflows only against approved disposable targets. Verify each original preview and confirmation remains intact, then read back the result.
5. Resolve the exceptions above separately. Stamp only the exact tested release hash and version; publish reviewed subsets rather than treating this draft as a blanket certification.

## Reproducing the structural checks

The baseline is main commit 41183a5ebe44c2716055ac678efad3e4a4ea210a. Materialize its 80 PowerShell source files under a separate baseline directory, retaining their relative paths and exact bytes. Run:

```powershell
pwsh -NoProfile -File docs/qa/Test-ConsoleAlignment.ps1 -BaselineRoot /absolute/path/to/baseline
pwsh -NoProfile -File docs/qa/Test-Batch1-Formatting.ps1
pwsh -NoProfile -File docs/qa/Test-Batch1-Review.ps1
```

```sh
node --test tests/site-security.test.mjs
node tools/check-site.mjs
```

The builder takes the original Inspect-ConsoleAlignment.ps1 JSON and baseline directory; run align-console-output.mjs first, then align-batch-one.mjs. Final report hashes must be refreshed after the tailored pass.
