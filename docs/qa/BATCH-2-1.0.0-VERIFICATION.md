# Batch 2 — owner-accepted VERIFIED releases

The owner accepted the eleven completed workflows in runner 0.5.0. Each completed with zero failed reads; Graph and Exchange preflight were ready. The returned metadata was matched to the supplied embedded package and its source hashes. Raw client findings are not published.

The tested sources were unversioned. Published 1.0.0 releases add a leading version comment only; their executable bodies are unchanged from the accepted bundle. Both tested and release hashes are recorded below and in the JSON companion. The two audit list-conversion fixes were already inside the tested bundle.

| Script | Tested source SHA-256 | Release SHA-256 |
|---|---|---|
| GET-DISTRIBUTION-GROUP-MEMBERS.ps1 | e4046dacdf671ce73b213bc570b74cc238b9ea60d1bf5ba5a3c5f50dc65f07a9 | 9e7862eefbdb1c7c89177f076d2c8030b26b65869623d6414f9ebf005d16f0ea |
| GET-GROUP-MEMBERS.ps1 | ba29a8c30f170c87b08a453fdfe73f6108bddfc69033f17a6270875ecc684dbd | 744ac9b55488b0b96f22f0ce886aee25698eb39cb15a82cbb1fb291d063d3478 |
| IR-GET-DATA-EXFIL-ACTIVITY.ps1 | 76338d697f76d557d8f6e9ff4399e9c2569de8f78d565e79579e00026c72c28f | 73a83bd02db13481dbd1feb9d9088bfedf6a5f925c09fa71c241eaa83f9746a0 |
| IR-GET-IP-TRACE.ps1 | cbb713d514fa4bef79374e051e68cd384e73caff62775e8194fa624b3197386c | 6f1bacdb932aa3e2e5077b3c810a0cfb9969e4c24b07e285e1ecdf53d3fffd2d |
| IR-GET-TENANT-EMAIL-SEARCH.ps1 | dbb53c592a523fdf2a2c94dd166296afe6a9f482ec4372c2d3f551af56ea797e | e4b41e56c30b37ea2ec5de44d5e2851fd5fd1c656122d03d9b2a21b4c89de83c |
| IR-GET-TIMELINE-BUILDER.ps1 | fb6e000a57b548f59fbc4f9317df3dac0ab61756c97223784d7b2e54a6d70c40 | 483a49fbc5439e1f6282a5fefd44bc6b085376092a27659991f056385b9d4469 |
| IR-GET-TOKEN-DECODE.ps1 | 179e01c20af4ad72faabd69c2567ccff9fa1d40a5ca3acf497544ba6d4849372 | 89be0780dd4434bbd1dfebf54bfe06df1f0bb3db23f1df111b1a3143f57918bf |
| TEST-POWERSHELL-READINESS.ps1 | b38f3eb165ac360eef390990dd6d2b4ee89f41916d3da54822f625b7d2c77612 | a8a52521cfa5a63477558769b97805e64e24fb03452c349ece4c8b9facbf7449 |
| GET-FOLDER-INVENTORY.ps1 | fce9d9db96b42fe9b352b867afdd1a370c400f4d6f67c1a58dd7d50aefde9ec6 | fc544a0aeef46727b8ba3ede8640114ea94707dd84a410a3c50cc36e0d273387 |
| TEST-SENSITIVE-DATA.ps1 | 2c28a71fe9195f3e032c0386ed10c3ee5d7fcdd2385839b8b74ee95dc8ba20d0 | 9543c614e26b54a6bb8776e5e6ccc23a04c644710f609cd192030cfd35b1f606 |
| INVOKE-FILE-INVENTORY.ps1 | c50633fd4f92e32f2401bf25c056d88dab2afee2296de1abf3976a32ef2e73d4 | acb04fd3968ef3a29356ef52583229a72926f7a6ed319b4b36bd01e56de28445 |

## Scope and exception

Cloud tests used up to ten processed records and forty service reads per workflow. Local tools used synthetic files, a synthetic JWT, or read-only host prerequisite checks. Group lookup covers the cloud path, not local AD fallback. Authentication was reused through batch adapters; standalone sign-in, legacy exports, pagination and unexercised paths are not established. VERIFIED is owner acceptance of this release and scope, not a security certification or clean-client verdict.

GET-ROOM-RESOURCE-ACCESS remains unverified. Its supplied target was a protected security group rather than an active resource mailbox, as confirmed by the owner. Record this as an expected target mismatch; the successful resource-mailbox path still needs a valid target. Batch 2 is otherwise closed; do not repeat its eleven accepted workflows to resolve that one gap.

Runner package SHA-256: 9c608095c3743b804728bb9de82be68a3dee7045df332a4a4dba256543194dd8

Returned metadata SHA-256: 006e973aaab9edf3c473a84434a3cfd188036fa7b1d173c76d4a9e579187022e
