# Catalog safety review matrix

Generated from current source hashes. Automated-test states describe the listed scope only; native operator verification is a separate gate. Pattern matches in the JSON are review leads.

{"entries":338,"scripts":80,"commands":235,"references":12,"pending":11,"operatorVerified":24,"scopedReviews":42}

| Script | Family | Review state | Scope / remaining review |
|---|---|---|---|
| GET-QUARTERLY-CLEANUP-REVIEW.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| GET-STALE-SIGNIN-REVIEW.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| INVOKE-DISABLE-ACCOUNTS.ps1 | Change workflows | Source reviewed | Changed control path review; No verified result is no longer described as no change |
| INVOKE-DELETE-ACCOUNTS.ps1 | Change workflows | Needs review | Parser/integrity screening; detailed source review remains |
| INVOKE-ASSIGN-LICENSES.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-UPN resolution and complete target preview; Expected tenant/account before reads and writes; One typed change approval; Missing state and failed/unverified completion reporting |
| INVOKE-REMOVE-LICENSES.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-UPN resolution and complete target preview; Expected tenant/account before reads and writes; One typed change approval; Missing state and failed/unverified completion reporting |
| RESOLVE-NAMES-TO-UPNS.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| GET-ACCOUNT-STATUS.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| GET-DISTRIBUTION-GROUP-MEMBERS.ps1 | Verified read-only workflows | Operator verified — exact version | Adapted sampled read-only workflow; ten records / forty reads; Test source matched returned runner manifest; release adds a version comment only |
| GET-GROUP-MEMBERS.ps1 | Verified read-only workflows | Operator verified — exact version | Adapted sampled read-only workflow; ten records / forty reads; Test source matched returned runner manifest; release adds a version comment only |
| GET-USER-GROUPS.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| INVOKE-REMOVE-USER-GROUPS.ps1 | Change workflows | Source reviewed | Changed control path review; No verified result is no longer described as no change |
| INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1 | Change workflows | Automated tests passed | Tenant binding and least required group/directory scopes; Existing-group ambiguity and failed-read blocking; Creation and post-change configuration validation |
| GET-TENANT-GROUP-OWNERS.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| GET-MAILBOX-PERMISSIONS.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| GET-MAILBOX-SECURITY-SNAPSHOT.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| GET-MAILBOX-FORWARDING.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| INVOKE-LITIGATION-HOLD.ps1 | Change workflows | Needs review | Parser/integrity screening; detailed source review remains |
| IR-INVOKE-EMAIL-RECOVERY.ps1 | Change workflows | Needs review | Parser/integrity screening; detailed source review remains |
| ir-risk-assessment.ps1 | Verified IR | Operator verified — exact version | Parser/integrity screening; detailed source review remains |
| ir-contain-eradicate.ps1 | Verified IR | Operator verified — exact version | Parser/integrity screening; detailed source review remains |
| IR-GET-DATA-EXFIL-ACTIVITY.ps1 | Verified read-only workflows | Operator verified — exact version | Adapted sampled read-only workflow; ten records / forty reads; Test source matched returned runner manifest; release adds a version comment only |
| IR-GET-IP-TRACE.ps1 | Verified read-only workflows | Operator verified — exact version | Adapted sampled read-only workflow; ten records / forty reads; Test source matched returned runner manifest; release adds a version comment only |
| IR-GET-TENANT-EMAIL-SEARCH.ps1 | Verified read-only workflows | Operator verified — exact version | Adapted sampled read-only workflow; ten records / forty reads; Test source matched returned runner manifest; release adds a version comment only |
| IR-GET-THREAT-INTEL-ACTIVITY.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| IR-GET-TIMELINE-BUILDER.ps1 | Verified read-only workflows | Operator verified — exact version | Synthetic local fixture or host prerequisite inspection; Test source matched returned runner manifest; release adds a version comment only |
| IR-GET-TOKEN-DECODE.ps1 | Verified read-only workflows | Operator verified — exact version | Synthetic local fixture or host prerequisite inspection; Test source matched returned runner manifest; release adds a version comment only |
| IR-GET-TOKEN-REPLAY-CHECK.ps1 | Verified read-only workflows | Operator verified — exact version | Changed control path review; Graph URI variable boundary correction; Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-APP-REGISTRATION-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-CONDITIONAL-ACCESS-GAPS.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-DEVICE-CODE-EXPOSURE.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-GUEST-APP-CONSENT-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-MFA-SECURITY-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-SECURE-SCORE-SNAPSHOT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-SERVICE-PRINCIPAL-OWNERS.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-SIGNIN-ANOMALIES.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-TRANSPORT-RULES-AUDIT.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| JOIN-COMPUTER-TO-DOMAIN.ps1 | Change workflows | Needs review | Parser/integrity screening; detailed source review remains |
| DEPLOY-TCPIP-PRINTER.ps1 | Change workflows | Automated tests passed | Default printer API and return values; Exact printer resolution without interpolated WQL; Optional-action failures and deployed driver/port validation |
| BACKUP-USER-PROFILE.ps1 | Change workflows | Automated tests passed | Native Robocopy invocation and return-code classification; Missing/partial/error backup summaries |
| TEST-POWERSHELL-READINESS.ps1 | Verified read-only workflows | Operator verified — exact version | Synthetic local fixture or host prerequisite inspection; Test source matched returned runner manifest; release adds a version comment only |
| GET-FOLDER-INVENTORY.ps1 | Verified read-only workflows | Operator verified — exact version | Synthetic local fixture or host prerequisite inspection; Test source matched returned runner manifest; release adds a version comment only |
| INSTALL-M365-MODULES.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| TEST-SENSITIVE-DATA.ps1 | Verified read-only workflows | Operator verified — exact version | Synthetic local fixture or host prerequisite inspection; Test source matched returned runner manifest; release adds a version comment only |
| RESET-M365-SESSION.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| UPDATE-WINDOWS-APPS.ps1 | Change workflows | Automated tests passed | Update and post-update command results; Cancel-before-update path |
| GET-USER-PREDELETE-CHECK.ps1 | Verified read-only workflows | Operator verified — exact version | Changed control path review; Graph URI variable boundary correction; Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| INVOKE-ENFORCE-PER-USER-MFA.ps1 | Change workflows | Needs review | Parser/integrity screening; detailed source review remains |
| GET-ADMIN-ROLE-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-OAUTH-CONSENT-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-GUEST-USER-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-TENANT-LICENSING-AUDIT.ps1 | Read-only workflows | Automated tests passed | Tenant/account binding and process-scoped delegated authentication; Successful empty, malformed, denied and interrupted collection reads; Graph URI interpolation and card input alignment |
| GET-TENANT-INBOX-RULES-AUDIT.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| GET-USER-SECURITY-SNAPSHOT.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| GET-TENANT-SECURITY-SNAPSHOT.ps1 | Verified read-only workflows | Operator verified — exact version | Exact-hash bounded read-only service queries; export and standalone paths separately scoped. |
| GET-ROOM-RESOURCE-ACCESS.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1 | Change workflows | Source reviewed | Changed control path review; No verified result is no longer described as no change |
| GET-TENANT-DRIFT-REVIEW.ps1 | Change workflows | Needs review | Parser/integrity screening; detailed source review remains |
| GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1 | Read-only workflows | Needs review | Parser/integrity screening; detailed source review remains |
| INVOKE-RESET-CLOUD-USER-PASSWORD.ps1 | Change workflows | Source reviewed | Accepted reset with unavailable timestamp read; Secure delivery pause and password/body variable cleanup; Pending/failed summary states |
| ir-recover-validate.ps1 | Verified IR | Operator verified — exact version | Parser/integrity screening; detailed source review remains |
| git-handoff.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| git-repo.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| git-security.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| set-execution.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| attractor.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| rain.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| static.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| SIGN-FOLDER-SCRIPTS.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| GET-TERMINAL-READINESS-CHECK.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| INVOKE-FILE-INVENTORY.ps1 | Verified read-only workflows | Operator verified — exact version | Synthetic local fixture or host prerequisite inspection; Test source matched returned runner manifest; release adds a version comment only |
| INVOKE-MAP-KIT.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| INVOKE-SESSION-RESET.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| SET-THEME-BASIC.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| SET-THEME-COBALT.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| SET-THEME-SEAGLASS.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| SET-THEME-SILICON-VALLEY.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
| MANAGE-CERT-SIGNATURES.ps1 | Local tools / toys | Needs review | Parser/integrity screening; detailed source review remains |
