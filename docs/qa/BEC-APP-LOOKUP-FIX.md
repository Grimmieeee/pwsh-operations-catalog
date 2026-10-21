# BEC app lookup correction — version 1.0.2

Assessment requested `/servicePrincipals/$ServicePrincipalId?...` without bracing the PowerShell variable. The parser treated the question mark as part of its name, so the intended identifier could disappear. A successful collection response could then be described as an unnamed app.

The revised assessment braces the identifier, requires a direct result to match the requested app ID, and accepts a filtered fallback only when exactly one result matches that ID. Failed, empty and mismatched results remain unresolved. Cache behavior remains unchanged. The isolated tests extract the actual current function; they do not patch a candidate before testing.

`tests/bec-app-lookup.test.ps1` covers direct resolution, filtered fallback, a collection returned by the direct request, failed requests, empty results, mismatched app IDs, cached repeated lookups and blank IDs. No live tenant requests run. The AST screening reports zero known URI exceptions.

All three workflow files use version 1.0.2 so the package retains matching versions. Containment and recovery changed only their version comments. Objective and alignment records bind the new bytes. The source comparison reverses only the three reviewed URI/response-guard changes and requires every other operational token to match the prior assessment fingerprint. The old runtime acceptance is retained as history; these offline checks do not confer a new operator-tested badge.

The workflow ZIP remains available only when each script's version, published hash, operational fingerprint and review evidence match the pinned package records. Unknown revisions and changed evidence still fail closed.
