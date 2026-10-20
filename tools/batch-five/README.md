# Batch 5 — local/setup/visual function checks

Build: `node tools/batch-five/build.mjs <output.ps1>`. Right-click the generated
file → Run with PowerShell, type RUN, and return the small JSON from
Desktop/FIELD-KIT-TESTS. No additional files, sign-in, API key, admin rights or
client targets are required. Original source hashes and exact coverage are
recorded per tool. The shared runner verifies hashes/syntax before any tests and
continues after individual failures. D 1 or D1 shows details; ENTER finishes.

13 sources / 51 cases. No previous batch is repeated. Git Security remains deferred.

Coverage: certificate selection/subject handling; signing-certificate selection;
Git filename screening; handoff metadata screening/object-ID validation; preflight
path presentation; simulated join success/failure; plain output helpers; generated
theme profile-block syntax/boundaries; palette values; screensaver cursor/bounds,
clock and drawing helpers. See the builder for exact per-source scope.

No real certificates are created, exported, imported, trusted or used for signing.
No repository commands run; no profile is edited; no policy changes, domain join,
reboot or continuous animation runs. These checks do not establish full native
workflow success, visual appearance, every display size or live resize behavior.

Known review areas remain explicit: theme installers contain behavior outside the
profile-block tests (including process-policy changes in some sources). A passing
block/palette test does not certify that installer behavior. Domain join tests
cover simulated approved outcomes; preflight/cancellation branches and real join
validation are outside this package. Signing and certificate-store workflows also
need separate evidence if those full-workflow claims are desired.
