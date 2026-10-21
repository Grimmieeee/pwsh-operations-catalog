// Reviewed connection behavior; bound to exact downloadable source bytes.
window.FIELD_KIT_CONNECTION_GUIDANCE = Object.freeze({
  "published-source/tenant/GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "sha256": "df729d70508b81bf0328f0313d0de406e56f4204c3dc8460ef0ea8bb4eb91606",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/tenant/GET-STALE-SIGNIN-REVIEW.ps1": {
    "sha256": "27e94610728226f9c43f44631b4c9921fc6412ddf8d79f2e2617a7725c1a4fa6",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/INVOKE-DISABLE-ACCOUNTS.ps1": {
    "sha256": "a123394ca9a041cb7f49225b334ce6fe02637038c554944d1c222d325fa72287",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-DELETE-ACCOUNTS.ps1": {
    "sha256": "0831cf439bc477cae85d6b6a4f2e2eb1043d4e61d5d4e65964eaa7de658c0eef",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-ASSIGN-LICENSES.ps1": {
    "sha256": "b41987e2a5912652d1e01a953a7dea402c7c49e24d20fade2fddb9f9696478be",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/INVOKE-REMOVE-LICENSES.ps1": {
    "sha256": "0fb9b390bdc16c4e677661003145ac9ab7718c2abedf0f6b44f303971bee2e2c",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/RESOLVE-NAMES-TO-UPNS.ps1": {
    "sha256": "8b150fd6e093ecf1a4b2b77cc5856f18de47a0f101a8f7257f0eea4742d12f8d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/GET-ACCOUNT-STATUS.ps1": {
    "sha256": "94258427439cc292f33bd76e835b10a407218bc9136537874a9cd267f2e20b75",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/mailbox/GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "sha256": "c91680865f7bc992c7638f1a5c3e371a281ed52100a2a3fc979b87d8321af676",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/identity/GET-GROUP-MEMBERS.ps1": {
    "sha256": "5c7baa7d0551de2eb0c21650bb8943ca198697c94cef2f556a5ab458f7916d67",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/identity/GET-USER-GROUPS.ps1": {
    "sha256": "d0b71178ddca2eb793610f21d5f52266d454360ca848d7257ebb3347d6ec9bdd",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-REMOVE-USER-GROUPS.ps1": {
    "sha256": "8bc820639a1d6e1479e0b1c7a2a1f58953fb0eb5396f922628a73855b0e3fc54",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "sha256": "7ed4b8f50be401d4004b6ff4672d19bcad5ab6e7f47cf7bc3d0a3e144290f83d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-GROUP-OWNERS.ps1": {
    "sha256": "742d126522230364471ab8bee9bc83132e8589a2ff144199d66cfda4f366107a",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1": {
    "sha256": "3faaae2c396c8615499bbd47570ee57d9d3a04e56f5e7c7a4a53b1f4d627257b",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "sha256": "e9e75ef77efeb81017c8dcc6f3f05cd5deb4fb8eba90890560808406762f7fda",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-FORWARDING.ps1": {
    "sha256": "0e184a41bd351c391985118eb128eaefad0311ec691abe4933868e6af5a88d91",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/INVOKE-LITIGATION-HOLD.ps1": {
    "sha256": "1ea2ff740e1f5eb24ba4aafa92636fce025ed90ffbc4050e80ce5aedcb3568fe",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-INVOKE-EMAIL-RECOVERY.ps1": {
    "sha256": "375f096c481686d5933fee82ceac7e56e4b33482e9ffe13ea588325869861f5e",
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
    "sha256": "a5f17427b6cb03c31b790b922d8119c9107309b0bb8dabd773928d33a264a638",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-IP-TRACE.ps1": {
    "sha256": "acce3f018ebcd20c0e3b199bf5b7ffc7924b26c6d4c64d75a47faf8b89f031c1",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-TENANT-EMAIL-SEARCH.ps1": {
    "sha256": "1851ee0ec2ebbc086aed89fed3bf2e4d839005497262fb6bb264a4b62a5622d8",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "sha256": "dea6a298adb935521b5d3b06b73ff0e654612bc8a04881382ade57a7b483964f",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TIMELINE-BUILDER.ps1": {
    "sha256": "00892f3409549b4fe2bad0a0d234f54ec06d581e63487982f30dd050d2fa2d5e",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TOKEN-DECODE.ps1": {
    "sha256": "4b95de1355f8eb34b43a87e29e247e5da04541fb83b91ef0328f86918fa9f254",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TOKEN-REPLAY-CHECK.ps1": {
    "sha256": "a800a61cf9c7f9a2b34f02bb49c3764cbf8261d5cd0ad92a13f0cb544fd120c5",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "sha256": "3f365d6e8677b2f59f1e3fba81f038c6645dd0e1e3a95b28c95804b161f06009",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ]
  },
  "published-source/tenant/GET-APP-REGISTRATION-AUDIT.ps1": {
    "sha256": "76613d8367421f66d7c546b3543168109eadfec80618fa46905ad3a2b3403a5d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "sha256": "adebcd1ba46cb0e58a7ac4381547d2aa7f501a906b5c521d27ca0ac9121b6555",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-DEVICE-CODE-EXPOSURE.ps1": {
    "sha256": "9595b261ea55f5fc61dd562df2e5297cd8d3fa8bf587d0d61cce5535df93e27b",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "sha256": "0e9676a036af440268ac33d3007fa34c05505e2765462a7143b2caa208585721",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-MFA-SECURITY-AUDIT.ps1": {
    "sha256": "f7a9db6339cac2c6725261c00908713e7fb4017f4441c66c6118bc0cc360a5eb",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "sha256": "bf4d87b38d221c5e6b86fef69b10a1cb7c4d75e6fe8c5abe64ec5c99993f3e5d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "sha256": "1934bda28cce1b49450261c0bbf1333210ec8723842c81de9c0dc3d5796c6fa3",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SIGNIN-ANOMALIES.ps1": {
    "sha256": "dcde2b39589b9c740a7a9c20ff17cc59d8752cc555a9359f9d0210e18fa053b1",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TRANSPORT-RULES-AUDIT.ps1": {
    "sha256": "7c4ff63bee17b5669a05a76657f3cca0b5b3674b102ead014df742ae720c62ae",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/endpoint/JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "sha256": "231cef1b8c4ca32837fa4ece5cc04162eb1de0371f3fd69a6fd7aa839bd6f147",
    "mode": "local",
    "services": [
      "AD"
    ]
  },
  "published-source/endpoint/DEPLOY-TCPIP-PRINTER.ps1": {
    "sha256": "adcb0d7445bbc847c2f1d7a22dcf5c12c645a68a81036c38dd510c67bd3821d1",
    "mode": "local",
    "services": []
  },
  "published-source/endpoint/BACKUP-USER-PROFILE.ps1": {
    "sha256": "dd1d1e62acc1343f0c5010dc93ebd5cf29671ff42d9876580c3f1ef7b285988d",
    "mode": "local",
    "services": []
  },
  "published-source/utility/TEST-POWERSHELL-READINESS.ps1": {
    "sha256": "59b6730559b3916819789d913503c610a06bbabe86f1fd8a9e70f820106cd784",
    "mode": "local",
    "services": []
  },
  "published-source/utility/GET-FOLDER-INVENTORY.ps1": {
    "sha256": "de076936d25c2b448ecc638f12f65fee672c9ada27aac56ef41c1c0ab76507f5",
    "mode": "local",
    "services": []
  },
  "published-source/utility/INSTALL-M365-MODULES.ps1": {
    "sha256": "6c5fb208fea47d9588354590817362336e644bc4887127f317d4816161c0b4a2",
    "mode": "local",
    "services": []
  },
  "published-source/utility/TEST-SENSITIVE-DATA.ps1": {
    "sha256": "594d18150acb832080f13776581f6d8d8d21d3addc7e14aa8aea017b76e9b69e",
    "mode": "local",
    "services": []
  },
  "published-source/utility/RESET-M365-SESSION.ps1": {
    "sha256": "a08270181dc4ac7ac0cb78fd8f651701a40ce25b668342a4e0a829fb09246809",
    "mode": "local",
    "services": []
  },
  "published-source/utility/UPDATE-WINDOWS-APPS.ps1": {
    "sha256": "32fcfc1c298460301dc5fe7841bb5bddb768691e23f7c9f28270c5396349c3c3",
    "mode": "local",
    "services": []
  },
  "published-source/identity/GET-USER-PREDELETE-CHECK.ps1": {
    "sha256": "4ae5545f73829374e5b1500bd3ba8cc029e3f095e700e9ce76bf835d8a034107",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "sha256": "23a9db7bcacb8f388d2e71b3cc54b720a00b9d377af7c10bac263b32f0008b62",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-ADMIN-ROLE-AUDIT.ps1": {
    "sha256": "764cf4825fa98591a0ab0bde803f96568e1a1c2d8ed4585095eda2460a04aa6c",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-OAUTH-CONSENT-AUDIT.ps1": {
    "sha256": "3f18ee0289321bc6b7cb226c08f33c79c0e4844bc03884ea24a99180699f4251",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-GUEST-USER-AUDIT.ps1": {
    "sha256": "641555328872d02331f3153eb686b48bf4cf5b21f67c7a9919c0bbef0d75da61",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-LICENSING-AUDIT.ps1": {
    "sha256": "d9d7da1dc4f720953848f56fa4c68ae594c7b183ed3f07f623d511321a2aae07",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "sha256": "c0a1a2459471df298746940de9a997ee60514cbec0bb11a821f4c7e2233c66f6",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/identity/GET-USER-SECURITY-SNAPSHOT.ps1": {
    "sha256": "b9d8d41d6fe83eb0c5b3c8cb6d71989719d8622bc359116fc20618814399cff6",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "sha256": "342829ae9c8df76225bdee4e0c76776aabb76a43a3c5756363a6add984ca0666",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/mailbox/GET-ROOM-RESOURCE-ACCESS.ps1": {
    "sha256": "476e8e8458b73432ec3c1e5d90be596b6472cece0e43c79cddc4b1de1693e1ad",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/tenant/GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "sha256": "90eadb894e2aa8ac36f62047a4c4aadcac67aa468c8bbbf583ec0992e6fc6e9c",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "sha256": "4a9291b9f133ce2bd5ec2f563fb6101aaf5857f9c9d88536853788ce1d56e804",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/tenant/GET-TENANT-DRIFT-REVIEW.ps1": {
    "sha256": "f5f1fdd5b2d6739ecc07989244e5da3f36811d1589109d4e7892609e937abfc2",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "sha256": "6b3deeb1c1cefe468ec8c46443fe4b235ea151daf697e9b06f7e7dde73860ae0",
    "mode": "local",
    "services": []
  },
  "published-source/identity/INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "sha256": "f3ada8c4e78014fbe24a23ea569863716db83e28ade000299fd1f41e415ad2d1",
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
    "sha256": "396dc02a8e7a54fc8a80bfdd3257d789ba2b33b5ae16d47ae67032b41dd543c5",
    "mode": "local",
    "services": []
  },
  "tools/git-repo.ps1": {
    "sha256": "a7bf40b9e18e0d772a484e728fec4b7604e44480e0906d86458d4ee82c81c4f1",
    "mode": "local",
    "services": []
  },
  "tools/git-security.ps1": {
    "sha256": "e99843711cd1f33cbd7a2851e631c0593ffa2378c01e675ced78a91cfb764279",
    "mode": "local",
    "services": []
  },
  "tools/set-execution.ps1": {
    "sha256": "c6c24e9e22bf78a342ab9bf01c0fbaf61051f1114f7f2b49157b082235a159a9",
    "mode": "local",
    "services": []
  },
  "toys/attractor.ps1": {
    "sha256": "1268680342075976f80599213dd97d25abc2af741a07a7f5de2ceab2c2ba4cc6",
    "mode": "local",
    "services": []
  },
  "toys/rain.ps1": {
    "sha256": "f793a1a68a8245527597522077f40dda3eeb209bf9c6ad1164f0dde5ef9daf96",
    "mode": "local",
    "services": []
  },
  "toys/static.ps1": {
    "sha256": "4aa3ae630d9631f11d110f78925c6e112508b3ccc7ba703f833537bb3c9394e0",
    "mode": "local",
    "services": []
  },
  "tools/SIGN-FOLDER-SCRIPTS.ps1": {
    "sha256": "2890218ee6951f81e46e0dd5cbc5b4ed38b80ccce031d0b04ad9c3561e654851",
    "mode": "local",
    "services": []
  },
  "tools/GET-TERMINAL-READINESS-CHECK.ps1": {
    "sha256": "aff60902758c4085701a22dc0ab5eeb0bd0f4db075a68d4c20164294226c70fb",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-FILE-INVENTORY.ps1": {
    "sha256": "3fbe443e0b5033489d2f7be78897ee6c7992448a4a86383b331f58166cfb2202",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-MAP-KIT.ps1": {
    "sha256": "e0bd93584585d1f47d550da919ed3f18f7e99c338d07f04e85e660ad9310c92a",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-SESSION-RESET.ps1": {
    "sha256": "2fa5b247f31b2dfe29bbed17ec9ffe576e53dbe3ce3e7ffb03f8328c7843dc07",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-BASIC.ps1": {
    "sha256": "fff5bd842f9f9c0b3e0f4ab27c1ba8d8bc3bf74954b4c2aa4ada22c4fe513bc0",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-COBALT.ps1": {
    "sha256": "0747cc7f881a84169801f4318c35e6bec8335db224cb5014178c5bd767d28486",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-SEAGLASS.ps1": {
    "sha256": "460efef8263380e50352a1f7acdc43284e9234cb6662bd40ed005f5578c1763f",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-SILICON-VALLEY.ps1": {
    "sha256": "161ca2b09e7798fa07b240896f1aa4b75bb0fba1073bc5e776ad0ba48bc3bd98",
    "mode": "local",
    "services": []
  },
  "tools/MANAGE-CERT-SIGNATURES.ps1": {
    "sha256": "d28176159f671ed1fe1e521f422a89f8de92f5ec032067e16f46156549d683fb",
    "mode": "local",
    "services": []
  }
});
