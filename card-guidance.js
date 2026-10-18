// Source-reviewed card details. Static review does not confer operator verification.
window.FIELD_KIT_CARD_GUIDANCE = Object.freeze({
  "GET-CONDITIONAL-ACCESS-GAPS.ps1": {
    "input": "Expected tenant ID (GUID).",
    "checks": [
      "Disabled policies",
      "Report-only policies",
      "User / group exclusions",
      "Device-code gaps",
      "Location conditions",
      "Weak coverage indicators"
    ],
    "guards": [
      "Expected tenant/account validated before collection",
      "Failed or unavailable reads stop the review"
    ],
    "sourceSha256": "133e3a33c7a988c5e3ec93344355feb034c9fec685253f45aa27bf617d9549c3"
  },
  "INVOKE-ASSIGN-LICENSES.ps1": {
    "input": "Expected tenant ID (GUID) and exact user UPNs or a TXT/CSV user list. Choose a license from the numbered list; provide a country/region code only for users missing UsageLocation.",
    "checks": ["Tenant license inventory", "Per-user license and approved UsageLocation verification", "Failed and unverified results kept open; optional result CSV"],
    "guards": ["Expected tenant and signed-in account validated", "Each target and planned license/location shown before approval", "Typed ASSIGN confirmation; unavailable targets stop preparation"],
    "sourceSha256": "f5585715db56fc58a71cc518221eeb367eb6e143e90df9a50259f9b07455312e"
  },
  "INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1": {
    "input": "Expected tenant ID (GUID), group display name and mail nickname; defaults are offered.",
    "requires": "Microsoft.Graph.Authentication: Group.ReadWrite.All and Directory.Read.All; tenant rights and licensing for dynamic groups.",
    "guards": ["Expected tenant and account validated", "Failed or ambiguous existing-group lookup blocks creation", "Typed CREATE approval of the displayed group and membership rule"],
    "sourceSha256": "7068d41c2fecf17249bbcb888534987f046c68ebcbc51133b9c23186daf37153"
  },
  "INVOKE-REMOVE-LICENSES.ps1": {
    "input": "Expected tenant ID (GUID) and exact user UPNs or a TXT/CSV user list (UPN column recommended). Choose a license from the numbered list, or ALL.",
    "checks": ["Current assigned licenses", "Per-user post-change removal verification", "Failed and unverified results kept open; optional result CSV"],
    "guards": ["Expected tenant and signed-in account validated", "Each target UPN and planned license shown before approval", "Typed REMOVE confirmation; cancellation makes no changes"],
    "sourceSha256": "4ca7d831f460991251a5a0fe980b17e537f96e48df906c4db576f3f43e623928"
  },
  "GET-QUARTERLY-CLEANUP-REVIEW.ps1": {
    "input": "Tenant domain; optional inactivity threshold (default 90 days).",
    "requires": "Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, AuditLog.Read.All, Group.Read.All; ExchangeOnlineManagement with recipient-read access.",
    "checks": [
      "Stale enabled members and unavailable sign-in data",
      "Active admin role counts and ownerless cloud groups",
      "External mailbox forwarding"
    ],
    "guards": [
      "Query failures remain data gaps; no automatic export"
    ],
    "sourceSha256": "19b092079ccc61f4de9cbc6510b3a57f290f520abb08ab2b5db4089457fcc570"
  },
  "GET-DISTRIBUTION-GROUP-MEMBERS.ps1": {
    "checks": [
      "Distribution group resolution",
      "Direct member details",
      "Optional member CSV"
    ],
    "guards": [
      "Ambiguous or failed group lookups remain visible"
    ],
    "sourceSha256": "e4046dacdf671ce73b213bc570b74cc238b9ea60d1bf5ba5a3c5f50dc65f07a9"
  },
  "INVOKE-REMOVE-USER-GROUPS.ps1": {
    "requires": "Microsoft.Graph.Authentication: User.Read.All, Group.Read.All, GroupMember.ReadWrite.All; ActiveDirectory module and AD change rights for synced memberships.",
    "checks": [
      "AD and Entra memberships and source authority",
      "Removal results and remaining memberships",
      "Optional verified result CSV"
    ],
    "guards": [
      "Complete removal plan before changes",
      "Typed REMOVE GROUPS confirmation",
      "Dynamic, role-assignable and Exchange-managed groups skipped",
      "Synced memberships changed in AD"
    ],
    "sourceSha256": "a813ab576da5f82eb11ae0d1ee6e26134b03997e73692c9e5d6181ed20d09b55"
  },
  "INVOKE-ENFORCE-PER-USER-MFA.ps1": {
    "checks": [
      "Current per-user MFA state",
      "Post-change MFA state for each user"
    ],
    "guards": [
      "Full target preview before changes",
      "Typed ENFORCE confirmation",
      "Separate from Conditional Access and Security Defaults"
    ],
    "sourceSha256": "52c6ce8dc1af2323b9dcc6c831cdd211b555ae44280417181599290212fcf7bd"
  },
  "GET-MAILBOX-SECURITY-SNAPSHOT.ps1": {
    "requires": "ExchangeOnlineManagement; rights to read recipient, mailbox configuration, inbox rules and mailbox permissions. Microsoft Graph is not used.",
    "sourceSha256": "ab87c10d108dff487da2d4cf762e0081ab88f6e501686db6042e301317363790"
  },
  "IR-INVOKE-EMAIL-RECOVERY.ps1": {
    "input": "Mailbox UPN; source and recovery folders; lookback hours (default 24).",
    "requires": "Microsoft.Graph.Authentication: delegated Mail.ReadWrite.Shared AND existing access to the target mailbox/folders. An admin role alone does not grant mailbox access.",
    "checks": [
      "Source and destination folder selection",
      "Message preview and selected move results",
      "Post-move source and target validation"
    ],
    "guards": [
      "Preview and typed MOVE confirmation",
      "Target folder creation requires approval"
    ],
    "sourceSha256": "e00946f377bdd4b0e9eb87d04025906763bb8c7307ecdaf87f5016f006ea6aaf"
  },
  "ir-risk-assessment.ps1": {
    "reviewNote": "Known limitation: app display names may be unresolved. Review the app IDs and grants; an unresolved name does not clear a finding.",
    "checks": [
      "Account state, password last changed and privileged roles",
      "Authentication methods and enabled Conditional Access policy inventory",
      "Latest-25 sign-in sample over 10 days",
      "Mailbox rules, forwarding, delegates, OAuth grants and protocols"
    ],
    "guards": [
      "Read-only assessment; no tenant changes",
      "Unavailable checks remain visible; findings are not a compromise verdict"
    ],
    "sourceSha256": "07f70bea99adcc4fcfc1115288ec4377f295f6b98ecfb6d16667da1d4f14383b"
  },
  "ir-contain-eradicate.ps1": {
    "checks": [
      "Account containment, password reset and session revocation results",
      "Selected mailbox rules, forwarding and delegated access",
      "Selected OAuth persistence and post-change state"
    ],
    "guards": [
      "Only selected, explicitly confirmed response actions",
      "Synced identity changes require SID-matched AD and local Windows rights",
      "No automatic sync; validate propagation separately",
      "Temporary password shown only after reset; cleared after secure-delivery pause"
    ],
    "sourceSha256": "e9c4eff8a9637416bb4b51f6de4f7f21838f01c0c80adcb9170ae98778b958fb"
  },
  "ir-recover-validate.ps1": {
    "checks": [
      "Fresh account, mailbox and persistence readiness",
      "Authoritative account enable state after recovery",
      "Recovery summary and sign-in/MFA follow-up"
    ],
    "guards": [
      "Operator confirms identity, remediation, scope review and MFA readiness",
      "Explicit approval before restoring access",
      "Pending AD-to-Entra sync remains unverified",
      "No password reset or persistence removal in recovery"
    ],
    "sourceSha256": "c8651f2ab0d3c0e3f50ee65bb80cda9e984bc6fe52ce268831b9a7cf501f9b04"
  },
  "IR-GET-DATA-EXFIL-ACTIVITY.ps1": {
    "input": "Target UPN; lookback days (default 30, maximum 90); optional source IP.",
    "requires": "ExchangeOnlineManagement; permission to run Search-UnifiedAuditLog.",
    "checks": [
      "SharePoint and OneDrive download and sharing events",
      "Source IP and download-burst indicators",
      "Optional activity CSV"
    ],
    "guards": [
      "Indicators require analyst review; not proof of exfiltration"
    ],
    "sourceSha256": "5f80f8a9a3af0a250963e48deeebb6ce278b392140a7fc82a01da396c3e3bf73"
  },
  "IR-GET-IP-TRACE.ps1": {
    "input": "Suspect IP; lookback days (default 7, maximum 90).",
    "requires": "ExchangeOnlineManagement; permission to run Search-UnifiedAuditLog.",
    "checks": [
      "Unified Audit Log activity for the source IP",
      "Daily search windows and optional CSV"
    ],
    "guards": [
      "Failed windows and record caps are reported as data gaps"
    ],
    "sourceSha256": "30ea759b710a12b3650b48191b2fe3dc123ebbed4c7798d4c6a934d0702689d3"
  },
  "IR-GET-TENANT-EMAIL-SEARCH.ps1": {
    "input": "Sender, recipient or source IP; lookback days (default 7, maximum 90).",
    "requires": "ExchangeOnlineManagement with Get-MessageTraceV2; message-trace read rights.",
    "checks": [
      "Message traces matching supplied indicators",
      "Search windows and optional CSV"
    ],
    "guards": [
      "Windows limited to 10 days; capped results reported as incomplete"
    ],
    "sourceSha256": "dbb53c592a523fdf2a2c94dd166296afe6a9f482ec4372c2d3f551af56ea797e"
  },
  "IR-GET-THREAT-INTEL-ACTIVITY.ps1": {
    "input": "Public IP addresses or TXT list; API key for each enabled provider.",
    "requires": "HTTPS access to the selected VirusTotal and/or AbuseIPDB API; provider API keys. No M365 connection.",
    "checks": [
      "VirusTotal and/or AbuseIPDB IP reputation",
      "Optional reputation CSV"
    ],
    "guards": [
      "Selected public IPs are sent to enabled providers",
      "API keys are not written to disk by this script"
    ],
    "sourceSha256": "a9126fcc537a71b9471d49ecfe5f714ede93bc5e1306b3eee9fe9ea7f014859a"
  },
  "IR-GET-TIMELINE-BUILDER.ps1": {
    "input": "Local case folder or manual event entries; optional search text.",
    "checks": [
      "Chronological events from JSON, text, log and Markdown evidence",
      "Optional manual events and TXT timeline"
    ],
    "guards": [
      "File-modified fallback timestamps are explicitly labeled",
      "Source evidence is never modified"
    ],
    "sourceSha256": "fb6e000a57b548f59fbc4f9317df3dac0ab61756c97223784d7b2e54a6d70c40"
  },
  "IR-GET-TOKEN-DECODE.ps1": {
    "checks": [
      "JWT header and payload decoded locally"
    ],
    "guards": [
      "No network or export",
      "Does not validate signature, trust or token usability"
    ],
    "sourceSha256": "179e01c20af4ad72faabd69c2567ccff9fa1d40a5ca3acf497544ba6d4849372"
  },
  "IR-GET-TOKEN-REPLAY-CHECK.ps1": {
    "input": "Target UPN; lookback hours (default 48); expected country/region (default US).",
    "requires": "Microsoft.Graph.Authentication: User.Read.All, AuditLog.Read.All, IdentityRiskEvent.Read.All; tenant licensing and role access for the requested logs.",
    "checks": [
      "Entra sign-ins and Identity Protection risk detections",
      "Token-specific risk signals and geography context"
    ],
    "guards": [
      "Unavailable data remains a limitation",
      "Unexpected geography alone is not called token replay"
    ],
    "sourceSha256": "8425b8ecc345535a4ac8be7049fcc076d88352b6120c16d2866832c0974c487f"
  },
  "GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "requires": "Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, Application.Read.All.",
    "checks": [
      "Delegated OAuth grants made by guests",
      "Application/resource names where resolvable",
      "High-risk granted scopes"
    ],
    "sourceSha256": "4eda293e510d60604da0508715db31807223de1cd5cfa9f3b356393d715f6c18"
  },
  "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "requires": "ExchangeOnlineManagement with recipient-read access; Microsoft.Graph.Authentication: AuditLog.Read.All, User.Read.All, Directory.Read.All; sign-in log role and licensing access.",
    "sourceSha256": "6ebe7be5484bca187bd5182753057874c43daa87a55956e40e4ccdef74f97f0a"
  },
  "GET-APP-REGISTRATION-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "requires": "Microsoft.Graph.Authentication: Application.Read.All, Directory.Read.All.",
    "sourceSha256": "8d82e57d695c5ee034525d3664dd4d6dc257c2c9345b49cfbbed24a526c942c3"
  },
  "GET-DEVICE-CODE-EXPOSURE.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "requires": "Microsoft.Graph.Authentication: Policy.Read.ConditionalAccess, AuditLog.Read.All, Directory.Read.All; policy/sign-in log role and licensing access.",
    "sourceSha256": "2a064c402cd8dda51e4f7ade3a9c3ed7645784ffc9f63804820dec3dc8aca2db"
  },
  "GET-MFA-SECURITY-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "requires": "Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, Reports.Read.All, UserAuthenticationMethod.Read.All; Policy.Read.ConditionalAccess when CA review is requested; appropriate report-read role.",
    "sourceSha256": "6eb755d2b8190da12132b30eb0080b2367a35a28129ac1f239d3c098571b444d"
  },
  "GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "requires": "Microsoft.Graph.Authentication: SecurityEvents.Read.All, SecurityActions.Read.All, Directory.Read.All; Secure Score read access.",
    "sourceSha256": "707321b6f1ae7285ae0ccb03b2061ae36280432bf6b296d72bde8ad93ba03db0"
  },
  "GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "requires": "Microsoft.Graph.Authentication: Application.Read.All, Directory.Read.All, User.Read.All.",
    "sourceSha256": "15c73ae6c21e78fc694aa3b0f20b4a6c941a9c5a7dbb5b328935eb77dfeb6a5f"
  },
  "GET-SIGNIN-ANOMALIES.ps1": {
    "input": "Expected tenant ID (GUID). Lookback hours (default 24), expected country/region codes (default US), optional exact UPN filter; MaxPages defaults to 5.",
    "guards": ["Expected regions are shown before interpreting foreign sign-ins", "Page-limit coverage remains explicitly partial", "Failed or malformed reads stop the review"],
    "requires": "Microsoft.Graph.Authentication: AuditLog.Read.All, User.Read.All, Directory.Read.All; sign-in log role and licensing access.",
    "sourceSha256": "bbc41b082ff6daff44f853527b6afe0a609b8ae29cecea4ad5c4bc22f2e77782"
  },
  "JOIN-COMPUTER-TO-DOMAIN.ps1": {
    "checks": [
      "Elevation, hostname and current domain state",
      "DNS and target domain reachability",
      "Domain join result"
    ],
    "guards": [
      "Typed JOIN confirmation",
      "Restart only when approved"
    ],
    "sourceSha256": "5e089c864ee6a869b050ccdfd7b6666b683eae845d188f8d1e3ba3c27d4d8f12"
  },
  "DEPLOY-TCPIP-PRINTER.ps1": {
    "checks": [
      "Printer reachability and installed driver",
      "TCP/IP port and printer creation",
      "Optional default-printer and test-page actions"
    ],
    "guards": [
      "Typed ADD confirmation before adding the printer"
    ],
    "sourceSha256": "2bed1d7391d8bf6a27b2127c806c246fd93b2fe7e62d8b91268b17a31bf79649"
  },
  "BACKUP-USER-PROFILE.ps1": {
    "checks": [
      "Common profile folders and optional Downloads",
      "Dated destination folder and local copy log"
    ],
    "guards": [
      "Typed BACKUP confirmation before copying profile data"
    ],
    "sourceSha256": "f51c3c9ff843c5a569765c635a2e57a71b221d11f3bf64266775701a7af6abb6"
  },
  "GET-USER-PREDELETE-CHECK.ps1": {
    "input": "Exact user UPN; access to the authoritative AD environment when applicable.",
    "requires": "ActiveDirectory module/domain read access for AD coverage; Microsoft.Graph.Authentication: User.Read.All, Group.Read.All, Directory.Read.All; ExchangeOnlineManagement with mailbox, permission, transport-rule and retention read rights.",
    "checks": [
      "AD identity, groups, ownership and direct reports",
      "Mailbox forwarding, delegates, retention and statistics",
      "Mail-group, transport-rule and Entra ownership dependencies",
      "Direct application assignments and licenses"
    ],
    "guards": [
      "Review only; does not delete the user"
    ],
    "sourceSha256": "99fd7d84bb4d12d7237ebaed5799e44d68dd594a791b40c9533ce1e81e9590b4"
  },
  "GET-ADMIN-ROLE-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "checks": [
      "Active Entra directory role assignments",
      "User state, hybrid source and recorded last sign-in",
      "Optional role-review CSV"
    ],
    "sourceSha256": "58862647a3ffb1bb3b7b1e3d3879ca671de475ee7da90183af9247f0a54bd696"
  },
  "GET-OAUTH-CONSENT-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "checks": [
      "Tenant delegated OAuth grants",
      "Application and resource name resolution",
      "High-risk scopes and optional CSV"
    ],
    "sourceSha256": "c1a55d472ac898b856b1c93bb7ea1c945d62600dc2849bd7828381d2e0e5a6d4"
  },
  "GET-GUEST-USER-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "checks": [
      "Guest state and invitation acceptance",
      "Stale guests and unavailable sign-in history",
      "Optional guest-review CSV"
    ],
    "sourceSha256": "ff9f8a39d9e7c102a6bb303c22bd10e00dce16a2603d1ed41cbb845158b941f6"
  },
  "GET-TENANT-LICENSING-AUDIT.ps1": {
    "input": "Expected tenant ID (GUID).",
    "guards": ["Expected tenant/account validated before collection", "Failed or unavailable reads stop the review"],
    "checks": [
      "Subscribed SKUs and user license assignments",
      "Disabled licensed and enabled unlicensed users"
    ],
    "sourceSha256": "7b7dba5740af97019b5fd2f969f5891dcd52ec0a8d6180bbff29f914411f0bf3"
  },
  "GET-TENANT-INBOX-RULES-AUDIT.ps1": {
    "checks": [
      "Tenant mailbox rules and optional shared mailboxes",
      "Forward, redirect, delete, move and hidden-rule indicators",
      "Optional suspicious-only results and CSV"
    ],
    "sourceSha256": "85a1c9164ba0d0c0661b6c3e7ecb197f4ac7ab2865d3436de3a5f48f76844880"
  },
  "GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1": {
    "checks": [
      "OS and drive utilization",
      "Measured cleanup candidate sizes",
      "Largest files and scan status"
    ],
    "guards": [
      "No deletion or settings changes",
      "Largest files are evidence, not automatically safe to delete",
      "Full-drive scans can take minutes and create disk I/O"
    ],
    "sourceSha256": "c795ac5d107db35eed303dff231cedbee577824c6fe8b93285ad5895a97cd44b"
  },
  "INVOKE-RESET-CLOUD-USER-PASSWORD.ps1": {
    "checks": [
      "Cloud account eligibility and reset results",
      "Optional force-change-at-next-sign-in setting"
    ],
    "guards": [
      "Synced users refused; AD remains authoritative",
      "Preview and typed RESET confirmation",
      "Temporary passwords shown only after successful reset; never exported"
    ],
    "sourceSha256": "5bf0df403969f64e2d7dd0787487dabf0abe183dce870dbf82b7b041da93bd11"
  },
  "GET-TERMINAL-READINESS-CHECK.ps1": {
    "input": "Local kit root (default C:\\Field-Kit); review expected layout for your installation.",
    "checks": [
      "PowerShell, policy, modules and existing cloud sessions",
      "Kit folder layout, anchor files and script signatures"
    ],
    "guards": [
      "Reports against a fixed expected layout; makes no changes"
    ],
    "sourceSha256": "e9d4d5f1974f2af40c01c23e4e4cf925f232baba8bd7f9b063f0c78110958c01"
  },
  "INVOKE-MAP-KIT.ps1": {
    "input": "Root folder; optional depth and display choices.",
    "checks": [
      "Folder counts, file map and script categories",
      "Signature state and cleanup/Git indicators"
    ],
    "guards": [
      "Reporter only; no enforced layout or file changes"
    ],
    "sourceSha256": "22046718b32efd8f0d8d5e27bbccb78836ee52262159aa215796e6df5ff7e418"
  },
  "INVOKE-SESSION-RESET.ps1": {
    "checks": [
      "Graph and Exchange disconnection",
      "Legacy Exchange PSSession cleanup and error-buffer reset"
    ],
    "guards": [
      "Unrelated remoting sessions remain intact",
      "Password-variable cleanup and new window are optional"
    ],
    "sourceSha256": "0f183c52bd1ca24dcccba318913eac70eb89848cbe32ef42fe631c6270744446"
  },
  "SET-THEME-BASIC.ps1": {
    "checks": [
      "Plain-text status and field-output examples"
    ],
    "guards": [
      "No host appearance changes; sample output is illustrative"
    ],
    "sourceSha256": "a3959c764ee2c0b4e155f89b5cf28faed7db74f54f2b277e2152b453c392827f"
  },
  "SET-THEME-COBALT.ps1": {
    "checks": [
      "Cobalt palette and status-output preview"
    ],
    "guards": [
      "Changes terminal appearance and Process execution policy; no profile installation"
    ],
    "sourceSha256": "01b14b7f32a176f6f107ea73c1421a40d967dd634957f2fb849e94bedab92347"
  },
  "SET-THEME-SEAGLASS.ps1": {
    "checks": [
      "Sea Glass console colors and syntax highlighting"
    ],
    "guards": [
      "Writes a persistent theme to the current-user all-hosts profile",
      "Changes Process execution policy"
    ],
    "sourceSha256": "4b67f87297ce80e2f4f34d4bade7f784005ee4788686046968022e075df167c0"
  },
  "SET-THEME-SILICON-VALLEY.ps1": {
    "checks": [
      "Silicon Valley console and syntax colors"
    ],
    "guards": [
      "Writes the theme to the PowerShell profile for persistence"
    ],
    "sourceSha256": "f8de1e1fc05f78dbabfdaf6d156ebbdd13049cc2ff7067e177e3c80bb63050aa"
  }
});
