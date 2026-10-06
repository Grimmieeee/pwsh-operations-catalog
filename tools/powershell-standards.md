# PowerShell Standards

A practical baseline for interactive PowerShell tools in FIELD // KIT.

## Core principles

- Keep scripts boring, practical, and easy to review.
- Preserve operational logic during style/alignment work unless a real flaw is identified.
- Prefer safe defaults and explicit operator intent.
- Keep output human-readable and ticket-friendly.
- Support Windows PowerShell 5.1 unless a script is deliberately scoped to PowerShell 7+.
- Keep PowerShell 7 compatibility where practical.
- Avoid unnecessary menus, splash screens, animation, and decorative noise.
- Do not hide changes from the operator.

## Compatibility

- Avoid PowerShell 7-only syntax unless the script intentionally requires or relaunches PowerShell 7.
- Avoid null-coalescing and ternary operators in PowerShell 5.1-compatible scripts.
- Avoid backtick line continuations; prefer splatting, arrays, and intermediate variables.
- Use full parameter names in production code.
- Prefer explicit error handling around network, Graph, Exchange, file, and destructive operations.
- Use $PSScriptRoot for related local files.
- Do not depend on the caller's current working directory unless that dependency is explicit and validated.
- Public interactive .ps1 files should support Windows PowerShell 5.1 and File Explorer > Run with PowerShell unless the catalog card clearly states a different requirement.

## Launch behavior

Interactive scripts should:

- show one clear objective;
- prompt only for input that is actually required;
- use a top-level try/catch/finally where practical;
- remain open long enough for the operator to review the result;
- provide a clean completion prompt when an Explorer-launched PowerShell host would otherwise close immediately;
- avoid host-closing exit behavior unless the execution model requires exit codes.

A downloaded script should not require being launched from the repository root unless that requirement is explicit and necessary.

Non-interactive automation is a separate execution model. Do not apply pause-at-end behavior to unattended jobs.

## Authentication

Authentication should be quiet and automatic when required.

- Reuse a healthy existing session when tenant and permissions are correct.
- Connect only to services the selected task needs.
- Validate tenant alignment after authentication.
- Use process-scoped Graph context for multi-tenant work.
- Suppress welcome/banner noise when supported.
- Treat a missing session as normal setup, not an error.
- Treat tenant mismatch, missing permission, failed validation, or declined authentication as an actionable failure.

Avoid hard-coding brittle authentication fallbacks. Use authentication modes supported by the installed module version and verify the resulting session.

## Changes and destructive actions

Every change-making tool must make that status obvious before execution.

Use these meanings:

- READ ONLY — reviews information.
- MAKES CHANGES — modifies configuration, state, or access.
- DESTRUCTIVE — can remove data, access, objects, or other difficult-to-reverse state.

For destructive or high-impact actions:

- show exactly what will change;
- require explicit confirmation;
- confirm per item when multiple unrelated objects are affected;
- report completed, skipped, and failed actions separately.

## Output

- Prefer names people recognize over raw IDs.
- Show IDs only when they are required for troubleshooting or precision.
- Keep execution quiet; surface meaningful progress, warnings, and failures.
- Summaries should be concise and usable in a ticket.
- Never represent a failed or skipped query as a clean result.
- Mark unavailable data as unavailable.

## Files and exports

- Do not hard-code user-specific or client-specific export paths.
- Use a sensible runtime default and allow override when export is part of the workflow.
- Distinguish a directory path from a full filename.
- Wrap export operations in error handling.
- Test the actual export path, not only the in-memory result.

## Security

- Never hard-code credentials, access tokens, refresh tokens, private keys, or client secrets.
- Do not publish tenant IDs, client names, internal server names, private paths, protected-group lists, or environment-specific allowlists.
- Avoid Invoke-Expression and dynamic script execution unless there is a reviewed, documented requirement.
- Treat external data as untrusted input.
- Use the least privilege required for the task.

## Publication integrity

- Treat a known-working script as evidence, not raw material for stylistic rewriting.
- Do not change executable logic merely to align formatting or catalog presentation.
- Keep the user's working/original file untouched when preparing a public copy.
- If sanitization changes executable behavior, restart operational review and testing for that revised file.
- Publish the exact reviewed copy and verify the published-source copy still matches it.
- Prefer holding a script from publication over making an unvalidated "cleanup" change.

## Validation

Before a script is considered ready:

1. Parse it with System.Management.Automation.Language.Parser.
2. Resolve every parse error.
3. Review error and exit paths.
4. Review authentication/session handling.
5. Review destructive actions and confirmations.
6. Review output for data gaps and false-clean states.
7. Review for secrets and environment-specific information.
8. Test the actual operator workflow.
9. When intended for direct download, test the standalone file outside the repository working directory.
10. When intended for interactive Windows use, test File Explorer > Run with PowerShell or an equivalent fresh Windows PowerShell 5.1 host.
