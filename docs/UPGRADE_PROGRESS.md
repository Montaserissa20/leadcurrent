# LeadCurrent Pro upgrade

Baseline: `28504e8`; checkpoint branch `checkpoint/pre-pro-upgrade-20261015`.
Baseline verified: 37 domain/HTTP tests (401 assertions), 2 browser tests (24 assertions), all passing.

- [x] Inspect existing services, permissions, views and tests; preserve database and checkpoint.
- [x] Actionable NBA and calculated automation, centralized thresholds; user timezone, bounded candidates, no background writes.
- [x] Customer 360 workspace and connected timeline/tasks; inline record editing and task creation.
- [x] Task creation/edit/completion and activity filters; parent/task ownership rechecked; repeated followup submission reuses task.
- [x] Interactive dashboard and database-backed analytics; currencies separated, zero-safe conversion and means.
- [x] Responsive light/dark UI and real browser verification at 390px; screenshots visually reviewed.
- [ ] Full regression/security/build checks, docs and exact-commit CI.
- [ ] Live verification (requires deployed environment/access; no public deployment currently verified).

No schema, dependency, transition graph, conversion or 24-hour rule changes. Existing test files retained. Render build/start configuration retained; no paid service added.

Final local run: 53 domain/HTTP tests / 537 assertions (seed 4574), 5 real Edge browser tests / 51 assertions (seed 38064): **58 tests / 588 assertions, zero failures/errors/skips**. Zeitwerk passed; Brakeman 8.1.0: zero warnings/errors. Production assets compiled; 25 source-package policy checks passed. Markdown/local-link checks passed; original tests, schema, Gemfile/lock and local key unchanged. Windows Ruby/Brakeman fallback diagnostics do not change these reported results.

Screenshots: ignored `.local/upgrade-preview/` (fictional test records; desktop light/dark, mobile overview/analytics/profile). Historical research/cost audit documents describe their original snapshots; this upgrade's current test record is here.
