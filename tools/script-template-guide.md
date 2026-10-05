# Script Template Guide

Use this as the structural starting point for a new interactive script.

## Recommended order

1. Compatibility / requirements note.
2. Script name and one-line objective.
3. Process-level setup required by the target PowerShell version.
4. Helper functions.
5. Dependency and session checks.
6. Target/input collection.
7. Pre-flight validation.
8. Core work.
9. Result summary.
10. Change/action summary when applicable.
11. Optional export.
12. Clean completion / pause behavior for interactive tools.

## Level 1 — single objective

Use for one lookup or one small action.

Keep:

- one input;
- one result block;
- one standard note;
- one clear completion point.

Do not add section chrome unless it improves scanning.

## Level 2 — multi-section review

Use for audits or tools returning several evidence groups.

Good section labels include:

- TARGET
- ACCOUNT
- FORWARDING
- PERMISSIONS
- RULES
- RESULTS

Keep section styling neutral. Status color should represent status, not decoration.

## Level 3 — connected workflow

Use for multi-phase response or recovery work.

Include:

- exact phase name;
- explicit READ ONLY / MAKES CHANGES / DESTRUCTIVE state;
- clear handoff to the next phase;
- completed / skipped / failed actions;
- recovery or escalation gates;
- operator confirmation before consequential changes.

## Prompting

Prompt only for values that cannot be discovered safely.

Prefer:

- runtime discovery;
- validated session context;
- target-specific input;
- sensible defaults.

Avoid:

- repeated tenant/company prompts;
- asking for values already available from the service;
- hidden assumptions.

## Reuse

When creating a related script:

- reuse the interaction pattern;
- reuse naming and output conventions;
- do not copy stale permissions or authentication blocks without validating them;
- keep shared behavior consistent without forcing every tool into the same size.
