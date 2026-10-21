# BEC response workflow

Current display release: 1.0.1. Titles and objectives align with the BEC cards;
response controls and operational tokens compare unchanged against the accepted
1.0.0 runtime baseline. The owner’s 1.0.0 acceptance remains historical evidence,
not a new runtime test of the display revision. See the [current review](qa/RELATIONSHIP-ALIGNMENT-REVIEW.md).

Download all three scripts into one folder, retaining their filenames. Start
`ir-risk-assessment` from an existing PowerShell window. Enter an
exact target UPN and tenant domain. The first sign-in requests the delegated
read and change scopes for the workflow; assessment itself makes no tenant
changes. Administrative roles and tenant consent are separate requirements.

1. **Assessment:** review indicators, unavailable checks and recommendations.
   Continue only when incident evidence warrants containment.
2. **Contain and Eradicate:** select actions, approve RESPOND, choose cleanup
   items, then approve ERADICATE. These can block access, reset passwords and
   delete rules or consent. Only approved items should be selected.
3. **Recovery and Validation:** approve RECOVER only after identity, remediation,
   device safety, trusted MFA methods and incident-owner authorization are
   confirmed. The script rechecks available evidence and verifies enable state.

Press ENTER at a handoff to continue in the same process with validated context.
Press ESC to end the workflow. In hosts without direct key support, type ESC
and press ENTER as prompted. The final assessment completes without offering
containment again. An existing PowerShell window remains open.

The companion filenames are `ir-risk-assessment.ps1`,
`ir-contain-eradicate.ps1`, and `ir-recover-validate.ps1`. Download and replace
all three together; older uppercase filenames are retired. Output uses STATUS
for results and NEXT STEP for guidance. Accepted baseline runtime evidence and hashes
are recorded in [IR-1.0.0-VERIFICATION.md](qa/IR-1.0.0-VERIFICATION.md).

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

Test-user setup, verification and teardown utilities remain outside the public
catalog release. The IR verification stamp does not cover those utilities.
