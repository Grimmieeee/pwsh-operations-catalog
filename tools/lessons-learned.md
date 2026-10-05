# Lessons Learned

Small rules worth keeping because they prevent recurring failures.

## PowerShell

- Parse every edited script before calling it ready.
- Avoid PowerShell 7-only syntax in scripts intended for Windows PowerShell 5.1.
- Avoid backtick line continuations when splatting or intermediate variables are clearer.
- Here-string terminators are syntax-sensitive; validate them with the parser.
- Single-quoted strings do not interpolate variables.
- Do not rely on a successful command when the next step requires verifying returned state.
- Do not hard-code operator export paths.

## Authentication

- A cached session can be valid but belong to the wrong tenant.
- Session reuse should include tenant validation.
- Authentication failures from native/.NET components may not behave like normal PowerShell stream errors.
- Module-version differences can change which authentication modes are available.
- A disconnected session is a normal setup state, not automatically a warning.

## Hybrid identity

- Know the source of truth before changing a synchronized identity.
- A cloud-side change can be temporary when an on-premises source later synchronizes over it.
- Report partial containment as partial containment.
- Do not label a result successful merely because one control-plane call succeeded.

## Output

- Failed or skipped queries must never become clean findings.
- Keep execution quieter than the final summary.
- Human-readable names usually help the operator more than raw IDs.
- Truncate noisy exception output to the actionable message when appropriate.
- Keep summaries dense enough to scan but complete enough to support the next decision.

## Publishing

- Internal context is not documentation.
- Tenant names, server names, private paths, app IDs, certificate identities, protected-group names, and allowlists should not leak into public examples.
- Sanitize comments and sample values, not only executable code.
- Publish only source that has been reviewed as a standalone public artifact.
