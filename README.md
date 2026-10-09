# FIELD // KIT

FIELD // KIT is a searchable PowerShell operations catalog built for practical service-desk, Microsoft 365, hybrid identity, mailbox, tenant-audit, endpoint, and incident-response work.

The public site is intentionally static: plain HTML, JavaScript, catalog data, and published PowerShell source.

## Start Here

Read [`OPERATING-STANDARDS.md`](OPERATING-STANDARDS.md) before adding, replacing, consolidating, or publishing scripts. It defines the canonical-source model, 1-to-N input standard, hybrid authority rules, auth/module behavior, public-safety requirements, validation expectations, and release workflow.

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

```text
https://grimmieeee.github.io/pwsh-operations-catalog/
```

GitHub Pages publishes from `main` at the repository root.

## Publishing Safety

Everything committed to this public repository should be treated as public information.

Do not publish passwords, tokens, secrets, private certificates/PFX material, client-specific identifiers, customer data, private incident evidence, or internal credentials.

Public scripts are unsigned canonical source. Internal Authenticode signing belongs to the internal release/deployment process, not the public source tree.