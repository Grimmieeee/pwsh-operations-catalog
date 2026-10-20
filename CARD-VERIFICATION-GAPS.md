# Card and output verification gaps

These are review findings, not verified runtime results. No script receives a VERIFIED flag from this list.

Current release status is in [docs/PROJECT-STATUS.md](docs/PROJECT-STATUS.md).
Batch 1 is closed and eight read-only releases earned VERIFIED through owner
acceptance and recorded test evidence, not through this static-review list.
The specific remaining source gaps below are not reopened batch-1 tests.

## License product names

- `published-source/identity/INVOKE-REMOVE-LICENSES.ps1`: maps subscribed SKU IDs to `skuPartNumber`; falls back to the raw SKU ID if no mapping exists. Operator selects a numbered option or ALL. It does not guarantee friendly product display names.
- `published-source/identity/INVOKE-ASSIGN-LICENSES.ps1`: lists and reports `skuPartNumber`; operator selects a numbered option. A country code can be requested for missing UsageLocation.
- Cards now describe these actual prompts rather than asking the operator to bring a SKU.
- Pending: friendly product-name resolution, explicit unresolved-name reporting, and operator tests covering selected/all removal, unknown SKUs, lookup failures, and assignment. Preserve current change/confirmation behavior during any fix.

## Library verification gate

For each source version, compare every card claim with actual prompts and behavior. Check application/client-ID display-name resolution wherever relevant; it is not exercised by the two license scripts above. Record source findings separately from operator results. The rest of the library has not received a new claim-by-claim runtime verification in this UI pass.
