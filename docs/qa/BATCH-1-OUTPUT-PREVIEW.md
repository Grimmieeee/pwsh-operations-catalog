# Batch one: output preview

Design preview only, using synthetic data. The five executable scripts have
not been changed. Formatting is reviewed first; the separate behavior issues
in BATCH-1-REVIEW.md remain held. These examples do not claim tenant execution.

## Shared contract

Use one uppercase title, one-sentence objective, start timestamp, short
connection confirmations, TARGET for each object, plain section headings,
STATUS for the result and NEXT STEP only when the operator has work to do.
Finish with COMPLETED and Press ESC to close. Existing PowerShell stays open.

Keep the one/many/TXT/CSV input paths, existing query scope, source order,
authentication, result/export schemas and optional export choices. Do not add
exports to Mailbox Permissions. Do not add IR-style companion handoffs to
independent lookup tools. Bulk runs repeat TARGET/results; show one final
summary and existing export choice, not five repeated approvals per target.

Green [OK] prefixes indicate connection/completion success. None found may be
green only after a successful complete query. Review/unavailable warnings are
yellow; actual failures red. Names, addresses and normal headings are neutral.
Forwarding or delegation being present is not itself a compromise verdict.

The closing key is a presentation/navigation change for these standalone tools,
not permission to close a caller's shell. Hosts without direct key support
will need the same explicit typed-ESC fallback used in the IR workflow.

## GET-ACCOUNT-STATUS

```text
ACCOUNT STATUS REVIEW
Review account state and recorded Entra sign-in activity.
2026-10-16 21:25:00

User UPN(s) or TXT/CSV path: user@example.com

[OK] GRAPH CONNECTED

TARGET
UPN: user@example.com
Account Status: Enabled
Recorded Entra Sign-In: 10/16/2026 15:42

STATUS: REVIEW COMPLETE

TICKET SUMMARY
Accounts checked: 1
Enabled: 1
Disabled: 0
Not found: 0
Query failures: 0
Sign-in unavailable: 0

COMPLETED: 10/16/2026 21:25

Export results to CSV [Y/N]: N

Press ESC to close
```

Show the recorded date rather than only an age on screen. Preserve the
existing DaysSince export field and query behavior. Do not call a recorded
sign-in a successful login. Missing sign-in activity stays unavailable.
The null account-state correction is a separate held fix, not part of this
formatting draft. A successful single-target run needs no extra NEXT STEP.

## GET-MAILBOX-FORWARDING

```text
MAILBOX FORWARDING CHECK
Review mailbox and inbox-rule forwarding.
2026-10-16 21:25:00

Mailbox UPN(s) or TXT/CSV path: user@example.com

[OK] EXCHANGE CONNECTED

TARGET
UPN: user@example.com

MAILBOX FORWARDING
Status: None found

INBOX RULE FORWARDING
Status: None found

STATUS: NO FORWARDING FOUND

TICKET SUMMARY
Mailboxes requested: 1
Mailboxes checked: 1
Mailbox failures: 0
Result rows: 1

COMPLETED: 10/16/2026 21:25

Export results to CSV [Y/N]: N

Press ESC to close
```

When configured, retain the actual target, rule name, enabled/disabled state
and delivery-copy setting. Keep inbox-rule query failures visibly unavailable.
Optional CSV remains a separate deliberate choice after the review.

## GET-USER-GROUPS

```text
USER GROUP MEMBERSHIPS
Review direct Active Directory and Entra ID memberships.
2026-10-16 21:25:00

User UPN(s) or TXT/CSV path: user@example.com

[OK] GRAPH CONNECTED

TARGET
Name: Example User
UPN: user@example.com

ACTIVE DIRECTORY GROUPS
- Domain Users [Protected]
- Finance

ENTRA ID GROUPS
- Finance [Synced]
- Microsoft 365 Users [Cloud] [Dynamic]

COVERAGE
Active Directory: Checked
Entra ID: Checked

STATUS: LOOKUP COMPLETE

TICKET SUMMARY
Users checked: 1
Entra check failures: 0
AD check failures: 0

COMPLETED: 10/16/2026 21:25

Export results to CSV [Y/N]: N

Press ESC to close
```

Preserve independent AD/Entra observations, existing list order and all group
markers, including M365 when present. The same synced group can appear in
both lists. Display existing unavailable coverage beside the affected section
instead of an isolated None found line; leave collectors and export values
unchanged. A failed source requires review, not a clean completion claim.

## GET-GROUP-MEMBERS

```text
GROUP MEMBERS
Review direct members of the selected group.
2026-10-16 21:25:00

Group name/email or TXT/CSV path: finance@example.com

[OK] EXCHANGE CONNECTED

TARGET
Input: finance@example.com
Name: Finance
Email: finance@example.com
Source: Exchange Distribution Group

DIRECT MEMBERS
- Example User <user@example.com>
- Sample User <sample@example.com>

STATUS: LOOKUP COMPLETE

TICKET SUMMARY
Groups checked: 1
Found: 1
Not found: 0
Member rows: 2

COMPLETED: 10/16/2026 21:25

Export member detail to CSV [Y/N]: N

Press ESC to close
```

Keep Exchange -> Entra -> AD lookup order and source-specific detail. Show
Graph/AD connection and coverage messages only when those sources are used.
Do not suggest this expands nested or effective membership. The duplicate-name
and failed-member-read fixes remain separate; this script is held from release.

## GET-MAILBOX-PERMISSIONS

```text
MAILBOX PERMISSIONS REVIEW
Review forwarding, delegates and inbox rules.
2026-10-16 21:25:00

Mailbox UPN(s) or TXT/CSV path: user@example.com

[OK] EXCHANGE CONNECTED

TARGET
UPN: user@example.com

FORWARDING
Status: None found

FULL ACCESS
- Delegate User <delegate@example.com>

SEND AS
Status: None found

SEND ON BEHALF
Status: None found

INBOX RULES
Status: None found

STATUS: REVIEW COMPLETE

COMPLETED: 10/16/2026 21:25

Press ESC to close
```

Use the delegate name/address returned by the existing query; do not add
directory calls just to fill this sample's friendly-name presentation. No CSV
prompt is added because this script has no export workflow. Visible-only rule
coverage must remain explicit if the existing hidden-rule fallback is used.

## Exception formatting

Apply the shared words to evidence the existing script actually has. Examples:

```text
INBOX RULE FORWARDING
Status: Not available
[WARN] Inbox rules could not be checked.

STATUS: REVIEW REQUIRED

NEXT STEP
Resolve the reported access or connection error and rerun this check.
```

```text
ACTIVE DIRECTORY GROUPS
Status: Not available

ENTRA ID GROUPS
- Microsoft 365 Users [Cloud] [Dynamic]

COVERAGE
Active Directory: Not checked
Entra ID: Checked

STATUS: REVIEW REQUIRED
```

```text
STATUS: RUN CANCELLED
No tenant changes made.

Press ESC to close
```

The cancelled example applies only where the existing path identifies
cancellation; do not relabel an arbitrary service error as user cancellation.
The group-member query failure cannot receive truthful new status handling
until its separately approved behavior fix is implemented. No approved fix
is implied by this preview.
