# Card and output verification gaps

These are review findings, not verified runtime results. No script receives a VERIFIED flag from this list.

Current release status is in [docs/PROJECT-STATUS.md](docs/PROJECT-STATUS.md).
Batch 1 is closed and eight read-only releases earned VERIFIED through owner
acceptance and recorded test evidence, not through this static-review list.
The specific remaining source gaps below are not reopened batch-1 tests.

## License product names — resolved in 1.0.2

Both license tools resolve Microsoft product names from an embedded official reference and explicitly label unknown names unavailable. The owner accepted successful live 1.0.1 assignment/removal testing and the display-only 1.0.2 update without another live run. Name lookup, unknown-product and write/readback failure paths have offline regression coverage. This is not an exhaustive live test of all products or ALL removal. See [release evidence](docs/qa/LICENSE-1.0.2-VERIFICATION.md).

## Library verification gate

For each source version, compare every card claim with actual prompts and behavior. Check application/client-ID display-name resolution wherever relevant; it is not exercised by the two license scripts above. Record source findings separately from operator results. The rest of the library has not received a new claim-by-claim runtime verification in this UI pass.
