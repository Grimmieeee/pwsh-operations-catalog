// Generated from recorded acceptance history; not current-release operator verification.
window.FIELD_KIT_VERIFICATION_HISTORY = Object.freeze({
  "GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "path": "published-source/tenant/GET-QUARTERLY-CLEANUP-REVIEW.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "df729d70508b81bf0328f0313d0de406e56f4204c3dc8460ef0ea8bb4eb91606",
    "accepted": {
      "version": "1.0.0",
      "sha256": "dfc7e8526aea4a3bfd36d934dad90378fde0800514fd597aa6ad6e2da6288093",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "GET-STALE-SIGNIN-REVIEW.ps1": {
    "path": "published-source/tenant/GET-STALE-SIGNIN-REVIEW.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "27e94610728226f9c43f44631b4c9921fc6412ddf8d79f2e2617a7725c1a4fa6",
    "accepted": {
      "version": "1.0.0",
      "sha256": "42ebf997eeef17e7970ba4d08c65203c0343f9799d0a28be10800bef16f089fd",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "INVOKE-DISABLE-ACCOUNTS.ps1": {
    "path": "published-source/identity/INVOKE-DISABLE-ACCOUNTS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "a123394ca9a041cb7f49225b334ce6fe02637038c554944d1c222d325fa72287",
    "accepted": {
      "version": "1.0.0",
      "sha256": "e973c60df895a359aa983525e8aa47650036e0db369168bffd7803d2b8a4f572",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Simulated cloud disable workflow: preview, approval, mutation and readback; auth and AD are fixtures.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-DELETE-ACCOUNTS.ps1": {
    "path": "published-source/identity/INVOKE-DELETE-ACCOUNTS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "0831cf439bc477cae85d6b6a4f2e2eb1043d4e61d5d4e65964eaa7de658c0eef",
    "accepted": {
      "version": "1.0.0",
      "sha256": "5cff2cc13a1db4e40fb260f63eddcfe87871ae152400103ce19ef0f691988d66",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Exact Graph lookup and post-delete absence verification functions only; no account deletion.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-ASSIGN-LICENSES.ps1": {
    "path": "published-source/identity/INVOKE-ASSIGN-LICENSES.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "b41987e2a5912652d1e01a953a7dea402c7c49e24d20fade2fddb9f9696478be",
    "accepted": {
      "version": "1.0.2",
      "sha256": "289d921e47af9ba0d05c0ecaef218a25101c704529e9aa31c85e4aa5d1e158b5",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Live assignment/removal; owner-accepted product-name display update",
      "evidence": "docs/qa/LICENSE-1.0.2-VERIFICATION.md"
    }
  },
  "INVOKE-REMOVE-LICENSES.ps1": {
    "path": "published-source/identity/INVOKE-REMOVE-LICENSES.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "0fb9b390bdc16c4e677661003145ac9ab7718c2abedf0f6b44f303971bee2e2c",
    "accepted": {
      "version": "1.0.2",
      "sha256": "eedbc44f46a0078347ebe4b7ac414b197ba47e6449a7ee8162b40ba9aeb13450",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Live assignment/removal; owner-accepted product-name display update",
      "evidence": "docs/qa/LICENSE-1.0.2-VERIFICATION.md"
    }
  },
  "RESOLVE-NAMES-TO-UPNS.ps1": {
    "path": "published-source/identity/RESOLVE-NAMES-TO-UPNS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "8b150fd6e093ecf1a4b2b77cc5856f18de47a0f101a8f7257f0eea4742d12f8d",
    "accepted": {
      "version": "1.0.0",
      "sha256": "cf9c443a440d8e7dc6e03072553129808458c1bd481e8258860e4d409198c7a6",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-ACCOUNT-STATUS.ps1": {
    "path": "published-source/identity/GET-ACCOUNT-STATUS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "94258427439cc292f33bd76e835b10a407218bc9136537874a9cd267f2e20b75",
    "accepted": {
      "version": "1.0.0",
      "sha256": "137ad42ab42a9739ceab2123570f2dc50c2cb258c087f48431c2204fb86e69b9",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "path": "published-source/mailbox/GET-DISTRIBUTION-GROUP-MEMBERS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "c91680865f7bc992c7638f1a5c3e371a281ed52100a2a3fc979b87d8321af676",
    "accepted": {
      "version": "1.0.0",
      "sha256": "9e7862eefbdb1c7c89177f076d2c8030b26b65869623d6414f9ebf005d16f0ea",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "GET-GROUP-MEMBERS.ps1": {
    "path": "published-source/identity/GET-GROUP-MEMBERS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "5c7baa7d0551de2eb0c21650bb8943ca198697c94cef2f556a5ab458f7916d67",
    "accepted": {
      "version": "1.0.0",
      "sha256": "744ac9b55488b0b96f22f0ce886aee25698eb39cb15a82cbb1fb291d063d3478",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-REMOVE-USER-GROUPS.ps1": {
    "path": "published-source/identity/INVOKE-REMOVE-USER-GROUPS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "8bc820639a1d6e1479e0b1c7a2a1f58953fb0eb5396f922628a73855b0e3fc54",
    "accepted": {
      "version": "1.0.0",
      "sha256": "18e441456d7201daf0985ad776e012a86248f40fc8de8026536c27ea1b60cf31",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Membership DELETE route and eventual removal readback functions only; no actual group changes.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "path": "published-source/identity/INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "7ed4b8f50be401d4004b6ff4672d19bcad5ab6e7f47cf7bc3d0a3e144290f83d",
    "accepted": {
      "version": "1.0.1",
      "sha256": "7068d41c2fecf17249bbcb888534987f046c68ebcbc51133b9c23186daf37153",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped safety checks",
      "scope": "15 synthetic group-creation cases: preview/cancel, tenant/context/scope checks, request failure and readback. No real group creation or auth tested.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-TENANT-GROUP-OWNERS.ps1": {
    "path": "published-source/tenant/GET-TENANT-GROUP-OWNERS.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "dc04a5c13230de80a767d325a6739c3df6240618d20e6419315cb96a43f224b0",
    "accepted": {
      "version": "1.0.0",
      "sha256": "830e2ed189de399a7f3813a021446ae68cba5c9c4e810b69cf41e5698751d786",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "GET-MAILBOX-PERMISSIONS.ps1": {
    "path": "published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "76535edd6d3e922cc44decedba707203716788afa4bdabbf68579549a57752e6",
    "accepted": {
      "version": "1.0.0",
      "sha256": "793bdd06ff9adadcae9312e8614513d7c6440f507858593a35eb05469fe43620",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "path": "published-source/mailbox/GET-MAILBOX-SECURITY-SNAPSHOT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "e9e75ef77efeb81017c8dcc6f3f05cd5deb4fb8eba90890560808406762f7fda",
    "accepted": {
      "version": "1.0.0",
      "sha256": "10e8a2aae2fff3b4a3708510008ac6a1f9b7892358256480c7a57d6a8dfabe2c",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "GET-MAILBOX-FORWARDING.ps1": {
    "path": "published-source/mailbox/GET-MAILBOX-FORWARDING.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "0e184a41bd351c391985118eb128eaefad0311ec691abe4933868e6af5a88d91",
    "accepted": {
      "version": "1.0.0",
      "sha256": "211c8d36fe0c258d787fea3229315b32aa38a3e636e430218045e19e9c3dd306",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "INVOKE-LITIGATION-HOLD.ps1": {
    "path": "published-source/mailbox/INVOKE-LITIGATION-HOLD.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "1ea2ff740e1f5eb24ba4aafa92636fce025ed90ffbc4050e80ce5aedcb3568fe",
    "accepted": {
      "version": "1.0.0",
      "sha256": "e084346e37bb4575a5be123fd99cd5ed6c30b463beea38827296ba5e6b6fe72b",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Simulated hold enforcement workflow: approval, mutation and readback; Exchange/auth are fixtures.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-INVOKE-EMAIL-RECOVERY.ps1": {
    "path": "published-source/incident-response/BEC-INVOKE-EMAIL-RECOVERY.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "bbbe2551ba6054995d4caa517e23a32711c0afbd4b7becbf2a5575662409482f",
    "accepted": {
      "version": "1.0.0",
      "sha256": "b75852825c289f1db32ffd2532f308546fe31f547be0298b56b2de78330b8894",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Encoded message-move request and root-folder creation functions only; no mailbox access or message changes.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-RISK-ASSESSMENT.ps1": {
    "path": "published-source/incident-response/BEC-RISK-ASSESSMENT.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "94526ec8ea67e88d9373d1cdb9beadf7ec4992b80cafcd4a97797c2a10c488f4",
    "accepted": {
      "version": "1.0.0",
      "sha256": "07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b",
      "operatorTested": true,
      "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-CONTAIN-ERADICATE.ps1": {
    "path": "published-source/incident-response/BEC-CONTAIN-ERADICATE.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "c8b857d6191a6bceecb651413552cad0bbc8a421046bfe2a95390728cb89ce10",
    "accepted": {
      "version": "1.0.0",
      "sha256": "e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb",
      "operatorTested": true,
      "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-GET-DATA-EXFIL-ACTIVITY.ps1": {
    "path": "published-source/incident-response/BEC-GET-DATA-EXFIL-ACTIVITY.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "1fa5c320ff44327b602d61a94ba5a76b9571b51fdbf36c77be0c59e34795fad1",
    "accepted": {
      "version": "1.0.0",
      "sha256": "73a83bd02db13481dbd1feb9d9088bfedf6a5f925c09fa71c241eaa83f9746a0",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-GET-IP-TRACE.ps1": {
    "path": "published-source/incident-response/BEC-GET-IP-TRACE.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "a97b049fad9c2a2f7f4344bc90a68689d1e1d5c4f720f2b6533b5106ae69970a",
    "accepted": {
      "version": "1.0.0",
      "sha256": "6f1bacdb932aa3e2e5077b3c810a0cfb9969e4c24b07e285e1ecdf53d3fffd2d",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-GET-TENANT-EMAIL-SEARCH.ps1": {
    "path": "published-source/incident-response/BEC-GET-TENANT-EMAIL-SEARCH.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "3a78895cbec147f408f82929e720c7e527c8bd3f18dad6d86c1e31ee1c868043",
    "accepted": {
      "version": "1.0.0",
      "sha256": "e4b41e56c30b37ea2ec5de44d5e2851fd5fd1c656122d03d9b2a21b4c89de83c",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "path": "published-source/incident-response/BEC-GET-THREAT-INTEL-ACTIVITY.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "e0864cdd7dd81324a3b1a71fbf80841c14d3bd86d0ca7abb100416b4a243461e",
    "accepted": {
      "version": "1.0.0",
      "sha256": "ea3d359ed80ce3b867b3ee1b84fba7234ccab29ba0e2c9d3cbd4e99001761f42",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "IP input guards only; provider API calls, credentials and reputation findings are not tested.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-GET-TIMELINE-BUILDER.ps1": {
    "path": "published-source/incident-response/BEC-GET-TIMELINE-BUILDER.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "a80ca2ee465da49ebb7d38b6728265be427d93a4aa7eb129d3e18f202a4b5ecf",
    "accepted": {
      "version": "1.0.0",
      "sha256": "483a49fbc5439e1f6282a5fefd44bc6b085376092a27659991f056385b9d4469",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Synthetic local fixture / host read-only check",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-GET-TOKEN-DECODE.ps1": {
    "path": "published-source/incident-response/BEC-GET-TOKEN-DECODE.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "809933ffd6759b71b20324825887e7d5b1530e1eecce8d8d0cd92c3ce5a57742",
    "accepted": {
      "version": "1.0.0",
      "sha256": "89be0780dd4434bbd1dfebf54bfe06df1f0bb3db23f1df111b1a3143f57918bf",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Synthetic local fixture / host read-only check",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "BEC-GET-TOKEN-REPLAY-CHECK.ps1": {
    "path": "published-source/incident-response/BEC-GET-TOKEN-REPLAY-CHECK.ps1",
    "currentVersion": "1.0.4",
    "currentSha256": "aacd5c9a0c91ecbd16ceedaa14b433aba25f882f3752efd903996bfc95dbfbde",
    "accepted": {
      "version": "1.0.0",
      "sha256": "5b2d89608eb132a45412260ed831f4c17030ea00b073f80789b5b5dcd4cb3d52",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "path": "published-source/tenant/GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "3f365d6e8677b2f59f1e3fba81f038c6645dd0e1e3a95b28c95804b161f06009",
    "accepted": {
      "version": "1.0.0",
      "sha256": "0d4eadce8535af2eb5817f455f2130070fee32f2fa6d619b0fc777b02786d0ac",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-APP-REGISTRATION-AUDIT.ps1": {
    "path": "published-source/tenant/GET-APP-REGISTRATION-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "76613d8367421f66d7c546b3543168109eadfec80618fa46905ad3a2b3403a5d",
    "accepted": {
      "version": "1.0.0",
      "sha256": "c1664f389dc41c33a2d5c361344f3ee187543acf235563ba334dd4b5dc398494",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "path": "published-source/tenant/GET-CONDITIONAL-ACCESS-GAPS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "adebcd1ba46cb0e58a7ac4381547d2aa7f501a906b5c521d27ca0ac9121b6555",
    "accepted": {
      "version": "1.0.0",
      "sha256": "700cda3659ae2f556b599105ea4505dd036fee12488f8dc62542105765342942",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-DEVICE-CODE-EXPOSURE.ps1": {
    "path": "published-source/tenant/GET-DEVICE-CODE-EXPOSURE.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "9595b261ea55f5fc61dd562df2e5297cd8d3fa8bf587d0d61cce5535df93e27b",
    "accepted": {
      "version": "1.0.0",
      "sha256": "a6394a47c1a6056ee7287dd74377399c2b93f88aeb8ab3ac4ad1c8507adde595",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "path": "published-source/tenant/GET-GUEST-APP-CONSENT-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "0e9676a036af440268ac33d3007fa34c05505e2765462a7143b2caa208585721",
    "accepted": {
      "version": "1.0.0",
      "sha256": "7668e2da42b22a226ae01c5b04fc20ff94db666e03fee586bf79ffcfb260f504",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-MFA-SECURITY-AUDIT.ps1": {
    "path": "published-source/tenant/GET-MFA-SECURITY-AUDIT.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "da69d7308448b31477b9de6ff104257a891562902ec0142a5b053b70482d73a5",
    "accepted": {
      "version": "1.0.0",
      "sha256": "73de4a26783e056f501d0e76c30882814c47dc9757898dbf64439087587862ed",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "path": "published-source/tenant/GET-SECURE-SCORE-SNAPSHOT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "bf4d87b38d221c5e6b86fef69b10a1cb7c4d75e6fe8c5abe64ec5c99993f3e5d",
    "accepted": {
      "version": "1.0.0",
      "sha256": "fda432b38f4ff200641ece8fe361282484e60be3ea0285fc3df9b17dd2479ecb",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Owner-reported sampled follow-up acceptance",
      "scope": "Owner-reported acceptance of the supplied sampled report follow-up. Secure Score was included in that bundle; no separate returned execution manifest or HTML report is available. Not a full-tenant or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "path": "published-source/tenant/GET-SERVICE-PRINCIPAL-OWNERS.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "7f300774005a7ba46d354c17b02cec9f09ca34863edaf8b057159cca7bef5885",
    "accepted": {
      "version": "1.0.0",
      "sha256": "a562cf302de63e53dc755cc83b9df06a8edf62059e0c3893f8f790a7bd1a9558",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-SIGNIN-ANOMALIES.ps1": {
    "path": "published-source/tenant/GET-SIGNIN-ANOMALIES.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "dcde2b39589b9c740a7a9c20ff17cc59d8752cc555a9359f9d0210e18fa053b1",
    "accepted": {
      "version": "1.0.0",
      "sha256": "1688aabd095a8b2dac4e078739227c375901c078f200626a7bf5c1536169dcb7",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-TRANSPORT-RULES-AUDIT.ps1": {
    "path": "published-source/tenant/GET-TRANSPORT-RULES-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "7c4ff63bee17b5669a05a76657f3cca0b5b3674b102ead014df742ae720c62ae",
    "accepted": {
      "version": "1.0.0",
      "sha256": "f8a2b77f30cc74153258b85aa86c2ac231debe523ab82caa298131d9b412fb68",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "path": "published-source/endpoint/JOIN-COMPUTER-TO-DOMAIN.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "231cef1b8c4ca32837fa4ece5cc04162eb1de0371f3fd69a6fd7aa839bd6f147",
    "accepted": {
      "version": "1.0.0",
      "sha256": "ceb45d86f50b2e220690edc42b923e79963484b3e860cfa6c9b9800e4f990867",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped local/setup checks",
      "scope": "Simulated approved join workflow success/failure and reboot-pending messaging; no actual join or reboot.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "DEPLOY-TCPIP-PRINTER.ps1": {
    "path": "published-source/endpoint/DEPLOY-TCPIP-PRINTER.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "adcb0d7445bbc847c2f1d7a22dcf5c12c645a68a81036c38dd510c67bd3821d1",
    "accepted": {
      "version": "1.0.0",
      "sha256": "fd3b71fe485ec15242bf10fef5293a10b48934abc657fb4e97b5395faeb81bac",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped safety checks",
      "scope": "5 synthetic default-printer method/result checks. No actual printer installation or device tested.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "BACKUP-USER-PROFILE.ps1": {
    "path": "published-source/endpoint/BACKUP-USER-PROFILE.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "dd1d1e62acc1343f0c5010dc93ebd5cf29671ff42d9876580c3f1ef7b285988d",
    "accepted": {
      "version": "1.0.0",
      "sha256": "4ba55933de25533cd3e523048cfc259bf850243ba3d6ab3e1e8b5f383256c3af",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped safety checks",
      "scope": "6 synthetic Robocopy outcome/coverage cases. No actual profile backup or restore tested.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "TEST-POWERSHELL-READINESS.ps1": {
    "path": "published-source/utility/TEST-POWERSHELL-READINESS.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "fee19c4cac0b5638a8f6515eb4be8734135c997d63c4b21e7f71b33a8a21e314",
    "accepted": {
      "version": "1.0.0",
      "sha256": "a8a52521cfa5a63477558769b97805e64e24fb03452c349ece4c8b9facbf7449",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Synthetic local fixture / host read-only check",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "GET-FOLDER-INVENTORY.ps1": {
    "path": "published-source/utility/GET-FOLDER-INVENTORY.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "218d4e788913c6a6d8d6578d8b1912cf7f68a8c4687ecaf6d557bbd4ea26cd60",
    "accepted": {
      "version": "1.0.0",
      "sha256": "fc544a0aeef46727b8ba3ede8640114ea94707dd84a410a3c50cc36e0d273387",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Synthetic local fixture / host read-only check",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "INSTALL-M365-MODULES.ps1": {
    "path": "published-source/utility/INSTALL-M365-MODULES.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "6c5fb208fea47d9588354590817362336e644bc4887127f317d4816161c0b4a2",
    "accepted": {
      "version": "1.0.0",
      "sha256": "a652531a49e22d4f8c243676075b07cf9f22c90953cf615c8fd8e1d900665181",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Simulated module installation workflow with cancellation, scope and failure checks; nothing is installed.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "TEST-SENSITIVE-DATA.ps1": {
    "path": "published-source/utility/TEST-SENSITIVE-DATA.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "594d18150acb832080f13776581f6d8d8d21d3addc7e14aa8aea017b76e9b69e",
    "accepted": {
      "version": "1.0.0",
      "sha256": "9543c614e26b54a6bb8776e5e6ccc23a04c644710f609cd192030cfd35b1f606",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Synthetic local fixture / host read-only check",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "RESET-M365-SESSION.ps1": {
    "path": "published-source/utility/RESET-M365-SESSION.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "a08270181dc4ac7ac0cb78fd8f651701a40ce25b668342a4e0a829fb09246809",
    "accepted": {
      "version": "1.0.0",
      "sha256": "a4c2a5f0c5b7decfccccc50fb3b3ec1a213d562edf00a28ff04233e22502d680",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Simulated reset workflow; checks unrelated sessions are preserved; no real disconnections.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "UPDATE-WINDOWS-APPS.ps1": {
    "path": "published-source/utility/UPDATE-WINDOWS-APPS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "32fcfc1c298460301dc5fe7841bb5bddb768691e23f7c9f28270c5396349c3c3",
    "accepted": {
      "version": "1.0.0",
      "sha256": "f0f5554fbd8925901f6b02a65401a437dccafa27462b820c751493898c532e4a",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped safety checks",
      "scope": "4 simulated WinGet completion/review/cancellation cases. No actual application updates tested.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-USER-PREDELETE-CHECK.ps1": {
    "path": "published-source/identity/GET-USER-PREDELETE-CHECK.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "4ae5545f73829374e5b1500bd3ba8cc029e3f095e700e9ce76bf835d8a034107",
    "accepted": {
      "version": "1.0.0",
      "sha256": "e7e86d7ae9e59ba32a7752feb55562b782fc5cf6623b3f33d7c584ef6d945f0f",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "path": "published-source/identity/INVOKE-ENFORCE-PER-USER-MFA.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "23a9db7bcacb8f388d2e71b3cc54b720a00b9d377af7c10bac263b32f0008b62",
    "accepted": {
      "version": "1.0.0",
      "sha256": "3270e9e8879fa3b0c7da913adc88d96edb484f92ad4a2fd6e06970f303d0874e",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Simulated per-user MFA workflow: approval, mutation and readback; auth is a fixture.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "GET-ADMIN-ROLE-AUDIT.ps1": {
    "path": "published-source/tenant/GET-ADMIN-ROLE-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "764cf4825fa98591a0ab0bde803f96568e1a1c2d8ed4585095eda2460a04aa6c",
    "accepted": {
      "version": "1.0.0",
      "sha256": "ccb2cffcb4a7a685782f5602868f338784f36f6b9557fc395182b4f1540941bb",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-OAUTH-CONSENT-AUDIT.ps1": {
    "path": "published-source/tenant/GET-OAUTH-CONSENT-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "3f18ee0289321bc6b7cb226c08f33c79c0e4844bc03884ea24a99180699f4251",
    "accepted": {
      "version": "1.0.0",
      "sha256": "2680aea2ddca4bdabc0e203535f5982bf11685199e76895fdda61a964fa56e25",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-GUEST-USER-AUDIT.ps1": {
    "path": "published-source/tenant/GET-GUEST-USER-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "641555328872d02331f3153eb686b48bf4cf5b21f67c7a9919c0bbef0d75da61",
    "accepted": {
      "version": "1.0.0",
      "sha256": "482e2632abcf13141fabab0266ca1ad3496628b48bd56072d21507054ecc2a95",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-TENANT-LICENSING-AUDIT.ps1": {
    "path": "published-source/tenant/GET-TENANT-LICENSING-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "d9d7da1dc4f720953848f56fa4c68ae594c7b183ed3f07f623d511321a2aae07",
    "accepted": {
      "version": "1.0.0",
      "sha256": "4bcffc030d5f4bb26ef3f9349f7a215f7a6b2b6f58e3784713f1a038e5b785be",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "path": "published-source/tenant/GET-TENANT-INBOX-RULES-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "c0a1a2459471df298746940de9a997ee60514cbec0bb11a821f4c7e2233c66f6",
    "accepted": {
      "version": "1.0.0",
      "sha256": "ead045dcca94d9cb5dd623be7e29b1563fc3716370f32fffc7e85b71d82a8ca7",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "GET-USER-SECURITY-SNAPSHOT.ps1": {
    "path": "published-source/identity/GET-USER-SECURITY-SNAPSHOT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "b9d8d41d6fe83eb0c5b3c8cb6d71989719d8622bc359116fc20618814399cff6",
    "accepted": {
      "version": "1.0.0",
      "sha256": "52ac45625a7a12b01d9f1a27d34636423b791ec78d77ea7640d86edb66af2ff6",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "path": "published-source/tenant/GET-TENANT-SECURITY-SNAPSHOT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "342829ae9c8df76225bdee4e0c76776aabb76a43a3c5756363a6add984ca0666",
    "accepted": {
      "version": "1.0.0",
      "sha256": "b4fbb3ad10dcde3e5beb1c414890597de2fd969a4e9fe4149f70b7bea2c5f44c",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled read-only batch and HTML export",
      "evidence": "docs/qa/READONLY-REPORTS-1.0.0-VERIFICATION.md"
    }
  },
  "GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "path": "published-source/tenant/GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "90eadb894e2aa8ac36f62047a4c4aadcac67aa468c8bbbf583ec0992e6fc6e9c",
    "accepted": {
      "version": "1.0.0",
      "sha256": "ea78878fbb017dbbdf095955c983904cbac2141d6a10293077b7f7bcdd056626",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Sampled functional read-only batch",
      "scope": "Owner-accepted sampled read-only run: at most 10 records per collection, 40 reads per script/user. No full pagination, exhaustive tenant coverage or standalone-launch claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "path": "published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "c50e6a31dbf37dea44f651d4cfdced99ba4f3ce053a8ec3e75edb1a8f4fb504d",
    "accepted": {
      "version": "1.0.0",
      "sha256": "e9b65c7fc9da2a09b87f84618b0d2693681cc8f497eef0343de990dee202c7c1",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Principal matching and SendOnBehalf target isolation only; disabled-state/auth and removal are not exercised.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "GET-TENANT-DRIFT-REVIEW.ps1": {
    "path": "published-source/tenant/GET-TENANT-DRIFT-REVIEW.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "f5f1fdd5b2d6739ecc07989244e5da3f36811d1589109d4e7892609e937abfc2",
    "accepted": {
      "version": "1.0.0",
      "sha256": "f473f3fffdf501b2b04604db04268f75670be319734b8c32da66bd1df45183ed",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Synthetic added/removed/changed comparisons and real temporary JSON write/read; no tenant queries.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "path": "published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "7af474157506fd00c85b064ec037e09286c7776e4b088b28e8af36d6f3cbc85d",
    "accepted": {
      "version": "1.0.0",
      "sha256": "cb834050cc7551dfa261f19ff53eb363e917de63d368884ef6f1964a20c84f47",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Storage collector with synthetic CIM/file records; top-file ranking and skip option; no real drive walk.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "path": "published-source/identity/INVOKE-RESET-CLOUD-USER-PASSWORD.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "40abec4baa9461a7ce2f60159d747340023985fe505191d1d7e530873d7b674a",
    "accepted": {
      "version": "1.0.0",
      "sha256": "bcaf79f5c432558ed746efd6667aff21cc0b7dc61a0d4c62e5cd444eeb402507",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped safety checks",
      "scope": "4 accepted-reset timestamp readback cases only: changed, unchanged, missing and denied. No actual reset, password generation or delivery tested.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "BEC-RECOVER-VALIDATE.ps1": {
    "path": "published-source/incident-response/BEC-RECOVER-VALIDATE.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "1b21a21f15d6618c0964c37ab21e0c167cfba5616efe8d108dbb18ac1aa0ce4e",
    "accepted": {
      "version": "1.0.0",
      "sha256": "c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04",
      "operatorTested": true,
      "evidence": "docs/qa/IR-1.0.0-VERIFICATION.md"
    }
  },
  "git-handoff.ps1": {
    "path": "tools/git-handoff.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "de09cbd42d120d932969dc229fa5437c7770fcdf6aed331f364acf6bec6c6531",
    "accepted": {
      "version": "1.0.0",
      "sha256": "886a5782009fc8abf4825f997ccab38c0c1679a32b6653596089e038cf3ba22c",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped local/setup checks",
      "scope": "Metadata redaction and object-ID validation only; no repository reads or handoff writes.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "git-repo.ps1": {
    "path": "tools/git-repo.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "3bcd5f6b61c9b5b24d3d8adcaa22f584e80bdfe0b612c9a53cacf9d03125b78c",
    "accepted": {
      "version": "1.0.0",
      "sha256": "cd0c87313d27c17cd79a82f470991aad016583781066f856841cc251f245afdd",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped local/setup checks",
      "scope": "Changed-filename risk screening with synthetic Git status; no real Git commands, commit, push or pull.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "set-execution.ps1": {
    "path": "tools/set-execution.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "4379e986662f2a80092938916ac5d2509fc5b01cb391d95e20b58c91b16ad294",
    "accepted": {
      "version": "1.0.0",
      "sha256": "90464f2b844266bdf88c5956fc44dd34939cf7c8664ac19c90f4be4defec2bc4",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Simulated execution-policy/unblock workflow; managed policy preserved; no real policy/unblock changes.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "attractor.ps1": {
    "path": "toys/attractor.ps1",
    "currentVersion": "1.0.1",
    "currentSha256": "1268680342075976f80599213dd97d25abc2af741a07a7f5de2ceab2c2ba4cc6",
    "accepted": {
      "version": "1.0.0",
      "sha256": "62820d67085b65d230bb28c4954259bd32bffd29f30aee8a6f9a2cdfcdfdc5aa",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "rain.ps1": {
    "path": "toys/rain.ps1",
    "currentVersion": "1.0.1",
    "currentSha256": "f793a1a68a8245527597522077f40dda3eeb209bf9c6ad1164f0dde5ef9daf96",
    "accepted": {
      "version": "1.0.0",
      "sha256": "67ff5ccad0eb69510576920fd8b36accfb606a2b1cd3ddeb1ae75f021fda9bc9",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "static.ps1": {
    "path": "toys/static.ps1",
    "currentVersion": "1.0.1",
    "currentSha256": "4aa3ae630d9631f11d110f78925c6e112508b3ccc7ba703f833537bb3c9394e0",
    "accepted": {
      "version": "1.0.0",
      "sha256": "75f06611710a84f21522226fffebb3bf2e6a6b5d58383baf507ba6c69ddf19ca",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "SIGN-FOLDER-SCRIPTS.ps1": {
    "path": "tools/SIGN-FOLDER-SCRIPTS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "2890218ee6951f81e46e0dd5cbc5b4ed38b80ccce031d0b04ad9c3561e654851",
    "accepted": {
      "version": "1.0.0",
      "sha256": "9b2d82c75017899485b76d227e323deca66c6660534e83c1238938f058d454a1",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Operator-selected certificate/signing wizard steps; dummy signing folder; native approvals preserved.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "GET-TERMINAL-READINESS-CHECK.ps1": {
    "path": "tools/GET-TERMINAL-READINESS-CHECK.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "0cdf541f4222218c359dddc9e441343d37ee7ad745cfe5588e06a9a45ad42316",
    "accepted": {
      "version": "1.0.0",
      "sha256": "fcb2a3383b43915e88dc3e819ba6f573dafb2dc256b008d1d896535bb7dae991",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped local/setup checks",
      "scope": "Relative-path presentation only; no installed-module, signature or certificate readiness claim.",
      "evidence": "docs/qa/ACCEPTED-TEST-RECONCILIATION.md"
    }
  },
  "INVOKE-FILE-INVENTORY.ps1": {
    "path": "tools/INVOKE-FILE-INVENTORY.ps1",
    "currentVersion": "1.0.3",
    "currentSha256": "435f354240c3178c5def5a4b2faaaaa013a7ef0d99f07fcf9170e69801b13279",
    "accepted": {
      "version": "1.0.0",
      "sha256": "acb04fd3968ef3a29356ef52583229a72926f7a6ed319b4b36bd01e56de28445",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Synthetic local fixture / host read-only check",
      "evidence": "docs/qa/BATCH-2-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-MAP-KIT.ps1": {
    "path": "tools/INVOKE-MAP-KIT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "ea3b5ee21dbd384d7107ec1458be968d7c7c5c00c9998a4dcc2f89856a8372a4",
    "accepted": {
      "version": "1.0.0",
      "sha256": "330fb1fc8cc144b3f9cd23a0e3399a2f69d168b31b6a9fe27c255e0c77ffdf2b",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Actual map workflow against a tiny disposable folder, including missing path; signatures skipped.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "INVOKE-SESSION-RESET.ps1": {
    "path": "tools/INVOKE-SESSION-RESET.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "2fa5b247f31b2dfe29bbed17ec9ffe576e53dbe3ce3e7ffb03f8328c7843dc07",
    "accepted": {
      "version": "1.0.0",
      "sha256": "4de135e684e778e091292f7fe56610ddee47739c15d34dda5367cbe3112a15bc",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Offline scoped behavioral checks; no live-service claim",
      "scope": "Simulated jumpbox reset workflow; no password variable removal, disconnections or new windows.",
      "evidence": "docs/qa/BATCH-4-1.0.0-VERIFICATION.md"
    }
  },
  "SET-THEME-BASIC.ps1": {
    "path": "toys/SET-THEME-BASIC.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "9dc01f2210cf808379be2770450283f0d44be72c4d3cae3f9a0087c2f15e98f2",
    "accepted": {
      "version": "1.0.0",
      "sha256": "82ddf2ed63914b6a1eb40664f486783e59690799b8df19bf9f00fbd3dc142756",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "SET-THEME-COBALT.ps1": {
    "path": "toys/SET-THEME-COBALT.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "602ddcb368e716ca73ced3b799d847262faca237ee43b63a7070596ce37d9d2b",
    "accepted": {
      "version": "1.0.0",
      "sha256": "3d0dbac577cce716e5427a9b2635ee6cefe29a45955bc632cb8b4f2dd48fe343",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "SET-THEME-SEAGLASS.ps1": {
    "path": "toys/SET-THEME-SEAGLASS.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "629b919cea8aabd890151a2402241e426a4c0c331a9a4d5861bd9aaa340e888e",
    "accepted": {
      "version": "1.0.0",
      "sha256": "16153f1c1989834f659ec7c08546c454dd95bdc51abebb2f7afb684b70964fdf",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "SET-THEME-SILICON-VALLEY.ps1": {
    "path": "toys/SET-THEME-SILICON-VALLEY.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "aab04649707578c0c57a9602b80cdae04465bff529fae0373d46f1aa2bc43739",
    "accepted": {
      "version": "1.0.0",
      "sha256": "1c732aa6c82182265dc02019c9805a7ac9faec56e7b3312e8d7b00c7d66dd60d",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Native separate-window preview; theme profile redirected; operator-reviewed appearance.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  },
  "MANAGE-CERT-SIGNATURES.ps1": {
    "path": "tools/MANAGE-CERT-SIGNATURES.ps1",
    "currentVersion": "1.0.2",
    "currentSha256": "d28176159f671ed1fe1e521f422a89f8de92f5ec032067e16f46156549d683fb",
    "accepted": {
      "version": "1.0.0",
      "sha256": "11544fc1bdedfe8e1e7ff69c1abb084cd5001132c40178782bd21281150c2cb8",
      "operatorTested": true,
      "ownerAccepted": true,
      "testMode": "Native separate-window operator review",
      "scope": "Operator-selected certificate/signing wizard steps; dummy signing folder; native approvals preserved.",
      "evidence": "docs/qa/NATIVE-1.0.0-VERIFICATION.md"
    }
  }
});
