# IR 1.0.0 release gate

Ruleset 24396050 was read before publication: active default-branch scope,
empty bypass list, deletion/force-push blocks, required PR and conversation
resolution, strict GitHub Actions Catalog integrity and safety check, and
CodeQL high-or-higher/error enforcement.

The pre-release protection drill used PR #17 (DO NOT MERGE), head
8a2e3cfb6332c898335f0fa0f5b00e7e03b68976, based on main
3f76c26f2737b3d184578f9df3dc557cae34024e. Only a harmless comment was added to
OPERATING-STANDARDS.md without updating the checksum. No workflow or
operational source changed. Required check 117304248111 / run 39001182412
failed in the checksum stage. GitHub reported mergeable true but merge state
blocked. The PR was closed without merging; no merge attempt was made.

The real release PR records passing CI, CodeQL, review-thread disposition,
merge commit, Pages deployment and live checks. Operator testing is recorded
separately in IR-1.0.0-VERIFICATION.md. Public source bytes match the exact
owner-confirmed ZIP. One existing trailing space in recovery source is
preserved to keep those verified bytes unchanged; other whitespace checks pass.

The inventory is a review queue, not a claim of runtime coverage for other
scripts. No account authentication settings, ruleset, workflow permission,
secrets or signing keys were changed by this release.
