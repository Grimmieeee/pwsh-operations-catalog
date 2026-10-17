# Catalog alignment plan

The repository is the source of truth. Start each batch from current main and
read the executable source, not remembered uploads or card descriptions.
Inventory: [CATALOG-REVIEW-INVENTORY.json](qa/CATALOG-REVIEW-INVENTORY.json).
Regenerate it with `node tools/catalog-review-inventory.mjs` after releases.

## Order of work

1. **Baseline:** inventory public source, inline commands, documentation and
   source-pending entries separately. Preserve useful lineage. IR 1.0.0 is the
   first exact-source VERIFIED release.
2. **Read-only identity/mailbox tools:** batches of 4-6 related scripts. Begin
   with account status, mailbox forwarding, user groups, group members and
   mailbox permissions. Establish reusable output conventions without merging
   executable implementations merely to make them look alike.
3. **Read-only tenant audits and IR utilities:** bounded queries, paging,
   licensing/permission gaps, timestamps, scope and false-clean outcomes.
4. **Change and destructive workflows:** batches of 2-3. Review authoritative
   source, preview, single approval per section, cancel paths and state readback.
   Live tests use approved test objects. Never run against a client from here.
5. **Local tools, setup and toys:** launch/exit, prerequisites, local writes,
   signing/profile/terminal differences. Preserve explicit setup exceptions.
6. **Quick commands and references:** inspect inline commands and links; do not
   present a command snippet as a tested standalone script.
7. **Source-pending and overlap decisions:** keep, implement, consolidate or
   retire only after a concrete scope/lineage decision. A missing source is
   not a formatting job and must not receive VERIFIED.

## Per-batch delivery

- Review purpose, actual access/risk, prerequisites, authentication, target
  binding, hybrid authority, error paths and meaningful output.
- Present representative clean, flagged, unavailable and cancelled output in
  chat before final files. Keep TITLE/objective/time, TARGET, STATUS, TICKET
  SUMMARY when useful, and NEXT STEP consistent. Only task content varies.
- Preserve core behavior during formatting. Handle a real functional fix as a
  separate explicit change with appropriate tests and a version increment.
- Parse PowerShell, inspect privacy and source, and exercise meaningful mocked
  good/bad/cancel/unavailable paths. Verify exact downloads and site interactions.
- Supply a short operator test list and exact version/hash for jumpbox testing.
  Record owner confirmation only for files actually tested. Stamps remain off
  until that confirmation; code changes remove their stamps until retested.
- Publish a protected PR after checks, record release evidence and verify Pages.

## Version and evidence

Use MAJOR.MINOR.PATCH according to OPERATING-STANDARDS.md. Preserve existing
versions where defensible; establish a reviewed baseline for unversioned tools
without pretending historical testing exists. Site flags show actual access
and readiness; VERIFIED is a separate exact-release evidence claim.

Static review, mocks, operator tests and download checks are separate evidence.
None proves a script is safe for every tenant or a clean assessment closes an
incident. No tenant credentials or private test transcripts go into the repo.

## Stop and check with the owner

Stop the affected batch for unclear intent, conflicting behavior, changed
authority/authentication, broader targets, extra writes, consolidation/retirement,
licensing-dependent gaps, or a result that cannot be reliably verified. Show the
specific conflict and proposed options. Do not silently fill the gap or drift
from the agreed operator flow. Unrelated read-only inventory can continue.
