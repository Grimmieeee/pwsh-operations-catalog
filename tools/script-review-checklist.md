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
- [ ] Interactive downloaded scripts do not depend on the repository working directory.
- [ ] Related local files resolve from $PSScriptRoot when applicable.
- [ ] File Explorer > Run with PowerShell is tested when that launch model is intended.
- [ ] Operational scripts do not silently install modules/capabilities unless setup is their explicit job.
- [ ] No normal execution path changes PowerShell execution policy.

## Authentication

- [ ] Only required services are connected.
- [ ] Existing sessions are validated before reuse.
- [ ] Graph tenant alignment is checked.
- [ ] Graph multi-tenant sessions use process scope.
- [ ] Exchange session health is checked before use.
- [ ] Connection failures return one actionable explanation.
- [ ] Required API scopes and administrative role/authority are both understood for change operations.

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
- [ ] Resulting state is verified after meaningful changes when the service exposes a reliable check.

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
- [ ] Generated temporary secrets are not auto-exported or automatically copied to the clipboard.
- [ ] Summary output does not repeat generated temporary secrets.
- [ ] The operator is warned when terminal capture/transcription could record a displayed temporary secret.

## Publication

- [ ] The user's working/original script was not modified merely for catalog alignment.
- [ ] Script source has been approved for public release.
- [ ] Comments and sample values are sanitized.
- [ ] No client-specific identifiers remain.
- [ ] No internal repository paths remain.
- [ ] No private certificate, app-registration, or automation identifiers remain.
- [ ] Catalog name, filename, primary module/platform, scope, risk flag, and card description match the script.
- [ ] Destructive items are represented as MAKES CHANGES + DESTRUCTIVE.
- [ ] The published-source copy matches the reviewed approved file.
- [ ] Any executable change made during sanitization was re-reviewed as a new revision.
