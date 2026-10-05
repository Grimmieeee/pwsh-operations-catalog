# Reusable Skills

Small repeatable workflows for building and maintaining FIELD // KIT.

## Build a new script

Inputs:

- objective;
- target scope;
- read-only / change / destructive classification;
- required services;
- expected output.

Process:

1. Start from PowerShell Standards.
2. Choose the smallest interaction level that fits the job.
3. Build the operator flow before adding polish.
4. Validate authentication/session behavior.
5. Parse the script.
6. Test success, empty-result, and error paths.
7. Run the Script Review Checklist.
8. Publish only after the Publishing Checklist passes.

## Review an existing script

1. Read the actual current file.
2. Separate logic review from style/alignment review.
3. Flag logic or safety problems before changing behavior.
4. Parse before and after edits.
5. Confirm permissions, confirmations, error paths, and output.
6. Preserve working behavior unless the change is intentional.

## Align a script to the standard

1. Keep the operational goal unchanged.
2. Simplify prompts.
3. Simplify output.
4. Make risk state obvious.
5. Reuse validated sessions.
6. Replace environment-specific assumptions with discovery or runtime input.
7. Keep compatibility requirements intact.

## Troubleshoot authentication

1. Identify the exact service and module.
2. Check whether a session already exists.
3. Validate tenant alignment.
4. Validate scopes/roles needed for the operation.
5. Distinguish module/runtime problems from permission problems.
6. Reconnect only when required.
7. Record the smallest reusable lesson after the issue is understood.

## Prepare a catalog card

1. Verify display name.
2. Verify scope and purpose.
3. Verify READ ONLY / MAKES CHANGES / DESTRUCTIVE state.
4. Verify connect command.
5. Build a checklist from actual script behavior.
6. Keep the description decision-focused.
7. Approve source separately from metadata.
8. Confirm COPY / SAVE behavior.

## Create a handoff

Use the Session Handoff Template.

Capture decisions, current state, known limitations, and next actions. Do not turn the handoff into a transcript.
