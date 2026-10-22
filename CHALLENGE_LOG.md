# LeadCurrent Phase 1 challenge log

Started: 20 October 2026 (Europe/Istanbul). Status: Phase 1 published to GitHub main, exact-commit CI passed, Railway deployment and one genuine production Groq analysis verified on 20 October. See release evidence below.

## Existing project and baseline

- Previous project: LeadCurrent, Ruby on Rails CRM.
- Repository: https://github.com/Montaserissa20/leadcurrent
- Baseline commit before this upgrade: [`346722284e94ce01a442bbc8d3c7e0a0ef47ebf7`](https://github.com/Montaserissa20/leadcurrent/commit/346722284e94ce01a442bbc8d3c7e0a0ef47ebf7). Delivery details are recorded in the release verification section below.
- Existing production URL: https://leadcurrent-production.up.railway.app
- Customer pain point: staff must manually synthesize customer notes, conversations and pending followups; deterministic priorities cannot interpret that context. Prior usability research remains in [ADAPTATION_EVIDENCE_TR.md](docs/ADAPTATION_EVIDENCE_TR.md). This addresses the task-specific need for contextual advice, not a claim that Salesforce lacks AI.
- Why continue: the user explicitly chose to extend the working, tenant-isolated CRM and preserve its deployed sales workflow rather than pivot or rebuild.
- This week's personal objective (user-stated assignment): genuine Groq-powered customer analysis, NBA explanations, activity summaries and followup drafts, all read-only.
- Publication boundary: initial implementation remained local; the user's subsequent "Safely Push LeadCurrent Phase 1 to GitHub" task explicitly authorizes the existing repository's normal main push and checking its Railway deployment. No force-push, history rewrite, new Railway service or Phase 2.

## Implementation and evidence

Implemented server-only real Groq HTTP integration, scoped PostgreSQL context, four advisory modes, lead/opportunity Turbo panels, loading/duplicate prevention/copy/error recovery, safe text output and process-local request limits. There are no new gems, migrations or CRM writes. Existing domain services, database configuration, CSP and original tests remain unchanged. Architecture, setup, privacy limits and production checklist: [AI_SALES_ASSISTANT_TR.md](docs/AI_SALES_ASSISTANT_TR.md). README and AGENT.md document the feature; earlier assignment documentation is preserved.

### Automated baseline and final regression

Actual local PostgreSQL/headless Edge runs on 20 October 2026:

| Run | Seed | Tests | Assertions | Failures / errors / skips |
|---|---|---|---|---|
| Baseline Rails domain/integration | 41435 | 67 | 924 | 0 / 0 / 0 |
| Baseline browser | 24517 | 9 | 104 | 0 / 0 / 0 |
| Final Rails domain/integration | 60629 | 89 | 1301 | 0 / 0 / 0 |
| Final browser | 31787 | 11 | 150 | 0 / 0 / 0 |

Baseline: 76 tests / 1,028 assertions. Final normal suite: **100 tests / 1,451 assertions**, including 24 added tests. All normal AI tests mock HTTP transport; none prove a real API call. Sources: [service tests](test/models/ai_services_test.rb), [HTTP/security tests](test/integration/ai_advice_test.rb), [browser tests](test/system/ai_sales_assistant_test.rb), [transport fixture](test/support/ai_test_support.rb). Mock token counts are synthetic and excluded from actual usage below.

Final Zeitwerk eager-load check passed. Brakeman 8.1.0 exited 0 with 0 scan errors and 0 security warnings (Windows Ractor/fork fallback diagnostics appeared on stderr). Production asset precompile passed with dummy production secret configuration; this is a local build, not deployment evidence.

Source policy scan: 219 eligible files, no local-secret match or forbidden path. Gitleaks 8.30.1 directory scan of 222 tracked/untracked source files returned two findings, both previously reviewed false positives in unchanged baseline files: a public commit hash in `docs/VERIFICATION_TR.md:39` and a synthetic test password in `test/integration/authentication_test.rb:46`. No new credential finding; no ignore rule was added. Documentation validation: 25 Markdown files, 230 local links, 34 tables, all 19 required README sections, 20 protected earlier evidence files unchanged, 16 ignore checks; local master key unchanged. Original prompt matches the attachment, protected domain/database/CSP files match the baseline, and the final runtime fingerprint matches the real API report.

### Real Groq verification

**PASS**, separate opt-in [live browser script](script/verify_groq.rb), seed 5829: 1 test / 27 assertions / 0 failures, errors or skips. Four actual POSTs used `openai/gpt-oss-20b`, a fictional Atlas 40-seat subscription lead in the local test PostgreSQL database, and a real headless browser. Final run: **2026-10-20 09:14:12–09:15:38 UTC** (12:14:12–12:15:38 Europe/Istanbul). The transaction rolled back. AI did not alter the lead, tasks, activities or audit records. Credential absence from rendered HTML was asserted without printing its value.

| Mode | Result | Prompt tokens | Completion tokens | Total | Browser response seconds |
|---|---|---|---|---|---|
| analysis | PASS | 886 | 237 | 1123 | 1.300 |
| next_action | PASS | 891 | 275 | 1166 | 1.787 |
| summary | PASS | 888 | 239 | 1127 | 1.371 |
| draft | PASS | 885 | 300 | 1185 | 1.580 |

Actual provider usage for this successful four-call run only: **3,550 prompt + 1,051 completion = 4,601 tokens**. These are provider-reported values, not coding-agent token usage or a total for every diagnostic request. Full non-secret report, actual fictional summaries and implementation fingerprint: [AI_LIVE_VERIFICATION_2026-10-20.json](docs/AI_LIVE_VERIFICATION_2026-10-20.json). Local screenshot: `.local/ai-preview/analysis-live-desktop.png` (inspected, genuine test browser capture, ignored and not a Railway screenshot).

Earlier attempts were not successful: an initial live run showed the safe invalid-response message (the specific failed schema field was not captured); a temporary transport diagnostic run failed and is not acceptance evidence. A subsequent real run passed analysis but rejected next_action because Groq populated draft outside draft mode. This exposed a real JSON-object limitation. The final implementation sends an explicit mode and strict schema for the supported GPT-OSS models, constraining source IDs and the empty draft field; local validation remains in place. Added regression assertions cover this failure. Temporary response diagnostics were removed before the final successful run. No failed attempt was silently replaced with a fake answer.

### Limits, publication and measurement

At completion of the initial local implementation, production AI was **not deployed / not verified**: no GitHub push, Railway variables or deployment had been performed. The user has since approved publication. Release checks below distinguish the delivery commit, exact-commit CI, deployment and real production acceptance. Server runtime Groq variables, appropriate single-process/shared rate limiting and provider/privacy review remain necessary.

AI remains probabilistic and must be reviewed. Prompt injection defenses and best-effort redaction do not guarantee anonymity or correctness. Only bounded history is included. No automatic email, stage/task changes, Page Agent, external AI-customer API or shared multi-instance limiter was added. Missing key, invalid responses, timeouts and quota failures remain visible safe errors.

Human effort, coding-agent tokens, paid financial cost and total development hours: **not measured**. The live-run timestamps/latencies are measured execution evidence, not human work time. No time or monetary savings claimed. Final live usage above excludes unmeasured/partly measured diagnostic calls and must not be used as an account-wide bill.

## Release verification — 20 October 2026

The user explicitly authorized safely committing/pushing Phase 1 to the existing `Montaserissa20/leadcurrent` main branch and checking Railway. Verified project root `D:\LeadCurrent`, expected HTTPS origin and main; `git fetch origin main` showed `0 0` divergence from the baseline. No old project files were modified.

Pre-push local verification was repeated without `GROQ_API_KEY` or live opt-in in the test process: domain/integration seed 24657, **89 tests / 1,301 assertions**, browser seed 42431, **11 tests / 150 assertions**, all passing with zero failures/errors/skips. Zeitwerk, Brakeman (zero warnings/errors) and production asset compilation passed. These automated Groq tests use mocks; the separately recorded real Groq check above was not rerun or misrepresented as a new production test.

Full reachable Git history scan: Gitleaks 8.30.1, 25 commits, exit 0, no detected secrets, using only the two already-reviewed historical false-positive fingerprints. An additional 283 unique historical blob check found no exact known local secrets or forbidden source file paths. Pre-push source policy: 219 eligible files, no local-secret matches or forbidden paths. Existing `.gitignore` protects master/private keys, real env files, `.local`, archives, logs/temp data and database exports; encrypted Rails credentials remain unchanged. Reviewed and staged exactly 27 Phase 1 files; exact staged blob policy and Gitleaks staged scan passed with no detected secrets. No credentials, local ZIPs, runtime data or unrelated files were included; no ignore exception was added.

Feature commit: [`75209db1eb4a3935f9dab67d7f76d74abf847af6`](https://github.com/Montaserissa20/leadcurrent/commit/75209db1eb4a3935f9dab67d7f76d74abf847af6), `feat: integrate Groq-powered AI sales assistant`. Normal fast-forward `git push origin main` succeeded; no force, history rewrite or new repository. GitHub main SHA matched, and all 27 published file blob IDs matched the local commit. Complete file list and non-secret evidence: [phase1-release-2026-10-20.json](docs/evidence/phase1-release-2026-10-20.json).

Exact-feature-commit [LeadCurrent CI run 39413540929](https://github.com/Montaserissa20/leadcurrent/actions/runs/39413540929): **completed / success**. Domain/HTTP, real Chrome browser, autoload, security scan and production assets all succeeded. This is actual GitHub Actions evidence, separate from the local Windows results.

Railway's GitHub deployment integration recorded **success** for the same feature SHA, GitHub deployment `7198221555`, environment `resourceful-nature / production`, updated **20 October 14:16:16 Europe/Istanbul**. This ID is the GitHub deployment record, not a claimed Railway-native deployment ID. Existing [Railway service](https://railway.com/project/190a3879-78ad-4f79-ac79-a4c6cab0775a/service/c66b7e7f-7372-40cc-b08b-45b56347954e) auto-deployed; no second service/project or variable change was made. Direct dashboard variables/worker count were not accessed.

Production HTTP at 14:16 Europe/Istanbul: `/up` **200**, `status=ok`, `database=connected`; `/login` **200**, all 12 referenced CSS/JS assets **200**, including AI CSS/Stimulus; anonymous `/leads` redirected to login.

Actual public-URL headless Edge acceptance ran **14:16:29–14:16:47 Europe/Istanbul**, **6/6 checks PASS**. Created one new fictional QA workspace/manager/40-seat customer; signed out/in and reopened the persisted lead; verified four AI controls; received one genuine Groq **Analyze customer** response using `openai/gpt-oss-20b` in **1.406 seconds**. Official priority 50 remained visibly separate, absent activity history was explicit, and lead status/deadline/tasks remained unchanged after AI and refresh. The subsequent contact → qualified → conversion → Proposal → Negotiation → Won flow persisted on refresh, and opportunity AI panel plus mobile light/dark layouts passed. No existing account/customer was modified. This production check proves one real analysis, not four production AI modes or production token usage; four real modes were separately verified locally above.

The fictional QA workspace and converted Won deal remain in production; no deletion/cleanup was performed and no credentials were saved. Production token usage/cost and worker/instance count are not measured/verified. The process-local limiter still requires one process or shared storage before scaling. Prompt-injection/hallucination/privacy limitations above still apply. A documentation-only follow-up publishes this observed evidence; its own CI/deployment status is checked separately in the final delivery report.

## Original Codex prompt (verbatim)

SHA-256 of supplied UTF-8 text: a6536e3ab02d06c033d992222a01e9d51a82417ef57ed5b7107eb85fb32bcd01.

```text
# CODEX TASK — LeadCurrent Phase 1: Real AI Sales Assistant with Groq

You are working on my existing **LeadCurrent** Ruby on Rails SaaS application.

## 1. Project context

LeadCurrent is an existing, deployed CRM inspired by Salesforce Sales Cloud.

Current technology:
- Ruby 3.4.7 and Rails 8.1.4
- PostgreSQL
- ERB, Hotwire, Turbo, Stimulus, and importmap
- Custom session-based authentication
- Multiple organizations/workspaces
- Leads, companies, contacts, activities, tasks, and opportunities
- Rule-based Next Best Action
- GitHub Actions CI
- Railway production deployment

Repository: https://github.com/Montaserissa20/leadcurrent

**This is an upgrade to an existing working application, NOT a new project.**

First, inspect the repository, read `AGENTS.md`, `AGENT.md`, and `README.md`, and understand the architecture.

Identify the existing services, controllers, models, tests, authorization rules, and UI conventions before modifying anything.

Run the existing tests to establish a baseline.

Do not modify the old `D:\ruby_project` application.

## 2. Main goal

My professor specifically requested **real AI intelligence inside the CRM**, similar in purpose to Salesforce Einstein.

The existing `NextBestAction` service is deterministic and rule-based. That is NOT sufficient for this new assignment.

Implement a genuine LLM-powered **LeadCurrent AI Sales Assistant** using the Groq API.

The AI must understand real customer records stored in PostgreSQL and produce useful, context-aware sales advice.

Do NOT implement a generic chatbot that knows nothing about the CRM.

### Example

A salesperson opens an existing lead for Atlas Industries.

The customer record contains:
- An interest in purchasing software subscriptions
- A specified budget, if recorded
- Previous conversation notes
- Pending follow-up tasks
- Lead status and first-contact deadline

The user asks:

"Analyze this customer and tell me what I should do next."

The assistant reads the authorized customer context and generates a practical recommendation based on the information actually available.

It should clearly distinguish known facts from suggestions or assumptions.

## 3. Groq integration

The API key has already been configured as a Windows user environment variable:

`GROQ_API_KEY`

Use it only on the server side.

Requirements:
- Use Groq's currently supported API endpoint and a supported model.
- Verify the model and API format against current official documentation before implementation.
- Make the model configurable through `GROQ_MODEL`.
- Use a small, fast, cost-efficient model suitable for the free tier.
- Never hardcode API keys.
- Never print, log, commit, or expose API keys.
- Never send the API key to the browser.
- Keep model requests and responses bounded with appropriate token limits.
- Add reasonable connection and response timeouts.
- Handle rate limits, network failures, invalid responses, missing configuration, and unavailable models.
- Display helpful errors instead of crashing the application.
- Do not silently replace real Groq results with fake AI responses.

Prefer a clean Ruby service implementation consistent with the existing application rather than introducing a large new framework.

Suggested architecture, adjustable after inspecting the repository:

`app/services/ai/groq_client.rb`

`app/services/ai/customer_context.rb`

`app/services/ai/sales_advisor.rb`

`app/controllers/ai/advice_controller.rb`

## 4. AI capabilities

Implement four useful customer-specific functions.

### A. Customer analysis

Analyze a selected lead or opportunity and produce:
- Short customer summary
- Relevant known facts
- Potential obstacles or risks
- Recommended next step
- Explanation of the recommendation

### B. AI Next Best Action explanation

Use our existing `NextBestAction` service to obtain factual deadlines, priority scores, and recommendation types.

The LLM may explain those recommendations in more useful language and suggest how a salesperson should respond.

The LLM must NOT change official priority scores or deadlines.

For example:

Existing business rule:
"First contact overdue by 30 hours — Priority 100."

AI enhancement:
"This customer has missed the initial contact deadline. I recommend contacting them now, confirming their requirements, and scheduling a discovery call."

Keep the distinction between the deterministic rule and AI-generated advice visible.

### C. Conversation summarization

Use existing activities and notes to summarize the customer's communication history.

Do not invent conversations, commitments, budgets, or meeting outcomes.

If no activity history exists, explicitly state that.

### D. Follow-up drafting

Generate a professional follow-up email or message based on the customer record.

This is a **draft only**.

Do not send emails or messages automatically.

The salesperson must review the generated text before copying or using it.

## 5. Interface and user experience

Integrate the AI feature into the existing LeadCurrent design.

Do not replace the application interface or add React.

Add a visually polished **"LeadCurrent AI"** section to the lead details page and opportunity details page.

Design requirements:
- Match the existing light/dark theme.
- Keep the interface responsive on desktop and mobile.
- Display a clear loading state while awaiting the Groq response.
- Provide a text field where the salesperson can ask questions.
- Provide suggested action buttons:
  - Analyze customer
  - What should I do next?
  - Summarize activities
  - Draft follow-up
- Display responses in a readable and professional format.
- Clearly label generated text as AI-generated.
- Provide a convenient Copy button where useful.
- Handle API errors without losing the current customer page.
- Prevent accidental duplicate submissions.
- Follow existing Hotwire/Turbo/Stimulus patterns.
- Respect the current Content Security Policy.
- Do not load unnecessary JavaScript libraries from external CDNs.

The goal is a genuine integrated SaaS feature, not a chatbot floating over an unrelated website.

## 6. Customer context and security

This is a multi-tenant CRM. Data security is mandatory.

The AI must only access records the authenticated user is authorized to view.

Use the existing `WorkspaceAccess` / controller authorization patterns.

Requirements:
- Reject unauthenticated requests.
- Never expose another organization's customers.
- Respect manager and salesperson access restrictions.
- Retrieve only the customer information needed for the request.
- Limit how many activities and tasks can be included in a prompt.
- Limit the length of user questions and customer notes.
- Avoid sending unnecessary personal information such as contact email addresses and phone numbers.
- Treat customer notes and user-provided text as untrusted data, not system instructions.
- Defend against prompt-injection attempts contained in stored notes.
- Never expose hidden system prompts, credentials, or internal secrets.
- Escape or safely render all AI-generated content.
- Do not treat AI output as executable HTML or JavaScript.
- Keep the original CSRF protections.
- Add basic request throttling and sensible token usage limits.

**Phase 1 AI is read-only.**

The model must NOT directly:
- Create or delete customers
- Change lead status
- Move an opportunity between stages
- Complete tasks
- Modify deadlines
- Send email
- Write arbitrary database records
- Execute code or terminal commands

The AI may propose an action, but existing Rails services remain responsible for any actual workflow changes.

## 7. Preserve the existing business rules

Do not break any existing CRM functionality.

These rules must remain authoritative:
- First-contact deadline: 24 hours
- First-contact warning: within 4 hours
- Opportunity inactivity: 72 hours
- Existing `NextBestAction` priority rules
- Allowed and forbidden lead transitions
- Allowed and forbidden opportunity transitions
- Terminal Won/Lost states
- Organization isolation and role-based permissions
- Existing real database persistence

Review these files before modifying relevant logic:

`app/services/next_best_action.rb`

`app/services/follow_up_deadline.rb`

`app/services/lead_transition.rb`

`app/services/opportunity_transition.rb`

`app/services/workspace_access.rb`

`app/controllers/dashboard_controller.rb`

`app/controllers/application_controller.rb`

The AI integration must extend the current system, not replace its deterministic business logic.

## 8. Testing requirements

Add real, automated tests.

At minimum verify:
1. An authorized salesperson can request AI analysis for an accessible lead.
2. A manager can analyze an accessible lead or opportunity.
3. Unauthenticated requests are rejected.
4. Cross-organization access is denied.
5. Unauthorized customer data is never sent to the LLM.
6. Customer information is correctly included in authorized AI requests.
7. Missing `GROQ_API_KEY` produces a safe error.
8. API timeouts and rate limits are handled gracefully.
9. Invalid provider responses do not crash the page.
10. AI responses containing HTML/script text cannot execute code.
11. AI requests do not change lead status, opportunity status, tasks, or deadlines.
12. Existing time-rule and workflow tests continue passing.
13. The interface works on mobile and with the current Content Security Policy.
14. AI request limits are enforced.

Mock or stub Groq HTTP requests for automated tests.

**Do not make CI depend on a real API key, paid API usage, or live network access.**

After the mocked tests pass, perform a separate real Groq integration test locally if `GROQ_API_KEY` is available.

Do not print the key during verification.

Clearly distinguish:
- Automated mocked tests
- Actual live Groq API verification
- Any test that could not be performed

Run the full existing test suite, not only the new AI tests.

## 9. Mandatory assignment documentation

At the START of this work, create:

`CHALLENGE_LOG.md`

This is required for my new university assignment.

Include:
- Previous LeadCurrent project and repository URL
- Baseline commit SHA before this upgrade
- Live website URL
- The actual customer pain point addressed
- Why I decided to continue LeadCurrent rather than pivot
- This week's personal objective
- The original Codex prompt for this task, preserved accurately
- What was implemented
- Which tests genuinely passed
- Links to relevant commits and verification evidence
- Known limitations
- Honest human and AI development time or cost measurements, when available

Do NOT invent token totals, working hours, financial costs, screenshots, API tests, or successful results.

Use "not measured" or "not verified" where appropriate.

Also update the README with a concise explanation of:
- AI Sales Assistant
- Groq integration
- Required environment variables
- Local setup
- Railway configuration
- How the assistant differs from the original rule-based Next Best Action
- Current limitations

Update `AGENT.md` to document the new AI architecture and development rules.

Preserve the previous assignment's documentation and evidence.

## 10. Implementation sequence

Follow this sequence:

**Step 1 — Audit**

Inspect the current Rails project, dependencies, authorization, existing business rules, and automated tests.

Record the baseline commit and create the initial `CHALLENGE_LOG.md`.

**Step 2 — Backend**

Implement the Groq client, safe customer context extraction, and AI advice service.

**Step 3 — Frontend**

Add the LeadCurrent AI panel to lead and opportunity pages.

**Step 4 — Tests**

Implement deterministic mocked tests, run the complete suite, and fix any regressions.

**Step 5 — Real API verification**

If the environment variable is available, verify an actual Groq response using a fictional test customer.

**Step 6 — Documentation**

Update `AGENT.md`, README, and `CHALLENGE_LOG.md` with actual outcomes.

**Step 7 — Final report**

Report the changes, test results, evidence, limitations, and deployment requirements.

## 11. Strict boundaries

Do not:
- Rebuild LeadCurrent from scratch.
- Replace Ruby on Rails.
- Delete existing features or tests.
- Change the 24-hour, 4-hour, or 72-hour business rules.
- Alter original project branding.
- Install an unrelated chatbot platform.
- Implement Alibaba Page Agent yet.
- Implement the external AI-customer API yet.
- Expose or commit credentials.
- Falsify test evidence or documentation.
- Push to GitHub or deploy to Railway without my explicit approval.

Keep changes focused, maintainable, and compatible with the existing application.

If an external API requirement cannot be verified, document the blocker rather than inventing a solution.

## 12. Final deliverable

When finished, give me:

1. A summary of the files created and modified.
2. A description of how the real AI integration works.
3. Instructions for running the feature locally.
4. The Groq model actually used.
5. Actual automated test counts and results.
6. Whether a real Groq API call succeeded.
7. Any limitations or security concerns.
8. What Railway environment variables will be needed.
9. What still needs to happen before production deployment.

**Success criterion:**

I should be able to open an existing lead in LeadCurrent, click "Analyze customer," and receive a genuine Groq-generated response based on that customer's authorized database information.

The existing sales workflow must continue to work correctly.

Start with the repository inspection and baseline testing, then implement Phase 1 systematically.
```

## Phase 2 — Alibaba Page Agent (20 October 2026)

Baseline: [65bcd55cfbd55ca1d91691bb1d873e0560fd76b0](https://github.com/Montaserissa20/leadcurrent/commit/65bcd55cfbd55ca1d91691bb1d873e0560fd76b0). Branch: `phase2/page-agent`. Phase 2 remains local: **no GitHub push or Railway deployment is authorized**. Phase 1's historical publication evidence above is preserved.

Why continue: the working Rails CRM already has tenant permissions, customer records and deployed Groq advice. The new user pain point is manual navigation/filtering/form preparation even after reading advice; this is the assignment's objective, not measured customer feedback. This week's promise: an authentic Alibaba DOM/tool-calling agent, scoped to navigation, filtering, reading and unsaved note preparation, with explicit human submission. Unlike Phase 1's text advice, Phase 2 must visibly interact with real controls. No external AI-customer API.

Baseline actual tests (Groq mocked, no API key in the test process): Rails seed 2543, **89 tests / 1,301 assertions**; browser seed 13594, **11 tests / 150 assertions**; all zero failures/errors/skips. Total **100 tests / 1,451 assertions**. Phase 1 keeps `tool_choice: none` because it is a read-only structured adviser; Page Agent requires a separate tool-calling transport.

Implementation and measured local acceptance are recorded after the original prompt below. Human hours, coding-agent tokens and paid costs remain unmeasured. Phase 2 publication remains prohibited.

### Phase 2 original prompt (verbatim)

SHA-256 of supplied UTF-8 text: 374af9094e5c3d41c1bdc9b8d2fdf9b1d7ab74cfb7387f7994f43ffa7f2de010.

```text
# CODEX TASK — LeadCurrent Phase 2: Integrate Alibaba Page Agent

You are upgrading my existing LeadCurrent CRM SaaS with a real, embedded browser-interaction AI agent.

Repository: https://github.com/Montaserissa20/leadcurrent

Production website: https://leadcurrent-production.up.railway.app

Existing technology:
- Ruby 3.4.7 / Rails 8.1.4
- PostgreSQL
- Hotwire, Turbo, Stimulus, importmap and Propshaft
- Existing Groq-powered AI Sales Assistant
- Existing deterministic Next Best Action
- GitHub Actions and Railway

Phase 1 has already been committed and deployed.

**This is Phase 2 only. Do not rebuild the project or begin the external AI-customer API feature.**

## 1. Mandatory inspection

Before changing code:

1. Read AGENTS.md, AGENT.md, README.md and CHALLENGE_LOG.md.
2. Inspect the existing Rails layout, JavaScript architecture, Content Security Policy, authentication and workspace permissions.
3. Identify the current Git commit SHA and record it as the Phase 2 baseline.
4. Run the existing automated tests.
5. Review the Phase 1 Groq client and understand why it currently uses `tool_choice: none`.
6. Inspect the official Alibaba Page Agent documentation and actual published package API.

Official sources:
- https://github.com/alibaba/page-agent
- https://alibaba.github.io/page-agent/
- https://alibaba.github.io/page-agent/docs/features/models/
- https://alibaba.github.io/page-agent/docs/introduction/limitations/
- https://alibaba.github.io/page-agent/docs/advanced/page-agent-core/

Use the authentic Alibaba Page Agent implementation, not a custom imitation with the same name.

Verify the current package version and APIs before integration.

## 2. Main goal

Integrate Alibaba Page Agent directly into LeadCurrent.

Users should be able to give natural-language instructions and watch the agent interact with their CRM interface.

Example:

User: "Find my overdue leads and open the most urgent customer."

Expected behavior:

1. The agent observes the available CRM interface.
2. It navigates to Leads.
3. It applies the appropriate overdue filter.
4. It identifies the most urgent available lead.
5. It opens the customer record.
6. It displays the completed actions in the agent panel.

This must be real Page Agent execution using the website DOM and genuine model responses.

Do not simulate navigation using a hardcoded keyword-to-route chatbot.

## 3. User interface

Add an **AI Agent** entry point to the authenticated LeadCurrent layout.

Design a modern right-side panel consistent with the existing brand, light/dark themes and mobile layout.

The panel should include:

- Header: "LeadCurrent AI Agent"
- Short description of what the agent can do
- Natural-language task input
- Example task suggestions
- Run button
- Stop button
- Current status (idle, thinking, acting, completed, failed)
- A readable step-by-step activity display
- Final task result
- Clear warnings and error messages

Suggested example tasks:

- "Show my overdue leads."
- "Find Atlas Industries."
- "Open opportunities in negotiation."
- "Show today's pending follow-ups."
- "Find this customer and prepare a follow-up note."
- "Navigate to sales analytics."

Make sure the panel does not obstruct navigation or important CRM controls.

The user should be able to see the agent interacting with the page.

Reuse existing CSS, Stimulus and Turbo conventions rather than introducing React.

## 4. Use the real Alibaba library

Use the official `page-agent` package or the officially maintained `@page-agent/core` components, depending on which best supports an embedded LeadCurrent panel.

The core requirement is authentic Page Agent execution with DOM-based interaction and model tool calls.

The official API includes functionality such as:

- execute(task)
- stop()
- execution status and activity events
- customFetch for authentication or proxy integration

Verify these interfaces against the installed version.

Integrate the library as a pinned, locally built JavaScript asset served from the LeadCurrent origin.

The project currently uses importmap and Propshaft. Introduce only the minimum build tooling needed for Page Agent, and preserve the existing Rails frontend architecture.

Do not load the demo CDN or use Alibaba's public testing LLM in production.

Document any new npm dependencies, version lockfiles, build commands, licensing, Docker requirements and GitHub CI updates.

Maintain the existing Content Security Policy. Do not use unsafe-inline or expose secrets to client JavaScript.

## 5. Groq connection

I already have `GROQ_API_KEY` configured in Windows and Railway.

The current AI model is:

`openai/gpt-oss-20b`

First, test whether this model supports the actual tool-calling interactions Page Agent requires.

Important:

The Phase 1 Groq client deliberately disables tools and uses a strict read-only sales-advice response format.

Do not modify or break that working integration.

Build a separate server-side transport/proxy for Page Agent using a fixed Groq provider endpoint.

Requirements:

- API key remains server-side.
- Browser sends requests only to our same-origin Rails proxy.
- Authenticate every proxy request using the existing session.
- Preserve CSRF protections.
- Never accept arbitrary target URLs, provider hosts or API keys from the browser.
- Allowlist the supported model and protocol options.
- Validate and bound request payload size, message structure and completion tokens.
- Preserve the tool-call structures required by Page Agent.
- Use TLS verification and bounded timeouts.
- Apply sensible account, workspace and provider request limits.
- Handle 401, 403, 429, timeouts and unsupported model behavior safely.
- Avoid logging prompts, customer records, credentials and model responses.

If Groq's current model is incompatible with Page Agent, do not fake success.

Document the exact incompatibility and evaluate another Groq model with verified tool support.

Do not switch providers or require an additional paid API without informing me first.

Important: Page Agent often needs multiple LLM requests for one task. Account for model context limits, free-tier token limits, and realistic provider usage.

## 6. Safety and permissions

The agent operates inside an authenticated CRM containing potentially sensitive customer data.

Treat all page content, user instructions and model responses as untrusted.

### Safe mode (mandatory)

The first version should support:

- Navigation
- Searching
- Filtering
- Opening accessible customer records
- Reading visible information
- Preparing form fields without submitting them

It must NOT autonomously:

- Submit completed customer-contact records
- Create or delete customers
- Convert leads
- Change opportunity status
- Mark opportunities Won or Lost
- Complete tasks
- Modify passwords or account settings
- Change ownership
- Send email or messages
- Execute arbitrary JavaScript
- Access another workspace
- Exfiltrate page content to unrelated websites

Require a separate, visible user interaction to approve and submit changes.

**Important:** Do not rely on the LLM system prompt alone to enforce safety.

Inspect the actual Page Agent tools and interaction hooks. Remove or constrain dangerous capabilities where supported.

If reliable enforcement of read-only/prepare-only behavior cannot be demonstrated, disable those actions in Phase 2 instead of claiming they are safe.

Retain Rails authorization and workflow validations as defense in depth.

Never use an agent as a reason to bypass server-side permissions.

Do not enable experimental JavaScript execution capabilities.

### Privacy

Page Agent can inspect page DOM content, and part of that content may be sent to Groq.

Implement practical protections:

- Avoid exposing password forms and security settings to agent observation.
- Mask contact emails, phone numbers, sensitive customer notes and credentials when possible.
- Use documented page-content transformation hooks where available.
- Limit the amount of page text supplied to the model.
- Do not include hidden customer records or server-side data outside the authorized visible page.
- Use only fictional test customers for live verification.
- Explain residual limitations; masking is not perfect anonymity.

Do not silently transmit entire customer histories to the model.

## 7. Working with Rails Turbo navigation

LeadCurrent uses Turbo and Stimulus rather than a conventional JavaScript SPA.

Page Agent is primarily designed for interaction with the current page.

Verify how it behaves when Turbo navigates between LeadCurrent screens.

Ensure:
- The agent panel remains usable.
- Running tasks are properly stopped or restored when navigation changes.
- Event listeners do not multiply after Turbo visits.
- Old agent instances are disposed of when appropriate.
- A full reload does not silently continue an unknown task.
- Browser back/forward navigation does not break the interface.

If multi-page tasks are not reliable without the optional extension, demonstrate and document the supported in-page behavior rather than pretending the agent can navigate indefinitely.

Do not require installation of a browser extension for the core Phase 2 demo.

## 8. Improve interface semantics if necessary

The agent should understand existing controls through accessible DOM structure.

Make narrow, appropriate improvements to:

- Navigation labels
- Lead search and filters
- Opportunity status filters
- Task lists
- Customer record links
- Form labels

Prefer semantic HTML, accessible names and stable selectors.

Do not redesign every page.

Do not create hidden privileged shortcuts only the agent can use.

## 9. Automated testing

Add genuine test coverage.

At minimum test:

1. The AI Agent panel renders for authenticated users.
2. Unauthenticated users cannot call the LLM proxy.
3. Cross-workspace access remains blocked.
4. The Groq key never appears in HTML, JavaScript, responses or logs.
5. The proxy refuses arbitrary remote URLs and unsupported methods.
6. The proxy correctly forwards supported tool-call data.
7. Tool-call errors are handled without crashing the CRM.
8. The Stop button interrupts a running task.
9. Loading and duplicate execution are handled.
10. Navigation and filtering work through real browser interactions.
11. Forbidden actions are blocked under Safe Mode.
12. Customer-contact activities are not falsely recorded.
13. CRM state remains unchanged after read-only agent tasks.
14. UI works with Turbo navigation and browser refresh.
15. Mobile and dark mode remain functional.
16. Existing Phase 1 AI functions still pass.
17. Existing 24-hour, 4-hour and 72-hour time-rule tests still pass.
18. Existing lead-to-Won workflow tests still pass.

Use mocked LLM transport for CI tests.

Where possible, test actual Page Agent DOM interactions in a browser with a deterministic tool-calling model fixture, not just mocked screenshots or hardcoded route changes.

Add a separate opt-in real Groq browser test using a fictional LeadCurrent workspace.

Do not run real Groq requests in normal CI.

If a real multi-step browser task does not work, record the actual failure and fix it rather than claiming it passed.

## 10. Mandatory CHALLENGE_LOG.md update

This is required for my university assignment.

Preserve all previous Phase 1 documentation and evidence.

Append a new Phase 2 section recording:

- Phase 2 baseline commit
- The original instruction/prompt, preserved accurately
- Why we continued the LeadCurrent project
- The specific new user pain point
- Phase 2 objective and promise
- Actual implemented changes
- Genuine Git commits and test results
- Real Page Agent integration evidence
- Successful and unsuccessful Groq attempts
- Development time and token usage if genuinely measured
- Unverified information and known limitations
- What changed compared with the previous week
- Whether our originally promised behavior is demonstrably working

Do not invent development time, API costs, token counts, successful tests or customer feedback.

Explain why Page Agent provides a different experience from Phase 1's text-based AI Sales Assistant.

Create a short Turkish technical report under `docs/` for Phase 2 architecture, safety, tests and demonstration instructions.

Update AGENT.md and README appropriately.

## 11. Demonstration acceptance criteria

Prepare a real browser demonstration involving a fictional Atlas Industries lead.

Scenario A:
User: "Find my overdue leads."

The agent navigates or filters to find overdue customer records and shows the result.

Scenario B:
User: "Open Atlas Industries."

The agent locates and opens the customer record using the real interface.

Scenario C:
User: "Prepare a follow-up note for this customer."

The agent prepares content or fills a permitted form, but does not save or submit it automatically.

The salesperson manually confirms and submits the action.

The demonstration must show that the agent performed meaningful page interaction rather than simply answering with text.

Keep the original CRM workflow operational.

## 12. Implementation order

1. Inspect the repository and official Page Agent APIs.
2. Record baseline test results and update CHALLENGE_LOG.md.
3. Verify Groq tool-call compatibility through a minimal test.
4. Integrate the official Page Agent JavaScript library.
5. Build the secure Rails LLM proxy.
6. Implement the right-side AI Agent interface.
7. Add constrained navigation and safe-mode interactions.
8. Verify Turbo behavior and privacy boundaries.
9. Run browser, integration and regression tests.
10. Run the optional real provider demonstration.
11. Update documentation and prepare the final report.

Do not introduce new features outside Phase 2.

## 13. Strict boundaries

- Do not replace Ruby on Rails.
- Do not rebuild LeadCurrent.
- Do not damage the existing AI Sales Assistant.
- Do not remove existing tests.
- Do not modify the sales deadline constants or transition rules.
- Do not bypass organization access boundaries.
- Do not expose GROQ_API_KEY.
- Do not use Alibaba's public demo model for real customer data.
- Do not implement the AI purchasing-customer API yet.
- Do not force-push or rewrite Git history.
- Do not push changes to GitHub yet.
- Do not deploy to Railway yet.
- Do not claim success unless tested.

Keep Phase 2 on the local development branch until I review the results.

## 14. Final report

When finished, tell me:

1. Which official Alibaba package and version were integrated.
2. How the Page Agent connects to Groq.
3. What users can actually ask it to do.
4. Whether multi-page Turbo navigation works.
5. Which actions are prevented for safety.
6. Actual automated test results.
7. Results of real Groq/Page Agent verification.
8. Whether existing CRM features still work.
9. Which files were created and modified.
10. Any blockers, cost or security limitations.
11. How to run and demonstrate Phase 2 locally.

**Success criterion:**

I can open LeadCurrent, click "AI Agent," enter "Find my overdue leads," and watch the real Alibaba Page Agent interact with the CRM interface using a genuine LLM, without exposing my API key or modifying customer data without approval.

Start by auditing the repository and testing Groq's compatibility with Alibaba Page Agent. Then implement the feature systematically.
```

### Phase 2 implementation and measured acceptance

Official `@page-agent/core@1.12.4` and `@page-agent/page-controller@1.12.4` execute the real observe/model/tool loop. Pinned Zod 4.5.1 and build-only esbuild 0.25.12 produce a locally served Propshaft/importmap asset; Node 22 is needed at build time. Actual published types/source and upstream `9eb6b6646500264d9034dd466a4270cb9fc1ef1e` were inspected. MIT notices are in `vendor/licenses/` and the bundle. The right-side Stimulus panel supports Run/Stop, live steps, safe errors, light/dark and mobile. Docker/CI/Render builds now include npm build; Docker's final runtime remains Ruby only.

The separate authenticated/CSRF-protected `PageAgent::CompletionsController` sends bounded canonical AgentOutput requests through server-only Groq HTTPS to `openai/gpt-oss-20b`. Browser-supplied endpoints/keys/models/protocol options are rejected. Phase 1 client, sales services/models/database configuration and 24/4/72-hour constants/transitions remain unchanged. Narrow UI changes add company search, explicit overdue filtering, urgency ordering and accessible navigation/record labels.

SafeDom allows only observed same-origin read links, GET filters/search and unsaved note preparation. Tokens are rebuilt and method/target/visibility are checked at execution. Broad click/input, arbitrary JavaScript, external URLs and settings are unavailable. CRM submit/contact/conversion/stage/task/ownership actions cannot be selected. Existing unsaved text is preserved; note preparation sets Add a note and clears scheduled follow-up without submitting. Password/security/contact/history text is excluded from observations; redaction remains best effort. Raw provider prompts/answers/credentials are not logged; console/debugger output is stripped without weakening CSP. Shared Phase 1/provider in-flight ownership and bounded account/workspace/provider quotas prevent unbounded calls, but the store is process-local.

| Actual check | Result |
|---|---|
| Rails, seed 40814 | 104 tests / 1,526 assertions; zero failures/errors/skips |
| Browser, seed 13495 | 17 tests / 250 assertions; zero failures/errors/skips |
| Total regular tests | **121 tests / 1,776 assertions**; real library/DOM/Turbo with mocked provider transport |
| Existing regression coverage | Original 100 tests retained; Phase 1 advice, password/workspace rules, lead-to-Won and exact 24/4/72-hour cases pass |
| Autoload / Brakeman | PASS / 0 errors and 0 security warnings (Windows fallback diagnostics emitted) |
| Npm audit / production assets | 0 dependency vulnerabilities / PASS |
| Secret/source review | Exact real local key absent from source, built JS and test log; original prompts/Phase 1 log/domain source preserved; see evidence JSON for scan scope |
| Gitleaks 8.30.1, source snapshot | 2 reviewed unchanged false positives: public commit SHA in docs/VERIFICATION_TR.md:39 and synthetic test password in test/integration/authentication_test.rb:46; no new findings |
| Docker / remote CI / Railway | Image build unverified (Linux daemon unavailable); Phase 2 remote CI/deployment not attempted |

### Real Groq and browser results, including failures

The key was initially missing from this Windows session/User/Machine scopes. The user restored the local Windows User variable and replied “configured”; its value was never requested in chat or printed. Minimal named-tool compatibility **PASS**, 2026-10-20T14:24:28Z–2026-10-20T14:24:29Z: AgentOutput, 592 prompt + 40 completion = **632 actual provider tokens**. No provider/model switch was needed.

Final multi-user fictional-workspace browser run **PASS**, 2026-10-20T14:52:48Z–2026-10-20T14:57:16Z UTC, seed 17208, **1 test / 34 assertions**. Scenario A navigated to Leads, selected **Owner=Me + Overdue**, submitted the real GET filter and excluded a colleague's overdue record. Scenario B clicked the real Atlas customer link through Turbo. Scenario C filled an unsaved Add a note form; all three tasks left lead/tasks/activities/audits unchanged. The separate Capybara test-user Save action click then recorded **only a note**, with no first contact, status change or task. This simulates the required separate human interaction; it is not customer feedback or an observed human approval.

This run made **11 real provider completions**, 13,165 prompt + 708 completion = **13,873 measured tokens**; browser CSP violations: 0. [Local fictional-data screenshot](docs/evidence/phase2-page-agent-2026-10-20.png) and [redacted structured evidence, prior attempts and limits](docs/evidence/phase2-page-agent-2026-10-20.json). An earlier single-user run also passed (7 completions, 7,721 tokens); the later run strengthens the “my records” acceptance with a colleague fixture.

Unsuccessful attempts are retained rather than hidden: (1) opened a record when the test expected the filtered list; (2) failed after applying the overdue filter, exact cause not captured; (3) safe model/protocol error after one completion, exact provider code not captured; (4) all agent tasks passed but the final test-user-save assertion used a cached association, fixed with reload; (6) a multi-user attempt repeated GET filtering and reached the six-step cap before done. The latter led to applied-URL feedback and grouped-filter/finish guidance. No forbidden CRM write was accepted. The final run is evidence of demonstrated acceptance, not a guarantee every probabilistic task succeeds.

### What changed this week, scope and honest unknowns

Phase 1 gives text analysis/advice/drafts. Phase 2 visibly acts through the existing interface: real DOM observation, tool choice, Turbo navigation, owner/overdue filters, accessible customer link, unsaved form preparation. The promised A/B/C behavior is demonstrated locally with genuine Groq and actual Page Agent. Other suggested tasks remain bounded by the same visible controls and six-step limit; this is not unlimited browser autonomy or an extension.

Human development time, coding-agent tokens, paid API cost and customer feedback were **not measured**. Provider usage above is only for the specified runs, not total development/billed usage. Residual risks: probabilistic repetition/failure, title/query/task data may be sensitive despite masking, free-tier/provider quotas, process-local limiter restart/multiworker limits, finite observation size and no guaranteed continuation across full document reload. Stop prevents further browser actions but an in-flight server call can still finish.

No Phase 2 commit was created: changes remain reviewable in the local `phase2/page-agent` working tree. HEAD is the real baseline `65bcd55cfbd55ca1d91691bb1d873e0560fd76b0`; no new Git SHA is invented. **No GitHub push, history rewrite, remote Phase 2 CI run or Railway deployment.** Historical Phase 1 production evidence remains unchanged. [Turkish architecture, safety and local demonstration guide](docs/PAGE_AGENT_PHASE2_TR.md).

## Phase 2.1 — Conversational Copilot (20 October 2026)

Baseline HEAD: `65bcd55cfbd55ca1d91691bb1d873e0560fd76b0`, local `phase2/page-agent`. Phase 2 was already uncommitted; a source-hash snapshot records the actual worktree at this correction's start. No invented Phase 2 commit. No GitHub push or Railway deployment.

User-observed defects: overdue navigation returned tool chatter without verified matches; ordinary help went through a forced AgentOutput tool protocol and could fail generation. Root causes confirmed in code: only DOM actions/done exist, observations omit full query results, and the panel accepts the model's done text without a database outcome check. The library's done activity itself returns generic “Task completed”. This is a correction to the existing project, not a new project or Phase 3.

Baseline run: Rails seed 37061, 104 tests / 1,526 assertions / zero failures/errors/skips. System seed 15392, 17 tests / 249 assertions / one failure in existing ProWorkspaceTest: expected stage toast existed only in hidden text. Unchanged isolated rerun seed 28098: 1 test / 7 assertions, passed. Earlier Phase 2 evidence is preserved above; this new run is not falsely reported green.

Objective: a model-routed conversation for help/clarification/refusal and narrow read-only verified CRM answers, with official Page Agent execution retained for safe UI actions. Raw tool steps become secondary. Authentication, tenant boundaries, CSP, privacy and 24/4/72-hour rules remain authoritative. Implementation and final evidence are recorded below when verified; development hours and paid cost are not measured.

### Phase 2.1 supplied prompt (verbatim)

```text
# CODEX TASK — LeadCurrent Phase 2.1: Upgrade Page Agent into a Conversational AI Copilot

We need to improve the existing Alibaba Page Agent integration in my LeadCurrent CRM.

**This is a correction and improvement of Phase 2, NOT a new project.**

My actual browser testing exposed two serious usability problems.

### Problem 1 — Technical tool steps instead of useful answers

User input:

"Which leads are overdue?"

The agent successfully applied the overdue filter but displayed:

- click_control: Filter
- choose_option: First contact — Overdue
- click_control: Filter
- done: Task completed

It then said overdue leads were visible without reporting which leads matched or whether there were any results.

This is not satisfactory.

The user should receive a helpful, factual answer, such as:

"I found 3 overdue leads. Here are their names and deadlines. I've opened the filtered Leads page."

The company names, counts, and deadlines must come from actual authorized CRM records, never fabricated by the LLM.

The low-level technical steps should be available in an optional expandable activity log, not presented as the primary answer.

### Problem 2 — Ordinary conversation fails

User input:

"Tell me how can I use the system."

The current agent returns:

"Groq could not produce a supported agent action."

This is unacceptable for a conversational AI assistant.

The system should recognize that the user is requesting guidance, not a browser action, and explain how LeadCurrent works.

The agent must not require users to type specific keywords or copy the provided example tasks.

## 1. Inspect the existing implementation

Before changing anything:

- Read AGENTS.md, AGENT.md, README.md and CHALLENGE_LOG.md.
- Inspect the existing Phase 1 AI Sales Assistant.
- Inspect the Phase 2 PageAgentCore integration.
- Inspect the Groq proxy and AgentOutput tool schema.
- Inspect SafeDom, the DOM observation transformation, and the UI activity renderer.
- Read the existing Phase 2 test and verification results.
- Preserve the current Rails authentication, workspace isolation and business rules.
- Record the current baseline commit.
- Run the existing test suite.

Understand the root cause of unsupported actions before changing the architecture.

Do not simply hide error messages or add hardcoded responses.

## 2. Create one intelligent AI Copilot experience

Keep the existing official Alibaba Page Agent library.

Add a Groq-powered conversational layer so users can ask questions or instruct the CRM through one panel.

The Copilot must understand at least these categories:

**A. General CRM questions**

Examples:

- How can I use LeadCurrent?
- What is a lead?
- What's the difference between a lead and an opportunity?
- Explain the sales pipeline.
- What does Won or Lost mean?
- How do I add a customer?
- How do I manage follow-up tasks?
- How does the AI Sales Assistant work?

Provide useful, natural conversational answers.

**B. Navigation and interface instructions**

Examples:

- Take me to the pipeline.
- Open Analytics.
- Find Atlas Industries.
- Show me negotiation opportunities.
- Where can I change my password?
- Show me overdue leads.

Use the existing Page Agent for supported browser actions.

For security-sensitive pages such as Settings, the Copilot may provide navigation instructions or an authorized ordinary link rather than exposing those pages to unrestricted agent observation.

**C. CRM data questions**

Examples:

- Which leads are overdue?
- How many leads need attention today?
- Who is my most urgent customer?
- What opportunities are currently in negotiation?
- What follow-up tasks are pending?

Use actual permitted CRM records.

Do not invent counts, company names, dates, statuses, budgets or deadlines.

**D. Unsupported or forbidden actions**

Examples:

- Send this email automatically.
- Delete every lead.
- Mark this opportunity as Won.
- Change another user's password.

Respond naturally with what the assistant cannot do, why, and what safe manual alternative is available.

Do not return an internal tool error just because no action is permitted.

## 3. Model-based intent understanding

Implement a reliable Groq-powered intent and response mechanism.

Possible structured intents:

- answer_question
- read_crm_data
- page_action
- clarify
- unsupported_action

These are architectural suggestions, not a requirement to use these exact strings.

Do NOT implement this as a list of hardcoded keyword rules.

Natural variations such as:

"Show my late leads"

"Do I have customers waiting for contact?"

"Who is overdue?"

should be understood as related requests when the context supports that interpretation.

The assistant must handle ordinary spelling mistakes and different phrasings.

Use validated structured responses with bounded input/output sizes and a safe fallback.

No client-side provider key.

Keep the existing Phase 1 AI Sales Assistant operational.

Choose whether to extend the current Groq Page Agent protocol with safe answer/clarification capabilities or introduce a separate intent router and help responder. Explain the architectural choice.

## 4. Give accurate CRM answers

The assistant must distinguish:

- General explanation
- Database-derived facts
- Model-generated recommendations
- Unknown or unavailable information

For data questions, implement narrow, explicit, read-only Rails query capabilities using WorkspaceAccess and existing domain services.

Examples:

- overdue lead count and bounded lead list
- pending follow-up count and bounded task list
- lead status breakdown
- opportunities by current stage
- existing NextBestAction priorities

Use existing authoritative deadline calculations and NextBestAction logic.

Never ask the LLM to invent SQL, execute arbitrary queries, access arbitrary models or choose unrestricted record identifiers.

Restrict queries to the current authenticated user's authorized organization and visibility scope.

Return record links only when the user is permitted to open those records.

Do not claim that a filter contains results before checking the actual filtered records.

When there are no matches, say so clearly.

If data retrieval fails, report that the result could not be verified.

## 5. Improve the AI panel

Keep the existing LeadCurrent visual design, dark mode and responsive layout.

Rename or enhance the current panel to:

**LeadCurrent AI Copilot**

Design the interaction around a conversation.

The primary response should be concise, helpful and written in natural language.

For example:

User:
"How can I use LeadCurrent?"

Assistant:
"LeadCurrent helps you manage leads, opportunities, follow-ups and sales activities. You can create leads, track conversations, move qualified leads into opportunities, and monitor deadlines. Would you like me to show you the Leads page or explain the pipeline?"

For an overdue-lead request, show actual results in a readable form with authorized links.

Add:

- Clear assistant and user messages
- Loading/working feedback
- Human-friendly final answers
- Optional expandable "Agent activity" section
- A Stop button for running tasks
- Error recovery without losing the conversation
- Short-lived conversation context for follow-up questions
- Accessible focus, labels and keyboard navigation
- Responsive behavior for desktop and mobile

Keep the activity log, but collapse it by default.

Replace raw messages like:

"click_control: Filter"

with human-friendly activity such as:

"Applied the overdue-lead filter."

Do not falsely describe an action as completed unless it was observed successfully.

Use safe text rendering, never unrestricted model-generated HTML.

## 6. Make the agent work with natural instructions

The existing Page Agent should continue interacting with actual visible DOM controls.

Do not replace it with a keyword-to-URL chatbot.

Improve its instruction handling so it can:

- Understand user intent
- Observe permitted CRM controls
- Navigate to the relevant page
- Select appropriate filters
- Verify the resulting page
- Produce a useful final explanation
- Ask clarifying questions when necessary

Keep the existing official PageAgentCore observe → plan → tool → observe execution cycle.

Keep the same-origin Groq proxy and never expose GROQ_API_KEY.

When a task ends, verify the observed outcome instead of blindly trusting the model's done message.

If the requested action is unsupported, explain the limitation conversationally rather than reporting "unsupported agent action."

## 7. Continue to enforce Safe Mode

This improvement must NOT weaken security to achieve more flexible conversation.

The Copilot may:

- Answer questions
- Read permitted CRM summaries
- Navigate
- Search and filter
- Open authorized records
- Prepare unsaved notes
- Produce drafts for manual review

It may NOT automatically:

- Submit contact records
- Send emails or messages
- Delete records
- Change lead or opportunity status
- Mark deals Won or Lost
- Complete tasks
- Modify deadlines
- Change user accounts or passwords
- Execute arbitrary JavaScript
- Access another workspace

Keep the existing SafeDom allowlists, CSRF enforcement, authorization checks, privacy protections and Content Security Policy.

Conversational flexibility must not mean unrestricted tool execution.

Treat user notes, page content and retrieved data as untrusted.

## 8. Improve response times

The current agent waits approximately 25 seconds between model steps, creating excessive delays.

Investigate the real reason for this pacing.

Check:
- Groq free-tier requests-per-minute and tokens-per-minute limits
- Existing Phase 1 and Phase 2 shared request limits
- Actual measured tokens and latency per model step
- Whether multiple interactions can safely be batched
- Whether navigation tasks require unnecessary model calls

Improve responsiveness without exceeding provider limits.

Use adaptive pacing where appropriate, bounded retries or backoff for 429 responses, and clear progress feedback.

Do not simply remove the delay if doing so would cause repeated rate-limit failures.

Report measured before/after completion times for equivalent tasks when possible.

## 9. Test real user expectations

Add automated and real browser tests for:

1. "Tell me how can I use the system?" produces useful CRM help.
2. "Explain what an opportunity is" produces a conversational answer.
3. "Show me overdue leads" navigates or filters and reports actual results.
4. "Which leads are late?" handles a natural paraphrase.
5. Empty overdue results are reported honestly.
6. "Find Atlas Industries" opens the correct authorized customer.
7. "Go to analytics" navigates successfully.
8. "Prepare a follow-up note" does not submit anything.
9. "Mark this deal won" refuses autonomous submission and explains manual approval.
10. Unrecognized requests produce clarification instead of an internal error.
11. Cross-workspace data remains inaccessible.
12. Groq API failures display safe, helpful feedback.
13. Conversational context works for a short follow-up question.
14. Low-level tool logs remain accessible but collapsed.
15. Existing Phase 1 AI functions remain operational.
16. Existing Phase 2 browser actions remain operational.
17. Existing time rules and CRM workflows are unchanged.

Mock provider calls in CI.

Run a separate optional real Groq test with fictional customer data.

Distinguish actual live API tests from mocked tests.

## 10. Documentation

Update:

- AGENT.md
- README.md
- CHALLENGE_LOG.md
- Phase 2 technical documentation

Explain:

- Why the original Phase 2 agent failed conversational questions
- How the AI decides between answering and acting
- How CRM facts are retrieved safely
- How the Page Agent interacts with actual UI controls
- The difference between Copilot explanations and verified CRM data
- Current limitations
- Real performance measurements and API usage, if measured
- Successful and unsuccessful test results

Do not invent evidence.

## 11. Final requirements

Do not push to GitHub yet.

Do not deploy to Railway yet.

Do not regenerate or expose API credentials.

Do not rebuild LeadCurrent or replace Rails.

Do not change the official 24-hour, 4-hour or 72-hour business rules.

Do not add an unrestricted SQL or JavaScript execution tool.

Do not implement Phase 3's external purchasing-agent API.

When finished, report:

1. Root cause of the previous failures.
2. New architecture.
3. Files changed.
4. Real capabilities.
5. Automated test results.
6. Real Groq/browser verification.
7. Security limitations.
8. Performance before and after.
9. Steps for local testing.

**Acceptance criterion:**

A user should be able to ask LeadCurrent AI Copilot ordinary questions about the CRM, request actual customer information, or instruct the Page Agent to perform safe UI actions, without memorizing example commands.

The assistant must return useful, verified answers rather than raw tool calls or unsupported-action errors.

Start by diagnosing the two observed failures, then implement and verify the improvements.
```

### Phase 2.1 final implementation and verification

The conversational layer is a separate fixed-Groq strict JSON planner/help responder, retaining official PageAgentCore/PageController 1.12.4. Natural language maps to validated help/read/show/action/clarify/refusal intents; there is no keyword-to-URL classifier. Read/show questions use narrow WorkspaceAccess queries for authoritative counts, bounded linked records, actual deadlines, task status, opportunity stages and unchanged NextBestAction priorities. Model data-answer prose is ignored. General explanations are labelled AI/product-guide, verified CRM facts separately; unknown/empty/unverified results remain explicit.

Safe UI actions remain genuine DOM observation/model tools. The panel is a conversation with source labels, context, Run/Stop/New chat, recovery and collapsed friendly activity. The server-held, session/user/workspace-bound plan controls completion: done is withheld until observed authorized destination/filters match, then only done is offered; final outcome is checked again. Model success/failure text is not a substitute for state verification. Unsaved notes additionally use browser-observed form checks and a separate user Save action, never agent submission. Owner/closed-record note requests receive a natural permission explanation. A single batch can change up to four existing search/select fields from the SAME approved GET filter form and submit it; all fields are checked first. Other forms, notes, overrides, POST, JS, settings/account/status/ownership/task writes and external links remain blocked. Phase 1 source, models, DB configuration, constants and transition services remain unchanged.

The original fixed 25-second delay was a conservative Phase 2 precaution. The new 400ms base delay uses numeric provider token/reset headers, conservative reservation and local reset deadlines, sharing the existing request/in-flight budgets. One cancellable 429 retry honors up to 60 seconds; no timeout/invalid-output retries or extra provider. Planner completion is bounded to 600 tokens, browser tools 512, raw response 24KB; strict action schema removes unnecessary reflection output. Server-defined product guide and input/record bounds remain explicit; no raw provider prompts/responses are logged. Conversation MemoryStore is 2MB, four previous turns, 10-minute idle/30-minute absolute life, bound to the existing login session. Multiworker/shared-store, privacy and provider limitations remain.

| Actual final check | Result |
|---|---|
| Rails seed 50371 | 124 tests / 1,692 assertions, 0 failures/errors/skips |
| Browser seed 33590 | 25 tests / 351 assertions, 0 failures/errors/skips |
| Regular total | **149 tests / 2,043 assertions**; normal HTTP transport mocked, actual library/DOM/Turbo used |
| Live seed 11016 | **11 scenarios, 1 test / 116 assertions**, all PASS; real Groq and fictional rollback data |
| Named strict tool compatibility | PASS, 824 actual provider tokens |
| Autoload / production assets | PASS; no deployment inference |
| Brakeman / npm audit | 0 warnings/errors / 0 dependency vulnerabilities; Windows fallback diagnostics recorded |

Final real run 2026-10-20T20:33:45Z–2026-10-20T20:36:41Z UTC: 20 genuine completions, 26,701 prompt + 2,132 completion = **28,833 measured tokens**, 0 CSP violations. Help, opportunity explanation, short follow-up, verified overdue records, no matches, Atlas, Analytics, unsaved note, separate test-user save, Won refusal and ambiguity clarification passed. CRM state remained unchanged after each AI request; the separate simulated user Save action recorded only a note, no first contact/status/task. This is Capybara user-approval simulation, not actual customer feedback or agent approval. The last live run was followed only by malformed-provider diagnostic parser hardening, covered by an added regression and the complete final suite.

Measured equivalent A/B/C + separate user save: **127.276s before batching → 64.443s after**. All 11 cases: 32 → 20 model calls. Overdue task: 58.808s/7 calls → 5.317s/4 calls. Provider budgets/cache differed. Ordinary help 1.057s and data question 1.061s passed, but another help turn waited 49.974s for quota; latency is not uniformly low. Historical Phase 2's timestamp range is about 268s and includes setup/login, so it is a less controlled comparison.

Failed live attempts remain in the JSON evidence: two correct-data/non-navigation classifications; HTTP 400/tool_use_failed; opened Atlas rejected by the earlier verifier (exact field not captured); premature done after selecting but not applying overdue; first batch run invalid response (exact shape/finish reason not captured then). They motivated the authoritative show intent, strict schema, state-based completion contract and safe response diagnostics. Early test implementation failures (CSRF parsing, renamed UI expectation, unavailable Minitest mock helper and synthetic quota exhaustion) were fixed and the final suite rerun. Baseline's unrelated toast visibility failure and unchanged isolated pass are retained above. No failed run was converted into fake success.

Source/secret and documentation scan scope/results are recorded in the final JSON evidence. Human hours, coding-agent tokens, customer feedback and paid API cost were **not measured**. Usage totals belong to the specified runs; diagnostic calls/partly measured rejected responses are not an account-wide bill. No new Phase 2.1 commit, GitHub push, remote CI or Railway deployment. HEAD remains `65bcd55cfbd55ca1d91691bb1d873e0560fd76b0` on `phase2/page-agent`. Docker image building remains unverified without its Linux daemon.

[Turkish architecture and local instructions](docs/COPILOT_PHASE21_TR.md), [structured evidence and complete Phase 2.1 changed-file list](docs/evidence/phase21-copilot-2026-10-20.json), [overdue screenshot](docs/evidence/phase21-overdue-2026-10-20.png), [conversation screenshot](docs/evidence/phase21-conversation-2026-10-20.png). Previous Phase 1/2 log and evidence are preserved.

Final source review **PASS**: 268 reviewable files; 78 protected source files unchanged; prior Phase 1/2 log and the exact supplied Phase 2.1 prompt preserved; real local key absent from source, compiled JS and test log. Gitleaks 8.30.1 raw exit 1, exactly two reviewed unchanged false positives (`docs/VERIFICATION_TR.md:39` public commit hash and `test/integration/authentication_test.rb:46` synthetic password), no new findings. Documentation: 27 Markdown files, 259 local links, 38 tables, 19 required README sections, 20 earlier protected files unchanged, 16 ignore checks, local master key unchanged, zero validation errors. `git diff --check` passed.

## Phase 2 finalization ? 21 October 2026

Original Phase 2 baseline and current pre-finalization HEAD: `65bcd55cfbd55ca1d91691bb1d873e0560fd76b0`, branch `phase2/page-agent`. The actual starting tree already contained 268 reviewed source files and uncommitted Phase 2/2.1 plus the local PostgreSQL helper repair. The original baseline was captured before changes; no older GitHub source was substituted. Baseline Rails seed 37289: 124 tests / 1692 assertions; browser seed 5184: 25 / 351, all passed.

User-observed usability gap: the team-size question fell through to general help because no team query existed in the closed planner schema. Settings already permits both roles to read their own team roster. Decision: continue the existing architecture with explicit read capabilities; no pivot/rebuild or Phase 3. This combines genuine LLM understanding, authorized PostgreSQL facts and official Alibaba DOM actions, with human-controlled writes; it does not establish industry novelty or absent Salesforce functionality.

### Finalization original prompt (verbatim)

Supplied UTF-8 file SHA-256: 2330e0482878f7aa879efda634fdf3308c8b20ecf4b4d699c2bb4ac4965afad2. Line endings normalized in Markdown.

```text
# CODEX TASK — LeadCurrent Phase 2 Finalization: Intelligent, Database-Aware AI Copilot

You are working on my existing LeadCurrent Ruby on Rails CRM application.

Repository: https://github.com/Montaserissa20/leadcurrent

Local project: `D:\LeadCurrent`

Production: https://leadcurrent-production.up.railway.app

## Objective

**Complete and polish Phase 2 of LeadCurrent AI Copilot.**

Phase 1 already integrated a Groq-powered AI Sales Assistant.

Phase 2 integrated the official Alibaba Page Agent and subsequently added conversational AI capabilities.

The system now successfully:
- Answers general questions about LeadCurrent.
- Holds natural conversations.
- Finds overdue leads.
- Reports verified customer records.
- Interacts with permitted browser controls.
- Navigates the CRM.
- Prepares notes without automatically submitting them.

Do not rebuild these working features.

However, during testing, we found an important remaining limitation.

### Actual user test

User:

"How many users are they in the team?"

Current Copilot answer:

"I don't have real-time access to the team roster, but you can view the current number of users in the team by navigating to Settings → Team → Members."

**This is not the experience we want.**

LeadCurrent already stores organization users in PostgreSQL.

The Copilot should understand this as a database question and, if the current user has permission, retrieve the actual number.

Example of the expected answer:

"Your workspace currently has 5 team members: 1 manager and 4 salespeople."

The numbers above are examples only.

**All actual numbers must come from the database.**

The goal is to build a more intelligent, reliable, and context-aware Copilot using our existing Groq API, Rails database, and Page Agent.

---

# 1. Understand the existing project

Before writing code:

1. Read `AGENTS.md`, `AGENT.md`, `README.md`, and `CHALLENGE_LOG.md`.
2. Inspect the existing AI Sales Assistant.
3. Inspect the official Alibaba Page Agent integration.
4. Inspect the current conversational Copilot architecture.
5. Inspect the Groq proxy and model-based intent handling.
6. Inspect the existing read-only CRM data tools.
7. Inspect `User`, `Organization`, `Lead`, `Opportunity`, `Task`, `Activity`, and their relationships.
8. Inspect `WorkspaceAccess`, roles, and the Settings/Team page permissions.
9. Inspect the current UI and browser tests.
10. Record the current Git branch and commit SHA.
11. Run the current automated tests to establish a baseline.

Do not overwrite the working local Phase 2.1 changes with the older Phase 1 version from GitHub.

Keep the existing Phase 2 development branch.

---

# 2. Make the Copilot understand actual CRM information

Extend the Copilot with safe, structured, read-only tools.

These tools should answer meaningful business questions from the user's actual LeadCurrent workspace.

## A. Team information

Implement an authorized team-information tool.

Support questions such as:

- "How many users are in my team?"
- "How many people work in this workspace?"
- "How many salespeople do we have?"
- "Are there any managers?"
- "What's our team size?"
- "Tell me how many members are registered."

Retrieve this information from existing `User` and `Organization` records.

Requirements:

- Scope all queries to the authenticated user's organization.
- Respect existing role permissions.
- If the current role cannot access a particular team detail, explain that limitation without exposing restricted data.
- Never include users from another organization.
- Do not invent users, names, or roles.
- Do not invent an `active` status if the existing schema does not have one.
- Distinguish registered team members from currently online users; do not claim to know online status without reliable session evidence.
- Clearly specify whether the count includes the current user.
- Minimize sharing team data with Groq.

Example verified response:

"Your workspace has 5 registered users, including you: 1 manager and 4 salespeople."

## B. Lead intelligence

Support questions such as:

- "How many leads do we have?"
- "Which leads are overdue?"
- "Which customers need attention today?"
- "How many leads are qualified?"
- "Which new customers haven't been contacted?"
- "Who is my most urgent customer?"
- "Show leads assigned to me."
- "What is the status of Atlas Industries?"

Use existing Rails models and business services.

For overdue leads, use the actual first-contact deadline logic.

For urgent recommendations, use our existing `NextBestAction` service rather than asking the LLM to calculate priority scores.

Support equivalent natural-language questions, even when they do not contain example keywords.

## C. Opportunity intelligence

Support:

- "How many opportunities do we have?"
- "How many deals have we won?"
- "Which opportunities are in negotiation?"
- "Show my lost deals."
- "What deals are waiting for proposals?"
- "Which opportunities have been inactive?"
- "What is our current sales pipeline?"

Use actual organization-scoped data.

Respect existing opportunity stages and transition rules.

Do not add together monetary values using different currencies unless the answer clearly separates the currencies.

## D. Tasks and follow-ups

Support:

- "How many tasks do I have today?"
- "Do I have any overdue follow-ups?"
- "Which customers should I contact first?"
- "What tasks are still pending?"
- "What should I focus on today?"

Use the current user's timezone and existing task/deadline rules.

Distinguish future scheduled tasks from completed contact activities.

Do not claim that scheduling a task completes a first contact.

## E. General system questions

Preserve conversational support for:

- "How can I use LeadCurrent?"
- "What is a lead?"
- "How does the sales pipeline work?"
- "What is the difference between a lead and an opportunity?"
- "How do I create a customer?"
- "How do I change my password?"
- "How does Next Best Action work?"
- "What can you do for me?"

These should produce natural answers without attempting unnecessary browser actions.

---

# 3. Implement a secure Rails tool layer

Create or extend a dedicated read-only CRM tool system.

Possible architecture:

- `Copilot::ToolRegistry`
- `Copilot::CrmReader`
- `Copilot::ToolExecutor`
- `Copilot::ResponseFormatter`

These names are suggestions. Follow the existing project conventions if the relevant components already exist.

Use explicit, allowlisted operations such as:

- `get_team_summary`
- `get_lead_summary`
- `list_overdue_leads`
- `get_urgent_leads`
- `get_opportunity_summary`
- `list_opportunities_by_stage`
- `get_task_summary`
- `get_customer_summary`

Do not implement a separate tool if an existing safe tool already provides the capability.

The LLM can select a supported operation and provide validated parameters.

However, **Rails must remain the authority over data access and calculations**.

Never allow the model to:

- Execute arbitrary SQL.
- Choose arbitrary Rails classes.
- Execute Ruby code.
- Run terminal commands.
- Call arbitrary URLs.
- Bypass authorization.
- Access unrestricted database records.
- Request arbitrary columns.
- Modify database records through read-only tools.

Use an explicit tool schema, strict argument validation, and appropriate result-size limits.

Reuse `WorkspaceAccess`, existing services, and role checks.

Do not create a second inconsistent implementation of the 24-hour, 4-hour, or 72-hour rules.

---

# 4. Improve natural-language understanding

The Copilot should not depend on a short list of keywords.

Examples:

"How many people are working with me?"

"What's the size of our sales team?"

"Do we have more than three users?"

These should all be recognized as team-information questions.

Likewise:

"Which customers are late?"

"Who have I forgotten to contact?"

"Do I have any overdue leads?"

should produce relevant, real CRM information when the request is clear enough.

Continue using Groq for model-based understanding.

The system should intelligently choose between:

1. Answering a general question.
2. Reading authorized CRM data.
3. Executing a safe Page Agent interaction.
4. Combining a data answer with navigation.
5. Asking a clarifying question.
6. Explaining that an action is unsupported.

Do not force every question through Page Agent's DOM interaction loop.

If a question can be answered accurately through a Rails database query, prefer that over several slow browser-agent steps.

Do not use keyword matching as the primary intent classifier.

---

# 5. Maintain conversation context

Make the Copilot understand short follow-up questions.

Example:

User: "How many leads are overdue?"

Copilot: "There are 3 overdue leads."

User: "Which one is the most urgent?"

Copilot should understand that "which one" refers to the overdue leads in the preceding question.

Another example:

User: "How many people are in our team?"

Copilot: "There are 5 registered team members."

User: "How many are salespeople?"

Copilot should understand that the user is still asking about team membership.

Requirements:

- Use bounded, short-lived conversation history.
- Scope the conversation to the current authenticated user and workspace.
- Never mix conversations across organizations or accounts.
- Do not let previous messages override security policies.
- Do not persist sensitive history unnecessarily.
- Clear private conversation content on logout.
- Handle Turbo navigation safely.
- Apply input, history and token limits.

---

# 6. Make results factual and useful

The assistant must clearly distinguish:

**Verified CRM data**

Data retrieved from authorized PostgreSQL queries.

**AI interpretation**

Suggestions, explanations, and generated language.

**Unknown information**

Anything that cannot be established from available records.

For database questions, attach or preserve structured query results so the displayed counts and record identities come from Rails rather than being freely generated by the model.

When possible, render verified numerical facts directly in Rails.

Example:

User: "How many opportunities are in negotiation?"

Good:

"You have 4 opportunities in Negotiation."

Bad:

"You probably have around 4 opportunities."

If a query returns zero results, state that explicitly.

If access is denied, explain it appropriately.

If the database or AI provider is unavailable, show a safe error rather than fabricated results.

Do not use "I don't have real-time access" when the appropriate authorized database tool is available.

---

# 7. Preserve and improve Alibaba Page Agent

Keep the official Alibaba Page Agent.

The Copilot should still be able to:

- Navigate between pages.
- Search for leads.
- Apply permitted filters.
- Open customer records.
- Show opportunities.
- Find overdue records.
- Prepare unsaved notes.

Maintain the actual DOM observation and tool-execution system.

Do not replace real Page Agent execution with hardcoded routes pretending to be AI actions.

Improve the user experience:

- Show the useful answer first.
- Collapse technical steps into an optional "Agent activity" section.
- Use understandable activity descriptions.
- Verify navigation results before reporting success.
- Avoid unnecessary page actions when Rails can answer directly.
- Preserve the Stop functionality.
- Handle unsupported actions conversationally.

An answer may combine both functions:

"I found 3 overdue leads. I've also opened the filtered Leads page."

Only claim that navigation occurred if the Page Agent actually performed and verified it.

---

# 8. Safety requirements

Keep the existing Phase 2 Safe Mode.

The Copilot can:

- Read authorized data.
- Answer questions.
- Navigate and filter.
- Open permitted records.
- Prepare drafts.
- Fill approved unsaved note fields.

It must NOT autonomously:

- Save customer activities.
- Mark first contact as completed.
- Change lead status.
- Move opportunities between stages.
- Mark deals Won or Lost.
- Delete records.
- Complete tasks.
- Send messages.
- Change passwords.
- Modify user accounts.
- Run arbitrary SQL or JavaScript.

Keep human approval for database-changing actions.

Do not weaken the existing SafeDom allowlists, session authentication, CSRF protections, Content Security Policy, or workspace isolation.

Treat CRM free text and browser content as untrusted, including prompt-injection attempts.

Keep `GROQ_API_KEY` on the server only.

Do not include unnecessary personal data in provider requests.

---

# 9. Performance and free-tier efficiency

We are using Groq because we do not want to host our own AI model.

Continue using the existing working model:

`openai/gpt-oss-20b`

Do not install or deploy Ollama or a new local LLM.

Do not require GPU hardware.

Do not introduce additional paid providers.

Improve efficiency where practical:

- Avoid Groq calls for deterministic calculations that Rails already performs.
- Avoid unnecessary repeated model calls.
- Keep database results compact.
- Limit conversation history.
- Retain safe rate limiting.
- Handle Groq 429 responses gracefully.
- Show progress for genuinely long Page Agent operations.
- Avoid excessive 25-second delays for simple CRM questions.

Do not remove existing rate-limit protections just to make the UI appear faster.

Preserve model configurability and the existing provider transport.

---

# 10. Improve the Copilot UI

Make the existing interface feel like one useful AI assistant rather than separate experimental features.

Keep the LeadCurrent visual identity and responsive design.

Improve:

- Conversation readability.
- Long-answer scrolling.
- Input positioning.
- Loading indicators.
- Clear error messages.
- Follow-up questions.
- Verified-data labels.
- Clickable authorized customer records.
- Expandable agent activity.
- Mobile layout.
- Light and dark mode.
- Keyboard usability.

Avoid excessive nested scrolling and large technical logs.

The user should be able to ask a question and immediately understand the answer.

Keep responses concise by default.

---

# 11. Automated tests

Add real regression coverage for:

**Team queries**
- Manager gets correct organization team counts.
- Salesperson gets only information permitted by the existing access policy.
- Cross-organization users are excluded.
- Role counts match database records.
- Zero-member edge cases are handled consistently with the data model.
- Natural paraphrases route to the same safe capability.

**CRM questions**
- Verified lead counts.
- Overdue lead filtering.
- Correct Next Best Action priority.
- Opportunity stage counts.
- Pending and overdue tasks.
- Timezone boundaries.
- Empty query results.
- Unauthorized record rejection.

**Conversation**
- Follow-up references work.
- Missing information is not invented.
- General CRM explanations still work.
- Invalid tool arguments are rejected.
- Groq failures do not crash the app.

**Page Agent**
- Safe navigation still works.
- Actual DOM controls are used.
- Technical steps are collapsed.
- Unsaved note preparation does not submit.
- Forbidden actions remain blocked.
- Turbo navigation remains functional.

**Regression**
- Phase 1 AI Sales Assistant still works.
- Phase 2 browser agent still works.
- All lead/opportunity transition rules remain unchanged.
- All existing 24h/4h/72h deadline tests pass.
- GitHub CI does not require an API key or live Groq requests.

Use mocked model responses for normal automated tests and a separate opt-in live integration test.

---

# 12. Real browser verification

After passing automated tests, use a fictional local workspace and real Groq requests to verify:

1. "Tell me how I can use the system."
2. "How many users are in my team?"
3. "How many of them are salespeople?"
4. "How many leads do we have?"
5. "Which leads are overdue?"
6. "Which one needs attention first?"
7. "Show my opportunities in negotiation."
8. "What follow-ups are due today?"
9. "Open Atlas Industries."
10. "Prepare a follow-up note for this customer."

Verify each database-derived answer against the actual PostgreSQL data.

Confirm the agent cannot submit the prepared note without a separate manual user action.

Clearly distinguish mocked tests from real Groq tests.

Do not claim that a test passed unless it actually ran successfully.

Do not modify production customer data.

---

# 13. Finalize university documentation

Update:

- `CHALLENGE_LOG.md`
- `AGENT.md`
- `README.md`
- Phase 2 technical documentation

Preserve all Phase 1 evidence.

Record:

- The original Phase 2 baseline.
- The current pre-finalization baseline.
- Why we continued rather than pivoted.
- The specific usability problems observed in manual testing.
- The new verified-data capabilities.
- Real tests and results.
- Groq tool usage if measured.
- Known limitations.
- Genuine time measurements if available.
- Unfinished promises.
- Actual source commits.
- Final decision: continue, pivot, or kill, with reasoning.

Include the original prompt accurately when available; never fabricate original prompts, working hours, API costs or measurements.

Explain how LeadCurrent now differs from a simple Salesforce-style CRM clone:

- Real LLM integration.
- Context-aware CRM questions.
- Verified, authorized database answers.
- Browser interaction using Alibaba Page Agent.
- Human-controlled business changes.

Do not claim these ideas are absent from Salesforce or unique to the entire CRM industry without evidence.

Prepare a short Turkish demo guide suitable for presenting the feature to the professor.

---

# 14. Final quality checks

Before declaring Phase 2 complete:

1. Run the full Rails test suite.
2. Run browser/system tests.
3. Run Zeitwerk checks.
4. Run Brakeman.
5. Run the Node/Page Agent build.
6. Verify the production asset build.
7. Verify Ruby and JavaScript syntax.
8. Review authentication, tenant isolation and AI rate limits.
9. Verify no API keys or credentials are tracked or staged.
10. Ensure no PostgreSQL database data was destroyed.
11. Check the Dockerfile and GitHub CI build requirements.
12. Verify the local application still starts and loads.

Avoid unnecessary architectural changes.

If a critical feature fails, repair it before marking Phase 2 complete.

---

# 15. Git and packaging

Keep all work on the existing Phase 2 development branch.

When implementation and tests are complete:

- Review the exact changes.
- Create a local commit with a descriptive message.
- Do not force-push.
- Do not push to GitHub yet.
- Do not deploy to Railway yet.

Our previous manually created ZIP accidentally contained `config/master.key`, `.git`, and local PostgreSQL files.

This must not happen again.

Use the existing `script/package_source.rb` safe packaging workflow, or an equivalent verified Git-tracked-source-only export.

Never include:

- `config/master.key`
- `.env` secrets
- `.git`
- `.local/postgres`
- Local databases
- Logs
- `node_modules`
- API keys
- Production credentials

Verify the actual archive file list before providing it.

Generate a clean review ZIP so I can upload it to ChatGPT for a final source-code review.

---

# 16. Final report

When finished, give me:

1. A summary of the improvements.
2. The reason the team-count question previously failed.
3. The new read-only CRM tools.
4. The model/tool-selection architecture.
5. Example questions that now work.
6. Actual automated test counts and results.
7. Actual live Groq test results.
8. Security and authorization results.
9. Performance improvements, if measured.
10. Files changed and local commit SHA.
11. Path to the clean source-only ZIP.
12. Known limitations and remaining problems.

**Definition of done:**

I can ask LeadCurrent AI Copilot ordinary questions, request verified CRM information, and give natural-language navigation instructions without memorizing example prompts.

When I ask, "How many users are in my team?", the system retrieves the authorized, actual number from PostgreSQL rather than claiming it cannot access the information.

Alibaba Page Agent must continue working, existing sales workflows must remain intact, and no database changes may occur without user approval.

Do not start Phase 3.

Do not push to GitHub or Railway until I approve the final reviewed version.

Start with the current Phase 2 implementation, diagnose missing CRM data capabilities, implement the smallest reliable improvements, and complete the final tests.
```


### Finalization review snapshot ? measured result and live quota block

**Status: local review snapshot; final continuous live acceptance BLOCKED. Do not mark Phase 2 fully verified or deployed.** Continue the existing CRM/LLM/DOM architecture; no Phase3, pivot, push or Railway changes. A local review commit is used to create the requested safe source ZIP; its actual SHA is resolved from Git HEAD, the ZIP name/comment and delivery message, not invented inside its own commit.

Implemented organization-scoped registered team/role counts following the existing both-role Settings roster policy; no identities, online/active inference or new write authority. Extended lead totals/stages/assigned/uncontacted/customer status, separate-currency pipeline and inactive opportunity reads. Existing overdue reads now include the first eligible official NBA recommendation, so follow-up urgency needs no duplicate tool. Tasks use the user's timezone. Strict per-query arguments and escaped bounded queries remain authoritative; model fact prose is ignored. The planner remains genuine Groq gpt-oss-20b with temperature0, not a keyword router. Ten schema fields now omit the redundant navigate boolean; Rails derives it from intent. A genuine diagnostic of the previous rejected JSON found 10 fields and exactly missing navigate; replay after the change passed with the same bounded note context, without raising token caps.

Record opening uses the same scoped customer summary only to choose a list type, then official Page Agent must use visible DOM navigation/search/record controls. Zero/ambiguous matches remain explicit. No privileged route/record ID is placed into its instruction. Canonical action policy no longer requests reflection fields; verified completion uses a separate short done-only policy/schema, independently enforced. SafeDom and official library source/allowlists unchanged. Logout purges that login's private cached conversation/pending plan. The only authentication-controller change is that purge; existing login/password/CSRF algorithms remain. Panel composer, scrolling, source labels, keyboard, mobile and optional activity were refined.

Final normal tests (mocked HTTP; real official library/browser DOM/Turbo): Rails seed38909 **139 tests /1820 assertions**, browser seed44039 **27 /385**, total **166 /2205**, zero failure/error/skip. Zeitwerk, Node locked ci/build, npm audit0, production assets and 120 Ruby/12 JS syntax passed. Brakeman0 warnings/errors with Windows Ractor/fork fallback diagnostics. Docker/CI source requirements reviewed, including the existing final-stage mkdir fix; Linux Docker daemon unavailable, so no image build or remote CI/deployment success is claimed.

Real API evidence: **16 runs**, 15 partial/failed and one focused note subset PASS (seed35567, 1 test/12 assertions, 3 real completions, 4297 measured tokens). Every one of the ten requested scenario TYPES had at least one observed pass across iterations. That is NOT a final-source single-run pass. The last schema run seed47881 (2026-10-21T09:16:15Z?09:17:56Z) passed first5/13 and stopped at the urgency follow-up with provider429/TPD. Three extra team paraphrases were not reached and are not claimed live. Provider response numeric-only diagnosis: TPD limit200000, used197642, requested2419, Retry-After27s; account-wide at observation, not a project bill or a guarantee that the remaining full run can fit after27s. Repeated live iterations consumed the available budget; further live requests stopped.

Across the 16 recorded runs: 89 successfully reported completions, 162847 prompt +9310 completion = **172157 measured tokens**, including repeated prefixes of failed runs. Rejected responses and separate diagnostics are not fully metered. Human hours, development-agent tokens and paid API costs are unmeasured. Failures retained: redundant overdue period rejected; earlier workspace owner scope carried into explicit my; read/show intent drift; duplicate urgency query selection; quota waits/retry exhaustion; Atlas searched in the wrong filtered list; HTTP400/tool generation; missing navigate JSON. Not all provider tool errors have a proven single cause. No failed run was relabelled all-pass. Test-only interquestion quota pacing reads existing budget windows and reports waits separately; no rate limits or invalid-output retry protections were removed.

Existing development data hashes unchanged for all non-session tables (2 users,7 leads,4 opportunities). Actual local browser login, dashboard, lists, customer profiles, Phase1 four controls and Copilot open/close passed; /up HTTP200/database connected. No reset/drop/seed/migration or production DB operation. Phase1 evidence and all prior challenge text remain preserved. Local master key remains unchanged/ignored. Source policy and final archive are independently checked before delivery; their exact commit/archive hash is delivered outside this self-referencing document.

[Current Turkish technical report and professor demo](docs/COPILOT_PHASE2_FINAL_TR.md), [full structured evidence including all run records and changed files](docs/evidence/phase2-finalization-2026-10-21.json), [actual fictional team-count screenshot](docs/evidence/phase2-team-2026-10-21.png). Known remaining work: recover Groq quota, rerun full opt-in live acceptance and extra paraphrases; retain safe model-error handling, bounded candidates, process-local limits, lack of online status and unverified Docker/deployment limitations. Decision: **CONTINUE, review locally; release remains unapproved and live acceptance remains incomplete.**

## 22 October 2026 — Phase 2 final release preparation

User request, preserved verbatim:

```text
# LeadCurrent — Phase 2 Final Release Preparation

We have completed Phase 2 of LeadCurrent, including:

- Groq-powered conversational AI Copilot.
- Official Alibaba Page Agent.
- Authorized database tools for team, leads, opportunities, and tasks.
- Natural-language questions and follow-up context.
- Safe DOM navigation and human-controlled changes.

Your task is to finalize Phase 2 for release. **Do not add new features or begin Phase 3.**

1. Inspect the current local Phase 2 implementation and preserve all existing work.
2. Run all automated Rails, browser, JavaScript build, security, and production-asset checks. Fix regressions.
3. Verify team counts, overdue leads, opportunities, natural conversation, Page Agent navigation, and unsaved-note preparation.
4. Run a limited real Groq acceptance test if sufficient quota is available. Avoid repeatedly exhausting the free tier. Record any remaining quota-related blockers accurately.
5. Keep `openai/gpt-oss-20b` as the default. Do not introduce unverified fallback models or additional providers.
6. Verify workspace isolation, read-only agent restrictions, credential protection, and the production Docker/Node build.
7. Update `CHALLENGE_LOG.md`, `AGENT.md`, README, and the Turkish presentation guide with genuine evidence.
8. Scan the Git changes and ensure no secrets, `.local` data, `config/master.key`, logs, or database files are included.
9. Create a final local commit and clean source-only review archive.
10. Produce a release-readiness report with test results, known limitations, commit SHA, and exact deployment steps.

**Do not push to GitHub or deploy to Railway yet.** Wait for my approval of the final report.

Preserve Phase 1, all sales business rules, and the existing working database. Do not start the AI-customer integration.

Success criterion: Phase 2 is verified, documented, and ready for a safe GitHub/Railway release.
```

Started from clean local `63184c6420deafc18029d09b164f9b91d20283df` on `phase2/page-agent`; all existing Phase2/2.1 work preserved. No app, domain, auth, schema, database config, Dockerfile, dependency lock or production setting changes. Only the opt-in acceptance harness gains a bounded release-smoke mode, plus documentation/evidence. This is not a new product feature or Phase3. The model remains openai/gpt-oss-20b with no fallback/provider addition.

Fresh normal Rails **139 tests/1820 assertions** (seed38868) and headless Edge **27/385** (seed5144), total **166/2205**, passed without failures/errors/skips. Normal HTTP is mocked; official Page Agent, DOM, Turbo and database authorization are real. Locked npm ci/build, npm audit0, Zeitwerk, 120 Ruby/12 JS syntax, production assets and Brakeman0 warnings/errors passed. Ruby advisory scan in a disposable container found no vulnerabilities against ruby-advisory-db commit `5fd86bbd406995ea4ed2df84651b209e28072031` (1266 advisories). No audit tool was added to application dependencies.

Docker Desktop Linux engine was initially stopped; starting it enabled a genuine production image build. Fresh-container PostgreSQL17 and Rails production startup passed /up200/connected, /login200, CSP without unsafe-eval, compiled Page Agent asset200 (537726 bytes), UID1000 and writable db/log/tmp. The real entrypoint ran three existing migrations only on the disposable empty database; zero users/leads were seeded. The working host DB was never prepared/reset/seeded/migrated. Temporary containers/network were removed individually. Two verification-harness failures were retained: internal-network port publishing unavailable, then a case-sensitive HTTP-header lookup; correcting the checker produced PASS without an application change. Initial advisory execution had a missing executable PATH; the ephemeral tool's explicit bindir fixed that check. These failed checks are not counted as successful product tests.

Fresh development fingerprint records all 11 non-session tables. Existing login, all CRM lists, Phase1's four AI controls on both record types, Copilot open/close and logout passed in a real browser without live AI calls. Team read is 2 registered members (1 manager/1 salesperson), includes requester; online unknown. Detailed limited-live results, final source/secret review, packaging, remaining limitations and approval-only deployment instructions are recorded in the [release report](docs/PHASE2_RELEASE_READINESS.md) and [dated evidence](docs/evidence/phase2-release-preparation-2026-10-22.json). Historical unsuccessful live attempts remain intact. No GitHub push or Railway deployment was performed.

Limited real Groq acceptance: exactly one bounded run (seed recorded in evidence), 2026-10-22T15:14:30Z–15:18:10Z, **8/8 selected scenarios PASS**, **1 test/105 assertions**, zero failures/errors/skips. Help, registered-team count, salesperson follow-up, overdue rows, urgency follow-up, actual Negotiation owner/stage filtering, visible-control Atlas navigation and UNSAVED note all passed. **16 real requests/completions**, **26290 prompt +1436 completion =27726 measured tokens**; no provider errors/429, no blocked extra request, no CRM writes, no CSP violations. Test time220.083s includes191.059s explicit quota pacing, not a new speed benchmark. No further real calls were made. The old TPD block did not recur for this scope; the remaining full13 run, lead-count/tasks live rerun and three extra team paraphrases are not claimed. Automated tests cover those read capabilities. Free-tier quota/headroom for another run or deployment is not guaranteed; paid cost and human hours unmeasured. Decision: ready for approval within this disclosed verification scope, not deployed or full-live-certified.

Final source review: 6 existing files changed and2 new documentation/evidence files; 267 existing tracked files unchanged, including164 protected runtime/config/build sources and10 historical evidence files. Historical challenge prefix preserved. Exact local-secret/signature/path policy passed272 source files. Redacted Gitleaks raw exit1 contains exactly2 unchanged reviewed false positives (public commit SHA and synthetic password fixture), zero confirmed credentials. Markdown/link/ignore checks passed29 files/282 links/41 tables/19 required README sections/16 ignore checks. Final commit and source-only archive are resolved after this documentation is committed; exact SHA, archive hash/content checks and clean status are supplied in the delivery manifest rather than fabricated in a self-referencing commit. No push/deploy authorization is implied by this local readiness result.


## 22 October 2026 — authorized Phase 2 GitHub publication

Original approved user task, verbatim:

```text
# CODEX TASK — Push LeadCurrent Phase 2 to GitHub

Phase 2 of LeadCurrent has been completed, reviewed, and prepared for release.

**I explicitly authorize you to commit and push the completed Phase 2 implementation to my existing GitHub repository.**

Repository: https://github.com/Montaserissa20/leadcurrent

Local project: `D:\LeadCurrent`

Production: https://leadcurrent-production.up.railway.app

## 1. Inspect the repository

Before pushing:

- Read `AGENTS.md`, `AGENT.md`, and `CHALLENGE_LOG.md`.
- Verify that you're working in the correct LeadCurrent project.
- Inspect `git status`, the current branch, remote configuration, and commit history.
- Preserve all completed Phase 1 and Phase 2 features.
- Verify that the latest Phase 2 code includes the improved database-aware AI Copilot.

The previously reviewed local Phase 2 release commit was:

`e220800f460f12159e5d613e4c550e63d9eb465c`

The last verified GitHub `main` commit was:

`65bcd55cfbd55ca1d91691bb1d873e0560fd76b0`

Check the actual current state rather than assuming those commits are still the latest.

## 2. Perform final safety checks

Before committing or pushing:

- Check that `config/master.key` is not tracked or staged.
- Exclude `.env` secrets, API keys, passwords, local PostgreSQL data, logs, and `.local` files.
- Exclude `node_modules`, `.git` metadata, and generated ZIP archives.
- Verify that `GROQ_API_KEY` never appears in committed files.
- Preserve the production database configuration.
- Do not run database resets or destructive migrations.

Our previous full-project ZIPs contained private local files. **Do not push or upload those ZIPs. Only commit intended source files.**

If you discover an exposed credential, stop and report it before pushing.

## 3. Verify the completed implementation

Confirm that Phase 2 includes:

- Groq-powered conversational AI Copilot.
- Official Alibaba Page Agent integration.
- Authorized team-member counts.
- Real lead, opportunity, and task intelligence.
- Natural-language CRM questions.
- Short conversation context.
- Safe UI navigation and filtering.
- Human approval for database-changing actions.
- Existing Phase 1 AI Sales Assistant.
- Updated documentation and `CHALLENGE_LOG.md`.

Do not rebuild or redesign the implementation.

## 4. Run final checks

Run the available automated verification:

- Rails tests.
- Browser/system tests.
- Node dependency installation and JavaScript build.
- Zeitwerk.
- Brakeman.
- Production asset compilation.
- Git secret scanning.

Make sure the tests don't require a real Groq API key.

Do not rerun the expensive live Groq acceptance suite unless essential; its available evidence has already been recorded.

If a required test fails, investigate and fix the issue before pushing.

## 5. Commit and push to main

After successful checks:

1. Fetch the latest `origin/main`.
2. Check for remote changes or divergence.
3. Preserve the Phase 2 commit history.
4. Commit any remaining reviewed Phase 2 source changes.
5. Integrate Phase 2 into `main` using a normal fast-forward workflow when possible.
6. Push to the existing `origin/main`.

Use a descriptive commit message if a new commit is necessary, such as:

`feat: complete Groq AI Copilot and Alibaba Page Agent integration`

**Do not create a new repository.**

**Do not force-push, reset remote history, or overwrite new remote commits.**

If the branch has diverged or contains unexpected changes, stop and report the situation instead of forcing the push.

## 6. Verify GitHub Actions

After pushing:

- Confirm the new commit appears on GitHub `main`.
- Retrieve the actual commit SHA and URL.
- Check the GitHub Actions workflow triggered by that commit.
- Confirm the Rails, browser, security, and JavaScript build jobs pass.
- Report any failures accurately.

If CI fails, investigate and fix the issue, then push a normal follow-up commit and recheck CI.

## 7. Check Railway deployment

Railway may automatically deploy when `main` changes.

Use the existing Railway service. Do not create a new project or database.

Check:

- Whether Railway deployed the new commit.
- Whether the Docker/Node build succeeded.
- Whether `/up` reports a healthy application.
- Whether the existing login page remains accessible.
- Whether the AI Copilot assets are available.

Preserve existing Railway variables, including `GROQ_API_KEY` and `GROQ_MODEL`.

Do not display secret values.

Do not make unrelated Railway configuration changes or reset production data.

If authenticated browser verification is possible safely, use only fictional test data. Otherwise provide manual testing instructions.

Do not claim a live Groq test passed unless it was actually performed.

## 8. Update release evidence

Update `CHALLENGE_LOG.md` and relevant release documentation with:

- Actual pushed commit.
- GitHub Actions URL and results.
- Railway deployment status.
- Verified production functionality.
- Remaining limitations.

Do not invent successful tests or deployment evidence.

Commit and push any necessary documentation-only follow-up using the normal workflow.

## 9. Final report

When finished, provide:

1. GitHub commit SHA and URL.
2. Confirmation that Phase 2 is on `main`.
3. Test results.
4. GitHub Actions status and URL.
5. Railway deployment status.
6. Confirmation that no secrets were committed.
7. Any remaining issues.
8. Simple steps to test the live Copilot.

**Success criterion:** Phase 2 is safely published to the existing LeadCurrent GitHub repository, GitHub Actions passes, and Railway successfully deploys the new version without losing any existing CRM data.

Do not begin Phase 3 yet.

Proceed with the push now.
```

Explicit approval superseded the historical local-only boundary. Fetched actual origin/main65bcd55; preserved reviewed `e220800f460f12159e5d613e4c550e63d9eb465c` and its parent63184c6 through a normal fast-forward/main push. No force/reset/history overwrite/new repository or Phase3. Fresh local Rails139/1820 seed55542 and browser27/385 seed20164, total166/2205, passed; npm locked build, Zeitwerk, Brakeman0 and production assets passed. Source272 and exact-secret history392 checks passed; Gitleaks outgoing two commits0 findings. No master key/env secrets/local DB/log/node_modules/archive data pushed.

Exact feature-commit [LeadCurrent CI](https://github.com/Montaserissa20/leadcurrent/actions/runs/39811052953) passed every Node/Rails/Chrome/autoload/security/production-assets step. Actual CI logs independently showed139/1820 and27/385. Railway had no feature-commit deployment record and production lacked new Page Agent assets at 2026-10-22T16:11:29.461Z; health/login still worked on the previous version. No successful Phase2 deployment or live production Groq test is claimed. No Railway credentials/configuration/database changes, production fixtures, reset/seed/destructive migrations. Available Railway integration was discovered/offered, not connected; deployment completion requires existing-service access or a manual Deploy Latest Commit. Historical8-case local acceptance preserved, expensive suite not rerun. [Publication report](docs/PHASE2_PUBLICATION.md), [evidence](docs/evidence/phase2-publication-2026-10-22.json). Documentation-only follow-up/final-tip CI checked separately after push; no future result fabricated.

## 22 October 2026 — finish GitHub handoff; Railway explicitly deferred

Latest user instruction, verbatim:

```text
Railway deployment is currently blocked by the platform, so I cannot deploy Phase 2 right now.
Please finish your work without waiting for Railway.
Verify that Phase 2 is correctly pushed to GitHub and that CI passed. Complete the documentation and final report using the evidence already available.
Clearly mark Railway deployment and production acceptance testing as **pending**, not completed.
Do not create another Railway service, modify production configuration, or start Phase 3.
Give me the final GitHub commit, CI results, and instructions for deploying Phase 2 when Railway becomes available again.
```

The user previously selected that they would trigger Deploy Latest Commit; no new Phase2 deployment was verified. They then reported the platform block and explicitly removed waiting for Railway from the current task. This is user-reported status, not a diagnosed provider incident. Deployment polling/attempts stop; **Railway deployment: PENDING. Phase2 production acceptance: PENDING / NOT RUN.** No new service, production configuration/variables/data changes, production fixtures, Phase3 or AI-customer integration.

GitHub `main` independently verified at `903b09508c495390bf6377f064122dbdf29c93fd`, which preserves reviewed Phase2 `e220800` and parent63184c6. Exact [documentation-checkpoint LeadCurrent CI](https://github.com/Montaserissa20/leadcurrent/actions/runs/39813080017) completed successfully, including Node build, Rails, browser, Zeitwerk, security and production assets. Feature CI39811052953 and local166/2205 evidence remain intact. Normal tests require no real Groq key; no expensive live suite was rerun.

Final source-only documentation update records the explicit PENDING statuses and existing-service deployment/acceptance steps for later platform recovery. It is pushed normally; final main SHA and its exact CI are verified after that commit exists and supplied in delivery, without inventing self-referencing hashes or future deployment results. Existing application/business/schema/database settings remain unchanged. [Final publication instructions](docs/PHASE2_PUBLICATION.md), [structured evidence](docs/evidence/phase2-publication-2026-10-22.json).


## 22 October 2026 — Phase 3: actual AI-agent-to-business inquiry (local review)

Starting project: existing independent LeadCurrent at D:\LeadCurrent, baseline `e8c3e0da485994567c948e40fbeb4cc32a4dc312`, verified clean before changes. Existing URL: https://leadcurrent-production.up.railway.app (historical Phase1 production evidence; Phase2 Railway deployment externally blocked per user, still pending). Continued on new `phase3/agent-customer` without resetting main, touching D:\ruby_project, overwriting Phase2 or resetting/seeded customer data. This new user brief explicitly authorizes local Phase3 and supersedes the earlier no-Phase3 boundary. No publication/deploy/production variables changed.

**Pain point and source:** the professor asks “What if your customer were an AI agent?” in the user's original brief below. The practical problem is receiving machine-originated buyer requests while preserving human control and not trusting claimed company/budget/authority. This is a project requirement, not a fabricated customer interview or evidence that other CRMs lack agent integrations. **Continue rather than pivot:** the existing workspace model, CreateLead, Groq and Phase1/2 provide the right foundation. **Promise:** an external actual AI buyer can submit an authenticated inquiry, see a real receipt and stop; the human sees unverified claims and alone can create a normal lead.

**Built:** organization-bound manager-issued once-visible/revocable/expiring digest-only credentials; independently authenticated bounded JSON intake; strict field/type and duplicate-key validation; rate caps; durable credential-key idempotency/conflicts; immutable dedicated source records; scoped responsive light/dark inbox; optional fixed-20b saved-data qualification; manager review/reject/needs-info; locked atomic existing CreateLead acceptance, tenant constraints, fresh24h deadline and audit. Separate Python stdlib deterministic and real Groq buyer modes use fixed local action schemas/destinations and no arbitrary code/payment tools. No trusted lead, completed contact, opportunity/Won or purchase is created by an incoming request/model response.

**Measured evidence:** baseline Rails139/1820 seed20008 and browser27/385 seed38958 passed. Final Rails164/2108 seed17603 and browser29/436 seed9596 passed, total193/2544; Python7 passed; normal provider transport mocked. Zeitwerk, Brakeman zero warnings/errors, Node22 locked build, production assets, upgrade from existing three-migration schema and actual Linux Docker production startup against isolated PostgreSQL17/four migrations passed. Nine original development application-table content hashes remained unchanged, new tables empty; sessions/schema metadata excluded. Direct DB constraint/race tests, secret-free Rails request log capture, CSRF/password checks, missing contacts and real CreateLead failure rollback passed. Actual development browser smoke12/12 passed. A copied smoke initially incorrectly required Page Agent on the new protected routes; the checker was corrected, not the route allowlist.

**Real live attempt1:** 2026-10-22T17:06:00Z–17:06:06Z. Actual deterministic Python POST201 and repeat200 passed; real Groq buyer HTTP403 failed, no successful completions reported. Preserved as FAIL, not a quota claim. Added an honest application User-Agent to Python transport; subsequent full run worked, without claiming all403 causes proven. **Attempt2:** 17:07:44Z–17:08:53Z,1test/48assertions seed51631 PASS,69.31s including60s test-only quota pause. Actual separate Python buyer → saved inquiry/inbox → real qualification → human approval/CreateLead/source/deadline → real Phase1 analysis → real Phase2 authorized lead query all passed. No production contacted, fictional fixtures rolled back. Four successful real completions,4808 measured tokens (4086prompt+722completion): buyer837,qualification786,Phase1 1063,Phase2 2122. No429 in passing run. Rejected403 has unreported usage, not assumed free. Later owner/reason/archive guards passed normal tests; no extra live calls after success. **Human/agent development hours, paid financial cost, savings/revenue were not measured.**

**Security and limitations:** possession is not corporate verification; stolen tokens can submit pending claims until revoke/expiry. Tenant-scoped reads/services/composite FKs, locks/unique indexes, early body/log bounds, strict JSON and escaped views protect the workflow. Prompt controls do not prove AI prose factual; no execution/write authority, AI labels and human verification remain mandatory. Free-text redaction is imperfect. Minute quotas/Groq gates are process-local: centralize before multiple workers/replicas. Latest100 lists; no outbound email, OAuth verification, inquiry update/polling API, quotation acceptance or payment. Missing contact requires a new complete inquiry rather than fabricated data. Source scanner adds agent/Groq signatures; actual final ZIP must exclude every private/runtime path and be verified. Historical generic Gitleaks false positives require individual review, not suppressed actual keys.

**Commit references:** Phase2 baseline `e8c3e0da485994567c948e40fbeb4cc32a4dc312` preserved; Phase3 local commit and archive hash are reported after the reviewed source commit exists, avoiding impossible self-reference. [Technical report](docs/AGENT_CUSTOMER_PHASE3.md), [short Turkish presentation/demo commands](docs/AGENT_CUSTOMER_DEMO_TR.md), [structured observations and actual screenshots](docs/evidence/phase3-agent-customer-2026-10-22.json). All earlier evidence retained.

**Unfinished commitments:** user review/approval, normal GitHub publication and exact Phase3 CI, then existing-service Railway deployment when available, additive production migration with backup and actual production acceptance. These are PENDING, not failed local tests or completed deployment. No public tunnel/new service/production environment change. **Decision: CONTINUE** to human review of the local result: the actual agent-to-business scenario and existing CRM integration passed. Keep production release gated; no pivot or kill is supported by the measured result.

### Original Phase 3 Codex prompt (verbatim)

````text
# CODEX TASK — LeadCurrent Phase 3: AI Agent as a Customer

You are working on my existing LeadCurrent Ruby on Rails CRM SaaS.

This is the final major development phase of my university project.

**Do not rebuild the application. Extend the existing working system.**

## 1. Project context

Repository:
https://github.com/Montaserissa20/leadcurrent

Local project:
`D:\LeadCurrent`

Production:
https://leadcurrent-production.up.railway.app

Technology:
- Ruby 3.4.7 / Rails 8.1.4
- PostgreSQL
- Hotwire, Turbo, Stimulus, importmap, Propshaft
- Existing Groq AI integration
- Existing Alibaba Page Agent
- GitHub Actions
- Railway Docker deployment

Completed features:

**Phase 1:** AI Sales Assistant with real Groq integration, customer analysis, activity summaries, AI-enhanced recommendations, and follow-up drafting.

**Phase 2:** Conversational AI Copilot with Alibaba Page Agent, safe browser interaction, CRM database queries, natural-language questions, team information, and authorized sales analytics.

Both phases are already in the GitHub repository.

The current Phase 2 GitHub baseline, last checked, is:

`e8c3e0da485994567c948e40fbeb4cc32a4dc312`

Verify the actual current branch and HEAD before making changes.

Railway deployment of Phase 2 is currently blocked externally. Do not treat that as a code failure and do not create another Railway service.

## 2. Main objective

My professor asked:

**"What if your customer were an AI agent?"**

We want LeadCurrent to support two kinds of customers:

1. Human customers, handled through the existing CRM.
2. External AI agents acting as prospective buyers.

An external AI purchasing agent should be able to communicate with LeadCurrent through a secure API and submit an actual purchasing inquiry.

LeadCurrent should:

1. Authenticate the external agent.
2. Receive and validate the inquiry.
3. Store the inquiry separately from trusted CRM leads.
4. Clearly mark the information as unverified.
5. Optionally analyze it with Groq.
6. Present it to a human salesperson.
7. Allow an authorized human to accept or reject it.
8. Convert accepted inquiries into ordinary LeadCurrent leads through existing domain services.

**Do not allow unknown AI agents to create trusted leads, accept purchases, change deals, or bypass human approval.**

This must be a functioning system, not merely a chatbot pretending to be a customer.

---

# 3. Inspect the existing application first

Before implementation:

- Read `AGENTS.md`.
- Read `AGENT.md`.
- Read `README.md`.
- Read `CHALLENGE_LOG.md`.
- Inspect the current Rails routes.
- Inspect Organization, User, Company, Contact, Lead, Opportunity and AuditEvent.
- Inspect CreateLead, WorkspaceAccess and the workflow services.
- Inspect the existing Groq client and Phase 1/2 AI services.
- Inspect database schema and migrations.
- Inspect the authentication and authorization architecture.
- Inspect current tests and CI configuration.
- Inspect current Docker and Railway configuration.

Run existing automated tests and record the baseline.

Do not overwrite Phase 2 with an older GitHub version.

Do not modify `D:\ruby_project`.

Do not reset the existing PostgreSQL database.

---

# 4. Feature A — Secure External Agent API

Build a secure API that allows an external AI purchasing agent to submit a sales inquiry.

Suggested endpoint:

`POST /api/v1/agent_inquiries`

Use JSON requests and JSON responses.

Example request:

```json
{
  "company_name": "Atlas AI Procurement",
  "contact_name": "Alex Morgan",
  "contact_email": "buyer@example.test",
  "product_or_service": "Business software subscriptions",
  "quantity": 50,
  "currency": "USD",
  "stated_budget": 10000,
  "requirements": "We need 50 subscriptions with team management and reporting.",
  "desired_timeline": "Within 30 days",
  "message": "Please provide licensing information and pricing."
}
```

The submitted information is a *claim made by the requester*, not independently verified company information.

The API must:

- Validate required fields.
- Enforce reasonable field lengths.
- Validate email and structured quantity/currency fields where supplied.
- Reject malformed JSON.
- Reject excessive request sizes.
- Reject unsupported fields or safely ignore them according to an explicit schema.
- Apply request rate limits.
- Produce predictable JSON error responses.
- Never expose Rails stack traces or internal secrets.
- Return a receipt containing the new inquiry identifier and review status.
- Avoid automatically creating a trusted CRM lead.

Do not require unsupported contact details at submission time if an inquiry can safely remain pending with missing information.

Do not invent missing email addresses, contacts, or company details.

## API authentication

Implement secure, workspace-bound agent credentials.

I recommend:

- A manager-only interface to generate an agent API credential.
- Random, high-entropy credentials.
- Store only a secure digest, never the original token.
- Display the token only once when created.
- Support revocation.
- Optional expiration.
- Bearer-token authentication.
- Constant-time credential comparison where applicable.
- Explicit API scopes such as `inquiries:create`.

An agent credential must belong to one specific LeadCurrent organization.

A requester must not be able to choose or override its organization by supplying `organization_id`.

The credential determines the destination workspace.

Use a separate API authentication mechanism, not a fake Rails user session.

Ensure the API does not accept session cookies as a substitute for bearer authentication.

Keep browser CSRF protections intact. Any CSRF exception must be narrowly restricted to the independently authenticated token-only API.

Do not print bearer tokens in logs, exception messages, audit records, or generated documentation.

---

# 5. Feature B — Agent Inquiry persistence

Create a dedicated model for inbound agent inquiries.

Suggested model:

`AgentInquiry`

Suggested attributes:

- organization_id
- agent_credential_id
- company_name
- contact_name
- contact_email
- product_or_service
- quantity
- currency
- stated_budget
- requirements
- desired_timeline
- message
- status
- submitted_at
- reviewed_at
- reviewed_by_id
- accepted_lead_id
- AI qualification fields if needed

Follow the existing database conventions.

Suggested statuses:

- pending_review
- needs_information
- accepted
- rejected

You may simplify this if it improves reliability.

Use strict allowed transitions.

Do not permit accepted or rejected inquiries to be silently resubmitted or approved twice.

Use database transactions, row locking where appropriate, and database constraints to protect against duplicate approvals.

Implement request idempotency so an external agent retry does not create multiple identical inquiry records.

Use a client-supplied idempotency key bound to the authenticated credential and a durable uniqueness constraint.

Reject use of the same idempotency key with a different payload.

Ensure submitted inquiries are permanently scoped to the correct organization.

Preserve the original inquiry payload needed for later review, subject to field limits and appropriate privacy handling.

Do not introduce destructive migrations.

---

# 6. Feature C — Agent Inquiry Inbox

Create a new section in LeadCurrent:

**Agent Inquiries**

Add it to the authenticated sidebar.

Only authorized users should access it.

Build a polished interface consistent with the existing LeadCurrent design.

The page should include:

- Total inquiries
- Pending review count
- Accepted inquiries
- Rejected inquiries
- Status filters
- Recent inquiry list
- Inquiry details
- Submission timestamp
- Source: External AI Agent
- Claimed company information
- Product and quantity requested
- Stated budget and timeline
- Optional AI qualification result
- Human review actions

A useful inquiry card might show:

**Atlas AI Procurement**

50 software subscriptions  
Stated budget: $10,000  
Status: Pending Review  
Source: External AI Agent  
Identity: Unverified

The interface must clearly distinguish:

- Information supplied by the external agent.
- Data verified by LeadCurrent.
- AI-generated interpretations.
- Human review decisions.

Do not label an external company as verified merely because its API request was authenticated.

Support light mode, dark mode, desktop and mobile.

Use the existing Rails/Hotwire frontend rather than introducing another frontend framework.

---

# 7. Feature D — Groq AI Inquiry Qualification

Reuse our existing server-side Groq integration.

Default model:

`openai/gpt-oss-20b`

Do not require a new AI provider or local GPU.

The AI should analyze incoming inquiries and help the salesperson understand them.

Example AI output:

**Request summary**

The requester claims to represent a company seeking 50 software subscriptions.

**Potential opportunity**

The inquiry includes a product category, quantity, and proposed budget.

**Missing information**

The required security features, actual decision-maker, and purchasing authority have not been verified.

**Suggested next step**

Confirm licensing requirements and request verification of the buyer's authority before preparing a quotation.

Requirements:

- Use actual saved inquiry data.
- Never invent verified company identities.
- Never invent approved budgets.
- Never claim that an inquiry was accepted when it is pending.
- Never automatically accept or reject an inquiry.
- Never create a Lead or Opportunity from an LLM response.
- Label AI interpretations clearly.
- Validate generated structured responses.
- Treat incoming text as untrusted data.
- Defend against prompt injection in agent-submitted messages.
- Keep provider secrets on the Rails server.
- Handle API timeouts, 429 responses, and missing Groq configuration gracefully.

Avoid automatic AI qualification on every incoming API request if that would unnecessarily consume our limited Groq free-tier quota.

Prefer an explicit **Analyze with AI** action or controlled background processing with strict limits.

If Groq is unavailable, the inquiry must remain accessible and reviewable without AI.

No fake AI analysis or fabricated fallback text.

---

# 8. Feature E — Human Approval

This is the most important security boundary.

An external AI agent can submit an inquiry, but **only an authorized human decides whether it becomes a lead**.

Implement:

- Accept Inquiry
- Reject Inquiry
- Request More Information, if feasible

Use existing manager/owner authorization conventions.

Manager-only approval is acceptable if it provides a safer and clearer workflow.

On acceptance:

1. Confirm the inquiry is still eligible for approval.
2. Validate all fields required by the existing Lead creation service.
3. If information is missing, leave the inquiry pending or mark it as needing information.
4. Select a valid owner from the current organization.
5. Use the existing `CreateLead` domain service or a narrowly adapted equivalent.
6. Create Company, Contact, and Lead consistently.
7. Associate the new Lead with its originating inquiry.
8. Record the approval and lead creation in the existing audit system.
9. Mark the inquiry Accepted.
10. Prevent a second acceptance from creating duplicate leads.

Preserve atomic behavior. A failed lead creation must not leave the inquiry falsely marked Accepted.

**Important first-contact rule:**

The ordinary 24-hour first-contact deadline should begin when the real Lead is created through human acceptance, using the existing LeadCurrent deadline service.

Do not mark the incoming agent message as a completed customer contact.

Do not automatically create a Won opportunity or mark a purchase completed.

On rejection:

- Record who rejected the inquiry and when.
- Optionally store a short reason.
- Do not delete the original submission.
- Do not create a customer record.

All review actions must be protected against CSRF, tampering, cross-workspace access, and double submission.

---

# 9. Feature F — Real External AI Purchasing Agent

Build a small, separate Python demonstration client.

Suggested location:

`examples/purchasing_agent/`

The purpose is to demonstrate an AI acting as the buyer, not simply a human clicking a form.

The demo should use a real Groq-powered model to turn a purchasing goal into a structured inquiry.

Example goal:

"We are a fictional startup that needs 50 software subscriptions for our employees. Our proposed budget is $10,000. We want to ask LeadCurrent for a quotation."

Expected agent behavior:

1. Receive the purchasing objective.
2. Identify information required by LeadCurrent's public agent API.
3. Generate or request the missing details without fabricating company verification.
4. Prepare a structured inquiry.
5. Validate the inquiry using a fixed local schema.
6. Submit it to the API using its authorized agent credential.
7. Receive and display the inquiry receipt.
8. Stop rather than autonomously accepting an offer or making a purchase.

Use a fixed allowlisted API base URL supplied through configuration.

Do not allow the LLM to choose arbitrary network destinations.

Do not give the model access to arbitrary Python execution, filesystem operations, or shell commands.

The Groq API key and LeadCurrent agent credential must remain outside prompts and source code.

The buyer agent may choose a structured `submit_inquiry` tool call, but only the trusted Python application should execute the HTTPS request.

Require an explicit allowlisted action schema.

Clearly distinguish fictional demonstration information from real business claims.

## Two testing modes

**Mode A — Deterministic client**

A simple API smoke test using fictional, predefined data, with no LLM calls.

This verifies authentication, validation, persistence, and idempotency.

**Mode B — Real AI purchasing agent**

A real Groq-powered agent that receives a purchasing goal and submits the inquiry through its permitted tool.

This verifies the actual agent-to-business concept.

Mode B must not be simulated with hardcoded successful model responses.

Allow the real AI demo to be run manually and independently of normal CI.

Use existing Groq credentials when available.

Do not exhaust the free daily quota by repeatedly running unnecessary model tests.

---

# 10. End-to-end demonstration

Prepare a complete demonstration for my professor.

Use fictional companies and local data.

Scenario:

**Step 1 — LeadCurrent manager**

The manager generates a workspace-bound agent API credential.

**Step 2 — External AI purchasing agent**

The agent receives:

"Find a way to request pricing for 50 software subscriptions with a proposed budget of $10,000."

**Step 3 — API communication**

The agent submits the actual request to the running LeadCurrent Rails API.

Show the real HTTP request/response, with credentials redacted.

**Step 4 — Incoming inquiry**

The Agent Inquiries inbox displays the newly received request.

**Step 5 — Groq qualification**

The manager clicks Analyze with AI.

The AI explains what the buyer requested, which information remains unverified, and the recommended response.

**Step 6 — Human approval**

The manager reviews and accepts the inquiry.

The application creates an ordinary LeadCurrent lead through the authorized workflow.

**Step 7 — Verify ordinary CRM functionality**

Open the newly created lead.

Demonstrate that:

- It belongs to the correct organization.
- It has the correct owner.
- It has the correct first-contact deadline.
- It is linked to its source inquiry.
- The external agent cannot alter it.
- Phase 1 AI Sales Assistant can analyze the lead.
- Phase 2 Copilot can find the lead through authorized queries.

The demo should prove real integration between all three phases.

Do not use a canned screenshot or hardcoded success response as evidence.

---

# 11. Security requirements

Treat this as an internet-facing API design even though the initial testing is local.

Mandatory protections:

- Cryptographically strong agent credentials.
- Secure token storage and revocation.
- No secrets in source control.
- No secrets in logs.
- No unrestricted API access.
- Organization isolation.
- Explicit API scopes.
- Bounded request sizes.
- Strict JSON validation.
- Rate limiting.
- Idempotency.
- Duplicate approval protection.
- Auditability.
- Safe exception handling.
- No arbitrary SQL execution.
- No arbitrary network access from the model.
- No automatic sales-stage changes.
- No autonomous purchasing or payment.
- Prompt-injection protections.
- Sensitive information minimization.
- Controlled access to inquiry data.

Keep the API independent from the normal browser login session.

If using process-local rate limits, document that production with multiple replicas requires a shared limiter.

Use database-backed or otherwise durable idempotency.

Preserve current password handling, Content Security Policy, session rules, CSRF protection, and existing Rails authorizations.

Review the threat model for:
- Forged company identities
- Stolen API credentials
- Cross-tenant data access
- Replayed requests
- Duplicate submissions
- Prompt injection
- API flooding
- Approval race conditions
- Malicious or oversized input

---

# 12. Automated tests

Write comprehensive Minitest and browser tests.

At minimum verify:

### API authentication
- Missing credential returns 401.
- Invalid credential returns 401.
- Revoked credential returns 401.
- Expired credential returns 401.
- Valid credential can submit only permitted inquiries.
- Credential cannot access another organization.
- Request-supplied organization IDs cannot change the destination tenant.

### API behavior
- Valid inquiry is persisted.
- Malformed JSON is rejected.
- Missing required fields are rejected.
- Invalid data types are rejected.
- Oversized input is rejected.
- Rate limits are enforced.
- Identical idempotent retries do not create duplicate records.
- Reusing an idempotency key with different content is rejected.
- API responses never expose secrets.

### Human review
- Manager can review an authorized inquiry.
- Unauthorized users cannot approve.
- Cross-workspace approval fails.
- Acceptance creates the expected company/contact/lead.
- Rejection does not create a lead.
- Missing required contact information prevents invalid acceptance.
- Concurrent approval does not create duplicate leads.
- Accepted leads follow the existing deadline rules.
- Approval and rejection produce appropriate audit evidence.
- Agent submissions do not count as completed first contact.

### AI qualification
- Correct saved inquiry context is supplied.
- Model output is safely validated.
- Prompt injection cannot execute an action.
- Groq errors do not corrupt inquiry data.
- AI does not change the inquiry decision.
- AI cannot access another workspace.

### Regression
- Phase 1 AI Sales Assistant passes.
- Phase 2 Page Agent passes.
- Existing Copilot database queries pass.
- Existing lead and opportunity transitions pass.
- 24-hour, 4-hour and 72-hour rules pass.
- Password/security tests pass.

Normal CI must mock external LLM calls.

Add a separate, explicitly enabled real Groq acceptance test.

Do not require paid API usage for GitHub Actions.

---

# 13. Performance and costs

Keep the project suitable for a university demonstration and Groq's free tier.

Do not:
- Train a new foundation model.
- Install a large local model.
- Require GPU hosting.
- Add paid cloud services unnecessarily.
- Add new AI providers without a demonstrated need.

Use the existing Groq model:

`openai/gpt-oss-20b`

Make API usage efficient.

Use the existing Rails and PostgreSQL architecture.

Measure real provider token use only when available.

Never fabricate token counts, development hours, cost savings or revenue projections.

---

# 14. Documentation and university requirements

Update:

- `README.md`
- `AGENT.md`
- `CHALLENGE_LOG.md`

Create a Phase 3 technical report and short Turkish presentation guide under `docs/`.

Preserve all earlier Phase 1 and Phase 2 evidence.

The mandatory `CHALLENGE_LOG.md` must preserve its existing content and add a new Phase 3 section including:

- Starting project and baseline commit
- Existing live URL
- Customer pain point and supporting source
- Why we continued rather than pivoted
- Phase 3 promise
- What was actually built
- Real tests and evidence
- Original Codex prompt, preserved accurately
- Commit references
- Human and agent development time, if actually measured
- Provider usage and financial costs, if actually measured
- Known limitations
- Unfinished commitments
- Final continue/pivot/kill decision with justification

Explain the business value:

Traditional CRM systems primarily receive information through human-facing forms and integrations.

Our adaptation demonstrates a machine-to-machine sales inquiry workflow in which external AI agents can act as prospective buyers, while human salespeople retain control over acceptance and commercial decisions.

Do not claim that Salesforce or other CRM platforms lack AI-agent integrations unless supported by current evidence.

Prepare a concise Turkish explanation answering:

"Bir müşteri AI agent olsaydı, LeadCurrent nasıl çalışırdı?"

Also explain how the architecture differs from a generic chatbot.

---

# 15. Local development and deployment restrictions

Railway deployment is currently blocked by the platform.

Therefore:

- Implement and test locally.
- Keep working on a new Phase 3 development branch.
- Do not overwrite or reset the Phase 2 main branch.
- Do not push to GitHub yet.
- Do not deploy to Railway yet.
- Do not create another Railway project.
- Do not change production environment variables.
- Do not reset or destroy the local database.

Use additive migrations and preserve existing customer records.

Verify that new migrations work from the current production-equivalent schema on a test database.

Do not require an immediately accessible public URL to test the external Python purchasing agent; it can communicate with Rails running locally.

Do not publicly expose localhost through an unauthenticated tunnel.

---

# 16. Implementation sequence

Follow this order:

1. Audit the existing repository.
2. Record baseline tests and commit.
3. Design the AgentInquiry and AgentCredential models.
4. Implement secure token authentication.
5. Implement the inquiry submission API.
6. Implement durable idempotency and rate limits.
7. Build the Agent Inquiries inbox.
8. Implement manager-controlled approval/rejection.
9. Reuse the existing CreateLead service.
10. Implement optional Groq qualification.
11. Create the external Python purchasing-agent demo.
12. Add comprehensive security, integration and browser tests.
13. Perform the real end-to-end demonstration locally.
14. Verify Phase 1 and Phase 2 regression tests.
15. Update documentation and CHALLENGE_LOG.md.
16. Prepare the final review package.

Keep the work focused. Do not add unrelated features.

---

# 17. Final verification

Before declaring success:

- Run all Rails tests.
- Run browser/system tests.
- Run Zeitwerk checks.
- Run Brakeman.
- Run JavaScript/Page Agent build.
- Run production asset compilation.
- Check migrations.
- Verify database constraints.
- Verify no credentials are staged.
- Verify no current customer data was lost.
- Verify the external client can submit an authenticated request.
- Verify the manager can review and accept it.
- Verify existing LeadCurrent AI capabilities still work.

If a real Groq test is blocked by free-tier limits, document that honestly and preserve all mocked/integration evidence.

Do not mark an unperformed real API test as successful.

---

# 18. Final delivery

At the end, report:

1. What was implemented.
2. How the external purchasing agent works.
3. How agent authentication and workspace isolation work.
4. How inquiries are stored and reviewed.
5. How AI qualification works.
6. How approval creates a normal CRM lead.
7. How duplicate requests are prevented.
8. The real test results.
9. Real Groq demonstration results.
10. Security findings.
11. Files created and modified.
12. Database migrations added.
13. Local commit SHA.
14. Exact local demo commands.
15. Known limitations.
16. What remains before a GitHub/Railway release.

Create a clean, source-only review ZIP.

Exclude:
- `config/master.key`
- `.git`
- `.local`
- PostgreSQL files
- `.env` secrets
- `node_modules`
- Logs
- API keys
- Local archives

Verify the actual ZIP contents.

**Do not push to GitHub or deploy to Railway until I approve the reviewed Phase 3 result.**

## FINAL SUCCESS CRITERION

I can run LeadCurrent locally, start an external AI purchasing agent in a separate Python process, and have that agent submit a real authenticated purchasing inquiry to the Rails API.

The inquiry appears in the CRM with unverified identity status.

A human manager can ask Groq to analyze it, review the information, and approve it.

Only after approval does LeadCurrent create an ordinary lead using existing business rules.

Phase 1 and Phase 2 continue functioning correctly.

This must demonstrate an actual **AI-agent-to-business workflow**, not a static chatbot response or a simulated screenshot.

Begin with the repository audit and architecture design, then implement and test Phase 3 systematically.
````
