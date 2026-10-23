# Live publishing

The reviewed catalog release is eeb827156d6b18a57d99036820fabba0b66dcfd9. Its protected PR checks passed, but the branch-based Pages publisher did not start a new run.

Restarting its build checked out that exact current main commit successfully. Deployment then rejected the two artifacts named github-pages in the reused run. The site continued to serve the preceding release; no successful publication was claimed.

The dedicated Publish live site workflow builds the reviewed merge commit, checks catalog integrity and site behavior, and deploys one specifically named package. It runs on main pushes or manual dispatch from main. PR events and other branches cannot deploy. The existing environment policy rejects PR-context deployments, even when the PR is merged; that protection remains in place. Package names include the run and attempt; the deploy job consumes the exact build output, avoiding collisions during retries. Build permissions are read-only; only deployment receives Pages and identity-token permissions.

After a release, verify the actual build commit and deployment result, then compare all 92 downloadable sources and eight site assets with the reviewed repository bytes. A merged PR alone does not establish live publication. The 48 site tests do not replace browser or native Windows testing.
