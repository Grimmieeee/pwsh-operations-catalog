# Native local closeout — nine accepted passes

Seven visuals and both certificate/signing tools passed operator review. Screensavers were intentionally closed by the operator; their control-C/close exit codes do not override the recorded Passed verdict. Theme profile paths were redirected to temporary files; permanent profile persistence is not established. Signing used a dummy folder and native wizard confirmations. The report does not identify every individual wizard operation; acceptance covers the operator-selected steps, not every export/import/trust path. Child PowerShell version was not recorded.

The two signing candidates normalize single-certificate results to arrays. Their tested implementation bytes are published unchanged, with a leading version comment. Other sources also add only that version comment. Git Security was skipped and Room/Resource Access was marked failed; both remain available without VERIFIED. The client-specific resource test is deferred without a repeat personal-PC run.

| Tool | Tested hash | Published 1.0.0 hash | Scope |
|---|---|---|---|
| SET-THEME-BASIC.ps1 | a3959c764ee2c0b4e155f89b5cf28faed7db74f54f2b277e2152b453c392827f | 82ddf2ed63914b6a1eb40664f486783e59690799b8df19bf9f00fbd3dc142756 | Native separate-window preview; theme profile redirected; operator-reviewed appearance. |
| SET-THEME-COBALT.ps1 | 01b14b7f32a176f6f107ea73c1421a40d967dd634957f2fb849e94bedab92347 | 3d0dbac577cce716e5427a9b2635ee6cefe29a45955bc632cb8b4f2dd48fe343 | Native separate-window preview; theme profile redirected; operator-reviewed appearance. |
| SET-THEME-SEAGLASS.ps1 | 4b67f87297ce80e2f4f34d4bade7f784005ee4788686046968022e075df167c0 | 16153f1c1989834f659ec7c08546c454dd95bdc51abebb2f7afb684b70964fdf | Native separate-window preview; theme profile redirected; operator-reviewed appearance. |
| SET-THEME-SILICON-VALLEY.ps1 | f8de1e1fc05f78dbabfdaf6d156ebbdd13049cc2ff7067e177e3c80bb63050aa | 1c732aa6c82182265dc02019c9805a7ac9faec56e7b3312e8d7b00c7d66dd60d | Native separate-window preview; theme profile redirected; operator-reviewed appearance. |
| rain.ps1 | 46d67ed7200597e89de91d76dbbceedb63f202852972070f18db6ea13f56a53c | 67ff5ccad0eb69510576920fd8b36accfb606a2b1cd3ddeb1ae75f021fda9bc9 | Native separate-window preview; theme profile redirected; operator-reviewed appearance. |
| static.ps1 | 4e4db77166ad4f60ceb3e50b5aa3685719d9d84805ec93dbd729005074d86e1f | 75f06611710a84f21522226fffebb3bf2e6a6b5d58383baf507ba6c69ddf19ca | Native separate-window preview; theme profile redirected; operator-reviewed appearance. |
| attractor.ps1 | 2adc04c32a4d20820577933c463d07642c8be18f9de17c739a617ffcc55c68a5 | 62820d67085b65d230bb28c4954259bd32bffd29f30aee8a6f9a2cdfcdfdc5aa | Native separate-window preview; theme profile redirected; operator-reviewed appearance. |
| MANAGE-CERT-SIGNATURES.ps1 | 2f9c03cef0b13b273118f14635ca41f6065de0e2d29b602f2f0d846136e13ea3 | 11544fc1bdedfe8e1e7ff69c1abb084cd5001132c40178782bd21281150c2cb8 | Operator-selected certificate/signing wizard steps; dummy signing folder; native approvals preserved. |
| SIGN-FOLDER-SCRIPTS.ps1 | 320b592637badea8d8295797b05fa1b39373d087c51a06396d78cd397ee480bd | 9b2d82c75017899485b76d227e323deca66c6660534e83c1238938f058d454a1 | Operator-selected certificate/signing wizard steps; dummy signing folder; native approvals preserved. |

The adjacent JSON preserves metadata and report/package hashes. No private client configuration or raw findings are included. Total: 78 of 80 standalone scripts have owner-accepted evidence. Quick-command runtime verification is separate.
