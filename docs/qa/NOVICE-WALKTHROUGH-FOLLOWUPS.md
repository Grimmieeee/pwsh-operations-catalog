# New technician walkthrough follow-ups

Implemented October 21, 2026 after a read-only walkthrough of the live catalog.

| Finding | Resolution |
| --- | --- |
| Tool purposes require opening every entry | Library and search rows show the existing brief objective; script purposes remain identical to source objectives. |
| Broad searches bury complete tools | Matching titles rank ahead of incidental mentions; reviewed full tools win comparable matches. Exact command searches still lead to that command. |
| Search scope disagrees with card scope | Reviewed entity scope is reused in search, including mailbox, group, IP and local scopes. Navigation retains its existing broad sections. |
| Unpublished tools end at an unavailable message | Nine pending tools have three curated available next steps, explicitly described as partial tasks. The two CSV utilities clearly state that no working replacement is published and direct operators to their approved process. Downloads remain unavailable. |
| First launch instructions omit right-click | Ordinary script steps explicitly say to right-click the downloaded file. Existing terminal and BEC exceptions remain intact. |
| Bulk input format is unclear | Details show source-checked TXT and CSV examples for all 15 tools that accept both. CSV headers are UPN or Group, as supported by the parser. |
| Printer preparation repeats itself | Driver installation/permissions and printer address are each stated once. |
| Resource mailbox input overpromises file import | Corrected to typed mailbox names or addresses, comma separated; explicitly states no file input. Source accepts multiple targets but does not import files. |

Validation: catalog/path/checksum/markup checks and 52 site behavior/theme tests pass. New checks cover search ordering, exact command discovery, purpose visibility, entity scope, pending destinations, launch instructions and source-backed sample columns. All 92 downloadable files remain byte-for-byte unchanged. This release changes site presentation and navigation only.

Remaining follow-ups: the 11 planned tools still need source publication. Full first-run Windows and live Microsoft 365 acceptance remains separate from these site checks. CSV examples use reserved example.com addresses and must be replaced before running.
