// Source-reviewed card details. Static review does not confer operator verification.
window.FIELD_KIT_CARD_GUIDANCE = Object.freeze({
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
    "sourceSha256": "b5a8a4be4b79e1ef77fc8f75eaef88b70d5f50ffd1dd47bccf1e21f1b35c6ecd"
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
    "sourceSha256": "2627de9b2b13220ef6de444ac4f98f9a5b0481f55a68dd4fbaf61ecc58be28e3"
  },
  "GET-GUEST-APP-CONSENT-AUDIT.ps1": {
    "requires": "Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, Application.Read.All.",
    "checks": [
      "Delegated OAuth grants made by guests",
      "Application/resource names where resolvable",
      "High-risk granted scopes"
    ],
    "sourceSha256": "e90b4af2ff9b35a32498ffa93836bcc8f502aa5a8e89ba3f9e3dc520a7f1be62"
  },
  "GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1": {
    "requires": "ExchangeOnlineManagement with recipient-read access; Microsoft.Graph.Authentication: AuditLog.Read.All, User.Read.All, Directory.Read.All; sign-in log role and licensing access.",
    "sourceSha256": "9df9711e8cdf8542a753a451b748e22d04a3448a3e88705f366fabacc3aae176"
  },
  "GET-APP-REGISTRATION-AUDIT.ps1": {
    "requires": "Microsoft.Graph.Authentication: Application.Read.All, Directory.Read.All.",
    "sourceSha256": "6948e5a25a54c218a5114a366a59f839454b64050b3c5726093506fa9e28f0a0"
  },
  "GET-DEVICE-CODE-EXPOSURE.ps1": {
    "requires": "Microsoft.Graph.Authentication: Policy.Read.ConditionalAccess, AuditLog.Read.All, Directory.Read.All; policy/sign-in log role and licensing access.",
    "sourceSha256": "4ac8a6ee2c3f5091ee24b47f3f91f9b12888ddeda0ed86308a9ecc7a7f1919bf"
  },
  "GET-MFA-SECURITY-AUDIT.ps1": {
    "requires": "Microsoft.Graph.Authentication: User.Read.All, Directory.Read.All, Reports.Read.All, UserAuthenticationMethod.Read.All; Policy.Read.ConditionalAccess when CA review is requested; appropriate report-read role.",
    "sourceSha256": "91aef944427d3e85f94874014a2f6dd726781ba9eb9931e2b9565d11a6f0b00c"
  },
  "GET-SECURE-SCORE-SNAPSHOT.ps1": {
    "requires": "Microsoft.Graph.Authentication: SecurityEvents.Read.All, SecurityActions.Read.All, Directory.Read.All; Secure Score read access.",
    "sourceSha256": "649b23416b9ed9c9e78c60fd2867c2e47c48b12e5ae73e80013aafec357b3efa"
  },
  "GET-SERVICE-PRINCIPAL-OWNERS.ps1": {
    "requires": "Microsoft.Graph.Authentication: Application.Read.All, Directory.Read.All, User.Read.All.",
    "sourceSha256": "3a45fdde22e453f23a1bd4a269daee6d5ed3334d19250ebe84701ec6691b289f"
  },
  "GET-SIGNIN-ANOMALIES.ps1": {
    "requires": "Microsoft.Graph.Authentication: AuditLog.Read.All, User.Read.All, Directory.Read.All; sign-in log role and licensing access.",
    "sourceSha256": "b87f694333ec632f76bc5edc8a6c8210fffccadac38c4bf955e5dac95cd48e91"
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
    "sourceSha256": "90a72cce1ace9af8d44ae02eeebc0cd47531b7c0b7b24e6e0a87e4c0368ee043"
  },
  "BACKUP-USER-PROFILE.ps1": {
    "checks": [
      "Common profile folders and optional Downloads",
      "Dated destination folder and local copy log"
    ],
    "guards": [
      "Typed BACKUP confirmation before copying profile data"
    ],
    "sourceSha256": "efdbdc7eab4effa096645be533d046ff2d8c3170fcdcc69186df405bd5dd0367"
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
    "sourceSha256": "922a2d16bcf7c753193e14296f9bf67715cf3e14ec8dd1fdeec8d9a31e10e9d2"
  },
  "GET-ADMIN-ROLE-AUDIT.ps1": {
    "checks": [
      "Active Entra directory role assignments",
      "User state, hybrid source and recorded last sign-in",
      "Optional role-review CSV"
    ],
    "sourceSha256": "b660a543b1044c58c74be40609c38caf40eb1cac040fcf87a77dea5e7d41fe78"
  },
  "GET-OAUTH-CONSENT-AUDIT.ps1": {
    "checks": [
      "Tenant delegated OAuth grants",
      "Application and resource name resolution",
      "High-risk scopes and optional CSV"
    ],
    "sourceSha256": "9b26065a085a5376d6fdd0312783f037505ac496d39310b062eb62add6401f65"
  },
  "GET-GUEST-USER-AUDIT.ps1": {
    "checks": [
      "Guest state and invitation acceptance",
      "Stale guests and unavailable sign-in history",
      "Optional guest-review CSV"
    ],
    "sourceSha256": "fe654017667917540bac5d099875379eb8760f24c448f9345fff626bf1894410"
  },
  "GET-TENANT-LICENSING-AUDIT.ps1": {
    "checks": [
      "Subscribed SKUs and user license assignments",
      "Disabled licensed and enabled unlicensed users"
    ],
    "sourceSha256": "eca8f567c83f132e3c0ba263e633cfcf2552e938b9c232bf9de2860fd17474d0"
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
    "sourceSha256": "7ab0323cef10c5cc09399432ccdf2417d3401f2f422e6200dc35ebfc4399e0c5"
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
