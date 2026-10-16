# Interactive incident-response workflow

Published baseline: 0.4.0. The owner tested assessment, containment, cleanup,
recovery and same-window handoffs on a Windows client jumpbox. This is not a
claim of compatibility with every tenant, module version or hybrid deployment.

Download all three scripts into one folder, retaining their filenames. Start
`IR-GET-IDENTITY-RISK-ASSESSMENT` from an existing PowerShell window. Enter an
exact target UPN and tenant domain. The first sign-in requests the delegated
read and change scopes for the workflow; assessment itself makes no tenant
changes. Administrative roles and tenant consent are separate requirements.

1. **Assessment:** review indicators, unavailable checks and recommendations.
   Continue only when incident evidence warrants containment.
2. **Contain and Eradicate:** select actions, approve RESPOND, choose cleanup
   items, then approve ERADICATE. These can block access, reset passwords and
   delete rules or consent. Only approved items should be selected.
3. **Restore and Validate:** approve RECOVER only after identity, remediation,
   device safety, trusted MFA methods and incident-owner authorization are
   confirmed. The script rechecks available evidence and verifies enable state.

Choose Y at a handoff to continue in the same process with validated context.
Choose N or Enter to return to PowerShell. In baseline 0.4.0, the optional
post-recovery assessment offers response again; choose N when finished. Newer
output-pacing and closing-flow refinements remain in testing, not this release.

## Limits and safety

- Windows PowerShell 5.1 and PowerShell 7 are intended hosts. Installed Graph,
  Exchange and authentication-library combinations still need local validation.
- Synced AD changes require Windows AD rights and an SID-matched target. Cloud
  admin sign-in does not grant local AD rights. No automatic remoting or delta
  sync is performed; separately verify replication, password propagation and
  synchronization before restoring access.
- MFA readiness is operator-confirmed. Enabled Conditional Access policies do
  not prove effective coverage for this user. A clean indicator snapshot is not
  proof of no compromise, successful sign-in or incident closure.
- A password is displayed only after a successful reset. Terminal capture or
  PowerShell transcription can retain it. Deliver through the approved secure
  channel. Clearing its variable does not erase scrollback or captured copies.
  Passwords are not automatically exported or copied to the clipboard.
- Inbox-rule changes may affect Outlook client-side rule data. Review the
  selected plan and applicable Microsoft guidance before deleting rules.
- No module installation, execution-policy adjustment or automatic export is
  performed. Public source is unsigned; internal signing is a separate step.
- Successful user sign-in with MFA, investigation, monitoring and closure remain
  the incident owner's responsibility. Keep private evidence out of this repo.

Test-user setup, verification and teardown utilities remain unpublished while
their authentication and verification fixes receive client-side testing.
