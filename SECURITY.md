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
