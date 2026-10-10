# Reusable Skills

Small repeatable workflows for building and maintaining FIELD // KIT.

Use this as the workflow router, not as a second standards document.

## Which document wins?

1. Start with `OPERATING-STANDARDS.md` for project-wide decisions.
2. Use `field-kit-build-standard.md` for site/UI behavior.
3. Use `powershell-standards.md` for script implementation.
4. Use the focused checklist, guide, or reference for the task at hand.
5. Use `PROJECT-HANDOFF.md` to carry current state into the next session.

## Build a new script

Inputs:

- objective;
- target scope;
- READ ONLY / MAKES CHANGES / DESTRUCTIVE classification;
- required services;
- expected output.

Process:

1. Confirm the job is not already covered by a canonical tool.
2. Start from PowerShell Standards.
3. Choose the smallest interaction level that fits the job.
4. Prefer one 1-to-N workflow when the same job safely supports one or many targets.
5. Build the operator flow before adding polish.
6. Validate authentication/session behavior and required authority.
7. Parse the script.
8. Test success, empty-result, and error paths.
9. Run the Script Review Checklist.
10. Publish only after the Publishing Checklist passes.

## Review an existing script

1. Read the actual current file.
2. Separate logic review from style/alignment review.
3. Flag logic or safety problems before changing behavior.
4. Parse before and after edits.
5. Confirm permissions, confirmations, error paths, output, and post-change verification.
6. Preserve working behavior unless the change is intentional.
7. Do not use catalog alignment as a reason to rewrite known-working logic.
8. When preparing public source, work from a copy and leave the user's working/original file unchanged.

## Align a script to the standard

1. Keep the operational goal unchanged.
2. Simplify prompts.
3. Simplify output.
4. Make risk state obvious.
5. Reuse validated sessions.
6. Replace environment-specific assumptions with discovery or runtime input.
7. Keep compatibility requirements intact.
8. Validate direct-download / Explorer launch behavior when that execution model applies.

## Troubleshoot authentication

1. Identify the exact service and module.
2. Check whether a session already exists.
3. Validate tenant alignment.
4. Validate scopes/consent and administrative role/authority separately.
5. Distinguish module/runtime problems from permission problems.
6. Reconnect only when required.
7. Record the smallest reusable lesson after the issue is understood.

Use Connection Patterns for the reusable Graph, Exchange Online, and hybrid guidance.

## Prepare a catalog card

1. Verify display name.
2. Verify scope and purpose.
3. Verify primary module/platform.
4. Verify READ ONLY / MAKES CHANGES / DESTRUCTIVE state.
5. Represent destructive work as MAKES CHANGES + DESTRUCTIVE.
6. Verify connect command.
7. Build a checklist from actual script behavior.
8. Keep the description decision-focused.
9. Approve source separately from metadata.
10. Verify the published copy matches the reviewed approved file.
11. Confirm COPY / SAVE behavior.

## Create a handoff

Use `PROJECT-HANDOFF.md`.

Record the source of truth, local/remote state, locked decisions, static and runtime validation separately, known limitations, and the exact first step for the next session.

Do not turn the handoff into a transcript.
