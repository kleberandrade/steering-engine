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

## 2026-11-17 — waypoint path following

- Retried synchronization after user authorization: connected GitHub write still
  returns HTTP 403, and normal git push cannot resolve github.com. No remote
  changes or remote CI execution are claimed.
- Added immutable SteeringPath and stateful FollowPath, per-agent traversal,
  bounded waypoint skipping, loops, final arrival and explicit reset.
- Added nine public-API tests: independent arrival math, copied configuration,
  route traversal, zero dt, overlapping waypoints and validation. All 37 core
  tests pass. The route example reaches its final region on Dart VM and JS.
- Added the numbered-route playground mode, English/Portuguese guide, updated
  roadmap and CI example execution. Dart and Flutter analysis pass.
- Existing local widget-test socket and publication-resolution restrictions
  remain. No package publication or release tag has been created.

## 2026-11-17 — GitHub synchronization and CI compatibility

- Published main through the authorized GitHub Desktop session and verified
  origin/main at a4e022e. The worktree is clean and tracks origin/main.
- First remote CI run 44012704639 passed Dart 3.3 and stable, including tests,
  JavaScript examples and the publication dry run. The Flutter 3.50 job exposed
  Material's library-level deprecation introduced after Flutter 3.47.
- Retained the legacy Material import to support the documented Flutter 3.35
  minimum. Suppressed only that import's deprecation, with an inline reason, in
  the application and widget tests. Other fatal analyzer checks remain enabled.
- The next CI run passed analysis and exposed Flutter 3.50's ListTile ink-surface
  assertion in both existing widget tests. Replaced the controls' opaque
  DecoratedBox with a shaped Material and inner Padding, so switches paint
  feedback on the visible surface. The existing tests supply the regression.
- The existing narrow-layout test now passes. The desktop-size test exposed a
  42-pixel dropdown overflow with the wider waypoint/composition labels under
  test fonts; enabled isExpanded so the selected label uses its finite width.

## 2026-11-17 — static circle avoidance

- Added immutable CircleObstacle and ObstacleThreat values plus stateless
  ObstacleAvoidance. Detection inflates circles for agent size and margin, selects
  the earliest ray surface, and returns lateral/braking or radial overlap escape.
- Preserved the integrator and composition contracts. This is reactive steering,
  not collision resolution; bounded acceleration and local visibility impose
  documented limits. Moving circles, walls and polygons remain future work.
- Added 15 public-API tests with independent off-axis entry/braking math, horizon
  and tangent boundaries, stable ties, copied configuration, rotated scenes,
  overflow rejection and a swept-clearance arrival scenario. Observed a failing
  derived-entry overflow assertion before fixing the numeric boundary.
- The three-circle CLI scene reaches its target on Dart and JavaScript with 9.96
  units of minimum swept physical clearance after accounting for agent radius.
- Added a Flutter obstacle mode with threat/expanded-circle/scan rendering and
  look-ahead/margin controls, plus an interaction test and bilingual visual guide.
- Local Dart and Flutter analysis and web compilation pass. Full remote CI,
  including widget tests and publication dry run, is checked after synchronization.

## 2026-11-17 — ub-mode and source organization

- Applied the explicitly requested local ub-mode instructions: baseline first,
  small ordered commits, tests before new group behavior, and factual validation.
- All 52 baseline tests passed before moving code. Separated immutable core/math,
  individual behaviors, composition, geometry and navigation into focused files.
  Split the Flutter page, painter and theme while preserving its existing tests.
- The public package entry point and existing class/constructor contracts remain
  unchanged; all 52 tests and Dart analysis pass after reorganization.
- Invoked installed crapper, dryer and mutator against lib in an isolated metrics
  directory. They reported no supported sources: their language lists omit Dart.
  These results are unsupported-language outcomes, not passing quality scores.
  Dart tests, analysis and explicit mathematical checks supply the validation;
  no CRAP, duplication or mutation score is claimed.

## 2026-11-17 — group steering with /ub-mode

- Read the explicitly requested local ub-mode workflow. Reorganized source and
  lab responsibilities in a separate baseline-preserving commit before adding
  group behavior. No public imports or existing constructor names were changed.
- Wrote the group contract and mathematical tests first and observed missing-API
  failures, then implemented AgentNeighborhood, Separation, Alignment, Cohesion
  and Flocking. Alignment delegates velocity response; Flocking delegates weights
  to the existing WeightedBlend rather than introducing another blend algorithm.
- The 16 new tests independently verify local acceleration equations, snapshot
  ownership and identity, duplicate references, inclusive radii, validation,
  symmetry and frame-order independence. A pair's relative motion is compared
  against the analytic damped-system solution, with integration tolerance.
- All 68 core tests and Dart analysis pass. The CLI advances 24 agents for 20
  simulated seconds with one shared observation per frame, on Dart and JS.
- Added a 24-agent visual lab with independent rule modes, weight controls,
  neighborhood rendering and seeded reset. Added its interaction test before
  the renderer/frame changes; initial analysis caught the absent flock contract.
- Resolved the new Flutter Alignment name collision explicitly and documented
  import prefixes for consumers. Local Flutter analysis/build and remote CI are
  tracked separately; no unsupported-language quality score is claimed.
- Added bilingual equations, a vector diagram, public-import guidance, roadmap
  updates and CLI/JS CI coverage. No package publication or release tag was made.

## 2026-11-17 — shared-frame flocking

- Applied the requested ub-mode workflow: preserved the 52-test refactor baseline,
  wrote the new public API tests first and observed missing-API failures, then
  implemented neighborhood ownership and collective rules. The new lab interaction
  test also preceded its renderer API and initially failed analysis as expected.
- Added 16 group tests for independent separation/alignment/cohesion calculations,
  snapshot identity and ownership, exact boundaries, symmetric/coincident agents,
  weights, limits, validation and frame-order independence. All 68 core tests pass.
- The synchronous pair scenario uses an independent solution of d''+4d'+0.2d=0
  to check both relative distance and speed while retaining shared translation.
- The 24-agent CLI advances toward its destination on Dart and JavaScript. The
  Flutter lab supports isolated rules, weighted flocking, separate target bias,
  a visible neighborhood, synchronous stepping and seeded reset. World wrapping
  remains a demo concern; perception uses Euclidean distance.
- Kept the supported public import unchanged. Documented the Flutter Alignment
  name collision and the import-prefix alternative. Dart and Flutter analysis
  pass; local widget testing still requires the socket-capable CI environment.
- Quality-tool language limitations remain as recorded above. No unsupported
  metrics are claimed. Remote CI and dry-run publication are checked after push;
  no hosted package publication or release tag is part of this change.

## 2026-11-17 — spatial perception and remaining following behaviors

- Measured the original linear implementation before index changes using native
  AOT, fixed-density seed-42 fixtures and separate processes at 100/500/1000 agents.
- Wrote spatial equivalence tests before the named constructor existed, observed
  missing-API failures, then added conservative grid queries with sorted source
  ordinals and exact filtering. Unsafe scales/expensive cell ranges fall back to
  linear scans. Seeded neighbor lists and complete flock accelerations match.
- Reduced unnecessary cell traversal after measuring the first index version;
  retained scale-aware boundary padding and passed the same equivalence oracle.
- Audited existing FollowPath. Added tested LeaderFollowing, movement-filtering
  QueueFollowing and WallFollowing with immutable WallSegment geometry. They are
  local steering rules, not collision solvers or a global queue reservation API.
- All 81 core tests pass. New examples verify VM and JS integration. Added lab
  population/index controls, per-tick physics timing and following demonstrations.
- Prepared a separate Flame 1.38 example and component-mapping tests. It requires
  a newer Flutter SDK than the local installation, so its analysis/tests/build
  are validated in the stable-SDK CI job, independently of the pure Dart core.

## 2026-11-17 — release preparation

- Complete CI run 44020178457 passed Dart 3.3/stable, all core tests, the expanded
  Flutter lab, Flame adapter tests/web build, JS examples and pub dry run.
- Prepared source 0.1.0, reorganized release notes and added English/Portuguese
  following, spatial-index and Flame guides. The behavior audit includes existing
  waypoint paths plus leader following, spatial queuing and finite wall following.
- Repeated current-code linear runs with the same AOT benchmark executable. The
  recorded uniform-scene medians are 66.07 ms linear vs 14.86 ms grid at 1000
  agents; at 100 agents the grid is slower. Reported process RSS and limitations
  separately rather than treating RSS as isolated index allocation.
- Consolidated geometry projections on the tested Vec2 dot product. Core tests,
  architecture checks and release source validation remain independent of Flutter.
- Actual publication and hosted metadata are verified after the release-source
  CI; a source version and successful dry run are not an upload confirmation.

## 2026-11-17 — release verification and remaining upload

- Release-source CI 44020825763 completed successfully at d07f32d: Dart 3.3/stable,
  81 core tests, five Flutter lab tests, two Flame tests, JS examples, both web
  builds and pub dry run. GitHub source release/tag v0.1.0 was created and visibly
  verified at that commit, with hosted-upload status explicitly marked pending.
- The authorized Terminal UI action was automatically denied by Computer Use.
  The normal command executor's publication preflight also failed because its
  restricted dependency cache could not be updated. No package upload occurred.
- Verified the official publication flow: a first package version requires the
  Dart CLI before pub.dev automation can be configured. Recorded a concrete
  `dart pub publish` handoff and hosted-version verification URL in the release
  audit. All implementation and source-release work is complete; actual pub.dev
  upload is the remaining action.

## 2026-11-17 — illustrated learning handbook and Wiki

- Replaced the missing learning sequence with a bilingual handbook: foundations,
  18 behavior/composition chapters, spatial lookup, recipes and troubleshooting.
  Each algorithm has implementation-matched pseudocode, tuning, an experiment,
  Dart configuration, limits and its own conceptual diagram. Preserved detailed
  equation guides and linked them from the learning path and both READMEs.
- Authored 21 accessible SVG diagrams with deterministic standard-library Python
  generation. Reviewed geometric conventions, including screen-Y wall normals,
  expanded-circle ray entry and exact-radius versus grid-candidate filtering.
- Corrected stale README/roadmap claims about optional spatial lookup, laboratory
  populations, collective rules and finite wall following versus contact physics.
- Created the initial GitHub Wiki Home and cloned the separate Wiki repository
  through GitHub Desktop. Added an explicit, reviewable mirror command: it rewrites
  links and copies images without network, commits, deletions or credentials.
  Reviewed handbook sources remain in this repository; Wiki publication is
  verified separately after syncing, not inferred from the local export.
- Local evidence: documentation links/coverage/XML checks passed for 27 documents,
  all 18 implemented SteeringBehavior classes and 21 diagrams. Extracted 22 Dart
  snippets; all generated programs compiled/executed with the package config.
  Dart analysis passed. The normal test launcher hit the restricted pub cache;
  invoking the existing test runner directly with package_config.json passed all
  81 tests. No runtime library or Flutter application behavior changed.
- Invoked crapper, dryer and mutator on lib as required by the workflow; these
  installed tools still report no supported Dart sources. No scores claimed.
- Added stable-SDK CI checks for documentation, diagram reproducibility and
  extracted snippets; excluded maintenance tooling from the published package.
- Publication evidence: source commit 22ed69f is pushed on main; Wiki commit
  6d674c2 is pushed on its master branch. Browser verification showed 22 pages,
  working Home-to-Arrive navigation, the grouped sidebar and an Arrive SVG loaded
  at its native 800x360 dimensions. The Wiki mirror check reports zero differences.
  CI run 44024426229 passed both Dart SDK jobs, handbook checks/snippets, Flutter
  lab and Flame jobs. The publication change is documentation-only.

## 2026-11-17 — publication follow-up, live labs and 0.2.0 plan

- Rechecked the source-release audit before changing hosted installation claims.
  The browser origin approval gate denied pub.dev access; no alternate route was
  used after denial. Hosted version and publisher remain unverified, and no
  transfer, upload or score is claimed. Both READMEs show the hosted dependency
  syntax conditionally, retaining the working local-path installation.
- Prepared GitHub Pages deployment of the existing Flutter and Flame artifacts,
  with correct project/subdirectory base hrefs. All existing Dart/Flutter/Flame
  jobs must pass before a main-branch deployment; PRs do not publish. Enabled
  Pages' GitHub Actions source through repository settings. Runtime core remains
  untouched and source version stays 0.1.0.
- Added shareable lab mode links to every algorithm chapter. Labels live once in
  lab_modes.dart; the entry point parses mode once, unknown/missing values fall
  back to Arrive, and the requested mode initializes before scene reset.
- Authored regression fixtures first: the independent Dart check failed on the
  missing mode parser, then passed all 18 supported labels and unknown/empty
  fallbacks. Added a Flutter unit test and a widget scenario checking Queue opens
  with eight agents. Local Flutter analysis passed and the production web build
  succeeded with the hosted base path; Flutter engine tests run in remote CI.
- Extended documentation checks to the new deployment and 0.2.0 design guides,
  and validated chapter-link coverage against all 18 supported laboratory modes.
  All 29 document/link checks and 21 deterministic diagrams passed locally.
- Recorded the 0.2.0 plan with a separate proposed FollowPolyline API, finite
  segment projection, arc-distance look-ahead, explicit progress/reacquisition,
  numerical acceptance fixtures and incremental release gates. The existing
  FollowPath contract is preserved; no planned algorithm is claimed implemented.
- crapper/dryer/mutator were invoked on lib; installed tools still report no Dart
  sources. Deployment/Wiki mirror status is recorded after remote verification.

## 2026-11-17 — source 0.2.0 continuous-route delivery

- Added and visibly verified ten GitHub topics, an accurate description and the
  Pages website in About. Retained version tags as separate release evidence.
- Implemented immutable PolylinePath and PathProjection, finite and constrained
  projection, duplicate-edge skipping, explicit all-coincident rejection and
  open-clamped/loop-wrapped arc sampling. Existing FollowPath is unchanged.
- Added FollowPolyline with one progress state per agent, shared geometry, predicted
  projection, global first acquisition, forward-window monotonic traversal,
  unwrapped laps, explicit reset/reacquisition and bounded final arrival.
- Added an optional tangent-angle/distance corner speed cap. The executable paired
  L-route comparison reduced peak corner-neighborhood speed from 39.9721 to
  37.7693 but increased maximum route distance from 4.8020 to 4.9133. Documented
  the tradeoff rather than claiming universally better tracking.
- Wrote new public-API tests first and observed missing API compilation failures.
  All 97 core tests now pass locally, preserving the prior 81 and adding 16 cases
  for independent geometry/math, branch windows, priority skips, laps, shared
  geometry, bounds and complete open/looping trajectories. VM and JS examples pass.
- Added a separate continuous lab scene with last projection and arc target,
  preserving the old mode. Added a widget regression; local Flutter analysis and
  hosted-base-path web build passed. Full Flutter/Flame tests run in CI.
- Added the bilingual Wiki chapter and reproducible SVG, updated navigation,
  README installation version, architecture, implementation record and 0.2.0
  audit. Checks cover 19 algorithms, 23 Dart snippets and 22 diagrams. Source
  version is prepared as 0.2.0; hosted pub.dev availability remains unverified.
- Invoked crapper/dryer/mutator after the Dart change; installed tools report no
  supported sources, so no complexity/duplication/mutation scores are asserted.
- Prior Pages deployment run 44025798157 succeeded for source 3ec2d20. The live
  browser check was interrupted; deployment success is not visual verification.
