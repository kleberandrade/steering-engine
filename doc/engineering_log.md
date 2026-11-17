# Engineering log

## 2026-11-17 — initial foundation

- Matched the sibling engines' pure Dart core, MIT license, bilingual guides,
  public-entry-point tests, semantic versioning and Flutter lab separation.
- Implemented seven local acceleration behaviors, weighted/priority composition
  and semi-implicit Euler integration. Navigation and flocking remain planned.
- Added an independent 10,000-vector regression, observed it fail on a one-ulp
  overspeed, and corrected vector limiting while preserving strict state bounds.
- Local Dart analysis, 28 core tests, both CLI examples and JavaScript execution
  pass on Dart 3.11.5. Flutter analysis and a web build pass on Flutter 3.41.9.
- Standard local Flutter widget tests cannot start because the execution sandbox
  denies the loopback socket needed by flutter_tester. They are included in CI.
- Publication dry run was attempted but dependency resolution cannot complete in
  the network-restricted environment; CI runs the normal dry run. No publication
  or release tag has been created.
- GitHub metadata confirmed an empty repository. Initial synchronization through
  the connected GitHub contents API was denied with HTTP 403 (Resource not
  accessible by integration). The remote remains unchanged; work is retained
  in the local repository with origin configured for a later push.
