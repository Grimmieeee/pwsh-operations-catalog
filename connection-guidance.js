// Source-reviewed connection paths. Re-review when the published source hash changes.
window.FIELD_KIT_CONNECTION_GUIDANCE = Object.freeze({
  "published-source/tenant/GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "sha256": "dfc7e8526aea4a3bfd36d934dad90378fde0800514fd597aa6ad6e2da6288093",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/tenant/GET-STALE-SIGNIN-REVIEW.ps1": {
    "sha256": "42ebf997eeef17e7970ba4d08c65203c0343f9799d0a28be10800bef16f089fd",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/INVOKE-DISABLE-ACCOUNTS.ps1": {
    "sha256": "e973c60df895a359aa983525e8aa47650036e0db369168bffd7803d2b8a4f572",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-DELETE-ACCOUNTS.ps1": {
    "sha256": "5cff2cc13a1db4e40fb260f63eddcfe87871ae152400103ce19ef0f691988d66",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-ASSIGN-LICENSES.ps1": {
    "sha256": "289d921e47af9ba0d05c0ecaef218a25101c704529e9aa31c85e4aa5d1e158b5",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/INVOKE-REMOVE-LICENSES.ps1": {
    "sha256": "eedbc44f46a0078347ebe4b7ac414b197ba47e6449a7ee8162b40ba9aeb13450",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/RESOLVE-NAMES-TO-UPNS.ps1": {
    "sha256": "cf9c443a440d8e7dc6e03072553129808458c1bd481e8258860e4d409198c7a6",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/GET-ACCOUNT-STATUS.ps1": {
    "sha256": "137ad42ab42a9739ceab2123570f2dc50c2cb258c087f48431c2204fb86e69b9",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/mailbox/GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "sha256": "9e7862eefbdb1c7c89177f076d2c8030b26b65869623d6414f9ebf005d16f0ea",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/identity/GET-GROUP-MEMBERS.ps1": {
    "sha256": "744ac9b55488b0b96f22f0ce886aee25698eb39cb15a82cbb1fb291d063d3478",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/identity/GET-USER-GROUPS.ps1": {
    "sha256": "fb1a0872e2282f6e945bc222ea16134e7b1b1d68c6f0ea8a677f53e4d0575d7a",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-REMOVE-USER-GROUPS.ps1": {
    "sha256": "18e441456d7201daf0985ad776e012a86248f40fc8de8026536c27ea1b60cf31",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "sha256": "7068d41c2fecf17249bbcb888534987f046c68ebcbc51133b9c23186daf37153",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-GROUP-OWNERS.ps1": {
    "sha256": "830e2ed189de399a7f3813a021446ae68cba5c9c4e810b69cf41e5698751d786",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1": {
    "sha256": "793bdd06ff9adadcae9312e8614513d7c6440f507858593a35eb05469fe43620",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "sha256": "10e8a2aae2fff3b4a3708510008ac6a1f9b7892358256480c7a57d6a8dfabe2c",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-FORWARDING.ps1": {
    "sha256": "211c8d36fe0c258d787fea3229315b32aa38a3e636e430218045e19e9c3dd306",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/INVOKE-LITIGATION-HOLD.ps1": {
    "sha256": "e084346e37bb4575a5be123fd99cd5ed6c30b463beea38827296ba5e6b6fe72b",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-INVOKE-EMAIL-RECOVERY.ps1": {
    "sha256": "b75852825c289f1db32ffd2532f308546fe31f547be0298b56b2de78330b8894",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/incident-response/ir-risk-assessment.ps1": {
    "sha256": "07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ]
  },
  "published-source/incident-response/ir-contain-eradicate.ps1": {
    "sha256": "e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/incident-response/IR-GET-DATA-EXFIL-ACTIVITY.ps1": {
    "sha256": "73a83bd02db13481dbd1feb9d9088bfedf6a5f925c09fa71c241eaa83f9746a0",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-IP-TRACE.ps1": {
    "sha256": "6f1bacdb932aa3e2e5077b3c810a0cfb9969e4c24b07e285e1ecdf53d3fffd2d",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-TENANT-EMAIL-SEARCH.ps1": {
    "sha256": "e4b41e56c30b37ea2ec5de44d5e2851fd5fd1c656122d03d9b2a21b4c89de83c",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "sha256": "ea3d359ed80ce3b867b3ee1b84fba7234ccab29ba0e2c9d3cbd4e99001761f42",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TIMELINE-BUILDER.ps1": {
    "sha256": "483a49fbc5439e1f6282a5fefd44bc6b085376092a27659991f056385b9d4469",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TOKEN-DECODE.ps1": {
    "sha256": "89be0780dd4434bbd1dfebf54bfe06df1f0bb3db23f1df111b1a3143f57918bf",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TOKEN-REPLAY-CHECK.ps1": {
    "sha256": "5b2d89608eb132a45412260ed831f4c17030ea00b073f80789b5b5dcd4cb3d52",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "sha256": "0d4eadce8535af2eb5817f455f2130070fee32f2fa6d619b0fc777b02786d0ac",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ]
  },
  "published-source/tenant/GET-APP-REGISTRATION-AUDIT.ps1": {
    "sha256": "c1664f389dc41c33a2d5c361344f3ee187543acf235563ba334dd4b5dc398494",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "sha256": "700cda3659ae2f556b599105ea4505dd036fee12488f8dc62542105765342942",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-DEVICE-CODE-EXPOSURE.ps1": {
    "sha256": "a6394a47c1a6056ee7287dd74377399c2b93f88aeb8ab3ac4ad1c8507adde595",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "sha256": "7668e2da42b22a226ae01c5b04fc20ff94db666e03fee586bf79ffcfb260f504",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-MFA-SECURITY-AUDIT.ps1": {
    "sha256": "73de4a26783e056f501d0e76c30882814c47dc9757898dbf64439087587862ed",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "sha256": "fda432b38f4ff200641ece8fe361282484e60be3ea0285fc3df9b17dd2479ecb",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "sha256": "a562cf302de63e53dc755cc83b9df06a8edf62059e0c3893f8f790a7bd1a9558",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SIGNIN-ANOMALIES.ps1": {
    "sha256": "1688aabd095a8b2dac4e078739227c375901c078f200626a7bf5c1536169dcb7",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TRANSPORT-RULES-AUDIT.ps1": {
    "sha256": "f8a2b77f30cc74153258b85aa86c2ac231debe523ab82caa298131d9b412fb68",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/endpoint/JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "sha256": "ceb45d86f50b2e220690edc42b923e79963484b3e860cfa6c9b9800e4f990867",
    "mode": "local",
    "services": [
      "AD"
    ]
  },
  "published-source/endpoint/DEPLOY-TCPIP-PRINTER.ps1": {
    "sha256": "fd3b71fe485ec15242bf10fef5293a10b48934abc657fb4e97b5395faeb81bac",
    "mode": "local",
    "services": []
  },
  "published-source/endpoint/BACKUP-USER-PROFILE.ps1": {
    "sha256": "4ba55933de25533cd3e523048cfc259bf850243ba3d6ab3e1e8b5f383256c3af",
    "mode": "local",
    "services": []
  },
  "published-source/utility/TEST-POWERSHELL-READINESS.ps1": {
    "sha256": "a8a52521cfa5a63477558769b97805e64e24fb03452c349ece4c8b9facbf7449",
    "mode": "local",
    "services": []
  },
  "published-source/utility/GET-FOLDER-INVENTORY.ps1": {
    "sha256": "fc544a0aeef46727b8ba3ede8640114ea94707dd84a410a3c50cc36e0d273387",
    "mode": "local",
    "services": []
  },
  "published-source/utility/INSTALL-M365-MODULES.ps1": {
    "sha256": "a652531a49e22d4f8c243676075b07cf9f22c90953cf615c8fd8e1d900665181",
    "mode": "local",
    "services": []
  },
  "published-source/utility/TEST-SENSITIVE-DATA.ps1": {
    "sha256": "9543c614e26b54a6bb8776e5e6ccc23a04c644710f609cd192030cfd35b1f606",
    "mode": "local",
    "services": []
  },
  "published-source/utility/RESET-M365-SESSION.ps1": {
    "sha256": "a4c2a5f0c5b7decfccccc50fb3b3ec1a213d562edf00a28ff04233e22502d680",
    "mode": "local",
    "services": []
  },
  "published-source/utility/UPDATE-WINDOWS-APPS.ps1": {
    "sha256": "f0f5554fbd8925901f6b02a65401a437dccafa27462b820c751493898c532e4a",
    "mode": "local",
    "services": []
  },
  "published-source/identity/GET-USER-PREDELETE-CHECK.ps1": {
    "sha256": "e7e86d7ae9e59ba32a7752feb55562b782fc5cf6623b3f33d7c584ef6d945f0f",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "sha256": "3270e9e8879fa3b0c7da913adc88d96edb484f92ad4a2fd6e06970f303d0874e",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-ADMIN-ROLE-AUDIT.ps1": {
    "sha256": "ccb2cffcb4a7a685782f5602868f338784f36f6b9557fc395182b4f1540941bb",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-OAUTH-CONSENT-AUDIT.ps1": {
    "sha256": "2680aea2ddca4bdabc0e203535f5982bf11685199e76895fdda61a964fa56e25",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-GUEST-USER-AUDIT.ps1": {
    "sha256": "482e2632abcf13141fabab0266ca1ad3496628b48bd56072d21507054ecc2a95",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-LICENSING-AUDIT.ps1": {
    "sha256": "4bcffc030d5f4bb26ef3f9349f7a215f7a6b2b6f58e3784713f1a038e5b785be",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "sha256": "ead045dcca94d9cb5dd623be7e29b1563fc3716370f32fffc7e85b71d82a8ca7",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/identity/GET-USER-SECURITY-SNAPSHOT.ps1": {
    "sha256": "52ac45625a7a12b01d9f1a27d34636423b791ec78d77ea7640d86edb66af2ff6",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "sha256": "b4fbb3ad10dcde3e5beb1c414890597de2fd969a4e9fe4149f70b7bea2c5f44c",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/mailbox/GET-ROOM-RESOURCE-ACCESS.ps1": {
    "sha256": "b7c2e01ae09248a8cfd83e997afaa9a17ef338d85d188ea6f96c83bc759c6cb0",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/tenant/GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "sha256": "ea78878fbb017dbbdf095955c983904cbac2141d6a10293077b7f7bcdd056626",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "sha256": "e9b65c7fc9da2a09b87f84618b0d2693681cc8f497eef0343de990dee202c7c1",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/tenant/GET-TENANT-DRIFT-REVIEW.ps1": {
    "sha256": "f473f3fffdf501b2b04604db04268f75670be319734b8c32da66bd1df45183ed",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "sha256": "cb834050cc7551dfa261f19ff53eb363e917de63d368884ef6f1964a20c84f47",
    "mode": "local",
    "services": []
  },
  "published-source/identity/INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "sha256": "bcaf79f5c432558ed746efd6667aff21cc0b7dc61a0d4c62e5cd444eeb402507",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/incident-response/ir-recover-validate.ps1": {
    "sha256": "c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "tools/git-handoff.ps1": {
    "sha256": "886a5782009fc8abf4825f997ccab38c0c1679a32b6653596089e038cf3ba22c",
    "mode": "local",
    "services": []
  },
  "tools/git-repo.ps1": {
    "sha256": "cd0c87313d27c17cd79a82f470991aad016583781066f856841cc251f245afdd",
    "mode": "local",
    "services": []
  },
  "tools/git-security.ps1": {
    "sha256": "3cba00d77603ffe94401fbda18953579b90492012be0446b08c6de806d5fe1e8",
    "mode": "local",
    "services": []
  },
  "tools/set-execution.ps1": {
    "sha256": "90464f2b844266bdf88c5956fc44dd34939cf7c8664ac19c90f4be4defec2bc4",
    "mode": "local",
    "services": []
  },
  "toys/attractor.ps1": {
    "sha256": "62820d67085b65d230bb28c4954259bd32bffd29f30aee8a6f9a2cdfcdfdc5aa",
    "mode": "local",
    "services": []
  },
  "toys/rain.ps1": {
    "sha256": "67ff5ccad0eb69510576920fd8b36accfb606a2b1cd3ddeb1ae75f021fda9bc9",
    "mode": "local",
    "services": []
  },
  "toys/static.ps1": {
    "sha256": "75f06611710a84f21522226fffebb3bf2e6a6b5d58383baf507ba6c69ddf19ca",
    "mode": "local",
    "services": []
  },
  "tools/SIGN-FOLDER-SCRIPTS.ps1": {
    "sha256": "9b2d82c75017899485b76d227e323deca66c6660534e83c1238938f058d454a1",
    "mode": "local",
    "services": []
  },
  "tools/GET-TERMINAL-READINESS-CHECK.ps1": {
    "sha256": "fcb2a3383b43915e88dc3e819ba6f573dafb2dc256b008d1d896535bb7dae991",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-FILE-INVENTORY.ps1": {
    "sha256": "acb04fd3968ef3a29356ef52583229a72926f7a6ed319b4b36bd01e56de28445",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-MAP-KIT.ps1": {
    "sha256": "330fb1fc8cc144b3f9cd23a0e3399a2f69d168b31b6a9fe27c255e0c77ffdf2b",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-SESSION-RESET.ps1": {
    "sha256": "4de135e684e778e091292f7fe56610ddee47739c15d34dda5367cbe3112a15bc",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-BASIC.ps1": {
    "sha256": "82ddf2ed63914b6a1eb40664f486783e59690799b8df19bf9f00fbd3dc142756",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-COBALT.ps1": {
    "sha256": "3d0dbac577cce716e5427a9b2635ee6cefe29a45955bc632cb8b4f2dd48fe343",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-SEAGLASS.ps1": {
    "sha256": "16153f1c1989834f659ec7c08546c454dd95bdc51abebb2f7afb684b70964fdf",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-SILICON-VALLEY.ps1": {
    "sha256": "1c732aa6c82182265dc02019c9805a7ac9faec56e7b3312e8d7b00c7d66dd60d",
    "mode": "local",
    "services": []
  },
  "tools/MANAGE-CERT-SIGNATURES.ps1": {
    "sha256": "11544fc1bdedfe8e1e7ff69c1abb084cd5001132c40178782bd21281150c2cb8",
    "mode": "local",
    "services": []
  }
});

