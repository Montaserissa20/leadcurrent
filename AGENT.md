# LeadCurrent agent guide

This describes the implemented independent application at D:\LeadCurrent. D:\ruby_project is a read-only reference: never write there, run its application or migrations, copy its data, keys, branding, or link to its files. Inspection is in docs/OLD_PROJECT_INSPECTION.md. No project license was found there; no application source was copied.

## Architecture

Ruby 3.4.7 / Rails 8.1.4 / PostgreSQL 17; ERB, Propshaft, importmap, Turbo, Stimulus; Minitest and Capybara/Selenium. Plain maintained CSS. No React, Redis, AI provider, worker or durable async jobs are required. Railway Docker deployment, retained Render native Ruby alternative; GitHub Actions Linux + PostgreSQL CI.

Production verified on Railway/Docker at https://leadcurrent-production.up.railway.app on 16 October 2026; Render is a retained alternative. Current evidence and deployment limitations: docs/PRODUCTION_TEST_REPORT.md. CSP uses a random per-session nonce for script-src and style-src; keep it nonempty for fresh anonymous sessions and do not add unsafe-inline. Integration/system regressions are in content_security_policy_test.rb.

Domain: Organization owns Users, Companies, Contacts, Leads, Opportunities, Activities, Tasks and AuditEvents. User has bcrypt password_digest, manager/salesperson role and time_zone. Database-backed Session expires after 12 hours. Login stores only an opaque Rails signed/encrypted session reference in an HttpOnly cookie; logout destroys DB Session. Signup creates an isolated Organization and manager in one transaction. Managers can add salespeople through settings; no email is sent.

Password management (17 October): Settings > Your profile > Security & Password is available to both roles. GET/PATCH /settings/password has no target user identifier: PasswordsController always uses current_user and rejects target fields. ChangePassword verifies current password under a user row lock, reuses has_secure_password (12+ characters, bcrypt's 72-byte ceiling), requires confirmation and a different password, clears password_change_required, replaces all of that user's DB Sessions and records a secret-free AuditEvent in one transaction. The replacement retains the current session's expiry; reset_session rotates the Rails cookie/CSRF nonce. Login authenticates and creates its Session under the same user lock to prevent a pre-change password check creating a post-change session.

Only newly manager-created salespeople get password_change_required=true. The additive 20261017000100 migration defaults false for all existing accounts and new workspace managers. ApplicationController blocks CRM reads/writes until replacement, including profile/team/signup bypasses; only password actions and login/logout are exempt. The restricted screen permits logout and omits CRM navigation. Never permit this flag, roles or target IDs in profile/password form input. Password changes are limited to five attempts per account per ten minutes using an explicit process-local MemoryStore; multiple production processes require a shared rate-limit store. Password forms use no-store/no Turbo snapshots, never render password values, and have accessible Stimulus visibility controls. No recovery email, administrator reset or MFA is added. See docs/PASSWORD_MANAGEMENT_TR.md and the new password_management/change_password tests.

Workspace members can read their organization records; only record owner or manager can mutate. All route queries must use WorkspaceAccess.scope. TenantRecord checks foreign associations and contact/company consistency. Never permit organization_id, role, first_contact_deadline, first_contact_at, status or closed_at from generic edit forms. All ownership changes must resolve users through the current organization. Recheck authorization after acquiring row locks.

## Source map

- app/models: persistence, validations, workflow update guards.
- app/services/create_lead.rb: company/contact/lead creation, transaction, owner permission.
- app/services/follow_up_deadline.rb:2: FIRST_CONTACT_WINDOW = 24.hours. deadline(created_at), overdue?(lead, now:), remaining.
- app/services/record_activity.rb: call; first completed contact tracking and optional followup atomic write.
- app/services/schedule_follow_up.rb: future task creation; parent lock and duplicate pending title/time reuse. Scheduling/completing a task is never completed first contact.
- app/services/manage_task.rb: task edit/complete; parent-before-task lock order, current task and parent ownership checks, no status/contact side effects.
- app/services/customer_profile.rb: contact + company + tenant scoped related records, recent combined lead/opportunity timeline and tasks. Converted lead conversations stay visible on the opportunity.
- app/services/sales_metrics.rb: database grouped counts/sums/averages; all-time current workspace snapshot, per-currency values; converted / all leads percentage (zero-safe).
- app/services/lead_transition.rb:2: TRANSITIONS, call. New → Contacted/Disqualified; Contacted → Qualified/Disqualified; Qualified → Disqualified. Converted/Disqualified terminal.
- app/services/lead_conversion.rb: call. Qualified-only; lock + transaction + unique Opportunity.lead_id. Copies associations, moves pending tasks, audits and marks lead Converted.
- app/services/opportunity_transition.rb:2: TRANSITIONS, call. Qualification → Proposal/Lost; Proposal → Negotiation/Lost; Negotiation → Won/Lost. Won/Lost terminal, closed_at persisted.
- app/services/next_best_action.rb: PRIORITIES: 100 overdue contact, 95 overdue task, 90 within 4h, 85 today's task, 80 72h inactivity, 70 close within 7d, 50 other new contacts. Bounded SQL candidates and eager loading, one highest-priority suggestion per record, user's day boundary. Reasons and executable contact/follow-up/task/stage actions; no provider dependency. Pending followups suppress duplicate opportunity scheduling suggestions.
- app/services/workspace_access.rb: query scope and owner/manager authorization.
- app/controllers/actions_controller.rb: allowlisted record type and authorized contact/note/followup actions.
- app/controllers/health_controller.rb: /up verifies DB query.
- app/javascript/controllers/appearance_controller.js: theme/localStorage, mobile menu.
- app/assets/stylesheets/application.css and pro.css: responsive light/dark identity, interactive metric cards, native progress visuals and compact inline forms.
- db/migrate: independent PostgreSQL schema, FKs, check constraints, unique conversion index; db/schema.rb generated, never edited by hand.

## Rules and tests

Exactly at first-contact deadline is on time; strictly after is overdue. Use elapsed hours, DB UTC, request Time.use_zone(user.time_zone). First contact means a manually recorded completed call/meeting/customer message. Activities require nonfuture completion timestamp. Future tasks do not count. Generic edits cannot change workflow attributes. Closed records cannot receive new activity/followup. All meaningful writes create AuditEvent inside the transaction. Currencies are grouped separately; no implicit exchange conversion.

Never keep workflow_change true after a service finishes. Internal flag is trusted server-side only. Use with_lock for transitions and conversion, including rechecking latest owner. Keep unique DB index even if model uniqueness exists. Use explicit boolean parsing for redirect flags; the string 'false' is present and must not be treated as true.

test/models/deadline_test.rb uses actual travel_to for creation, before/exact/after boundary, completion, scheduled tasks, midnight and DST. test/models/workflow_test.rb exercises all lead/opportunity transition pairs and rollback. test/models/concurrent_conversion_test.rb uses two DB connections and threads with transactional tests disabled only for that class; cleanup targets only its own test organization. test/models/next_best_action_test.rb covers priorities/reasons/tenants and fulfilled suggestions. test/integration covers protected HTTP flow, tampered params, authorization, CSRF, persistence, forms and all pages. test/system covers actual Turbo browser flow, theme/mobile and one-submit NBA action. Reset viewport per browser test.

Pro coverage: test/models/pro_upgrade_test.rb (metrics, Customer 360, reminder idempotency, thresholds, timezone, ownership and query growth), test/integration/pro_upgrade_test.rb (task CRUD/completion, filters, profile, analytics and NBA endpoints), test/system/pro_workspace_test.rb (real inline tasks/edits, NBA task/stage actions, analytics and 390px layouts). Screenshots use fictional test records under ignored .local/upgrade-preview. They are not production evidence.

## Commands

Windows PostgreSQL: powershell -ExecutionPolicy Bypass -File bin/local-postgres.ps1 [-Action start|stop]. Default independent loopback port 55432; trust is development only. Other environments configure PGHOST, PGPORT, PGUSER, PGPASSWORD. Rails does not load .env files automatically.

bundle install
bundle exec rails db:prepare db:seed
bundle exec rails server -b 127.0.0.1 -p 3100
bundle exec rails test
bundle exec rails test:system
bundle exec rails zeitwerk:check
bundle exec brakeman --no-pager --quiet
Production asset build: RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile (PowerShell set env variables separately).

Tests use leadcurrent_test only. Do not run test cleanup against development/production. Keep clock-changing tests sequential. Linux CI uses Chrome; Windows uses headless Edge.

## Security and deployment

CSRF :exception; parameterized SQL search; allowed statuses and DB checks; bcrypt; DB sessions; rate-limited login/signup; CSP; production SSL/secure cookies; filtered secret/email parameters. Rate limiting is process-local and requires central storage for multi-instance production. No master key, .local files, .env, logs or DB dumps may be committed or packaged. Never log provider/local GitHub credentials.

render.yaml defines web + separate PostgreSQL; bin/render-build.sh installs production gems, assets, migration and explicit optional seeds. SECRET_KEY_BASE generated by Render; DATABASE_URL from database binding. DEMO_PASSWORD must be supplied for production. Demo seeds are idempotent and fictional; do not reset production on deploy. Free Postgres expires after 30 days; document upgrade requirement. Core rules do not depend on the developer machine or background jobs.

Public deployment must be checked at its actual URL: health, login, create/contact/qualify/convert/close, refresh persistence, deadline and NBA, unauthorized workspace access. A build alone is not proof. Missing Render account access blocks only deployment, not local work. Always check the named LeadCurrent CI workflow for the exact delivered commit; a successful Dependabot run is not application CI. Do not merge unrelated dependency PRs just to make a badge green.

Conventions: Rails naming, short domain services, transactional writes, scoped queries, strong params, ERB escaping, accessible labels, minimal dependencies. Add tests for domain changes and actual regressions; do not fabricate tests, costs, research sources, CI states or public URLs. docs/PRESENTATION_TR.md contains verified file line locations; update them when rules move.

## Convention audit and explicit design choices

The 16 October source audit found no application global monkey patches, method_missing, default_scope or core-class reopening in app/, lib/ or config/. Lead's before_validation :set_deadline, on: :create intentionally persists the initial deadline through FollowUpDeadline; keep this small, visible initialization callback. Authentication before_action and the timezone around_action are ordinary request filters. Model validations, including TenantRecord association checks, reject invalid writes without performing workflow side effects.

Workflow orchestration deliberately lives in explicit app/services classes instead of model callbacks. Lead/Opportunity workflow_change is a server-only guard flag, not an authorization mechanism; services authorize again under lock and clear the flag in ensure. This project-specific convention and bounded NBA queries are intentional; there is no global Rails override. Two independent travel_to boundary tests in test/models/time_rule_boundaries_test.rb cover the 4-hour warning and 72-hour inactivity alongside the existing exact 24-hour tests. Keep all three thresholds independent.

TenantRecord is the only application model concern: it declares organization ownership and validates same-tenant associations plus contact/company consistency; it does not write records. Record the concern here whenever its behavior changes. Domain vocabulary: aday = Lead; fırsat = Opportunity; tamamlanmış temas = contact Activity; planlı takip = Task; gecikmiş = overdue; aort dilimi = lead-to-won core flow. test/system/adaptation_interaction_test.rb measures the existing dashboard contact-plus-followup flow using browser events and Rails request notifications, with persisted database assertions; never infer Salesforce click counts or missing features from it.
