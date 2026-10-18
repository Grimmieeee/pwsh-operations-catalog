# Catalog alignment fixes — October 17, 2026

Scope: all 338 effective catalog entries, 80 published PowerShell scripts and 92 downloadable sources. This pass corrects the QA findings without redesigning the catalog or changing the verified IR scripts.

## Corrections

- Braced the variable in the Tenant Group Owners module-load error. All tracked PowerShell sources now parse without executing them. CI runs the same gate, including build helpers.
- Added concise operational CHECKS to the 32 script cards previously missing that section. Existing INPUT/CHECKS/GUARDS styling is preserved.
- Replaced the group-removal card's copied review facts with removal results, plan, typed approval, protected-group exclusions and source-authority safeguards. Included the Graph read scopes used by the script.
- Replaced vague per-user MFA authentication language with its actual preview, typed ENFORCE gate and post-change state check.
- Corrected Mailbox Security Snapshot to Exchange-only requirements. Replaced generic tenant-permission descriptions with scopes requested by each script, including role/licensing prerequisites where relevant.
- Added example-replacement directions to quick commands with target placeholders. Command bytes are unchanged; this does not imply script-level confirmation gates.
- Added source fingerprints to reviewed card overrides. Stale card or connection profiles fail release checks; changed scripts still need new operator evidence before retaining verification.
- Updated standards for plain risk text, raised circled V, source-only COPY and source/internal versioning. Added these checks to the publishing checklist.
- Retired the old concept page in place: its URL leads to the current index, with a fallback link and no second app instance.

## Versioning disposition

The three verified IR sources keep their exact 1.0.0 bytes and evidence. Legacy files without formal version headers remain unversioned until release review. No new verified marks are granted.

## Validation boundaries

Catalog integrity, source hashes, paths, security regression tests and PowerShell parsing are checked locally and in CI. Live acceptance covers IR facts, group-removal guards, Exchange-only requirements, quick-command input and the legacy redirect. These checks do not prove Windows PowerShell 5.1 behavior, tenant permissions, synchronization or change execution in a client environment.

Draft PR #19 remains separate. No draft script rebuilds are promoted by this release.
