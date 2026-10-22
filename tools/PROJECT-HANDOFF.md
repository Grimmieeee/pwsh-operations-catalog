# Current naming checkpoint — October 22, 2026

Response and investigation tools now use BEC-prefixed canonical filenames and BEC display names. IR and incident response are search aliases. Use the [current naming review](../docs/qa/BEC-NAMING-REVIEW.md) and [current project checkpoint](../docs/PROJECT-STATUS.md). The earlier handoff material below remains historical; do not use its old counts or testing claims as the current release state.

# Current alignment checkpoint — October 21, 2026

Read [the current status](../docs/PROJECT-STATUS.md) and [alignment review](../docs/qa/RELATIONSHIP-ALIGNMENT-REVIEW.md) first. All 80 cards and their 240 explicit script-card relationships are reviewed. Guided response uses BEC: and broader tools use BEC:. Current presentation revisions have source/DOM/offline evidence; original runtime acceptance is retained separately. The BEC package has a source-bound display review, not an inherited runtime badge. Earlier dated release descriptions below are historical.

# Current checkpoint — native closeout accepted

78/80 standalone scripts have owner-accepted, source-bound evidence. Seven visuals and both signing utilities passed native local review. The tested single-certificate array fixes are released; no other implementation change is bundled. See docs/qa/NATIVE-1.0.0-VERIFICATION.md.

Git Security and the client-dependent resource-mailbox check remain available and unverified. Do not schedule another personal-PC resource test. Quick commands remain separate from runtime script verification. The lighter flag treatment is preview-only pending owner selection; live typography has not been changed by this release. Earlier checkpoints are historical.

# Current checkpoint — accepted passes reconciled

69 owner-accepted scoped VERIFIED releases. The reconciliation reuses matching earlier evidence; no new client runs are claimed. See docs/qa/ACCEPTED-TEST-RECONCILIATION.md. Secure Score has owner-reported attribution explicitly distinguished from the returned batch-1 manifest.

11 deferred tools remain available: six passing theme/visual tools reserved for local native review, Rain, both certificate/signing wizards, Git Security and Room/Resource Access with a valid mailbox target. Do not rerun accepted operational batches. Visual tools stay in Toys; setup utilities stay available. Earlier checkpoints below are historical.

# Current checkpoint — batch 4 accepted / batch 5 prepared

39 VERIFIED tools. Batch 4: 15 passing sources accepted with explicit offline/function-level scope; Git Security failed and is deferred at the owner’s request. Published 1.0.0 sources add a version comment only. See docs/qa/BATCH-4-1.0.0-VERIFICATION.md. Batches 1–4 are closed except that named exception.

Next: one batch-5 package for 13 local/setup/visual sources. No real trust, profile, domain, signing or repository changes execute. Prior checkpoints below are historical.

# Current checkpoint — batch 4 prepared

Batches 1–3 are closed per owner acceptance. Batch 4 is one offline upload with 16 sources and 103 scoped behavioral cases; see tools/batch-four/README.md. No new functional VERIFIED marks are granted by building or running synthetic tests. The catalog retains 24 VERIFIED releases. Source hashes and coverage are embedded in the package and returned report.

Site flags now use 12px bold type; the row verification seal is slightly larger. Plain labels, right alignment, spacing, colors and title seal remain as approved.

Earlier checkpoints below are historical.

# Current checkpoint — October 20, 2026

24 VERIFIED tools. License assignment and removal passed live at 1.0.1; the owner accepted the display-only Microsoft product-name update in 1.0.2 without a repeat live run. Exact tested and released hashes are recorded separately in docs/qa/LICENSE-1.0.2-VERIFICATION.md. Batch 3 is closed per owner acceptance; the underlying evidence retains its recorded scope. Earlier checkpoints below are historical.

# FIELD // KIT Project Handoff

Current continuation record for the FIELD // KIT PowerShell Operations Catalog.

This file records the current project state so a new session can resume without reconstructing prior conversations. Project-wide rules still come from `OPERATING-STANDARDS.md`; this handoff records where the work currently stands.

## October 19, 2026 — current state: batches 1 and 2 closed

Batch 2 adds eleven owner-accepted VERIFIED releases: 22 total. The supplied
runner metadata identifies their tested source hashes; release 1.0.0 adds only
a version comment. See `docs/qa/BATCH-2-1.0.0-VERIFICATION.md`. Room/Resource
Access remains unverified after an expected security-group/resource-mailbox
target mismatch. Do not repeat the eleven accepted tools for that one gap.
Next work is batch-3 preparation; the older batch-2 planning below is historical.
The approved row flag group stays right-aligned: mint circled V + VERIFIED
first, then extra space before the brighter risk labels. See DESIGN-LOCK.md.
Batch 3's 85 offline safety cases passed on Windows PowerShell 5.1. The evidence
is in docs/qa/BATCH-3-OFFLINE-RESULTS.json/.md. Live-change testing is the next
stage; the offline run adds no functional VERIFIED release marks.

Read [the current project status](../docs/PROJECT-STATUS.md) first. It supersedes
older pending-testing instructions and test counts below; those dated sections
are retained as history, not a new work queue.

- The main 28-script sampled read-only run and final eight HTML-export retests
  belong to the same batch 1. The owner accepted completion. Do not repeat them
  or request a missing execution manifest as a new release prerequisite.
- Eight read-only report releases are VERIFIED and published in PR #55, in
  addition to the three unchanged IR releases: 11 VERIFIED tools total.
- Exact versions, hashes, scope and provenance are recorded in
  `docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md` and its JSON companion.
  Sample coverage does not establish pagination or every environment.
- Reconcile remaining tools against existing evidence and owner confirmation
  before defining batch 2. Secure Score was included in the next-group runner;
  absence of an HTML report does not establish that it was untested.
- Keep candidate branches separate. Do not publish all development changes or
  treat unbadged tools as necessarily untested. No next batch is finalized.
- Preserve the approved design, plain-language card contract, source-bound
  verification and client-data privacy. No raw client reports belong in Git.

## Historical updates

## October 18, 2026 — catalog-wide safety review

See `docs/qa/CATALOG-SAFETY-REVIEW.md`, `CATALOG-SAFETY-MATRIX.md`, `CATALOG-SAFETY-AUDIT.json` and `SOURCE-REVIEW-LEDGER.json`. The full 338-entry screen covers 80 scripts, 235 commands, 12 references and 11 pending entries. Scoped fixes cover 24 script sources; offline checks cover 265 cases plus 28 site tests. Thirteen tenant audits now require the expected tenant GUID and reject wrong-tenant reuse. Assignment and dynamic-group creation also require it. Source/card/connection evidence must be refreshed after each source edit.

The three IR 1.0.0 executables and their operator evidence remain unchanged. A known app-name lookup limitation in assessment is visible on its card; its tested candidate is `docs/qa/IR-APP-NAME-LOOKUP.patch`. It still needs an IR revision/operator retest before release. No additional script earned VERIFIED. Native Windows/client tests and remaining source-review scopes are explicit in the ledger and matrix. The earlier sections below are historical, including old test counts. Draft PR #19 remains separate.

## October 17, 2026 — design lock and testing handoff

License-removal safety follow-up: `INVOKE-REMOVE-LICENSES.ps1` 1.0.1 requires an expected tenant GUID, validates delegated/process context and signed-in account, previews every exact target UPN and planned license before one REMOVE approval, and leaves failed/unverified results incomplete. Lookup URI interpolation is corrected; unavailable reads no longer silently become empty data, and the exact-UPN resolver has no alias/first-match fallback. All supplied users must resolve before approval. The CI suite includes 19 offline mocked Graph/prompt regressions; this is not native Windows/client runtime verification and adds no VERIFIED mark. Plain-language offboarding searches lead to read-only preparation; no-result text offers task-name and browsing recovery. The unrelated candidate PR #19 remains separate.

Owner-approved guided-start release: investigation-first search, IR package/guide, path-prompted launch, preparation and expected-result/next/blocked guidance. Detailed IR checks/guards use one disclosure while INPUT and preparation remain visible. The shared launch helper covers 80 downloadable scripts. All 24 tests pass; parsing covers 83 .ps1 files plus 235 quick commands and 80 launch helpers. No script bytes or verification evidence change. See `docs/qa/GUIDED-START-PREVIEW.md`. The owner explicitly authorized publication after the preview discussion; required CI and live deployment QA still apply.

Follow-up quick-command QA: two stray-brace snippets and six copied separators corrected; WinGet placeholders replaced with quoted package-ID examples and INPUT directions; added quick-command INPUT fields are preserved. Account deletion and hard-delete commands receive combined change/destructive labels. Fourteen previously unscoped Graph task commands now have explicit delegated preparation; context inspection and disconnect need no sign-in. The Graph connector example states its limited example scope. Eleven source-less cards are consistently SOURCE PENDING without launch commands. CI parses 83 tracked PowerShell files plus all 235 inline commands; the node suite has 19 tests. Quick Commands navigation is 234 because Revoke Active Sessions lives under Incident Response. See `docs/qa/QUICK-COMMAND-QA-FIXES.md`.

Approved refinement: plain access labels; raised circled V beside the selected title with meaning in About; source/internal versions; COPY inside exposed source; small mint connection headings and boxed services. The subsequent alignment pass fixes the Tenant Group Owners parser error and reviews its Graph/Exchange connection path. Connection guidance now covers 80 released PowerShell files (50 auto-connect, 30 without a cloud connection step). Every script card has operational CHECKS; reviewed card overrides carry exact-source hashes. The site suite has 18 tests and CI also parses every tracked PowerShell file without execution. See `docs/qa/CATALOG-ALIGNMENT-FIXES.md`, `card-guidance.js` and `connection-guidance.js`. Legacy versions await formal release review; the verified IR trio remains byte-identical. Draft PR #19 remains separate.

Read `DESIGN-LOCK.md` before visual work. The final in-chat footer preview is approved: BY above the larger B, bright BURN with muted SID//, and bright EST. / muted 2026 at the far right on the same baseline. Preserve the design; preview future visual changes before publishing.

The public catalog has 338 entries and 92 downloadable sources. Cards now separate INPUT, CHECKS and GUARDS; requirements and long connection commands are compact disclosures. Home Screen branding is explicit. Card copy must match each exact source's prompts and behavior. Twelve site tests cover source integrity, exact-version verification, safe loading, clipboard errors, dialog accessibility, global search and card grouping. No PowerShell source changed during this design pass.

### Next work

- Draft PR #19 (`work/alignment-batch-1`, head `a16051fc45544993f5e246e2b07a6927d28bf96d`) holds 64 alignment candidates and the first read-only user batch runner. It remains unmerged and untested by the owner. Do not publish it as verified.
- Start operator testing with the read-only user batch runner. Preserve tenant binding, shared-session validation and per-script evidence. A batch result does not automatically verify every catalog item.
- Review `CARD-VERIFICATION-GAPS.md`. License tools currently resolve IDs to technical SKU codes, not guaranteed friendly product names. Cards correctly describe numbered selections. Product-name and applicable client-ID resolution need source work and operator tests.
- Known candidate defects remain for Account Status null/disabled handling and Group Members permission-denied/empty results and ambiguous names. Re-read candidate sources before fixing or releasing.
- Compare every card claim with its exact script; exercise runtime-dependent claims. Avoid scope, authority, authentication or destructive-behavior drift during presentation alignment.
- The three IR 1.0.0 operator-verified downloads remain the released baseline. Other items do not acquire VERIFIED from static review.

### Release and continuation

Run `node --check field-kit-app.js`, `node --check site-brand.js`, `node tools/check-site.mjs`, `node --test tests/site-security.test.mjs`, and `git diff --check`; then required GitHub checks, Pages deployment and live browser inspection. Review current main/branch state before pushing. The associated pull request and Actions runs hold deployment results. Use current repository source rather than old upload names or local archive copies.

The earlier dated sections below are historical context. They do not supersede this design lock, the tested IR 1.0.0 release or the draft candidate status above.

## IR 1.0.0, version-bound verification and catalog alignment

The owner confirmed all three exact files in FIELD-KIT-IR-1.0.0.zip passed on
the client jumpbox. The canonical downloads now use BEC-RISK-ASSESSMENT.ps1,
BEC-CONTAIN-ERADICATE.ps1 and BEC-RECOVER-VALIDATE.ps1 at version 1.0.0. Their
VERIFIED records bind version, SHA-256 and sanitized owner-test evidence in
docs/qa/IR-1.0.0-VERIFICATION.md. Any source change invalidates the stamp until
the replacement is tested. Do not stamp other tools based on static review.

Approved output uses STATUS and NEXT STEP, concise paced sections, one approval
per section, exact-filename ENTER navigation and ESC to close. The final
assessment ends the workflow. Test-user utilities remain unpublished.

Continue with docs/CATALOG-ALIGNMENT-PLAN.md and the generated source inventory.
Review existing repository source in small batches. Stop for owner decisions
on behavior, authority, scope, consolidation, or unclear success criteria.

## Previous interactive IR baseline — October 16, 2026

The three canonical interactive IR downloads now use the owner's tested 0.4.0
copies. Source-pending placeholders are replaced with real paths and reviewed
metadata; containment is destructive because selected persistence is deleted.
See `docs/IR-WORKFLOW.md` for launch, consent, hybrid authority, secret-display
and validation limits. Exact uploaded source bytes are retained, with no test
transcripts or client evidence published. Assessment, response, cleanup,
recovery and same-process handoffs were reported successful on the test jumpbox.
Authentication-library combinations and synchronization remain deployment-specific.

0.4.1 output/closing-flow candidates and test-user setup/verify/teardown auth
hotfixes remain outside the public release pending the owner's next tests.
Do not overwrite this tested baseline with those files without that review.

## Tools and Toys publication — 2026-10-13

Tools now includes standalone Git repository check/push/pull, security-export review, execution setup, the updated handoff snapshot, and a quick-start reference. Toys contains Attractor, Rain, and Static terminal animations. Public copies are unsigned and contain no personal exports or review checkpoints.

Security review saves exact-event checkpoints silently only after a full unfiltered review with no flags; acknowledging flagged records remains explicit. The ALL CLEAR wording describes rule matches, not proof of authorization. Execution setup installs no modules and pauses with Enter to exit.

Validation includes PowerShell parser checks, Linux PowerShell behavior tests, terminal animation smoke tests, and catalog DOM checks for navigation/source/copy/download. Native Windows and visual browser validation remain outstanding. Publishing also fixes the shared copy-button completion handler and excludes an empty legacy split-command duplicate from the catalog audit.

## Compact cards and uploaded tools — October 12, 2026

Added nine unique public scripts from ten uploads. SIGN-FOLDER-SCRIPTS and INVOKE-SIGN-FOLDER-SCRIPTS were identical after normalizing newlines/removing signatures and are represented by Digital Signature. Originals were left untouched. Published copies remove signing blocks, replace local root defaults with C:\Field-Kit, and use generic signing/example labels. Control flow and operational commands are preserved.

Tools includes setup, repository helpers, and reference groups. Themes live in Toys alongside animations. Existing generic readiness, repository inventory, and M365 reset remain separate from the uploaded fixed-layout readiness, file inventory, folder map, and profile-aware reset. They have different checks and inputs; no executable implementations were merged.

Silicon Valley retains its predictable date-seeded daily password generator and key bindings, explicitly disclosed on its card. Sea Glass and Silicon Valley write profiles; Cobalt is a preview; Basic is plain-output examples. Cobalt and Sea Glass retain Process Bypass as supplied. Native Windows validation is still needed.

Validation: all Tools/Toys parsed in PowerShell 7; nine uploaded copies matched their normalized originals with only listed sanitization replacements. The 338-entry audit, all new/renamed card downloads/copy/source tests, desktop/mobile Chromium checks, and three PTY animation/label/Ctrl+C checks passed. Native Windows execution is outstanding.

Cards use USE FOR, risk flags, visible download/view/copy, up to three checks, and expandable detail. The site and existing animations are brighter; uploaded theme palettes remain unchanged. Animations use editable <YOUR TEXT HERE> and terminal titles Attractor/Rain/Static. BEC discovery displays as M365 User Security Review while preserving search terms and workflow sequence.

## Goal

Maintain a small, dependable, searchable catalog of practical PowerShell tools and operator references.

Grow by useful operational coverage, not file count:

```text
real need
    ↓
check the catalog
    ↓
improve the canonical tool or fill a real gap
    ↓
review + static QA
    ↓
runtime test when behavior changed / when practical
    ↓
publish
```

## Source of truth

- Repository: `Grimmieeee/pwsh-operations-catalog`
- Development branch: `v1-repo-ui`
- Public / GitHub Pages branch: `main`
- Last executable build release checkpoint: `afdcef1`
- Current branch tip after handoff-only documentation updates: use the current remote HEAD
- Canonical operating contract: `OPERATING-STANDARDS.md`
- Canonical handoff: `tools/PROJECT-HANDOFF.md`
- Overlap / lineage record: `AUDIT-LIMBO.md`

## Current repository state

At the last release checkpoint:

- `main` and `v1-repo-ui` were identical at `afdcef1`.
- The reviewed `v1-repo-ui` build was promoted to `main` by fast-forward.
- The site was manually reviewed and accepted before promotion.
- No executable source was changed as part of the branch promotion.
- `AUDIT-LIMBO.md` has no current HOLD, SALVAGE, or REPLACEMENT items.

When resuming locally, run `git check` before making changes. Use `git grab it` only from a clean working tree.

## Current product shape

FIELD // KIT is intentionally:

- static;
- search-first;
- dependency-light;
- source-first;
- usable from local HTTP or GitHub Pages;
- organized around canonical operational jobs rather than historical script count.

Do not add a framework, backend, database, account system, or dashboard layer without a real need that the current static model cannot solve.

## Current catalog direction

The catalog has completed a major consolidation pass.

Current growth rule:

- bring ideas;
- check whether the job is already covered;
- improve the existing canonical tool when appropriate;
- add a new tool only when it owns a distinct, defensible job;
- prefer one 1-to-N tool over separate single/bulk copies when the safety model is the same;
- keep focused tools separate when their decision purpose, prerequisites, or safety model is materially different.

New work currently being explored is mainly:

- additional practical Tools / operator references;
- terminal customizations and terminal-native experiments;
- incremental operational tools that fill real gaps.

Terminal customization is a separate creative lane from the public operations catalog. It does not need to replace existing operational code to be worth keeping, but it should still be curated hard to avoid near-duplicate clutter.

## Recently completed

Recent release work includes:

- universal Handoff Snapshot tool published under Tools; first workstation runtime test still pending;
- canonical 1-to-N workflow consolidation;
- stronger group membership behavior across AD and Entra;
- Windows Storage Cleanup Review;
- cloud-only user password reset;
- MFA audit preferred/default authentication-method context;
- NATO Phonetic Alphabet reference;
- Project Handoff;
- Operating Standards / PowerShell Standards / build-standard true-up;
- review and publishing checklist alignment;
- search and Tools metadata cleanup;
- removal of the public Backup Exporter card while retaining the helper as repository-maintenance tooling.

## Validation policy

Do not turn runtime QA into a blanket retest project.

Use this rule:

> Re-runtime-test executable source when behavior changed after the last meaningful runtime test, or when a previously untested path is about to be relied on.

Prior runtime validation remains useful for executable source that has not materially changed.

Keep these states separate:

- static / parser QA;
- manual site/UI QA;
- runtime PowerShell / service validation.

Do not describe static QA as runtime validation.

Recent or materially changed scripts that have not yet been proven in the intended environment should be tested naturally as they come into use. Do not claim runtime success merely because the source passed static review.

## Locked decisions

- Search remains the primary discovery model.
- Full Library searches the complete catalog.
- Single User / Multi User / Tenant Wide search across those three scopes as one working set.
- Incident Response keeps execution sequence instead of alphabetical order.
- Other non-sequential lists sort A-Z.
- Risk labels are exactly READ ONLY / MAKES CHANGES / DESTRUCTIVE.
- Destructive items also display MAKES CHANGES.
- Public source stays unsigned canonical text.
- Internal signed copies are release artifacts, not separate code lineages.
- Publishing is not a refactor step.
- Do not rewrite known-working executable logic solely for style consistency.
- Failed or skipped queries must never become clean findings.
- Hybrid observation and change authority are separate concepts.
- Synced identity/group changes follow the authoritative source.
- Generated temporary secrets are never auto-exported or automatically copied to the clipboard.
- Repository-maintenance helpers under `tools/` are not automatically public catalog items.
- `tools/PROJECT-HANDOFF.md` is the canonical continuation record.

## Do not rediscover

- Numeric `1-` / `2-` prefixes are historical scope markers, not required canonical naming.
- Separate single-user and bulk cards are not needed when one safe 1-to-N workflow handles both.
- A successful command call is not the same as verified resulting state.
- A valid cached Graph/EXO session may still belong to the wrong tenant.
- Scopes/consent and administrative role/authority are separate requirements.
- Public sanitization must not silently change executable behavior.
- The Backup Exporter remains repository maintenance tooling; do not surface it publicly by default.
- The site does not need another structural redesign before a real usability problem justifies one.

## Known limitations / pending validation

- Some newer or materially changed tools may still need environment-specific runtime validation.
- Runtime validation should be recorded when it occurs, but no blanket re-test is required.
- Windows / Graph / Exchange / AD behaviors cannot be considered runtime-proven from static QA alone.
- Local browser / Windows execution checks still require an actual workstation when the task depends on them.

## Next phase

Take Step 3 slowly while continuing to build and refine.

Likely work:

1. On the next workstation session, pull current repos and run the Handoff Snapshot tool once to establish the first baseline.
2. Continue accepting new tool/reference ideas and evaluate them against the canonical-job rule.
3. Runtime-test changed/new executable behavior when it naturally comes into use.
4. Add RELATED / NEXT relationships only where they genuinely improve operator flow.
5. Continue improving search aliases/synonyms instead of adding UI clutter.
6. Keep terminal experimentation separate and curated.

## Next session — start here

First action:

1. Read this file.
2. Read `OPERATING-STANDARDS.md` before changing project behavior.
3. Check the current branch/working-tree state.
4. Ask what new tool, reference, or terminal idea is being evaluated next.

Do not begin with a redesign or broad cleanup pass. The current catalog structure is accepted.

## Useful commands

```powershell
git check
git check details
git grab it
git send it
```

Local preview, from the repository root:

```powershell
http-server -p 9443 -c-1
```

Then browse to:

```text
http://127.0.0.1:9443
```

## Public handoff safety

Do not store credentials, tokens, temporary passwords, tenant IDs, private hostnames, customer data, real incident evidence, private app/certificate identifiers, or unnecessary user-specific filesystem paths in this public handoff.

## Approved catalog treatment — October 13, 2026

Apply the approved compact card treatment through the shared renderer in every section. Preserve existing typography and weights; use stronger colored access flags, concise objectives, up to three visible checks, and directly available download/view/copy controls. Keep setup first and A–Z within groups, with incident response sequence preserved.

Signing Certificates is the separate certificate-management companion to Digital Signature. Its public copy removes the signature block and uses Local Script Signing as the default label. It still lists installed current-user certificates; automatic personal-certificate selection and organization filtering have not been implemented. Uploaded operational logic remains unchanged. Windows runtime validation and broader portability work remain outstanding.

## Task organization and incident names — October 13, 2026

Approved incident names and intended canonical filenames:
- IR: Identity Risk Assessment — IR-GET-IDENTITY-RISK-ASSESSMENT.ps1
- IR: Contain and Eradicate — IR-INVOKE-CONTAINMENT-ERADICATION.ps1
- IR: Restore and Validate — IR-INVOKE-RECOVERY-VALIDATION.ps1

IMPORTANT: The interactive Step 1/2 executable files were not in the repository or supplied workspace, and Step 3 previously existed only as a workflow label. These three catalog entries are explicitly Source pending, with no download. Their names are approved; executable renaming and behavior verification await the interactive originals. The supplied assessment is an RMM-native version and has NOT been substituted into the interactive catalog. Recovery is a planned description pending source verification. No executable script changed in this release.

RMM entries are excluded at the common item-building boundary, including supplemental RMM records; archived definitions/source are retained. The Revoke Sessions quick command remains available as an independent IR action. Numbered workflow links are navigation, not automatic execution or mandatory authorization to proceed.

Browse groups distinguish User, Groups, Permissions, Licenses, Mailbox, Security, On / Offboarding, and Audit. Setup stays first; subject and action order come before A–Z tie-breaking. IR sequence remains fixed. Contextual navigation labels replace JUMP TO. Search uses controlled subject/task synonyms. Documents have GUIDE/REFERENCE flags rather than execution-risk labels. Related links are curated sets and resolve to real catalog cards.
