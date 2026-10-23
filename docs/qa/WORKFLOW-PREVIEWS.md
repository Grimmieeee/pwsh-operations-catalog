# Workflow preview cards

81 script cards have authored, scrollable static examples. Quick Commands and documentation/reference cards are excluded. Values are illustrative; examples are shortened representations rather than captured or byte-exact console sessions. Terminal animations have static illustrations. No script is executed to produce these examples.

Card order: purpose / scope / impact and operational notices, example output, run directions, source actions, collapsed DETAILS. Requirements, permissions, historical acceptance evidence, workflow navigation and related tools remain available in DETAILS. Sensitive-action notices remain before the preview. Existing checksum-verified source download, code view and workflow-package controls remain intact.

Authored data: workflow-preview-specs.json. Shipped data: workflow-previews.js. Regenerate with node tools/build-workflow-previews.mjs after reviewing examples against the current source. The build command preserves authored source hashes; it does not silently renew a stale review. The release gate requires all 81 scripts, matching current source hashes, source evidence and agreement between authored and shipped data. Runtime acceptance is unchanged.

Validation: 96 Node tests; site/card contracts, taxonomy, permissions, impact and safety checks. All 232 Quick Command card HTML strings were compared with the prior release and are unchanged. Tests cover preview coverage, stale-source rejection, escaped sample text, keyboard focus/scroll markup, collapsed supporting content and exclusions. Browser screenshot QA was unavailable in the local environment; these checks do not claim visual browser acceptance.
