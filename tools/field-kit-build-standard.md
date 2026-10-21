## Shared purpose sentence — October 21, 2026

Every script card shows one brief purpose sentence directly below the title. Use the exact same sentence as the script objective. Describe the specific job plainly; keep scope, steps and limitations separate. The objective must not imply complete access coverage, a clean security verdict, successful changes, or unsupported bulk behavior. Reuse an existing suitable objective when that preserves an accepted specialized release. Card/source parity is a release check.

## Approved operator cards — October 20, 2026

The owner approved this card design and broad rollout in the current conversation. It supersedes older card/drawer instructions below. The main dashboard/navigation is not being redesigned.

- Use a short action/object name. Mirror pairs such as Get User Groups / Remove User Groups; use stable filenames for source and handoffs.
- Show impact, platform and accurate scope up front: SINGLE-USER, MULTI-USER, SINGLE or MULTI-USER, TENANT or LOCAL. Use GROUP/MAILBOX where the target is not a user. Never imply bulk support the source does not have.
- Keep input format brief: UPN / CSV / TXT where supported. Surface extra preparation such as a required tenant ID when it changes what the operator must bring.
- STEPS comes before Download / View Code. Ordinary interactive tools use: Download file. Select Run with PowerShell. Press Enter to close session when complete.
- Preserve existing-session, administrator, IR and terminal controls as explicit launch exceptions. Never imply automatic closing or force-close a caller's window. Unattended jobs must remain noninteractive.
- DETAILS is one optional disclosure of operational necessity and limits. Avoid duplicating script notes, module lists, generic use cases, or every prompt. Important destructive impact remains visible in the impact labels.
- Related Items uses clear tool names and impact labels, without repeated use-case captions or decorative symbols. Script cards have three valid task-related destinations. Never link to missing source as a working tool.
- Keep exact command preparation, target placeholders and safety warnings for quick commands. These are execution requirements, not removable decoration.
- Script presentation uses a matching title, one objective, useful results, a neutral SESSION COMPLETE marker and the agreed Enter prompt where compatible. A completion marker does not establish successful results.
- Preserve authentication, target resolution, service calls, confirmations, outcomes and exports during a presentation-only change. Behavior changes need their own evidence and follow-up.
- Existing operational tests remain accepted for their recorded source and scope. Presentation comparisons do not invent live runtime testing of revised bytes; retain history and apply the exact-source verification gate.

# FIELD // KIT Build Standard

The final October 17, 2026 visual contract is in `DESIGN-LOCK.md`. It takes precedence over older visual descriptions here. Future visual changes require an in-chat preview and explicit owner approval before publication.

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
- Risk labels are plain colored text without boxes: mint read-only, yellow changes, coral red destructive.

Do not use abbreviated CHANGE labels.

## 7. Main list

Each row should prioritize:

1. display name;
2. small exact-version circled V when earned;
3. primary scope in search results when useful;
4. risk state;
5. navigation arrow.

Context treatment:

- module/platform labels belong in the selected card's technical section;
- scope examples: SINGLE USER, MULTI USER, TENANT WIDE;
- context badges are informational, not separate click targets;
- context text stays deliberately subdued;
- risk labels retain their warning color without borders or fill;
- do not expose a metadata wall.

Rows should remain dense enough for fast scanning while giving a new operator enough context to understand what the item targets, what it uses, and what it can do.

## 8. Selected card contract

All selected cards use one shared renderer.

Order:

1. Scope, title, small raised circled V when earned, and plain risk labels.
2. USE FOR: one short sentence.
3. Important changes and required workflow order.
4. INPUT, CHECKS and GUARDS, using matching headings and no overflow groups.
5. Compact REQUIRES disclosure, then AUTO-CONNECT or CONNECT FIRST above small boxed service names and accurate start directions.
6. Useful expandable Details; DOWNLOAD .PS1 / .MD and VIEW CODE actions.
7. COPY inside the exposed source box only.

Use the compact Path Ping card as the default. Checkmarks describe distinct capabilities; do not repeat the title, purpose, or generic summary/CSV availability. Omit empty sections. Do not invent checks. Preserve important behavior and limitations in Details; show unusual side effects prominently.

## 9. Source behavior

PowerShell and documentation cards expose download and View Code. COPY appears inside the source box only after approved source loads. All actions use the same checksum-verified same-origin content. Missing source is labeled unavailable, never presented as a working download. Copy confirms success; loading failures remain visible.

Standalone atomic commands:

- show the command directly;
- COPY inside the command's code box;
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
- [ ] READ ONLY / MAKES CHANGES / DESTRUCTIVE text labels match actual behavior;
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

## Selected card information

Order: USE FOR, INPUT, CHECKS, GUARDS, connector commands, useful additional Details, source actions. INPUT lists what the operator supplies and distinguishes choices discovered by the script. Omit empty sections. INPUT, CHECKS and GUARDS use matching headings. Keep requirements in a compact REQUIRES disclosure with hover text and tap/keyboard access; never rely on hover alone. Keep change consequences visible when they add safety information. Do not duplicate the objective or checklist in Details.

Card accuracy is part of script verification: trace every input, check, guard, permission, connection and output claim to the exact source version. Operator testing must exercise name resolution and failure paths before granting a verified release. Never infer functionality from a title, template, or another script.

## Toys

Toys is a separate primary navigation area after Tools. Its Animations and Themes groups uses the same cards, A-Z ordering, risk labels and source controls. Include terminal requirements and exit instructions; never imply screen-lock protection.

Theme previews and installers must be distinguished. Preserve explicitly requested source behavior and disclose profile writes, process policy changes, and other non-cosmetic effects. New uploaded theme palettes remain as supplied; the site and existing animations use a brighter palette.

## Task navigation update — October 13, 2026

Preserve established typography, weights, and risk colors. Browse by subject and task; setup first, then subject/action order with alphabetical ties. Incident workflow order takes priority. Use contextual group-navigation labels and controlled search aliases. Distinguish GUIDE/REFERENCE documents from executable risk labels. Related links must resolve to catalog cards, with only curated, useful relationships. Missing incident sources must remain visibly unavailable; never substitute RMM implementations or invent executable downloads.
