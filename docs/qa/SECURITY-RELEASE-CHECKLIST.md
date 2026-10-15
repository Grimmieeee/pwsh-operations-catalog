# Security and release checklist

## Every change

1. Branch from current `main`; inspect `git status`, the complete diff, and `git diff --check`.
2. Review source behavior, authority, confirmation/cancel paths, privacy, and workflow changes. Never store signing keys or credentials in the repository.
3. After approved downloadable-source edits, run `node tools/check-site.mjs --write-integrity` and review the resulting checksum diff.
4. Run `node tools/check-site.mjs`, `node --test tests/site-security.test.mjs`, and JavaScript syntax checks. These are static/fixture checks, not tenant execution.
5. Open a pull request. Require the GitHub Actions `Catalog integrity and safety` check on a branch current with `main`. Resolve review conversations.
6. Confirm CodeQL completes for JavaScript/TypeScript and Actions and review new findings in Security > Code scanning. Fix or explicitly document the disposition; never call skipped/failed analysis clean. CodeQL does not cover PowerShell.
7. Record Windows/tenant tests separately, with pending validation stated. No runtime-validation claim based solely on CI.
8. Merge only the reviewed commit through the protected PR. Do not disable protections to make a release pass.

## After merge

1. Confirm Pages deployed the merged commit successfully, not merely a previous commit.
2. Verify the public URL returns the catalog over HTTPS.
3. On desktop and phone, exercise search, View Code, Copy, and Download. Compare a representative download with canonical bytes.
4. Record failures and the last known-good commit. Roll back through a reviewed PR; do not force-push `main`.

## Protection drill

Run after ruleset, workflow/check-name, permission, or publishing-source changes, and before major public releases.

1. Read the saved ruleset: active; default branch targeted; empty bypass list; deletion and force pushes blocked; PR and conversation resolution required; strict required check `Catalog integrity and safety` sourced from GitHub Actions.
2. Create a temporary branch from `main`. Append a harmless comment to `OPERATING-STANDARDS.md` without updating its download checksum. Change no operational script or workflow.
3. Open a non-draft PR clearly labeled DO NOT MERGE. Verify the actual required check fails for the stale checksum and the PR merge state is blocked. A draft-only block or pending check does not prove failure enforcement.
4. Do not attempt to merge. Capture the PR, head SHA, check run/conclusion, failure reason, and merge-block state.
5. Close the PR without merging. Keep the closed PR as evidence. Recheck `main` and live deployment are unchanged. Delete the temporary branch when supported.
6. Verify a subsequent legitimate PR can pass checks. Distinguish failure enforcement from a permanently blocked workflow.

## Repository and account baseline

- Workflow token defaults read-only; Actions cannot create or approve PRs. Individual analysis jobs request only necessary permissions.
- External-contributor workflows require approval. Review their diff before approving a run.
- Actions pinned to full commit SHAs; checkout does not persist credentials. Dependabot proposes reviewed updates.
- Secret scanning and push protection enabled. Review alerts; a clean scan is not proof that every private value was detected.
- MFA enabled; periodically review sessions, personal tokens, SSH/deploy keys, connected apps, collaborators, and bypass actors. Owner retains the chosen MFA method.
- Pages publishes `main` at repository root with HTTPS enforced. Do not require the production Pages deployment as a pre-merge check; it happens after merge.
- After CodeQL baseline success and findings review, configure a ruleset requiring CodeQL results at the agreed severity threshold. A successful upload alone does not enforce a findings gate.

## Evidence record

Record date, PR/commit, check results, scanning findings/disposition, ruleset verification, Pages deployment, live smoke tests, runtime tests, and remaining gaps. See `PROTECTION-VERIFICATION-2026-10-15.md` for the initial drill.
