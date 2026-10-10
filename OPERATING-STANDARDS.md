# FIELD // KIT Operating Standards

## 1. Purpose

FIELD // KIT is the working standard for building, reviewing, publishing, and handing off the PowerShell Operations Catalog and its scripts.

The goal is not to preserve every historical script. The goal is to maintain a smaller set of dependable operational tools with clear jobs, predictable inputs, safe behavior, and enough documentation that another engineer can understand or rebuild the project without relying on conversation history.

This document is the default decision record when script behavior, naming, publication, or repository structure is unclear.

### Documentation hierarchy

When guidance overlaps, use this order:

1. `OPERATING-STANDARDS.md` — top-level project decision contract.
2. `tools/field-kit-build-standard.md` — site, visual, navigation, and interaction baseline.
3. `tools/powershell-standards.md` — PowerShell implementation baseline.
4. Focused references, checklists, and templates — apply within their specific job.
5. `tools/PROJECT-HANDOFF.md` — records current project state for continuation; it does not override the standards above.

Keep focused documents focused. Do not copy the full operating contract into every checklist or template.

## 2. Core Principles

### One job, one canonical source

When two scripts perform the same operational job, prefer one canonical implementation.

Do not keep separate single-object and bulk scripts only because they were originally written separately. If the same workflow can safely support one object or many objects without making the common case harder, one canonical script should support both.

Keep a separate tool only when it has a distinct operational purpose, substantially different output, materially different prerequisites, or different safety requirements.

### Signal over noise

Output should help the operator make a decision. Avoid decorative verbosity, duplicate summaries, unexplained raw objects, and success messages that do not prove anything useful.

### Evidence before action

Read-only discovery should be easy to run. Change-making workflows should show what was found, what will change, what authority will be used, and what validation will be performed before execution.

### Observation and authority are different concepts

Hybrid objects may be visible in more than one system. Do not hide useful observations merely to remove duplicate names.

For example, a synced group may appear in both Active Directory and Entra ID. That is useful evidence and should be shown as such.

When making changes, act only at the authoritative source:

- Synced identity or group state: Active Directory unless the specific property is cloud-owned.
- Cloud-only identity or group state: Entra ID / Microsoft Graph.
- Exchange recipient, mailbox, transport, or delegation state: Exchange Online unless the setting is explicitly owned elsewhere.

### Public and internal behavior must not drift

A signed/internal copy and a public copy may differ in signature block, branding, private configuration, or deployment wrapper. They should not silently differ in core logic, authentication model, input handling, validation, or safety controls.

The unsigned canonical source is the behavior source of truth. Internal signing is a release step, not a separate code lineage.

## 3. Script Scope and Naming

Historic source prefixes are interpreted as:

- `1-` — single-object workflow.
- `2-` — explicitly supplied multi-object workflow.
- `TENANT-` — enumerates or evaluates tenant-wide state.
- `IR-` / `BEC-IR-` — incident-response workflow or investigative utility.

These prefixes describe historical scope; they are not required on final canonical public filenames.

When a single-object and multi-object pair is consolidated into one 1-to-N tool, the canonical filename should normally drop the numeric prefix.

Examples:

- `GET-USER-GROUPS.ps1`
- `GET-GROUP-MEMBERS.ps1`
- `GET-MAILBOX-PERMISSIONS.ps1`
- `INVOKE-DISABLE-ACCOUNTS.ps1`

Do not label a script `2-` merely because it loops through tenant objects internally. Tenant-wide discovery belongs under `TENANT-`.

## 4. Input Standard: 1 to N

When an operation naturally supports one or many targets, use one input path.

Preferred interaction:

```text
Enter name, email, UPN, or TXT/CSV path:
```

The script should detect whether the supplied value is:

1. A direct object identifier.
2. Multiple direct values where supported.
3. A TXT file.
4. A CSV file.

Do not require the operator to choose "single mode" or "bulk mode" when the same execution engine can handle both.

### Catalog discoverability for 1-to-N tools

A canonical 1-to-N tool may belong to more than one browsing scope without duplicating the catalog record or source file.

When a tool naturally supports both one target and many targets:

- Keep one catalog record and one canonical source.
- Declare both `Single User` and `Multi User` scope metadata.
- Allow the site to surface the same record under either scope.
- Do not create a second "bulk" card merely to make the workflow discoverable.
- Global search should show all declared scope tags for the record.

Scope metadata is a discovery aid; it does not create separate implementations.

### TXT input

- One target per line.
- Ignore blank lines.
- Ignore lines beginning with `#` where practical.
- Trim surrounding quotes and whitespace.
- Deduplicate exact repeated inputs before execution.

### CSV input

Prefer known columns first, then fall back to the first populated column when safe.

Common accepted identity columns:

- `UPN`
- `UserPrincipalName`
- `Email`
- `Address`
- `User`
- `Name`
- `Input`

Common accepted group columns:

- `Group`
- `GroupName`
- `Name`
- `Email`
- `Address`
- `Mail`
- `Input`

### Bulk behavior

Bulk input must not reduce per-object validation. Every object should retain its own resolution, result, error, and post-change verification state.

## 5. Group Standards

There are two separate operational questions.

### User to Groups

`GET-USER-GROUPS.ps1` answers:

> What groups is this user in?

For every user, attempt both:

- Active Directory direct group memberships.
- Entra ID direct group memberships.

Do not cross-deduplicate AD and Entra observations.

A synced group seen in Entra should remain visible and be marked `[Synced]` even when an AD group with the same name is also present.

Useful Entra markers include:

- `[Synced]`
- `[Cloud]`
- `[Dynamic]`
- `[M365]`
- `[Protected]` when the workflow uses protected/reference groups.

Output must report source coverage independently:

```text
COVERAGE
Active Directory : Checked / Not checked
Entra ID         : Checked / Not checked
```

A failure to query one source must not be represented as an empty result from that source.

### Group to Members

`GET-GROUP-MEMBERS.ps1` answers:

> Who is in this group?

The general resolver checks in this order unless the tool is intentionally source-specific:

1. Exchange Online distribution group.
2. Entra ID group.
3. Active Directory group.

It should accept one group or TXT/CSV input and retain per-group resolution status.

A focused Exchange-only `GET-DISTRIBUTION-GROUP-MEMBERS.ps1` may remain because it has a distinct low-dependency job and does not require Graph or AD access.

## 6. Identity and Lifecycle Standards

### Read-only identity checks

Natural 1-to-N candidates include:

- Resolve names to UPNs.
- Verify account status.
- User group membership review.
- Stale-login/status review when the operator supplies targets.

### Change-making identity workflows

Natural 1-to-N candidates include:

- Disable accounts.
- Delete approved accounts.
- Assign or remove licenses.
- Remove approved group memberships.
- Enforce a repeated account-level setting when the same safety model applies.

Change-making 1-to-N tools must preserve:

- Preview before execution.
- Per-object resolution.
- Authoritative-source decision.
- Explicit confirmation.
- Per-object result.
- Post-change validation.

### Workflows that normally remain single-object

Keep guided single-object execution when batching materially increases risk or hides important review context. Examples include:

- User onboarding.
- User offboarding execution.
- Pre-delete dependency review.
- Incident containment / eradication / recovery workflows.

A read-only audit companion may still support multiple users when the output remains understandable.

## 7. Mailbox Standards

Use focused tools when the operational question is distinct.

Examples:

- `GET-MAILBOX-FORWARDING.ps1` — focused forwarding check.
- `GET-MAILBOX-PERMISSIONS.ps1` — forwarding, delegation, and inbox-rule review for one or more mailboxes.
- `GET-MAILBOX-SECURITY-SNAPSHOT.ps1` — deeper one-user mailbox posture snapshot.
- `GET-ROOM-RESOURCE-ACCESS.ps1` — room/equipment access and booking delegation.
- Tenant mailbox access audit — tenant-wide forwarding/delegation review.

Do not maintain separate single and bulk permission scripts when one implementation can accept direct values and TXT/CSV input.

## 8. Tenant-Wide Standards

Tenant tools answer a tenant-level question and should remain independent when their decision purpose is different.

Current model:

- Tenant security snapshot — fast broad posture.
- Quarterly cleanup review — operational hygiene/debt.
- Tenant drift review — compare current state with a known baseline.
- Focused tenant audits — MFA, Conditional Access gaps, app registrations, guest consent, service-principal ownership, Secure Score, sign-in anomalies, device-code exposure, shared-mailbox sign-ins, and similar focused checks.

Do not merge focused tenant audits into one monolithic script solely to reduce file count.

## 9. Incident Response Standards

Incident Response is intentionally evidence-first and may keep narrower utilities.

Recommended layers:

1. User / mailbox exposure snapshot.
2. Containment / eradication.
3. Recovery.
4. Deep-dive investigation utilities such as IP trace, token replay, token decode, threat intelligence, timeline, data exfiltration, tenant email search, and email recovery.

Read-only discovery and evidence collection should be clearly separated from containment or recovery actions.

A Service Desk first-response tool may collect evidence and perform explicitly approved containment, but ownership of broader investigation, scope validation, recovery decisions, monitoring, and closure can remain with the designated security function.

## 10. Authentication and Module Standard

### Modules

Published operational tools should not silently install PowerShell modules or Windows capabilities.

The dedicated setup utility `INSTALL-M365-MODULES.ps1` is the intentional exception: installing prerequisites is its explicit job, is visible to the operator, and is classified as a change-making setup tool.

If a required module is missing:

1. State the missing prerequisite.
2. Print an appropriate installation command or requirement.
3. Stop or skip only the affected source as appropriate.

This keeps runtime behavior predictable and avoids changing the operator's workstation as a side effect of a read-only tool.

### Microsoft Graph

- Prefer `Microsoft.Graph.Authentication` plus `Invoke-MgGraphRequest` when full SDK modules are unnecessary.
- Request only the scopes required by the job.
- Prefer `ContextScope Process` when the installed module supports it.
- Suppress the welcome banner when supported.
- Reuse an existing session only after required scopes and tenant/object visibility are validated.
- If a supplied tenant is explicit, reconnect rather than silently using an unrelated cached context.
- Show enough tenant/account context for the operator to verify where the query is running.

### Exchange Online

- Require `ExchangeOnlineManagement` rather than auto-installing it.
- Reuse a valid connection when the target resolves in that connection.
- Otherwise reconnect and validate the target before continuing.

### Active Directory

- Do not auto-install RSAT from an audit script.
- If the ActiveDirectory module is required and unavailable, report the gap.
- When a script can safely use `System.DirectoryServices` instead, that may be used to reduce module dependency.
- Hybrid user resolution should favor authoritative identifiers from Graph when available, then exact UPN/mail/proxy/SAM fallbacks with ambiguity checks.

### Prohibited setup side effects

Published tools must not call `Set-ExecutionPolicy` as part of normal execution.

## 11. Error Handling

Default to:

```powershell
$ErrorActionPreference = 'Stop'
```

Use local `try/catch` blocks where a failed source should be reported and execution can safely continue.

Do not use global `SilentlyContinue` as the primary error strategy for published tools.

Never translate "query failed" into "none found."

Use explicit states such as:

- Checked - none found.
- Not checked.
- Not available.
- Not found.
- Ambiguous.
- Failed.
- Pending sync.
- Verified.

## 12. Read-Only, Change, and Destructive Classification

Every catalog entry must declare one access classification:

### Read-only

No intended state change.

### Change

Makes reversible or administratively recoverable changes. Requires clear preview and confirmation when the effect is meaningful.

### Destructive

Deletes or irreversibly removes data/state, or carries equivalent operational risk. Requires explicit approval, strong confirmation, and post-action evidence.

Labels in the catalog and script comments must match actual behavior.

## 13. Confirmation Standard

For meaningful changes:

1. Resolve and show targets.
2. Show intended action.
3. Show authoritative source when hybrid behavior matters.
4. Require confirmation.
5. Perform the action.
6. Validate the result.

High-impact or destructive bulk changes should use typed confirmation such as:

```text
Type DISABLE to continue
Type DELETE to continue
```

Do not count a successful command invocation as validation when the resulting state can be queried.

## 14. Output Standard

Console output should be human-readable and ticket-friendly.

Recommended structure:

```text
TITLE
Read-only / Changes may be made

TARGET / USER / GROUP
...

FINDINGS
...

COVERAGE
...

TICKET SUMMARY
...
```

Prefer plain names and addresses over raw IDs unless an ID materially helps investigation or follow-up.

Sort human-facing lists alphabetically when order has no operational meaning.

Mark source/state rather than hiding overlap.

## 15. Export Standard

Exports are optional unless the workflow specifically requires an artifact.

For generated CSV/TXT artifacts:

- Ask before exporting unless the caller explicitly supplied an export switch/path.
- Use deterministic, readable columns.
- Read the export back after writing.
- Verify row count at minimum.
- For reviewed public tools, compare key exported fields against in-memory results when practical.
- Report the final path only after verification succeeds.

Do not claim an export is verified when only the write command succeeded.

### Generated credentials and temporary secrets

Tools that generate or reset passwords, recovery codes, tokens, or equivalent temporary secrets require tighter output handling:

- Never auto-export the secret to CSV, TXT, JSON, logs, or repository files.
- Never copy the secret to the clipboard automatically.
- Show the secret only after the related change succeeds.
- Keep summary tables free of the secret value.
- Warn that terminal capture or PowerShell transcription can record console output.
- Clear in-memory variables containing the secret as soon as practical.
- Validation should use resulting account state or metadata rather than echoing the secret again.

## 16. Public Publishing Standard

The public repository must not contain:

- Client names or tenant-specific private identifiers.
- Passwords, tokens, secrets, API keys, or certificate private material.
- PFX files or private certificates.
- Internal-only paths that reveal private deployment structure when unnecessary.
- Real incident evidence or private user data.
- Hard-coded customer domains, UPNs, GUIDs, or infrastructure identifiers except clearly synthetic examples.

Public scripts should be unsigned canonical text. Authenticode signatures belong to generated/internal release artifacts.

Public examples should use neutral placeholders such as:

- `user@contoso.com`
- `group@contoso.com`
- `<tenant-domain>`

## 17. PowerShell Compatibility

Default target:

- Windows PowerShell 5.1+
- PowerShell 7+

Use PowerShell 5.1-compatible syntax unless a script explicitly declares a newer requirement.

When importing Windows-only modules from PowerShell 7, compatibility mechanisms may be used where appropriate.

## 18. Catalog Metadata Standard

Every full script card should accurately describe:

- Name.
- Operational area / subarea.
- Platform.
- Access classification.
- Status.
- Source/provenance at a non-sensitive level.
- Required modules/scopes/rights.
- Accepted input.
- Output.
- File name.
- Public source path when published.
- Useful keywords.
- Concise objective.

Do not describe Graph-only behavior as Graph + AD, single-object behavior as bulk, or tenant enumeration as multi-user input.

Catalog metadata is part of the product and must be reviewed against executable behavior.

## 19. Catalog Status Model

### Ready

Defensible job, reviewed behavior, appropriate metadata, and no known blocker for its intended use.

### Candidate

Future coverage idea or incomplete implementation. Not a promise that a working public source exists.

### Private

Useful internal tool that should not be exposed publicly in its current form.

### External Reference

Useful pointer or external material, not a FIELD // KIT-maintained script.

`AUDIT-LIMBO.md` tracks overlap and lineage decisions. It should not become a second catalog.

## 20. Duplicate and Lineage Review

Similarity alone is not enough to remove a script.

When reviewing overlap:

1. Compare executable behavior, not just filenames/comments.
2. Identify unique edge cases.
3. Preserve useful logic in the strongest survivor.
4. Prefer one broader input model when it does not make the normal job harder.
5. Keep a separate tool only for a distinct job.
6. Record archived/replaced lineage in `AUDIT-LIMBO.md`.

Signed copies, renamed copies, and copies differing only in branding are one lineage unless executable behavior differs.

## 21. Validation Standard

A script is not considered fully runtime-validated merely because it passes static review.

### Static QA

Before publishing:

- Balanced braces, parentheses, and brackets.
- No obvious truncated blocks.
- No unexpected client/internal strings.
- No hard-coded secrets or real UPNs/domains.
- No Authenticode block in public canonical source.
- No unintended `Set-ExecutionPolicy`.
- No global `SilentlyContinue` in reviewed public tools.
- Catalog path exists.
- Catalog names/orders/published paths remain unique.
- JavaScript parses after UI/catalog changes.

### Runtime QA

When Windows/tenant access is available:

- Run read-only tools first.
- Test a known-good object.
- Test a not-found object.
- Test one-object input.
- Test TXT/CSV input for 1-to-N tools.
- Validate tenant/account context.
- Verify exports.
- For change tools, validate preview/cancel paths before any real change.
- Use non-production/test objects for destructive-path validation whenever possible.

Static QA must never be described as successful production execution.

## 22. Repository and Release Workflow

Primary repository:

```text
pwsh-operations-catalog
```

Working/development branch:

```text
v1-repo-ui
```

Public GitHub Pages branch:

```text
main
```

The public site is deployed from `main` at the repository root.

Preferred local workflow:

```powershell
git check
git check details
git grab it
git send it
```

Semantics:

- `git check` — current repository summary.
- `git check details` — exact changed-file detail.
- `git grab it` — upstream to local; refuses a dirty tree.
- `git send it` — reviewed local changes to upstream.

Always verify which repository the terminal is currently inside before using the custom commands.

### Publication flow

1. Work and review on `v1-repo-ui`.
2. Static QA.
3. Runtime QA when available and applicable.
4. Make the reviewed branch state available locally/remote.
5. Fast-forward `main` only when the build is intended to become public.
6. Verify GitHub Pages is actually sourcing `main`.
7. Check desktop and phone layouts after deployment.

Do not use a force update on `main` for ordinary publication.

## 23. Site Structure and Rebuild

Current public site is intentionally static and dependency-light.

Primary files:

```text
index.html          page structure + current responsive styling
catalog-data.js     catalog records
field-kit-app.js    search, navigation, drawers, rendering, curated behavior
published-source/   public canonical PowerShell source
tools/              build/review/reference material
AUDIT-LIMBO.md      overlap and historical lineage decisions
OPERATING-STANDARDS.md  project operating contract
```

Local QA can be served from the repository root. The established local URL is:

```text
http://127.0.0.1:9443
```

The public GitHub Pages URL is:

```text
https://grimmieeee.github.io/pwsh-operations-catalog/
```

The site must remain usable on desktop and mobile. Mobile behavior includes a slide-out navigation drawer, full-width detail view, touch-sized controls, safe-area handling, and narrow-screen wrapping for long filenames/code.

## 24. Handoff Checklist

A new maintainer should be able to recover the project with the repository alone.

Use `tools/PROJECT-HANDOFF.md` as the canonical handoff template. The handoff records current state and pending work; it does not redefine project standards.

At handoff, verify:

- Repository, branch, and last known-good commit are recorded.
- Working-tree / upstream state is recorded, including any stash or local-only files.
- Static QA and runtime QA are reported separately.
- The exact first step for the next session is recorded.
- `main` represents the intended public site.
- `v1-repo-ui` contains current development work.
- Working trees are clean or documented.
- `OPERATING-STANDARDS.md` reflects current decisions.
- `AUDIT-LIMBO.md` reflects unresolved/replaced lineage.
- Public `published-source` files match catalog metadata.
- Private-only scripts are not accidentally published.
- Signing/private deployment material remains outside the public source tree.
- Known runtime limitations are documented rather than hidden.

## 25. Decision Rule When Unsure

When a new script or variant appears, ask in this order:

1. What operational question does it answer?
2. Is that question already answered by an existing canonical tool?
3. Does it add a real edge case or only a different input shape?
4. Can the stronger tool support 1-to-N input instead?
5. Is it read-only, change-making, or destructive?
6. What system is authoritative for the action?
7. Can every claimed result be validated?
8. Is the public version safe to publish?
9. Is runtime validation still outstanding?

If those questions are clear, the catalog decision usually becomes obvious.