# IR 1.0.0 live follow-up

The previous environment-disconnect limitation on PR #18 has been resolved
for desktop interaction and direct HTTPS checks. See the PR conversation for
the completion record. Main remains the reviewed release commit
41183a5ebe44c2716055ac678efad3e4a4ea210a.

- HTTPS retrieval of catalog-data.js, field-kit-app.js, source-integrity.js and
  all three IR sources matched the reviewed repository bytes. Each source hash
  matches IR-1.0.0-VERIFICATION.md.
- Live search found the exact ir-risk-assessment filename and VERIFIED version.
- All three workflow cards showed VERIFIED · v1.0.0. Containment retained its
  DESTRUCTIVE label. The card explanation was visible in the detail view.
- View Code displayed the actual .VERSION 1.0.0 source.
- COPY SCRIPT displayed COPIED. Clipboard text matched the displayed source
  after normalization of the leading BOM removed by the browser clipboard.
- DOWNLOAD .PS1 emitted an actual browser download and showed Download verified.

These are live desktop observations, separate from the ten pre-merge fixture
tests and the owner's jumpbox tests. Phone viewport checks remain unperformed.
No screenshots, downloaded browser files, private evidence or clipboard secrets
are included in this record. No script source or site behavior changed here.
