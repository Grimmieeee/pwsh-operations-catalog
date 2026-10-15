# Security

This repository is public and is deployed as a static GitHub Pages site.

## Publishing rules

Treat every committed file as public, including files that are not linked from the UI.

Do not commit:

- passwords, tokens, API keys, or client secrets
- private keys, PFX files, or certificate passwords
- tenant-specific credentials
- client names, domains, ticket data, or private incident evidence
- private internal paths or configuration values that are not intentionally public

Placeholder examples are fine when they are clearly synthetic.

## Architecture

The site is intentionally simple:

- static HTML
- local CSS
- local JavaScript
- no backend
- no database
- no login
- no third-party JavaScript dependencies

The page uses a restrictive Content Security Policy and only permits same-origin or HTTPS reference links.

## If a secret is exposed

Deleting the file is not enough because Git history may still contain it.

1. Revoke or rotate the exposed credential first.
2. Remove it from the current repository content.
3. Rewrite Git history when necessary.
4. Verify the GitHub Pages deployment no longer serves the exposed value.
5. Review related logs and access if the credential could have been used.

## Before publishing

Review `git diff`, run `git diff --check`, and confirm that the catalog contains only information intended for public distribution.

## Download integrity

Every catalog download has a SHA-256 entry in `source-integrity.js`. The browser allows only approved catalog-relative source paths, refuses redirects and HTML/error bodies, bounds request time and size, and verifies the original bytes before displaying, copying, or saving a script. UTF-8 byte-order marks and line endings are preserved on download; clipboard text omits a leading byte-order mark.

These checks detect changed/corrupted files, bad responses, and mismatched releases. They do not establish authorship, prove a script is safe, or protect against an attacker who can replace the repository, page, and checksums together. Repository access protection and source review remain essential.

After an approved source edit, regenerate the manifest and run the checks:

```text
node tools/check-site.mjs --write-integrity
node tools/check-site.mjs
node --test tests/site-security.test.mjs
```

The release checker covers effective catalog entries, local source paths and extensions, strict UTF-8 round trips, missing/stale checksums, high-confidence credential patterns, private credential file types, and uncatalogued PowerShell files in the download trees. It is a guardrail, not a comprehensive secret or vulnerability scanner. The two uncatalogued build/handoff wrappers are explicitly allowlisted.

The GitHub workflow runs these checks with a read-only token, pinned checkout action, and no persisted Git credentials. Configure `Catalog integrity and safety` as a required status check after its first successful run if it should block merges.

## Hosting limits and launch checks

The HTML CSP blocks unapproved script origins, inline script attributes, embedded content, forms, and cross-origin data fetches. The page has a no-referrer policy. Google Fonts remains the only intentional external page dependency; JavaScript stays local.

`frame-ancestors` and `X-Frame-Options` require HTTP response headers; adding them to HTML meta tags would not protect the site. Anti-framing and other custom response headers must be verified on the actual host or an approved fronting service. `frame-src 'none'` controls embedded children, not whether another site can frame this catalog.

Before announcing a release, verify Pages is enabled for the intended branch/root, HTTPS is enforced, the public URL returns the catalog rather than a 404 page, and live search/download/copy work on desktop and phone. Do not infer current hosting availability from an old successful deployment run.
