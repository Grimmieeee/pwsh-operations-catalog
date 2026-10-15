# Protection verification: October 15, 2026

## Saved ruleset

Repository: `Grimmieeee/pwsh-operations-catalog`; ruleset `24396050`.

API inspection confirmed active default-branch protection, no bypass actors (`current_user_can_bypass: never`), deletion/force-push blocks, required pull requests, required conversation resolution, and strict `Catalog integrity and safety` checks from GitHub Actions (integration 15368). Required human approvals remain zero for the solo-maintainer workflow.

## Controlled failure

- Test PR: https://github.com/Grimmieeee/pwsh-operations-catalog/pull/12
- Head: `1b6524d4a44baac3e2799c35c73800d0f346c9cc`.
- Changed only a harmless documentation comment; deliberately left its source checksum stale.
- Actual required check: `Catalog integrity and safety`, completed with `failure`.
- Evidence: https://github.com/Grimmieeee/pwsh-operations-catalog/actions/runs/38807079874/job/116670581320
- Non-draft PR had no merge conflict (`mergeable: true`) but GitHub reported `mergeable_state: blocked`.
- Closed without merging or attempting a merge. Temporary branch retained as evidence; not a publishing source.
- `main` remained `5a9be0f8f40785db0723ba900f7936136649ab73` throughout the drill.

This verifies the required-check merge gate, not malware detection or tenant behavior.

## Scanning and remaining verification

No CodeQL runs were present in the retrieved Actions history before this change. The connector did not permit the default-setup configuration endpoint, so default setup could not be inspected directly. This change adds an explicit advanced CodeQL workflow for JavaScript/TypeScript and Actions; verify successful scans and findings on the PR before recording scanning as operational. If default setup blocks the advanced upload, resolve that configuration explicitly rather than reporting a clean scan.

The user screenshots showed read-only default workflow permissions, no Actions PR creation/approval, external-contributor run approval, no deploy keys or stored Actions secrets, and enabled secret scanning/push protection. These were screenshot observations rather than API assertions about every account permission.

CodeQL findings enforcement, live desktop/phone smoke tests, and Windows/tenant execution are separate evidence items. Record completion on the release PR. Do not infer them from the failing-check drill.
