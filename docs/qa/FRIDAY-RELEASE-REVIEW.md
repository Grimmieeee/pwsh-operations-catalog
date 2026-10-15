# Friday release review — 2026-10-14

Reviewed the main-branch static catalog and prepared focused fixes on `work/friday-site-hardening`. The separately tested IR workflow is not part of this change.

## Findings addressed

- A slow View Code request could attach an earlier script's copy handler after the user changed cards. Detached/stale requests now stop before changing the active source controls.
- Clipboard fallback ignored the browser's false return value and could report COPIED when nothing was copied. All copy paths now handle failure and provide manual-copy guidance.
- Source loading trusted any successful HTTP response. Downloads now require an approved catalog path and SHA-256 match, refuse redirects and HTML responses, and have bounded size/time.
- Text decoding could strip an existing UTF-8 byte-order mark. Verified downloads now preserve the reviewed bytes, BOM, Unicode, and line endings. Copying to a terminal omits only the leading BOM.
- The offscreen drawer remained keyboard-focusable, and the visible modal did not isolate background content or contain Tab focus. Initial inert state, modal background isolation, a focus loop, and return focus now match the dialog's existing semantics.
- Search has an explicit accessible label, item counts announce updates, and a no-JavaScript source-repository link is available.
- A dependency-free release checker and read-only GitHub workflow now validate catalog paths/files/checksums, policy/markup, high-confidence credential patterns, private credential file types, and unlisted PowerShell artifacts in the download trees.

## Evidence

- JavaScript syntax checks passed.
- 338 effective catalog items, 89 source downloads; every linked file exists and round-trips as exact UTF-8 bytes.
- Eight automated tests passed: source/reference URL boundaries; exact-byte source preservation and caching; bad/changed/oversized/redirect/empty responses; timeout/retry; stale-card race; clipboard failure; drawer focus/isolation; global search scope.
- No matches for the checked high-confidence credential patterns or the client/incident identifiers checked in current source. This is not proof that every possible secret or unsafe script has been found.
- The public URL returned HTTP 404 in an independent HTTP request and the review browser. Current repository metadata reported `has_pages: false` and public visibility. An earlier successful Pages build does not establish current availability.
- The active default-branch ruleset requires a pull request and blocks deletion/force updates. Required approval count is zero; no required status check was listed in that ruleset at review time.

## Before sharing on Friday, October 16

1. Merge/release the reviewed site fixes through the protected branch workflow.
2. Restore the intended Pages publication from main/root and verify HTTPS and the actual public URL. Hosting was left unchanged during this review.
3. Check live search, View Code, Copy, and Download on desktop and phone after deployment. Live UI regression coverage is incomplete while Pages is offline; DOM fixtures are not a substitute for a real browser.
4. Confirm candidate IR scripts are not made available as validated production tools before their controlled Windows/tenant tests are complete. A public repository exposes files even if the site has no download card.
5. After the new GitHub check runs successfully, decide whether `Catalog integrity and safety` should become a required merge check.
6. Choose and add intended reuse/license terms. No LICENSE file was present; this review did not select terms on the owner's behalf.

## Hosting and integrity limits

The existing site is static, with no application login/backend/database and no external JavaScript. Google Fonts remains an intentional external CSS/font dependency. The CSP and no-referrer policy remain enabled.

SHA-256 checks detect corruption and mismatched releases. They do not prove authorship or protect against someone who can replace source, manifest, and page together.

Anti-framing (`frame-ancestors` / X-Frame-Options) must be delivered as HTTP headers. The existing meta CSP cannot provide those controls. Custom response-header support must be checked on the chosen host; adding ineffective meta tags would not fix it.
