// Source-reviewed connection paths. Re-review when the published source hash changes.
window.FIELD_KIT_CONNECTION_GUIDANCE = Object.freeze({
  "published-source/tenant/GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "sha256": "19b092079ccc61f4de9cbc6510b3a57f290f520abb08ab2b5db4089457fcc570",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/tenant/GET-STALE-SIGNIN-REVIEW.ps1": {
    "sha256": "2c962dbc7d1ab56ef3a9968636e679c99ca482680ea7af4bdf859fb8a3c063ac",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/INVOKE-DISABLE-ACCOUNTS.ps1": {
    "sha256": "c6b31ea701d1e5a7886a73a125b67e726e66eb01d99e1c8ee8de9d4e0fae274e",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-DELETE-ACCOUNTS.ps1": {
    "sha256": "0fbb42bb1db268b3f6e4b74a21af7008528b5acc2e684cccdf3696122fcb6bd2",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-ASSIGN-LICENSES.ps1": {
    "sha256": "f29671426b25b460169d4f8c7d0fe33d9d4ae5f525f61f24a08dcf201f248a22",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/INVOKE-REMOVE-LICENSES.ps1": {
    "sha256": "c35632545c2818350704c9b9652bd9fd6bd2945dd5b347427800bcf04d67a038",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/RESOLVE-NAMES-TO-UPNS.ps1": {
    "sha256": "9f0560d35c0941ff0723d400129f20b345673e0d9b6e4c751de48529ca6f232c",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/identity/GET-ACCOUNT-STATUS.ps1": {
    "sha256": "4a6e6aed3b612556706c107b667911ef79a4c6a47074d7054ab907cc3ca3dbfc",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/mailbox/GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "sha256": "e4046dacdf671ce73b213bc570b74cc238b9ea60d1bf5ba5a3c5f50dc65f07a9",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/identity/GET-GROUP-MEMBERS.ps1": {
    "sha256": "ba29a8c30f170c87b08a453fdfe73f6108bddfc69033f17a6270875ecc684dbd",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/identity/GET-USER-GROUPS.ps1": {
    "sha256": "a423d1f10e9bcfee903c646d95cf5dbf2142eda04d014e0521a29114c1b55469",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-REMOVE-USER-GROUPS.ps1": {
    "sha256": "b5a8a4be4b79e1ef77fc8f75eaef88b70d5f50ffd1dd47bccf1e21f1b35c6ecd",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "sha256": "5d0d109515d67948673e6f3058c068899a8f74f06cba74908eeb961dd0612cd4",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-GROUP-OWNERS.ps1": {
    "sha256": "6bd4a410ed549559c63b9c33d100051dbd6bfbc0b574dc61a396917af62cfa6f",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1": {
    "sha256": "a88851cc5a2e69684d26f90c8f028626daf986c57ca5938e14b02ea29ceed052",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "sha256": "ab87c10d108dff487da2d4cf762e0081ab88f6e501686db6042e301317363790",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/GET-MAILBOX-FORWARDING.ps1": {
    "sha256": "b99f2dc2c2b3eb9e4feff190f3fae7951dee4bfa2d95909eaad582457f9f768a",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/INVOKE-LITIGATION-HOLD.ps1": {
    "sha256": "c0d3bb2f0bf4857f45d6f6d52afb80b8171f4fc700d2e2999ec716b21df2cccf",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-INVOKE-EMAIL-RECOVERY.ps1": {
    "sha256": "e00946f377bdd4b0e9eb87d04025906763bb8c7307ecdaf87f5016f006ea6aaf",
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
    "sha256": "5f80f8a9a3af0a250963e48deeebb6ce278b392140a7fc82a01da396c3e3bf73",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-IP-TRACE.ps1": {
    "sha256": "30ea759b710a12b3650b48191b2fe3dc123ebbed4c7798d4c6a934d0702689d3",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-TENANT-EMAIL-SEARCH.ps1": {
    "sha256": "dbb53c592a523fdf2a2c94dd166296afe6a9f482ec4372c2d3f551af56ea797e",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/incident-response/IR-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "sha256": "a9126fcc537a71b9471d49ecfe5f714ede93bc5e1306b3eee9fe9ea7f014859a",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TIMELINE-BUILDER.ps1": {
    "sha256": "fb6e000a57b548f59fbc4f9317df3dac0ab61756c97223784d7b2e54a6d70c40",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TOKEN-DECODE.ps1": {
    "sha256": "179e01c20af4ad72faabd69c2567ccff9fa1d40a5ca3acf497544ba6d4849372",
    "mode": "local",
    "services": []
  },
  "published-source/incident-response/IR-GET-TOKEN-REPLAY-CHECK.ps1": {
    "sha256": "2627de9b2b13220ef6de444ac4f98f9a5b0481f55a68dd4fbaf61ecc58be28e3",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "sha256": "9df9711e8cdf8542a753a451b748e22d04a3448a3e88705f366fabacc3aae176",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ]
  },
  "published-source/tenant/GET-APP-REGISTRATION-AUDIT.ps1": {
    "sha256": "6948e5a25a54c218a5114a366a59f839454b64050b3c5726093506fa9e28f0a0",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "sha256": "e4bf3fe87b7acc39ee21eb89a09d158568330a799755c8b553fe325d4dd34a45",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-DEVICE-CODE-EXPOSURE.ps1": {
    "sha256": "4ac8a6ee2c3f5091ee24b47f3f91f9b12888ddeda0ed86308a9ecc7a7f1919bf",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "sha256": "e90b4af2ff9b35a32498ffa93836bcc8f502aa5a8e89ba3f9e3dc520a7f1be62",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-MFA-SECURITY-AUDIT.ps1": {
    "sha256": "91aef944427d3e85f94874014a2f6dd726781ba9eb9931e2b9565d11a6f0b00c",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "sha256": "649b23416b9ed9c9e78c60fd2867c2e47c48b12e5ae73e80013aafec357b3efa",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "sha256": "3a45fdde22e453f23a1bd4a269daee6d5ed3334d19250ebe84701ec6691b289f",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-SIGNIN-ANOMALIES.ps1": {
    "sha256": "b87f694333ec632f76bc5edc8a6c8210fffccadac38c4bf955e5dac95cd48e91",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TRANSPORT-RULES-AUDIT.ps1": {
    "sha256": "38ca6289d157f33a57a60b316a3a0f1de15de8f07310b71eb977d1efbe86609f",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/endpoint/JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "sha256": "5e089c864ee6a869b050ccdfd7b6666b683eae845d188f8d1e3ba3c27d4d8f12",
    "mode": "local",
    "services": [
      "AD"
    ]
  },
  "published-source/endpoint/DEPLOY-TCPIP-PRINTER.ps1": {
    "sha256": "90a72cce1ace9af8d44ae02eeebc0cd47531b7c0b7b24e6e0a87e4c0368ee043",
    "mode": "local",
    "services": []
  },
  "published-source/endpoint/BACKUP-USER-PROFILE.ps1": {
    "sha256": "efdbdc7eab4effa096645be533d046ff2d8c3170fcdcc69186df405bd5dd0367",
    "mode": "local",
    "services": []
  },
  "published-source/utility/TEST-POWERSHELL-READINESS.ps1": {
    "sha256": "b38f3eb165ac360eef390990dd6d2b4ee89f41916d3da54822f625b7d2c77612",
    "mode": "local",
    "services": []
  },
  "published-source/utility/GET-FOLDER-INVENTORY.ps1": {
    "sha256": "fce9d9db96b42fe9b352b867afdd1a370c400f4d6f67c1a58dd7d50aefde9ec6",
    "mode": "local",
    "services": []
  },
  "published-source/utility/INSTALL-M365-MODULES.ps1": {
    "sha256": "a143a317bb85b76c39a5768b7b5cad4096d4acce4d5509465c01be820b37ff24",
    "mode": "local",
    "services": []
  },
  "published-source/utility/TEST-SENSITIVE-DATA.ps1": {
    "sha256": "2c28a71fe9195f3e032c0386ed10c3ee5d7fcdd2385839b8b74ee95dc8ba20d0",
    "mode": "local",
    "services": []
  },
  "published-source/utility/RESET-M365-SESSION.ps1": {
    "sha256": "203ba913f1d8d1d72544ecf950c0b346e4e92244a9e6b75730095339c858a16a",
    "mode": "local",
    "services": []
  },
  "published-source/utility/UPDATE-WINDOWS-APPS.ps1": {
    "sha256": "aa949908eb989f4aedf0569c3c4c7c8111ae2d1cca1895754de167669ee1a25d",
    "mode": "local",
    "services": []
  },
  "published-source/identity/GET-USER-PREDELETE-CHECK.ps1": {
    "sha256": "922a2d16bcf7c753193e14296f9bf67715cf3e14ec8dd1fdeec8d9a31e10e9d2",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/identity/INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "sha256": "52c6ce8dc1af2323b9dcc6c831cdd211b555ae44280417181599290212fcf7bd",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-ADMIN-ROLE-AUDIT.ps1": {
    "sha256": "b660a543b1044c58c74be40609c38caf40eb1cac040fcf87a77dea5e7d41fe78",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-OAUTH-CONSENT-AUDIT.ps1": {
    "sha256": "9b26065a085a5376d6fdd0312783f037505ac496d39310b062eb62add6401f65",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-GUEST-USER-AUDIT.ps1": {
    "sha256": "fe654017667917540bac5d099875379eb8760f24c448f9345fff626bf1894410",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-LICENSING-AUDIT.ps1": {
    "sha256": "eca8f567c83f132e3c0ba263e633cfcf2552e938b9c232bf9de2860fd17474d0",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "sha256": "85a1c9164ba0d0c0661b6c3e7ecb197f4ac7ab2865d3436de3a5f48f76844880",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/identity/GET-USER-SECURITY-SNAPSHOT.ps1": {
    "sha256": "f09c4716f0a801c7c6fd02328975142ed86e3c4307ea11f540b9c22b7195e6ab",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/tenant/GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "sha256": "fc9963bdd53137c6dcee21f8b9c3f5f20bdb3fb64c110e67a148bd0651eb256c",
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
    "sha256": "79cf872432e023f6eb0036e355a71fab156ec79489e84344be7eee0b82e68c15",
    "mode": "auto",
    "services": [
      "EXO"
    ]
  },
  "published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "sha256": "bf750de1d4d0f7b2baf30d3f73254106ca09b210d5a4d4aea728b2ad16298de8",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ]
  },
  "published-source/tenant/GET-TENANT-DRIFT-REVIEW.ps1": {
    "sha256": "668267cbadfc88d212a8708c77f0a5454343a0e4222e2e1cfaff2a44e84afb54",
    "mode": "auto",
    "services": [
      "GRAPH"
    ]
  },
  "published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "sha256": "c795ac5d107db35eed303dff231cedbee577824c6fe8b93285ad5895a97cd44b",
    "mode": "local",
    "services": []
  },
  "published-source/identity/INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "sha256": "7ab0323cef10c5cc09399432ccdf2417d3401f2f422e6200dc35ebfc4399e0c5",
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
    "sha256": "6783255cf5418e432da3677406f281460ab6538a1628f47b5c9ea3b558de70a6",
    "mode": "local",
    "services": []
  },
  "tools/git-repo.ps1": {
    "sha256": "4ec1ebc30c976a410c5dc616f0671727c34278b777b323e671189553f0b1aa7a",
    "mode": "local",
    "services": []
  },
  "tools/git-security.ps1": {
    "sha256": "3cba00d77603ffe94401fbda18953579b90492012be0446b08c6de806d5fe1e8",
    "mode": "local",
    "services": []
  },
  "tools/set-execution.ps1": {
    "sha256": "fe6e46d409518b856bf52ee985d4298e41376676d2e984af8092c0ef316bf09f",
    "mode": "local",
    "services": []
  },
  "toys/attractor.ps1": {
    "sha256": "2adc04c32a4d20820577933c463d07642c8be18f9de17c739a617ffcc55c68a5",
    "mode": "local",
    "services": []
  },
  "toys/rain.ps1": {
    "sha256": "46d67ed7200597e89de91d76dbbceedb63f202852972070f18db6ea13f56a53c",
    "mode": "local",
    "services": []
  },
  "toys/static.ps1": {
    "sha256": "4e4db77166ad4f60ceb3e50b5aa3685719d9d84805ec93dbd729005074d86e1f",
    "mode": "local",
    "services": []
  },
  "tools/SIGN-FOLDER-SCRIPTS.ps1": {
    "sha256": "b8a7e1411654e6f9aa358cf6def278b5df4d1f4ccef8c4d18549609a32f50b27",
    "mode": "local",
    "services": []
  },
  "tools/GET-TERMINAL-READINESS-CHECK.ps1": {
    "sha256": "e9d4d5f1974f2af40c01c23e4e4cf925f232baba8bd7f9b063f0c78110958c01",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-FILE-INVENTORY.ps1": {
    "sha256": "c50633fd4f92e32f2401bf25c056d88dab2afee2296de1abf3976a32ef2e73d4",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-MAP-KIT.ps1": {
    "sha256": "22046718b32efd8f0d8d5e27bbccb78836ee52262159aa215796e6df5ff7e418",
    "mode": "local",
    "services": []
  },
  "tools/INVOKE-SESSION-RESET.ps1": {
    "sha256": "0f183c52bd1ca24dcccba318913eac70eb89848cbe32ef42fe631c6270744446",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-BASIC.ps1": {
    "sha256": "a3959c764ee2c0b4e155f89b5cf28faed7db74f54f2b277e2152b453c392827f",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-COBALT.ps1": {
    "sha256": "01b14b7f32a176f6f107ea73c1421a40d967dd634957f2fb849e94bedab92347",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-SEAGLASS.ps1": {
    "sha256": "4b67f87297ce80e2f4f34d4bade7f784005ee4788686046968022e075df167c0",
    "mode": "local",
    "services": []
  },
  "toys/SET-THEME-SILICON-VALLEY.ps1": {
    "sha256": "f8de1e1fc05f78dbabfdaf6d156ebbdd13049cc2ff7067e177e3c80bb63050aa",
    "mode": "local",
    "services": []
  },
  "tools/MANAGE-CERT-SIGNATURES.ps1": {
    "sha256": "1ce17ac14c10b3af62b553e2fde13423c039f24edea5e55eb2a86133cd5d7066",
    "mode": "local",
    "services": []
  }
});

