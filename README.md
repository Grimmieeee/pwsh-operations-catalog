# FIELD // KIT

FIELD // KIT is a searchable PowerShell operations catalog built for practical service-desk, Microsoft 365, hybrid identity, mailbox, tenant-audit, endpoint, and incident-response work.

The public site is intentionally static: plain HTML, JavaScript, catalog data, and published PowerShell source.

## Start Here

Read [`OPERATING-STANDARDS.md`](OPERATING-STANDARDS.md) before adding, replacing, consolidating, or publishing scripts. It defines the canonical-source model, 1-to-N input standard, hybrid authority rules, auth/module behavior, public-safety requirements, validation expectations, and release workflow.

For the current continuation state, read [`docs/PROJECT-STATUS.md`](docs/PROJECT-STATUS.md), then [`tools/PROJECT-HANDOFF.md`](tools/PROJECT-HANDOFF.md).

The approved site design is locked in [`DESIGN-LOCK.md`](DESIGN-LOCK.md). Preview and approve visual changes before publishing them.

Overlap and historical lineage decisions are tracked in [`AUDIT-LIMBO.md`](AUDIT-LIMBO.md).

## Repository Structure

```text
index.html               site structure + responsive styling
catalog-data.js          catalog records
field-kit-app.js         search, navigation, drawers, rendering, curated behavior
published-source/        public canonical PowerShell source
tools/                   build/review/reference material
AUDIT-LIMBO.md           overlap and lineage decisions
OPERATING-STANDARDS.md   project operating contract
```

## Run Locally

From the repository root:

```powershell
http-server -p 9443 -c-1
```

Then browse to:

```text
http://127.0.0.1:9443
```

Stop the server with `Ctrl+C`.

## Git Workflow

The local PowerShell profile provides:

```powershell
git check
git check details
git grab it
git send it
git handoff -Open
```

These commands act on the Git repository containing the current working directory. Verify the current path before using them.

Development branch:

```text
v1-repo-ui
```

Public GitHub Pages branch:

```text
main
```

## Public Site

The interactive three-step IR tools are available with an
[execution and safety guide](docs/IR-WORKFLOW.md). The published baseline is
1.0.0. Batch 1 is closed; eight accepted read-only report releases are also
VERIFIED, bringing the total to 11. See the [project status](docs/PROJECT-STATUS.md)
and [release evidence](docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md).

```text
https://grimmieeee.github.io/pwsh-operations-catalog/
```

GitHub Pages publishes from `main` at the repository root.

## Publishing Safety

Everything committed to this public repository should be treated as public information.

Do not publish passwords, tokens, secrets, private certificates/PFX material, client-specific identifiers, customer data, private incident evidence, or internal credentials.

Public scripts are unsigned canonical source. Internal Authenticode signing belongs to the internal release/deployment process, not the public source tree.

## Git Handoff

[`tools/git-handoff.ps1`](tools/git-handoff.ps1) captures readable repository state in a locally excluded `.handoff/HANDOFF-SNAPSHOT.md`. It screens metadata for recognizable sensitive values; review the output before sharing. See [usage, privacy limits, and validation](tools/git-handoff.md). The Tools download uses this canonical file.

## Tools and Toys

Tools now includes standalone Git Repository Tools (check/push/pull), Git Security Review, Handoff Snapshot and Set Execution. See [Git tools quick start](tools/git-tools.md). Toys contains Attractor, Rain and Static terminal screensavers. All downloads use the shared same-origin source viewer and copy/save controls. No private security exports, account baseline notes, signing identities or full terminal profiles are published.

## Terminal tools and themes

Tools includes Digital Signature, Terminal Readiness, File Inventory, Folder Map, and Session Reset. Two identical signing uploads share one canonical download. General-purpose readiness, inventory, and M365 reset helpers remain available with separate names because their behavior differs.

Toys includes Basic and Cobalt previews plus Sea Glass and Silicon Valley profile installers. Silicon Valley also retains a predictable daily password generator: do not use its output as a credential. The cards explain profile and process-policy changes. Public copies are unsigned; uploaded originals are unchanged.

Download and copy are available before opening source. Setup comes first where relevant, then A–Z; incident-response steps keep their required order.
