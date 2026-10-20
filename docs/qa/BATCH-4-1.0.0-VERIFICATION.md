# Batch 4 — owner-accepted scoped verification

The owner accepted the 15 passing tools from the Windows PowerShell 5.1 report. These marks cover only the listed offline tests. Authentication, permissions, live tenant/device changes and unlisted branches are not established by this evidence. Git Security failed after 7/13 cases and is deferred; it receives no mark.

Published 1.0.0 sources add a leading version comment only. The implementation bytes match the tested source after removing that comment. Both hashes are recorded separately. No client identifiers or raw findings are published.

| Tool | Tested SHA-256 | Release SHA-256 | Accepted scope |
|---|---|---|---|
| INVOKE-DISABLE-ACCOUNTS.ps1 | 591c0dad82f02548b19d7a664ea5b2c70db85e0a6afac4f7e49b562c2dd244a4 | e973c60df895a359aa983525e8aa47650036e0db369168bffd7803d2b8a4f572 | Simulated cloud disable workflow: preview, approval, mutation and readback; auth and AD are fixtures. |
| INVOKE-ENFORCE-PER-USER-MFA.ps1 | 52c6ce8dc1af2323b9dcc6c831cdd211b555ae44280417181599290212fcf7bd | 3270e9e8879fa3b0c7da913adc88d96edb484f92ad4a2fd6e06970f303d0874e | Simulated per-user MFA workflow: approval, mutation and readback; auth is a fixture. |
| INVOKE-LITIGATION-HOLD.ps1 | c0d3bb2f0bf4857f45d6f6d52afb80b8171f4fc700d2e2999ec716b21df2cccf | e084346e37bb4575a5be123fd99cd5ed6c30b463beea38827296ba5e6b6fe72b | Simulated hold enforcement workflow: approval, mutation and readback; Exchange/auth are fixtures. |
| INVOKE-DELETE-ACCOUNTS.ps1 | 0fbb42bb1db268b3f6e4b74a21af7008528b5acc2e684cccdf3696122fcb6bd2 | 5cff2cc13a1db4e40fb260f63eddcfe87871ae152400103ce19ef0f691988d66 | Exact Graph lookup and post-delete absence verification functions only; no account deletion. |
| INVOKE-REMOVE-USER-GROUPS.ps1 | a813ab576da5f82eb11ae0d1ee6e26134b03997e73692c9e5d6181ed20d09b55 | 18e441456d7201daf0985ad776e012a86248f40fc8de8026536c27ea1b60cf31 | Membership DELETE route and eventual removal readback functions only; no actual group changes. |
| CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1 | 8a48dd3160a4bd5228ac4490e081b3e49b7ff1a163d09878f1d9881766ae9bcb | e9b65c7fc9da2a09b87f84618b0d2693681cc8f497eef0343de990dee202c7c1 | Principal matching and SendOnBehalf target isolation only; disabled-state/auth and removal are not exercised. |
| IR-INVOKE-EMAIL-RECOVERY.ps1 | e00946f377bdd4b0e9eb87d04025906763bb8c7307ecdaf87f5016f006ea6aaf | b75852825c289f1db32ffd2532f308546fe31f547be0298b56b2de78330b8894 | Encoded message-move request and root-folder creation functions only; no mailbox access or message changes. |
| GET-TENANT-DRIFT-REVIEW.ps1 | 668267cbadfc88d212a8708c77f0a5454343a0e4222e2e1cfaff2a44e84afb54 | f473f3fffdf501b2b04604db04268f75670be319734b8c32da66bd1df45183ed | Synthetic added/removed/changed comparisons and real temporary JSON write/read; no tenant queries. |
| INSTALL-M365-MODULES.ps1 | a143a317bb85b76c39a5768b7b5cad4096d4acce4d5509465c01be820b37ff24 | a652531a49e22d4f8c243676075b07cf9f22c90953cf615c8fd8e1d900665181 | Simulated module installation workflow with cancellation, scope and failure checks; nothing is installed. |
| RESET-M365-SESSION.ps1 | 203ba913f1d8d1d72544ecf950c0b346e4e92244a9e6b75730095339c858a16a | a4c2a5f0c5b7decfccccc50fb3b3ec1a213d562edf00a28ff04233e22502d680 | Simulated reset workflow; checks unrelated sessions are preserved; no real disconnections. |
| INVOKE-SESSION-RESET.ps1 | 0f183c52bd1ca24dcccba318913eac70eb89848cbe32ef42fe631c6270744446 | 4de135e684e778e091292f7fe56610ddee47739c15d34dda5367cbe3112a15bc | Simulated jumpbox reset workflow; no password variable removal, disconnections or new windows. |
| set-execution.ps1 | fe6e46d409518b856bf52ee985d4298e41376676d2e984af8092c0ef316bf09f | 90464f2b844266bdf88c5956fc44dd34939cf7c8664ac19c90f4be4defec2bc4 | Simulated execution-policy/unblock workflow; managed policy preserved; no real policy/unblock changes. |
| IR-GET-THREAT-INTEL-ACTIVITY.ps1 | a9126fcc537a71b9471d49ecfe5f714ede93bc5e1306b3eee9fe9ea7f014859a | ea3d359ed80ce3b867b3ee1b84fba7234ccab29ba0e2c9d3cbd4e99001761f42 | IP input guards only; provider API calls, credentials and reputation findings are not tested. |
| INVOKE-MAP-KIT.ps1 | 22046718b32efd8f0d8d5e27bbccb78836ee52262159aa215796e6df5ff7e418 | 330fb1fc8cc144b3f9cd23a0e3399a2f69d168b31b6a9fe27c255e0c77ffdf2b | Actual map workflow against a tiny disposable folder, including missing path; signatures skipped. |
| GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1 | c795ac5d107db35eed303dff231cedbee577824c6fe8b93285ad5895a97cd44b | cb834050cc7551dfa261f19ff53eb363e917de63d368884ef6f1964a20c84f47 | Storage collector with synthetic CIM/file records; top-file ranking and skip option; no real drive walk. |

The adjacent JSON records the report and package hashes, exact case counts, owner acceptance and the deferred failure. This closeout brings the catalog to 39 VERIFIED tools.
