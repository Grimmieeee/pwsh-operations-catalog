# Batch one source review

Baseline: main commit 41183a5ebe44c2716055ac678efad3e4a4ea210a.
Owner direction: formatting and alignment first. Existing operator-test
history will be supplied as the review proceeds. No blanket verification
claim is made. The owner selected Format first after the issues below were
shown. No executable source, catalog metadata, versions or stamps changed.

## Exact reviewed files

| File | SHA-256 | Disposition |
| --- | --- | --- |
| GET-ACCOUNT-STATUS.ps1 | 4a6e6aed3b612556706c107b667911ef79a4c6a47074d7054ab907cc3ca3dbfc | Formatting preview; release held for account-state issue |
| GET-MAILBOX-FORWARDING.ps1 | b99f2dc2c2b3eb9e4feff190f3fae7951dee4bfa2d95909eaad582457f9f768a | Formatting preview |
| GET-USER-GROUPS.ps1 | a423d1f10e9bcfee903c646d95cf5dbf2142eda04d014e0521a29114c1b55469 | Formatting preview; preserve separate source coverage |
| GET-GROUP-MEMBERS.ps1 | ba29a8c30f170c87b08a453fdfe73f6108bddfc69033f17a6270875ecc684dbd | Formatting preview; release held for read/resolution issues |
| GET-MAILBOX-PERMISSIONS.ps1 | a88851cc5a2e69684d26f90c8f028626daf986c57ca5938e14b02ea29ceed052 | Formatting preview |

These scripts currently lack an explicit release version. Establish versions
when the approved candidate source is built; do not label unmodified legacy
source as a newly tested release.

## Confirmed behavior issues: separate from formatting

1. **Missing account state becomes Disabled.** Get-UserStatus maps any value
   other than true to Disabled, including null. A mocked Graph user with
   accountEnabled null reproduces it. A later fix should report Unknown / Not
   available and include it in review counts rather than inventing a state.
2. **Failed distribution-group member read becomes an empty result.** The
   group resolver sets groupResolved true before Get-DistributionGroupMember
   succeeds. Its catch swallows the error. A mocked denied member query then
   prints Members: 0, none, and a Found summary. A later fix should retain the
   resolved group while marking member coverage unavailable, with no zero claim.
3. **Duplicate Entra group names select the first match.** Get-GraphGroupByInput
   pipes name matches through Select-Object -First 1. Two mocked groups with
   the same display name reproduce selection of the first. A later fix should
   report ambiguity and require a unique identifier rather than choose silently.

Reproduce in an isolated process with
`pwsh -NoProfile -File docs/qa/Test-Batch1-Review.ps1`.
All service calls in that file are fixtures; no tenant is contacted. These
are observations of current behavior, not passing acceptance tests for fixes.

Other review observations are not silently folded into formatting. Preserve
existing authentication/session reuse and Exchange -> Entra -> AD resolution
order. Keep unavailable AD/Entra coverage adjacent to displayed empty lists.
Retain visible-only warnings when hidden inbox rules cannot be read. Keep
actual skipped/error meanings and optional export behavior.

## Next review checkpoint

Review BATCH-1-OUTPUT-PREVIEW.md in chat, then build formatting candidates with
the existing collectors and data/export schemas preserved. Review those diffs
separately from functional fixes. Do not publish the two held tools as finished
or apply VERIFIED. Any future exact candidate needs its own source hash and
appropriate operator confirmation under the agreed version policy.
