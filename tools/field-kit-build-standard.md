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

Keep the signature quiet, mint, and secondary to the product mark. Do not add an EST / year line.

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
10. Toys
11. About

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

Setup and terminal provisioning come first where relevant. Within each non-sequential group, items are A-Z by display name.

Exceptions:

- Incident Response: execution sequence wins.
- Search results: relevance wins; A-Z breaks ties.

Never alphabetize a sequence-dependent workflow.

## 6. Risk labels

Use exactly:

- READ ONLY
- MAKES CHANGES
- DESTRUCTIVE

Meaning:

- READ ONLY: reviews information and does not intentionally modify state.
- MAKES CHANGES: modifies configuration, state, or access.
- DESTRUCTIVE: can remove data, access, objects, or other difficult-to-reverse state.

Display contract:

- READ ONLY is shown explicitly.
- MAKES CHANGES is shown explicitly.
- DESTRUCTIVE is shown together with MAKES CHANGES because destructive work is also change-making.
- The main-list row and selected card must use the same wording and combined state.
- Risk labels use restrained outline badges; yellow remains the change warning and red remains the destructive warning.

Do not use abbreviated CHANGE labels.

## 7. Main list

Each row should prioritize:

1. display name;
2. primary module / platform;
3. primary scope when applicable;
4. risk state;
5. navigation arrow.

Context treatment:

- module/platform examples: EXCHANGE, GRAPH, ACTIVE DIRECTORY, GRAPH + EXO;
- scope examples: SINGLE USER, MULTI USER, TENANT WIDE;
- context badges are informational, not separate click targets;
- neutral badges stay deliberately subdued and brighten with row hover;
- risk badges retain their warning color;
- do not expose a metadata wall.

Rows should remain dense enough for fast scanning while giving a new operator enough context to understand what the item targets, what it uses, and what it can do.

## 8. Selected card contract

All selected cards use one shared renderer.

Order:

1. Scope, title, and risk flags.
2. USE FOR: one short sentence.
3. Important changes and required workflow order.
4. Up to three useful checks; remaining checks expand under More checks.
5. DOWNLOAD .PS1 / .MD, VIEW CODE, and COPY actions.
6. Required inputs, permissions, and connection commands.
7. Expandable details and source.

Use the compact Path Ping card as the default. Checkmarks describe distinct capabilities; do not repeat the title, purpose, or generic summary/CSV availability. Omit empty sections. Do not invent checks. Preserve important behavior and limitations in Details; show unusual side effects prominently.

## 9. Source behavior

PowerShell and documentation cards expose download and copy before opening source. All three actions load the same approved same-origin content. Missing source is labeled unavailable, never presented as a working download. Copy confirms COPIED; loading failures remain visible.

Standalone atomic commands:

- show the command directly;
- COPY COMMAND;
- no unnecessary source indirection.

Source must never be fetched from arbitrary external URLs.

## 10. Tools section

Tools contains reusable public-safe documentation, references, and explicitly approved Git and local setup helpers. Repository-maintenance helpers may also live under `tools/`, but they are not automatically public catalog items.

Preferred groups:

- Setup
- Repository
- Reference (includes standards and templates)

Good candidates:

- build standards;
- script standards;
- review checklists;
- publishing checklists;
- connection patterns;
- reusable skills/workflows;
- project handoff templates;
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

Behavior:

- Full Library searches the complete catalog.
- Searching from Single User, Multi User, or Tenant Wide searches across all three scope buckets as one working set.
- Search includes every section; the selected area controls browsing only.
- Flattened search results must retain useful scope context through the scope badge.
- Search may use hidden aliases/metadata for matching, but the UI should display only decision-relevant information.

Avoid a metadata wall.

## 13. Publication boundary

Private/original source remains canonical until a script is explicitly approved for public release.

Publishing is not a refactor step.

Before publishing script source:

1. review the actual current file;
2. parse it;
3. review operational behavior;
4. review permissions;
5. review destructive actions;
6. scan for secrets;
7. scan for proprietary/environment-specific identifiers;
8. sanitize comments and sample values only when required;
9. remove internal Authenticode signature blocks from the public copy when they expose an environment-specific signing identity;
10. preserve executable logic when signature-only sanitization is sufficient;
11. re-review any file whose executable logic changed during sanitization;
12. confirm card metadata matches the real script;
13. publish an approved same-origin copy;
14. verify the published copy is identical to the reviewed approved source.

Do not modify the user's working/original script merely to fit catalog style.

If a functional script needs generalization, portability work, or behavior changes, treat that as a separate revision and validation cycle before publication.

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
- [ ] Single / Multi / Tenant cross-scope search works;
- [ ] drawer opens/closes correctly;
- [ ] module/platform badges are accurate;
- [ ] scope badges are accurate;
- [ ] READ ONLY / MAKES CHANGES / DESTRUCTIVE badges match actual behavior;
- [ ] destructive items show both MAKES CHANGES and DESTRUCTIVE in list and selected card;
- [ ] CHECKS / DOES / INCLUDES render consistently;
- [ ] download, view-code, and copy controls work;
- [ ] COPY works;
- [ ] SAVE works;
- [ ] same-origin source loading works;
- [ ] published source matches the reviewed approved file;
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

Canonical maintainer helper:

`tools/export-field-kit.ps1`

This is repository maintenance tooling. Do not surface it as a public catalog download unless it is deliberately generalized and independently reviewed for that execution model.

Default backup location:

`<FIELD-KIT project root>\Backups`

The exporter derives the backup folder from the repository location, so moving the FIELD-KIT parent folder keeps the backup workflow valid.

The ZIP is a recovery/export snapshot. It is not a replacement for the repository.

## Toys

Toys is a separate primary navigation area after Tools. Its Animations and Themes groups uses the same cards, A-Z ordering, risk labels and source controls. Include terminal requirements and exit instructions; never imply screen-lock protection.

Theme previews and installers must be distinguished. Preserve explicitly requested source behavior and disclose profile writes, process policy changes, and other non-cosmetic effects. New uploaded theme palettes remain as supplied; the site and existing animations use a brighter palette.

## Task navigation update — October 13, 2026

Preserve established typography, weights, and risk colors. Browse by subject and task; setup first, then subject/action order with alphabetical ties. Incident workflow order takes priority. Use contextual group-navigation labels and controlled search aliases. Distinguish GUIDE/REFERENCE documents from executable risk labels. Related links must resolve to catalog cards, with only curated, useful relationships. Missing incident sources must remain visibly unavailable; never substitute RMM implementations or invent executable downloads.
