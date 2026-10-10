# Connection Patterns

Reusable connection guidance for Microsoft Graph, Exchange Online, and hybrid work.

## General

- Connect only to services required by the selected task.
- Reuse a healthy session instead of reconnecting unnecessarily.
- Validate the tenant before using a reused session.
- Keep authentication output separate from the evidence/report output.
- Request only the permissions the task needs.
- Treat API scopes/consent and administrative roles as separate requirements; change operations may require both.

## Microsoft Graph

Recommended behavior:

1. Check the current Graph context.
2. Validate tenant alignment.
3. Validate required scopes.
4. Reconnect only when validation fails or required scopes are missing.
5. Use process-scoped context for multi-tenant sessions.
6. Suppress nonessential welcome output when supported.

Never assume a successful authentication means the session belongs to the intended tenant.

## Exchange Online

Recommended behavior:

1. Check current connection information.
2. Validate that the connection is healthy and aligned to the target tenant.
3. Reconnect only when required.
4. Suppress nonessential connection banners when supported.
5. Use an authentication mode supported by the installed Exchange Online module.
6. Return one actionable failure if authentication cannot be completed.

Avoid embedding a module-version-specific fallback chain into every script unless that exact behavior has been tested and intentionally standardized.

## Hybrid identity

- Determine account source from authoritative service data where possible.
- Treat on-premises identity state as authoritative for attributes synchronized from Active Directory.
- Make synchronization direction explicit before changing cloud state that may later be overwritten.
- Do not imply permanent containment when a synchronized source can restore the prior cloud state.

## Validation

After connection, validate what the script actually needs:

- tenant;
- target object resolution;
- required permission/scope;
- service health for the requested operation.

Authentication is setup. Validation is proof the setup is usable.
