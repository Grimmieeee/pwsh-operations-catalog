# FIELD // KIT Project Handoff

Current continuation record for the FIELD // KIT PowerShell Operations Catalog.

This file records the current project state so a new session can resume without reconstructing prior conversations. Project-wide rules still come from `OPERATING-STANDARDS.md`; this handoff records where the work currently stands.

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
