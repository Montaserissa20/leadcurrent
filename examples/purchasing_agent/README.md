# External purchasing agent

Python standard library only; no pip packages, model SDK, arbitrary tools or new provider. Run from the repository root. [Exact PowerShell setup and demo commands](../../docs/AGENT_CUSTOMER_DEMO_TR.md) show how to enter a manager-issued credential without putting it in shell history. [API/security contract and measured results](../../docs/AGENT_CUSTOMER_PHASE3.md).

Required environment: `LEADCURRENT_AGENT_TOKEN` and `LEADCURRENT_BASE_URL` (use `http://127.0.0.1:3100` locally). Real AI mode also requires `GROQ_API_KEY`. Never print/store these values in prompts, source, screenshots or request traces. Credentials authorize only pending inquiry submission for their issuing workspace.

```powershell
python examples/purchasing_agent/client.py --mode deterministic --idempotency-key fictional-mode-a-0001
python examples/purchasing_agent/client.py --mode ai --goal 'Fictional startup needs pricing for 50 software subscriptions; proposed budget 10000 USD, not approved; no purchase.' --company 'Fictional Meridian Procurement' --contact-name 'Fictional Alex Buyer' --contact-email buyer@example.test --idempotency-key fictional-mode-b-0001
python -m unittest discover -s examples/purchasing_agent/tests -v
```

Repeat an identical deterministic command/key for a 200 replay of the original 201 receipt. Reusing a key with different data gives 409. Use a new key for a new inquiry. AI generation can vary: a later identical goal/key may produce a different payload and legitimately conflict. The client does not retry. Missing contact details may remain pending, but human acceptance requires the unchanged CRM service's contact name/email.

Mode A uses fixed fictional data without Groq. Mode B calls actual Groq `openai/gpt-oss-20b`, validates only `submit_inquiry` or `request_information`, checks that identity matches explicit CLI inputs, and lets trusted code post validated data. `request_information` stops without submitting. The model cannot choose network destinations, execute Python, access files, accept an offer or make a payment. HTTP redirects are forbidden; loopback HTTP is allowed only at fixed local ports 3100/3170, and remote traffic is restricted to the existing allowlisted production HTTPS origin. Do not run against production without release approval.

Output contains fictional inquiry/receipt and numeric provider usage, never either credential. Provider errors yield a safe code and a failing exit status. No fabricated fallback response is used. Normal tests mock transport only; the opt-in Rails verifier exercised actual separate Python processes and actual Groq/HTTP calls. Real usage and the first failed 403 attempt are preserved in the technical report. Avoid repeated free-tier calls.


## Phase 3.1 developer entry point

Open http://127.0.0.1:3100/agent-integrations for copyable cURL, PowerShell and standalone Python examples, or download [OpenAPI3.1](../../docs/api/agent-inquiries.openapi.yaml). [Integration/authorization, safe environment setup, replay and professor guide](../../docs/AGENT_INTEGRATION_GUIDE.md). A single `python examples/purchasing_agent/client.py --mode deterministic` command generates a fresh key and makes an actual API request without Groq. The client source and existing deterministic/real-AI behavior were preserved. External integrations may use any model/provider; only the authenticated HTTPS/JSON contract is required. Public deployment remains pending approval.
