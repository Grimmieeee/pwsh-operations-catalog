# FIELD // KIT Build Standard

Status: LOCKED BASELINE
Purpose: Preserve the approved visual, interaction, taxonomy, and publication model for FIELD // KIT.

## 1. Product shape

FIELD // KIT is a static, search-first working catalog for PowerShell scripts, commands, operational workflows, and reusable documentation.

Keep it:

- static;
- fast;
- dependency-light;
- readable without a build pipeline;
- useful from a local HTTP server or GitHub Pages;
- source-first, not marketing-first.

Do not introduce a framework, backend, database, or authentication layer unless the catalog genuinely outgrows the static model.

## 2. Canonical visual direction

Visual language:

- dark charcoal work surface;
- neon mint accent;
- thin Scandinavian/editorial display typography;
- quiet metadata;
- strong whitespace;
- restrained borders;
- minimal animation;
- no decorative dashboard clutter.

Primary palette:

- Neon Mint: #00F0B5
- Charcoal Gray: #282D32

Typography intent:

- display: thin, editorial, geometric;
- UI/body: neutral and highly readable;
- filenames/commands: monospace.

The design should feel like a high-end technical field reference, not a SaaS dashboard.

## 3. Brand

Primary mark:

F I E L D  //  K I T

Rules:

- FIELD carries the stronger weight.
- // uses Neon Mint.
- KIT is thinner.
- Preserve intentional spacing around //.
- Browser title should use: F I E L D  //  K I T

Sidebar signature block:

B U R N S I D //
--------------------------------
E S T.  2 0 2 6

Keep the signature quiet, mint, and secondary to the product mark.

Masthead line:

A WORKING REFERENCE.  USE RESPONSIBLY.

Keep this on one line where viewport width allows.

## 4. Navigation

Primary navigation order is intentional:

1. Full Library
2. Single User
3. Multi User
4. Tenant Wide
5. Incident Response
6. RMM
7. Utility
8. Standalone
9. Tools
10. About

Do not reorder primary navigation alphabetically.

Full Library groups items by primary scope/category.

Scoped pages use purpose sections:

1. Access
2. Audit
3. Identity
4. On / Offboarding
5. Mailbox
6. Security

These purpose headings are intentionally ordered by operator workflow, not alphabetically.

## 5. Sorting

Within every non-sequential section, items are A-Z by display name.

Exceptions:

- Incident Response: execution sequence wins.
- Search results: relevance wins; A-Z breaks ties.

Never alphabetize a sequence-dependent workflow.

## 6. Risk labels

Use exactly:

- READ ONLY
- MAKES CHANGES
- DESTRUCTIVE

The list-row flag and selected-card flag must use the same wording.

Meaning:

- READ ONLY: reviews information.
- MAKES CHANGES: modifies configuration, state, or access.
- DESTRUCTIVE: can remove data, access, objects, or other difficult-to-reverse state.

Do not use abbreviated CHANGE labels.

## 7. Main list

Each row should prioritize:

1. display name;
2. filename / source name;
3. risk flag when applicable;
4. navigation arrow.

Filename treatment:

- monospace;
- visible but deliberately dimmer than the display name;
- large enough to scan without competing with the title.

Rows should remain dense enough for fast scanning.

## 8. Selected card contract

All selected cards use one shared renderer.

Order:

1. SELECTED header
2. SCOPE / PURPOSE context
3. title with final word accented in mint
4. mint underline
5. READ ONLY / MAKES CHANGES / DESTRUCTIVE
6. CONNECT when required
7. change note when useful
8. workflow/option block when required
9. CHECKS / DOES / INCLUDES
10. concise decision-focused description
11. POWERSHELL or MARKDOWN source button
12. source viewer when opened
13. palette footer

CHECKS / DOES / INCLUDES use the same [✓] visual rhythm.

Do not invent checklist items. Omit a section when approved metadata does not exist.

## 9. Source behavior

PowerShell cards:

- button label: POWERSHELL;
- lazy-load approved same-origin source;
- COPY SCRIPT;
- SAVE .PS1.

Documentation cards:

- button label: MARKDOWN;
- lazy-load approved same-origin source;
- COPY MARKDOWN;
- SAVE .MD.

Standalone atomic commands:

- show the command directly;
- COPY COMMAND;
- no unnecessary source indirection.

Source must never be fetched from arbitrary external URLs.

## 10. Tools section

Tools contains reusable public-safe documentation.

Preferred groups:

- Reference
- Standards
- Templates

Good candidates:

- build standards;
- script standards;
- review checklists;
- publishing checklists;
- connection patterns;
- reusable skills/workflows;
- session handoff templates;
- lessons learned.

Do not publish:

- client identifiers;
- tenant IDs;
- private server names;
- private filesystem paths;
- internal allowlists;
- private app registrations;
- certificate identifiers;
- credentials or secrets;
- vendor-specific internal deployment details unless intentionally public and generic.

## 11. About page

About should explain:

- what FIELD // KIT is;
- how scope and purpose work;
- A-Z behavior;
- Incident Response sequence exception;
- risk-label meanings;
- that reusable standards/checklists/templates live under Tools.

Keep About concise. It is orientation, not a manual.

## 12. Search

Search is primary discovery.

Search should include useful hidden aliases/metadata, but the UI should display only decision-relevant information.

Avoid a metadata wall.

## 13. Publication boundary

Private repository/source remains canonical until a script is explicitly approved for public release.

Before publishing script source:

1. review the actual current file;
2. parse it;
3. review operational behavior;
4. review permissions;
5. review destructive actions;
6. scan for secrets;
7. scan for proprietary/environment-specific identifiers;
8. sanitize comments and sample values;
9. confirm card metadata matches the real script;
10. publish an approved same-origin copy.

Never bulk-publish private source without review.

## 14. Framework guardrails

Keep:

- one shared card renderer;
- one shared risk-label function;
- one shared sorting model;
- one shared source loader;
- runtime framework audit;
- explicit same-origin CSP for scripts/source loading;
- public-safe static files only.

Do not fork separate card layouts for individual scripts.

## 15. Change policy

This document is the locked baseline.

When proposing a design/framework change:

1. explain the problem it solves;
2. show why the existing pattern is insufficient;
3. prefer the smallest change;
4. preserve the approved visual hierarchy;
5. re-run framework, sorting, source, and publication checks.

Do not redesign stable areas casually.

## 16. Release checklist

Before publishing a new build:

- [ ] navigation correct;
- [ ] non-sequential sections A-Z;
- [ ] Incident Response sequence correct;
- [ ] search works;
- [ ] drawer opens/closes correctly;
- [ ] risk flags match card behavior;
- [ ] CHECKS / DOES / INCLUDES render consistently;
- [ ] filenames remain readable and subdued;
- [ ] POWERSHELL / MARKDOWN source controls work;
- [ ] COPY works;
- [ ] SAVE works;
- [ ] same-origin source loading works;
- [ ] About is current;
- [ ] Tools docs are current;
- [ ] secret/proprietary-content scan passes;
- [ ] runtime framework audit passes.


## 17. Local backup / recovery

The checked-out Git repository is the working source of truth.

Do not replace the working repository with a ZIP archive.

Backup model:

- working source stays in the Git clone;
- backup ZIPs live outside the repository;
- backups are created only from a clean working tree;
- update with a fast-forward-only pull before archiving;
- archive the exact tracked contents of HEAD;
- exclude .git history and untracked/local-only files from the portable ZIP;
- preserve timestamped backups;
- refresh FIELD-KIT-LATEST.zip on each successful run;
- write a manifest containing branch, commit, tracked-file count, and SHA256.

Canonical helper:

`tools/export-field-kit.ps1`

Default backup location:

`%USERPROFILE%\Downloads\FIELD-KIT-Backups`

The ZIP is a recovery/export snapshot. It is not a replacement for the repository.
