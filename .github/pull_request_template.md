## Change

Describe the resulting behavior and why it is needed.

## Release evidence

- [ ] Reviewed the full diff, public source, credential/privacy risks, and any workflow permissions or action updates.
- [ ] Regenerated `source-integrity.js` after approved downloadable-source edits; checked the manifest diff.
- [ ] `node tools/check-site.mjs` and `node --test tests/site-security.test.mjs` pass.
- [ ] Required `Catalog integrity and safety` check passes against current `main`.
- [ ] CodeQL scans completed and findings reviewed, or the exact blocker is recorded below.
- [ ] Review conversations resolved.

Windows/tenant testing performed, or pending validation and operational limits:

## After merge

- [ ] Pages deployment matches the merged commit; public URL and HTTPS work.
- [ ] Desktop and phone: search, View Code, Copy, and Download checked.

Do not mark pending tests as passed. Use `docs/qa/SECURITY-RELEASE-CHECKLIST.md` for the security gate and protection drill.

- [ ] Related Items reviewed for task relevance, destination accuracy, scope and unsupported handoffs.
- [ ] Required operator information verified in rendered cards, not only metadata.
