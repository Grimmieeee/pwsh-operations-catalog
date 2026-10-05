# Script Review Checklist

Use this before approving a new script or publishing an updated one.

## Syntax

- [ ] Parser returns no errors.
- [ ] Functions and script blocks close correctly.
- [ ] String interpolation and nested quotes are tested.
- [ ] PowerShell 5.1 compatibility is preserved when required.
- [ ] No unsupported syntax is present.

## Structure

- [ ] Objective is clear.
- [ ] Inputs are collected only when required.
- [ ] Helper functions are defined before use.
- [ ] Top-level failure handling is present where practical.
- [ ] The script remains reviewable on both success and failure.
- [ ] RMM / unattended scripts do not pause for keyboard input.

## Authentication

- [ ] Only required services are connected.
- [ ] Existing sessions are validated before reuse.
- [ ] Graph tenant alignment is checked.
- [ ] Graph multi-tenant sessions use process scope.
- [ ] Exchange session health is checked before use.
- [ ] Connection failures return one actionable explanation.

## Data handling

- [ ] Null results are handled.
- [ ] Empty collections are safe.
- [ ] Failed queries are not presented as clean results.
- [ ] JSON parsing is protected by error handling.
- [ ] File operations use safe paths.
- [ ] Export failures are visible.

## Changes

- [ ] READ ONLY / MAKES CHANGES / DESTRUCTIVE classification is accurate.
- [ ] Change-making behavior is obvious before execution.
- [ ] Destructive actions require explicit confirmation.
- [ ] Multi-object destructive work is confirmed at an appropriate level.
- [ ] Completed, skipped, and failed actions are distinguishable.

## Output

- [ ] Human-readable names are preferred over IDs.
- [ ] Output is concise and ticket-friendly.
- [ ] Warnings are actionable.
- [ ] No confidential environment detail is printed without a clear need.
- [ ] Data gaps are explicit.

## Security

- [ ] No credentials or tokens are hard-coded.
- [ ] No tenant IDs, client names, internal hosts, or private paths are embedded for publication.
- [ ] No unsafe dynamic execution is used without review.
- [ ] External input is treated as untrusted.
- [ ] Permissions requested are no broader than necessary.

## Publication

- [ ] Script source has been approved for public release.
- [ ] Comments and sample values are sanitized.
- [ ] No client-specific identifiers remain.
- [ ] No internal repository paths remain.
- [ ] No private certificate, app-registration, or automation identifiers remain.
- [ ] Catalog name, filename, risk flag, and card description match the script.
