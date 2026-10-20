# Microsoft license product names

The JSON snapshot retains 623 distinct product entries from Microsoft's licensing
reference CSV. It records the reference URL, source date, retrieval date and full
CSV checksum. Only product GUID, string ID and display name are embedded.

Both standalone license tools embed the same resolver and data. No network
dependency is added to the client. Exact GUID matches take precedence, then an
unambiguous string ID. Documented Microsoft Copilot Studio aliases prefer the
current Microsoft branding. Unknown/ambiguous entries remain visibly unresolved.
The API continues to receive the original SKU GUIDs; display names never replace
identifiers in mutation requests.

Menus sort by display name. Assignment and removal previews and result/export
details use the same resolver. Candidate source version: 1.0.2. The replacement
live test package is 0.2.0; public site source remains at its last released version
until operator testing and acceptance.

`build.mjs` inserts or refreshes only the embedded resolver. For a refreshed
reference, review product aliases before regenerating. Embedded JSON escapes
non-ASCII characters so Windows PowerShell 5.1 decodes names correctly without
depending on the source file's legacy code page.
`tests/license-product-names.test.ps1` checks every reference product in both
scripts and exercises GUID precedence, SKU fallback, unknown and ambiguous names.
