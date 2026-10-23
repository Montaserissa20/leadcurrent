# LeadCurrent external-agent integration guide

23 October 2026 · Phase 3.1 · local review only. This extends Phase 3 commit `87cd77ead659523482c0e9682b8c444a92c228d5` on `phase3/integration-center`. No GitHub push, Railway deployment, production configuration/data change or new migration is part of this task. Public deployment and production acceptance remain **PENDING**. Preserve the existing local Phase 3 implementation; remote main may still contain only Phase 2.

## Start with the Integration Center

Open **http://127.0.0.1:3100/agent-integrations**. It is public, contains no CRM records or issued credentials, and links to protected credential management and the Agent Inquiries inbox. The inbox also links back to it. The page supports the existing light/dark themes, desktop/mobile, keyboard-accessible example disclosures, copy buttons with temporary success feedback and explicit clipboard-failure guidance. It has no browser API tester, token input/storage, external analytics or model connection. A copy never sends an inquiry.

[Actual full-page light screenshot](evidence/phase31-integration-center-light-2026-10-23.png) · [dark screenshot](evidence/phase31-integration-center-dark-2026-10-23.png) · [390px mobile screenshot](evidence/phase31-integration-center-mobile-2026-10-23.png) · [actual deterministic inquiry inbox](evidence/phase31-integration-inbox-2026-10-23.png). These are direct browser captures, without image generation or credential-page captures.

The actual [OpenAPI 3.1 specification](api/agent-inquiries.openapi.yaml) is available locally at **http://127.0.0.1:3100/api-docs/agent-inquiries/openapi.yaml**, as an attachment. The page advertises this through an HTML `rel="service-desc"` link and HTTP Link header. Download/import the file or URL into an OpenAPI-compatible development client or agent framework. Choose a server explicitly and configure its credential privately; importing the contract grants no permission. No hosted Swagger UI, MCP server or public self-registration was added.

The existing production origin is `https://leadcurrent-production.up.railway.app`. The equivalent documentation and API URLs are usable **only after an approved commit is deployed and checked**. Their inclusion is not a deployment claim. The page derives its current-server endpoint from the real Rails POST route, and code payloads from the same checked-in OpenAPI example. It does not use database records as sample content.

## What any outside agent needs

An agent needs the HTTPS endpoint, JSON schema, an active credential issued by the destination workspace, and permission to submit inquiries. It may use **any AI model/provider, or no AI at all**. Groq, Alibaba Page Agent, the internal Rails Copilot, the browser UI and our Python demonstration client are not required for submission. Do not send model identity, prompts, private reasoning or system instructions; they are not accepted fields.

An outside company asks its LeadCurrent workspace manager for authorization through an agreed private channel. The manager decides who receives access and how claimed business identity/authority will be verified. Credential possession authenticates a narrow submission capability; it does not establish corporate identity or approved funding.

## Issue and protect the credential

1. Sign in as a manager and open **Agent Inquiries → Manage agent credentials**, or use the Integration Center's **Manage Agent Credentials** link.
2. Name the integration and optionally set an expiration. Generate the credential.
3. Copy it once into a private environment/secret mechanism and share through an approved private channel. LeadCurrent stores only a digest and cannot display it again. Do not put the value in source, prompts, command history, URLs, screenshots, browser logs or verbose HTTP traces.
4. Revoke a test, leaked or obsolete credential using the same protected page. Revocation blocks new submissions and replays. The existing inquiry remains reviewable.

Each credential is permanently bound to one organization with `inquiries:create` scope. The client cannot select a tenant or owner. Missing/invalid/revoked/expired credentials return 401; browser session cookies do not substitute. Credential creation/revocation and inquiry decisions remain manager-only; ordinary CSRF, login, mandatory-password and tenant guards are unchanged.

## Send the purchasing inquiry

```http
POST /api/v1/agent_inquiries
Authorization: Bearer YOUR_AGENT_TOKEN
Content-Type: application/json
Idempotency-Key: fictional-integration-request-0001
```

Use HTTPS remotely. Loopback HTTP is permitted for local testing. The API accepts JSON and returns JSON; maximum raw request body is **16,384 bytes**. Do not add query parameters. Required fields are nonblank `company_name`, `product_or_service` and `message`. Contact name/email, quantity, currency, stated budget, requirements and desired timeline are optional at intake; supplied data must validate. Missing contact details may remain pending but prevent lead acceptance. Never invent them.

The contract gives exact lengths/types and error/receipt shapes. Unknown fields, duplicate JSON keys, forbidden controls and recognized embedded credential formats are rejected. Quantity must be a JSON integer token, not boolean/string/decimal. Stated budget is nonnegative with at most 12 integer digits and two decimals, and requires USD/EUR/TRY currency. String lengths are checked before trimming. Some wire-level distinctions (for example integer `1` versus decimal token `1.0`) cannot be fully expressed by JSON Schema's mathematical integer type; the contract documents the stricter Rails parser behavior. Rails remains authoritative.

The page provides runnable **cURL/Bash**, **PowerShell** and **Python standard-library** examples with the real endpoint, bearer and idempotency headers, private environment-variable references and fictional data. Its copy buttons copy the displayed source, not hidden credentials. Expand examples with Enter/Space. If clipboard access is denied, the page selects the text and explains manual copying. Each execution creates a real fictional inquiry; none calls an LLM.

## Deterministic professor/developer test

Keep the existing PostgreSQL and Rails server on port 3100. Do not reset/drop/seed/migrate customer data for Phase 3.1; no migration was added. If necessary, start the existing application using the setup in [Phase 3](AGENT_CUSTOMER_PHASE3.md), whose one additive migration must already be applied. A running server can be reused.

In a **separate PowerShell** terminal:

```powershell
Set-Location D:\LeadCurrent
$env:LEADCURRENT_BASE_URL = 'http://127.0.0.1:3100'
$credentialInput = Read-Host 'Agent credential (hidden)' -AsSecureString
$credentialPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentialInput)
try {
  $env:LEADCURRENT_AGENT_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($credentialPtr)
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($credentialPtr)
}
python examples/purchasing_agent/client.py --mode deterministic
```

This single final command generates a fresh UUID idempotency key, posts a real fictional purchase inquiry and prints the actual receipt and key. It needs neither Groq nor pip dependencies. In the browser open Agent Inquiries; the new request is `pending_review` with **Identity: Unverified**. There is still no ordinary CRM lead.

To demonstrate replay, run this explicit-key pair once with a fresh chosen key:

```powershell
python examples/purchasing_agent/client.py --mode deterministic --idempotency-key fictional-professor-demo-0001
python examples/purchasing_agent/client.py --mode deterministic --idempotency-key fictional-professor-demo-0001
```

The first creates an inquiry (201); the second returns its same ID (200, `replayed:true`). Choose a new key for the next presentation. Do not use a token as the key. After the demo, revoke the credential and clear the client process variable:

```powershell
Remove-Item Env:LEADCURRENT_AGENT_TOKEN -ErrorAction SilentlyContinue
```

Our preserved demo client intentionally has fixed destination allowlists: local 3100, isolated verifier 3170, and the existing production HTTPS origin. If using another port/origin, the Integration Center's independent examples can target the current server; the API itself is not tied to our demo client. Do not weaken that client's model/network boundary to add a destination chosen by a model.

## Idempotency and response handling

Idempotency keys are 16–100 ASCII letters, digits, `.`, `_`, `:` or `-`, scoped to the credential and persisted as digests with a database unique constraint. Identical payload/key retries return the current status of the same inquiry. Top-level key order is ignored; omitted versus explicit null, changed strings or numeric/string representations count as different payloads. The same key with different contents returns 409. Replaying an accepted/rejected inquiry never reopens it or creates another lead. Replacing the credential changes the idempotency namespace.

```json
{"inquiry_id":123,"status":"pending_review","identity":"unverified","replayed":false}
```

This is a fictional illustrative receipt; actual IDs are allocated by Rails. The deterministic run's genuine responses are in the dated evidence. Statuses mean pending human review, internally needing information, human-accepted into a normal lead, or retained/rejected. Accepted/rejected are final. There is no public status polling/update API. Request-information records an internal decision and sends no email; obtaining missing details/new complete submission is a human process.

| HTTP | Meaning and action |
| --- | --- |
| 201 / 200 | Created / identical replay; retain the actual inquiry ID and key |
| 400 | Malformed or duplicate JSON, bad key, query parameters; correct the request |
| 401 | Check credential, scope, expiry/revocation with the manager; never paste the token into an error report |
| 405 / 413 / 415 | Use POST, body at most 16 KB and application/json |
| 409 | Restore the original body/key for retry, or use a new key for a deliberately new inquiry |
| 422 | Correct field schema/types/lengths; never add organization/status/owner overrides |
| 429 | Respect Retry-After: 60; retry the same body/key later |
| 503 | Temporary intake failure; retry later with the same body/key, without assuming it was not persisted |

Errors are fixed JSON `{error:{code,message}}`, not stack traces/provider text. Minute limits are 60/IP, 10/credential and 30/workspace. Retries count. These limits are process-local and need a shared implementation before multiple workers/replicas. Server-to-server integrations need no permissive browser CORS; none was added. Do not automate retries that evade quotas or flood the service.

## Optional real AI demonstration

Mode A tests API integration without tokens. Mode B really turns a goal into a structured purchasing request with the existing Groq **`openai/gpt-oss-20b`** demo buyer; it uses the **same authenticated API** and may consume free-tier tokens. This optional demonstration does not constrain the model used by outside agents.

```powershell
$env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY', 'User')
python examples/purchasing_agent/client.py --mode ai --goal 'Fictional startup requests pricing for 50 software subscriptions; proposed budget 10000 USD, not approved. No purchase.' --company 'Fictional Meridian Procurement' --contact-name 'Fictional Alex Buyer' --contact-email buyer@example.test
```

If clarification is requested, the buyer stops rather than inventing required information. If quota/timeout/provider failure occurs, report it honestly; there is no fake success/fallback. The original [real Phase 3 proof](evidence/phase3-agent-customer-2026-10-22.json) includes the successful four-completion run and initial 403. **No live Groq tests were repeated for Phase 3.1.** Keys stay outside prompts and source. The buyer cannot choose network destinations, execute code, approve an inquiry, accept a quotation or pay.

## How human review protects the CRM

An agent can only create an unverified source record. Both authenticated CRM roles may read their own workspace's inbox; only a manager may analyze/review. Optional AI qualification reads the saved scoped inquiry, remains labeled interpretation and cannot make a decision. Human acceptance requires real saved contact information and a valid same-workspace owner, then calls unchanged `CreateLead` atomically under a lock. The first-contact deadline starts at **lead creation +24 hours**. It does not mark a contact completed or create a purchase/Won opportunity. Source linkage and real human audit events remain. Reject does not create a customer or discard the source. Credential authentication never marks the company/budget/authority verified.

## Verification and development tooling

Normal Rails/system/Python tests mock provider transport and require no model key. OpenAPI shape is checked with maintained [openapi-spec-validator](https://openapi-spec-validator.readthedocs.io/en/latest/), pinned as a development/CI-only requirement. Rails tests cross-check routes, field limits, scopes, errors and statuses, then submit the published fictional example to the actual controller. Browser tests use the actual clipboard, allow platform newline normalization, check denial feedback, keyboard disclosures and 390px theme layouts. This is not a claim of a complete WCAG audit. Copyable examples use a validated current-server origin to prevent code syntax from a Host header.

```powershell
python -m venv .local/openapi-venv
& .local/openapi-venv/Scripts/python.exe -m pip install -r docs/api/requirements-validation.txt
& .local/openapi-venv/Scripts/python.exe -m openapi_spec_validator docs/api/agent-inquiries.openapi.yaml
& .local/openapi-venv/Scripts/python.exe script/validate_agent_openapi.py
bundle exec rails test
bundle exec rails test:system
python -m unittest discover -s examples/purchasing_agent/tests -v
bundle exec rails zeitwerk:check
bundle exec brakeman --no-pager --quiet
npm run build
```

The validator is not a Rails/runtime/Python-client dependency and adds no paid service. OpenAPI 3.1 semantics were checked against the [official specification](https://spec.openapis.org/oas/v3.1.1.html); its JSON Schema integer definition explains the wire-token caveat. New CI validates the specification, but remote CI is **NOT RUN** because this local work was not pushed. Actual final counts, checks, screenshots and preservation evidence are in [Phase 3.1 evidence](evidence/phase31-integration-center-2026-10-23.json).

The explicit actual-HTTP verifier creates a fictional manager in a rollback test transaction, issues its credential through UI, launches the existing Python client in a separate process, performs POST201/replay200, verifies the saved pending inbox, and never modifies development customers or calls Groq:

```powershell
$env:LEADCURRENT_VERIFY_INTEGRATION = '1'
bundle exec ruby script/verify_agent_integration.rb
Remove-Item Env:LEADCURRENT_VERIFY_INTEGRATION
```

This opts in only locally, refuses CI/production and preserves success/failure reports under ignored `.local`. Its first attempt exposed a test navigation race after Turbo login; awaiting the completed redirect fixed the verifier. It was not an API/authentication bypass. The passing run is recorded separately. Follow full regression results rather than silently treating an interrupted baseline/browser trial or early harness assertion failure as a passing test.

## Kısa Türkçe sunum

**“Başka bir şirketin yapay zekâ ajanı LeadCurrent'a nasıl bağlanır?”**

“Agent Integrations sayfasını açar; OpenAPI belgesinden gerçek endpoint'i, JSON alanlarını ve hata kodlarını öğrenir. Hedef workspace'in yöneticisinden yalnız inquiry gönderme yetkisi olan credential alır. Kendi yazılımı HTTPS üzerinden bearer ve idempotency başlıklarıyla satın alma talebi gönderir. Groq, Alibaba Page Agent veya bizim Copilot'umuzu kullanması gerekmez; istediği modelle çalışabilir. Kimlik ve bütçe iddiadır, doğrulanmış sayılmaz. Talep ayrı inbox'a düşer; ancak insan yönetici kabul ederse normal lead oluşur.”

Sunum sırası: **Integration Center → OpenAPI indir → manager credential oluştur → ayrı terminalde deterministic komutu → gerçek 201 receipt → inbox'ta unverified/pending → aynı key ile 200 replay → manager review**. Clipboard kopyalama, dark/light ve mobil görünümü gösterin. İsterseniz önceki Phase 3 gerçek AI demosunu açıklayın; kota harcayarak tekrar çalıştırmak zorunlu değildir. Deterministic API testi ile gerçek model-generated alıcı testi farklıdır. Sonunda test credential'ını revoke edin. Satın alma, doğrulanmış şirket veya başarılı Railway deploy iddia etmeyin.

## Remaining release steps and limits

No Phase 3.1 migration, new provider/model, public registration, MCP server, browser tester or CORS relaxation was added. Existing inquiry limits remain: latest100 lists, no outbound email or public update/polling, fallible AI interpretation and imperfect free-text redaction. Credential possession is not legal/commercial identity proof. Revoke stolen credentials; introduce shared quotas before multi-process scaling. Public docs are non-sensitive; management/intake/review remain protected.

User review and explicit publication approval come first. Compare the current remote main and merge the preserved local Phase 3/3.1 commits normally, then require exact-commit GitHub CI. When Railway becomes available, use the **existing** service/variables/Dockerfile; back up data before the already-reviewed additive Phase 3 migration and verify health, docs download, secure intake, controlled fictional inquiry and human approval. Do not reset/seed production, create a replacement service or claim deployment/acceptance before observing it. GitHub publication, Railway deployment and production acceptance remain **PENDING**.
