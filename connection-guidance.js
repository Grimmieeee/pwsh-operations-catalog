// Reviewed connection behavior and source-bound connector requirements.
window.FIELD_KIT_CONNECTION_GUIDANCE = Object.freeze({
  "published-source/tenant/GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "sha256": "df729d70508b81bf0328f0313d0de406e56f4204c3dc8460ef0ea8bb4eb91606",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "ExchangeOnlineManagement"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "AuditLog.Read.All",
        "Group.Read.All"
      ],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Get-Mailbox",
        "Get-MailboxForwardingReview",
        "Get-Recipient"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-STALE-SIGNIN-REVIEW.ps1": {
    "sha256": "27e94610728226f9c43f44631b4c9921fc6412ddf8d79f2e2617a7725c1a4fa6",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "AuditLog.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/INVOKE-DISABLE-ACCOUNTS.ps1": {
    "sha256": "a123394ca9a041cb7f49225b334ce6fe02637038c554944d1c222d325fa72287",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.ReadWrite.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/INVOKE-DELETE-ACCOUNTS.ps1": {
    "sha256": "0831cf439bc477cae85d6b6a4f2e2eb1043d4e61d5d4e65964eaa7de658c0eef",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Users",
        "Microsoft.Graph.Identity.DirectoryManagement"
      ],
      "scopes": [
        "User.ReadWrite.All",
        "Organization.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": true,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/INVOKE-ASSIGN-LICENSES.ps1": {
    "sha256": "b41987e2a5912652d1e01a953a7dea402c7c49e24d20fade2fddb9f9696478be",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.ReadWrite.All",
        "Directory.Read.All",
        "Organization.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/INVOKE-REMOVE-LICENSES.ps1": {
    "sha256": "0fb9b390bdc16c4e677661003145ac9ab7718c2abedf0f6b44f303971bee2e2c",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.ReadWrite.All",
        "Directory.Read.All",
        "Organization.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/RESOLVE-NAMES-TO-UPNS.ps1": {
    "sha256": "8b150fd6e093ecf1a4b2b77cc5856f18de47a0f101a8f7257f0eea4742d12f8d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/GET-ACCOUNT-STATUS.ps1": {
    "sha256": "94258427439cc292f33bd76e835b10a407218bc9136537874a9cd267f2e20b75",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "AuditLog.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/mailbox/GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "sha256": "c91680865f7bc992c7638f1a5c3e371a281ed52100a2a3fc979b87d8321af676",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-DistributionGroup",
        "Get-DistributionGroupMember"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/GET-GROUP-MEMBERS.ps1": {
    "sha256": "5c7baa7d0551de2eb0c21650bb8943ca198697c94cef2f556a5ab458f7916d67",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Groups",
        "ExchangeOnlineManagement"
      ],
      "scopes": [
        "Group.Read.All",
        "User.Read.All"
      ],
      "exchangeCmdlets": [
        "Get-DistributionGroup",
        "Get-DistributionGroupMember"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/GET-USER-GROUPS.ps1": {
    "sha256": "d0b71178ddca2eb793610f21d5f52266d454360ca848d7257ebb3347d6ec9bdd",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Group.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": true,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/INVOKE-REMOVE-USER-GROUPS.ps1": {
    "sha256": "8bc820639a1d6e1479e0b1c7a2a1f58953fb0eb5396f922628a73855b0e3fc54",
    "mode": "auto",
    "services": [
      "GRAPH",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Group.Read.All",
        "GroupMember.ReadWrite.All"
      ],
      "exchangeCmdlets": [],
      "ad": true,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "sha256": "7ed4b8f50be401d4004b6ff4672d19bcad5ab6e7f47cf7bc3d0a3e144290f83d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Group.ReadWrite.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-TENANT-GROUP-OWNERS.ps1": {
    "sha256": "dc04a5c13230de80a767d325a6739c3df6240618d20e6419315cb96a43f224b0",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Groups",
        "ExchangeOnlineManagement"
      ],
      "scopes": [
        "Group.Read.All",
        "User.Read.All"
      ],
      "exchangeCmdlets": [
        "Get-DistributionGroup",
        "Get-Recipient",
        "Get-UnifiedGroup"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1": {
    "sha256": "76535edd6d3e922cc44decedba707203716788afa4bdabbf68579549a57752e6",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-InboxRule",
        "Get-Mailbox",
        "Get-MailboxInputs",
        "Get-MailboxPermission",
        "Get-Recipient",
        "Get-RecipientPermission"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/mailbox/GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "sha256": "e9e75ef77efeb81017c8dcc6f3f05cd5deb4fb8eba90890560808406762f7fda",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Get-CASMailbox",
        "Get-EXOMailboxStatistics",
        "Get-InboxRule",
        "Get-Mailbox",
        "Get-MailboxPermission",
        "Get-MailboxStatistics",
        "Get-OrganizationConfig",
        "Get-Recipient",
        "Get-RecipientPermission"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/mailbox/GET-MAILBOX-FORWARDING.ps1": {
    "sha256": "0e184a41bd351c391985118eb128eaefad0311ec691abe4933868e6af5a88d91",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-InboxRule",
        "Get-Mailbox",
        "Get-MailboxInputs",
        "Get-Recipient"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/mailbox/INVOKE-LITIGATION-HOLD.ps1": {
    "sha256": "1ea2ff740e1f5eb24ba4aafa92636fce025ed90ffbc4050e80ce5aedcb3568fe",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Get-Mailbox",
        "Set-Mailbox"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-INVOKE-EMAIL-RECOVERY.ps1": {
    "sha256": "bbbe2551ba6054995d4caa517e23a32711c0afbd4b7becbf2a5575662409482f",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Mail.ReadWrite.Shared"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-RISK-ASSESSMENT.ps1": {
    "sha256": "94526ec8ea67e88d9373d1cdb9beadf7ec4992b80cafcd4a97797c2a10c488f4",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "ExchangeOnlineManagement"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "UserAuthenticationMethod.Read.All",
        "AuditLog.Read.All",
        "Policy.Read.All",
        "User.RevokeSessions.All",
        "User.EnableDisableAccount.All",
        "User-PasswordProfile.ReadWrite.All",
        "DelegatedPermissionGrant.ReadWrite.All"
      ],
      "exchangeCmdlets": [
        "Get-RecipientAddress"
      ],
      "ad": false,
      "sharedSession": true,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-CONTAIN-ERADICATE.ps1": {
    "sha256": "c8b857d6191a6bceecb651413552cad0bbc8a421046bfe2a95390728cb89ce10",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "ExchangeOnlineManagement"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "UserAuthenticationMethod.Read.All",
        "AuditLog.Read.All",
        "Policy.Read.All",
        "User.RevokeSessions.All",
        "User.EnableDisableAccount.All",
        "User-PasswordProfile.ReadWrite.All",
        "DelegatedPermissionGrant.ReadWrite.All"
      ],
      "exchangeCmdlets": [
        "Get-MailboxAccessItems",
        "Get-MailboxObject",
        "Get-MailboxState"
      ],
      "ad": false,
      "sharedSession": true,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-GET-DATA-EXFIL-ACTIVITY.ps1": {
    "sha256": "1fa5c320ff44327b602d61a94ba5a76b9571b51fdbf36c77be0c59e34795fad1",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Search-UnifiedAuditLog"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-GET-IP-TRACE.ps1": {
    "sha256": "a97b049fad9c2a2f7f4344bc90a68689d1e1d5c4f720f2b6533b5106ae69970a",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Search-UnifiedAuditLog"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-GET-TENANT-EMAIL-SEARCH.ps1": {
    "sha256": "3a78895cbec147f408f82929e720c7e527c8bd3f18dad6d86c1e31ee1c868043",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Get-MessageTraceV2"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "sha256": "e0864cdd7dd81324a3b1a71fbf80841c14d3bd86d0ca7abb100416b4a243461e",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/incident-response/BEC-GET-TIMELINE-BUILDER.ps1": {
    "sha256": "a80ca2ee465da49ebb7d38b6728265be427d93a4aa7eb129d3e18f202a4b5ecf",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/incident-response/BEC-GET-TOKEN-DECODE.ps1": {
    "sha256": "809933ffd6759b71b20324825887e7d5b1530e1eecce8d8d0cd92c3ce5a57742",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/incident-response/BEC-GET-TOKEN-REPLAY-CHECK.ps1": {
    "sha256": "aacd5c9a0c91ecbd16ceedaa14b433aba25f882f3752efd903996bfc95dbfbde",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "AuditLog.Read.All",
        "IdentityRiskEvent.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "sha256": "3f365d6e8677b2f59f1e3fba81f038c6645dd0e1e3a95b28c95804b161f06009",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "ExchangeOnlineManagement"
      ],
      "scopes": [
        "AuditLog.Read.All",
        "User.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [
        "Get-Mailbox"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-APP-REGISTRATION-AUDIT.ps1": {
    "sha256": "76613d8367421f66d7c546b3543168109eadfec80618fa46905ad3a2b3403a5d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Application.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "sha256": "adebcd1ba46cb0e58a7ac4381547d2aa7f501a906b5c521d27ca0ac9121b6555",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Policy.Read.ConditionalAccess",
        "Directory.Read.All",
        "User.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-DEVICE-CODE-EXPOSURE.ps1": {
    "sha256": "9595b261ea55f5fc61dd562df2e5297cd8d3fa8bf587d0d61cce5535df93e27b",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Policy.Read.ConditionalAccess",
        "AuditLog.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "sha256": "0e9676a036af440268ac33d3007fa34c05505e2765462a7143b2caa208585721",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "Application.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-MFA-SECURITY-AUDIT.ps1": {
    "sha256": "da69d7308448b31477b9de6ff104257a891562902ec0142a5b053b70482d73a5",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "AuditLog.Read.All",
        "UserAuthenticationMethod.Read.All",
        "Policy.Read.ConditionalAccess"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": true
    }
  },
  "published-source/tenant/GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "sha256": "bf4d87b38d221c5e6b86fef69b10a1cb7c4d75e6fe8c5abe64ec5c99993f3e5d",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "SecurityEvents.Read.All",
        "SecurityActions.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "sha256": "7f300774005a7ba46d354c17b02cec9f09ca34863edaf8b057159cca7bef5885",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Application.Read.All",
        "Directory.Read.All",
        "User.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-SIGNIN-ANOMALIES.ps1": {
    "sha256": "dcde2b39589b9c740a7a9c20ff17cc59d8752cc555a9359f9d0210e18fa053b1",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "AuditLog.Read.All",
        "User.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-TRANSPORT-RULES-AUDIT.ps1": {
    "sha256": "7c4ff63bee17b5669a05a76657f3cca0b5b3674b102ead014df742ae720c62ae",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Get-TransportRule"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/endpoint/JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "sha256": "231cef1b8c4ca32837fa4ece5cc04162eb1de0371f3fd69a6fd7aa839bd6f147",
    "mode": "local",
    "services": [
      "AD"
    ],
    "connector": null
  },
  "published-source/endpoint/DEPLOY-TCPIP-PRINTER.ps1": {
    "sha256": "adcb0d7445bbc847c2f1d7a22dcf5c12c645a68a81036c38dd510c67bd3821d1",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/endpoint/BACKUP-USER-PROFILE.ps1": {
    "sha256": "dd1d1e62acc1343f0c5010dc93ebd5cf29671ff42d9876580c3f1ef7b285988d",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/utility/TEST-POWERSHELL-READINESS.ps1": {
    "sha256": "fee19c4cac0b5638a8f6515eb4be8734135c997d63c4b21e7f71b33a8a21e314",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/utility/GET-FOLDER-INVENTORY.ps1": {
    "sha256": "218d4e788913c6a6d8d6578d8b1912cf7f68a8c4687ecaf6d557bbd4ea26cd60",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/utility/INSTALL-M365-MODULES.ps1": {
    "sha256": "6c5fb208fea47d9588354590817362336e644bc4887127f317d4816161c0b4a2",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/utility/TEST-SENSITIVE-DATA.ps1": {
    "sha256": "594d18150acb832080f13776581f6d8d8d21d3addc7e14aa8aea017b76e9b69e",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/utility/RESET-M365-SESSION.ps1": {
    "sha256": "a08270181dc4ac7ac0cb78fd8f651701a40ce25b668342a4e0a829fb09246809",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/utility/UPDATE-WINDOWS-APPS.ps1": {
    "sha256": "32fcfc1c298460301dc5fe7841bb5bddb768691e23f7c9f28270c5396349c3c3",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/identity/GET-USER-PREDELETE-CHECK.ps1": {
    "sha256": "4ae5545f73829374e5b1500bd3ba8cc029e3f095e700e9ce76bf835d8a034107",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement",
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Group.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [
        "Get-DistributionGroup",
        "Get-InboxRule",
        "Get-Mailbox",
        "Get-MailboxPermission",
        "Get-MailboxStatistics",
        "Get-Recipient",
        "Get-RecipientPermission",
        "Get-TransportRule"
      ],
      "ad": true,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "sha256": "23a9db7bcacb8f388d2e71b3cc54b720a00b9d377af7c10bac263b32f0008b62",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Policy.ReadWrite.AuthenticationMethod",
        "UserAuthenticationMethod.Read.All",
        "User.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-ADMIN-ROLE-AUDIT.ps1": {
    "sha256": "764cf4825fa98591a0ab0bde803f96568e1a1c2d8ed4585095eda2460a04aa6c",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Directory.Read.All",
        "RoleManagement.Read.Directory",
        "User.Read.All",
        "AuditLog.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-OAUTH-CONSENT-AUDIT.ps1": {
    "sha256": "3f18ee0289321bc6b7cb226c08f33c79c0e4844bc03884ea24a99180699f4251",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Application.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-GUEST-USER-AUDIT.ps1": {
    "sha256": "641555328872d02331f3153eb686b48bf4cf5b21f67c7a9919c0bbef0d75da61",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "AuditLog.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-TENANT-LICENSING-AUDIT.ps1": {
    "sha256": "d9d7da1dc4f720953848f56fa4c68ae594c7b183ed3f07f623d511321a2aae07",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "Organization.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "sha256": "c0a1a2459471df298746940de9a997ee60514cbec0bb11a821f4c7e2233c66f6",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-InboxRule",
        "Get-Mailbox"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/identity/GET-USER-SECURITY-SNAPSHOT.ps1": {
    "sha256": "b9d8d41d6fe83eb0c5b3c8cb6d71989719d8622bc359116fc20618814399cff6",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "UserAuthenticationMethod.Read.All",
        "AuditLog.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-TENANT-SECURITY-SNAPSHOT.ps1": {
    "sha256": "342829ae9c8df76225bdee4e0c76776aabb76a43a3c5756363a6add984ca0666",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Organization.Read.All",
        "User.Read.All",
        "AuditLog.Read.All",
        "Directory.Read.All",
        "RoleManagement.Read.Directory",
        "Policy.Read.ConditionalAccess",
        "DelegatedPermissionGrant.Read.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/mailbox/GET-ROOM-RESOURCE-ACCESS.ps1": {
    "sha256": "476e8e8458b73432ec3c1e5d90be596b6472cece0e43c79cddc4b1de1693e1ad",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-Mailbox",
        "Get-MailboxPermission",
        "Get-Recipient"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1": {
    "sha256": "90eadb894e2aa8ac36f62047a4c4aadcac67aa468c8bbbf583ec0992e6fc6e9c",
    "mode": "auto",
    "services": [
      "EXO"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement"
      ],
      "scopes": [],
      "exchangeCmdlets": [
        "Get-Mailbox",
        "Get-MailboxPermission",
        "Get-Recipient",
        "Get-RecipientPermission"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1": {
    "sha256": "c50e6a31dbf37dea44f651d4cfdced99ba4f3ce053a8ec3e75edb1a8f4fb504d",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication",
        "ExchangeOnlineManagement"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All"
      ],
      "exchangeCmdlets": [
        "Get-AcceptedDomain",
        "Get-Mailbox",
        "Get-MailboxPermission",
        "Get-Recipient",
        "Get-RecipientPermission",
        "Remove-MailboxPermission",
        "Remove-RecipientPermission",
        "Set-Mailbox"
      ],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/tenant/GET-TENANT-DRIFT-REVIEW.ps1": {
    "sha256": "f5f1fdd5b2d6739ecc07989244e5da3f36811d1589109d4e7892609e937abfc2",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "Directory.Read.All",
        "Application.Read.All",
        "Policy.Read.All",
        "RoleAssignmentSchedule.Read.Directory",
        "RoleEligibilitySchedule.Read.Directory"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "sha256": "7af474157506fd00c85b064ec037e09286c7776e4b088b28e8af36d6f3cbc85d",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/identity/INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "sha256": "40abec4baa9461a7ce2f60159d747340023985fe505191d1d7e530873d7b674a",
    "mode": "auto",
    "services": [
      "GRAPH"
    ],
    "connector": {
      "modules": [
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "User-PasswordProfile.ReadWrite.All"
      ],
      "exchangeCmdlets": [],
      "ad": false,
      "sharedSession": false,
      "conditionalAccess": false
    }
  },
  "published-source/incident-response/BEC-RECOVER-VALIDATE.ps1": {
    "sha256": "1b21a21f15d6618c0964c37ab21e0c167cfba5616efe8d108dbb18ac1aa0ce4e",
    "mode": "auto",
    "services": [
      "GRAPH",
      "EXO",
      "AD"
    ],
    "connector": {
      "modules": [
        "ExchangeOnlineManagement",
        "Microsoft.Graph.Authentication"
      ],
      "scopes": [
        "User.Read.All",
        "Directory.Read.All",
        "UserAuthenticationMethod.Read.All",
        "AuditLog.Read.All",
        "Policy.Read.All",
        "User.RevokeSessions.All",
        "User.EnableDisableAccount.All",
        "User-PasswordProfile.ReadWrite.All",
        "DelegatedPermissionGrant.ReadWrite.All"
      ],
      "exchangeCmdlets": [
        "Get-MailboxObject",
        "Get-MailboxState"
      ],
      "ad": false,
      "sharedSession": true,
      "conditionalAccess": false
    }
  },
  "tools/git-handoff.ps1": {
    "sha256": "de09cbd42d120d932969dc229fa5437c7770fcdf6aed331f364acf6bec6c6531",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/git-repo.ps1": {
    "sha256": "3bcd5f6b61c9b5b24d3d8adcaa22f584e80bdfe0b612c9a53cacf9d03125b78c",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/git-security.ps1": {
    "sha256": "8082019f51b75c2184dcf74985cc73c80eb31135e8cd2ad3b9aaab5a73ea8352",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/set-execution.ps1": {
    "sha256": "4379e986662f2a80092938916ac5d2509fc5b01cb391d95e20b58c91b16ad294",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "toys/attractor.ps1": {
    "sha256": "1268680342075976f80599213dd97d25abc2af741a07a7f5de2ceab2c2ba4cc6",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "toys/rain.ps1": {
    "sha256": "f793a1a68a8245527597522077f40dda3eeb209bf9c6ad1164f0dde5ef9daf96",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "toys/static.ps1": {
    "sha256": "4aa3ae630d9631f11d110f78925c6e112508b3ccc7ba703f833537bb3c9394e0",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/SIGN-FOLDER-SCRIPTS.ps1": {
    "sha256": "2890218ee6951f81e46e0dd5cbc5b4ed38b80ccce031d0b04ad9c3561e654851",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/GET-TERMINAL-READINESS-CHECK.ps1": {
    "sha256": "0cdf541f4222218c359dddc9e441343d37ee7ad745cfe5588e06a9a45ad42316",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/INVOKE-FILE-INVENTORY.ps1": {
    "sha256": "435f354240c3178c5def5a4b2faaaaa013a7ef0d99f07fcf9170e69801b13279",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/INVOKE-MAP-KIT.ps1": {
    "sha256": "ea3b5ee21dbd384d7107ec1458be968d7c7c5c00c9998a4dcc2f89856a8372a4",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/INVOKE-SESSION-RESET.ps1": {
    "sha256": "2fa5b247f31b2dfe29bbed17ec9ffe576e53dbe3ce3e7ffb03f8328c7843dc07",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "toys/SET-THEME-BASIC.ps1": {
    "sha256": "9dc01f2210cf808379be2770450283f0d44be72c4d3cae3f9a0087c2f15e98f2",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "toys/SET-THEME-COBALT.ps1": {
    "sha256": "602ddcb368e716ca73ced3b799d847262faca237ee43b63a7070596ce37d9d2b",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "toys/SET-THEME-SEAGLASS.ps1": {
    "sha256": "629b919cea8aabd890151a2402241e426a4c0c331a9a4d5861bd9aaa340e888e",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "toys/SET-THEME-SILICON-VALLEY.ps1": {
    "sha256": "aab04649707578c0c57a9602b80cdae04465bff529fae0373d46f1aa2bc43739",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "tools/MANAGE-CERT-SIGNATURES.ps1": {
    "sha256": "d28176159f671ed1fe1e521f422a89f8de92f5ec032067e16f46156549d683fb",
    "mode": "local",
    "services": [],
    "connector": null
  },
  "published-source/utility/PREPARE-FIELD-KIT.ps1": {
    "sha256": "8b555611dffc223f909b9e13fa158f0daf472703ac9d42dc8d72d161cd430372",
    "mode": "local",
    "services": [],
    "connector": null
  }
});
