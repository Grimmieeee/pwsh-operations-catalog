# Catalog safety review matrix

Generated from current source hashes. Automated-test states describe the listed scope only; native operator verification is a separate gate. Pattern matches in the JSON are review leads.

{"entries":338,"scripts":80,"commands":235,"references":12,"pending":11,"operatorVerified":3,"scopedReviews":77}

| Script | Family | Review state | Scope / remaining review |
|---|---|---|---|
| GET-QUARTERLY-CLEANUP-REVIEW.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-STALE-SIGNIN-REVIEW.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-DISABLE-ACCOUNTS.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-DELETE-ACCOUNTS.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-ASSIGN-LICENSES.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-REMOVE-LICENSES.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| RESOLVE-NAMES-TO-UPNS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-ACCOUNT-STATUS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-DISTRIBUTION-GROUP-MEMBERS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-GROUP-MEMBERS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-USER-GROUPS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-REMOVE-USER-GROUPS.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TENANT-GROUP-OWNERS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-MAILBOX-PERMISSIONS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-MAILBOX-SECURITY-SNAPSHOT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-MAILBOX-FORWARDING.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-LITIGATION-HOLD.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| IR-INVOKE-EMAIL-RECOVERY.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| ir-risk-assessment.ps1 | Verified IR | Operator verified — exact version | Parser/integrity screening; detailed source review remains |
| ir-contain-eradicate.ps1 | Verified IR | Operator verified — exact version | Parser/integrity screening; detailed source review remains |
| IR-GET-DATA-EXFIL-ACTIVITY.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| IR-GET-IP-TRACE.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| IR-GET-TENANT-EMAIL-SEARCH.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| IR-GET-THREAT-INTEL-ACTIVITY.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| IR-GET-TIMELINE-BUILDER.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| IR-GET-TOKEN-DECODE.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| IR-GET-TOKEN-REPLAY-CHECK.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-APP-REGISTRATION-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-CONDITIONAL-ACCESS-GAPS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-DEVICE-CODE-EXPOSURE.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-GUEST-APP-CONSENT-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-MFA-SECURITY-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-SECURE-SCORE-SNAPSHOT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-SERVICE-PRINCIPAL-OWNERS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-SIGNIN-ANOMALIES.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TRANSPORT-RULES-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| JOIN-COMPUTER-TO-DOMAIN.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| DEPLOY-TCPIP-PRINTER.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| BACKUP-USER-PROFILE.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| TEST-POWERSHELL-READINESS.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-FOLDER-INVENTORY.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INSTALL-M365-MODULES.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| TEST-SENSITIVE-DATA.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| RESET-M365-SESSION.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| UPDATE-WINDOWS-APPS.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-USER-PREDELETE-CHECK.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-ENFORCE-PER-USER-MFA.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-ADMIN-ROLE-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-OAUTH-CONSENT-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-GUEST-USER-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TENANT-LICENSING-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TENANT-INBOX-RULES-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-USER-SECURITY-SNAPSHOT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TENANT-SECURITY-SNAPSHOT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-ROOM-RESOURCE-ACCESS.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TENANT-DRIFT-REVIEW.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1 | Read-only workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-RESET-CLOUD-USER-PASSWORD.ps1 | Change workflows | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| ir-recover-validate.ps1 | Verified IR | Operator verified — exact version | Parser/integrity screening; detailed source review remains |
| git-handoff.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| git-repo.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| git-security.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| set-execution.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| attractor.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| rain.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| static.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| SIGN-FOLDER-SCRIPTS.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| GET-TERMINAL-READINESS-CHECK.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-FILE-INVENTORY.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-MAP-KIT.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| INVOKE-SESSION-RESET.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| SET-THEME-BASIC.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| SET-THEME-COBALT.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| SET-THEME-SEAGLASS.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| SET-THEME-SILICON-VALLEY.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
| MANAGE-CERT-SIGNATURES.ps1 | Local tools / toys | Objective aligned — source/DOM checked | Exact card/script purpose parity; Non-presentation token fingerprint unchanged |
