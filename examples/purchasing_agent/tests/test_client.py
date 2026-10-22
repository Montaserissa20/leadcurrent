import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import secrets
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location("buyer_client", Path(__file__).resolve().parents[1] / "client.py")
client = importlib.util.module_from_spec(spec)
spec.loader.exec_module(client)


class PurchasingAgentTest(unittest.TestCase):
    def setUp(self):
        self.token = "lc_agent_" + secrets.token_hex(12) + "." + secrets.token_urlsafe(32)
        self.key = secrets.token_urlsafe(24)
        self.env = mock.patch.dict(os.environ, {"LEADCURRENT_AGENT_TOKEN": self.token, "GROQ_API_KEY": self.key}, clear=False)
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_fixed_destinations_reject_model_urls_userinfo_queries_and_nonloopback_http(self):
        for base in ("https://evil.example", "http://0.0.0.0:3100", "http://127.0.0.1:3100/evil", "http://user@127.0.0.1:3100", "http://127.0.0.1:3100?secret=x", "http://127.0.0.1.evil:3100"):
            with self.subTest(base=base), self.assertRaises(client.ClientError):
                client.api_url(base)
        self.assertEqual("http://127.0.0.1:3100/api/v1/agent_inquiries", client.api_url("http://127.0.0.1:3100"))
        self.assertIsNone(client.NoRedirect().redirect_request(None, None, 302, "", {}, "https://evil.example"))

    def test_schema_rejects_invalid_types_unknown_fields_and_credential_content(self):
        for changes in ({"quantity": True}, {"quantity": "50"}, {"quantity": 0}, {"stated_budget": "1.234"}, {"currency": "JPY"}, {"company_name": None}, {"message": self.token}, {"message": self.key}, {"contact_email": "bad"}, {"organization_id": 7}):
            with self.subTest(fields=list(changes)), self.assertRaises(client.ClientError):
                client.validate_inquiry({**client.deterministic_inquiry(), **changes})
        inquiry = {**client.deterministic_inquiry(), "contact_name": None, "contact_email": None}
        self.assertEqual(inquiry, client.validate_inquiry(inquiry))
        with self.assertRaises(client.ClientError):
            client.decode_json('{"action":"a","action":"b"}')
        with self.assertRaises(client.ClientError):
            client.decode_json('{"quantity":NaN}')

    def test_deterministic_submission_uses_bearer_and_durable_key_without_groq(self):
        calls = []
        receipt = {"inquiry_id": 7, "status": "pending_review", "identity": "unverified", "replayed": False}
        def transport(url, payload, headers):
            calls.append((url, payload, headers))
            return 201, receipt
        status, result = client.submit_inquiry(client.deterministic_inquiry(), "http://127.0.0.1:3100", "deterministic-key-123", transport)
        self.assertEqual((201, receipt), (status, result))
        self.assertEqual(1, len(calls))
        self.assertEqual("Bearer " + self.token, calls[0][2]["Authorization"])
        self.assertEqual("deterministic-key-123", calls[0][2]["Idempotency-Key"])
        self.assertNotIn(self.token, json.dumps(calls[0][1]))

    def test_real_mode_contract_mocks_transport_only_and_does_not_send_credentials_to_model(self):
        inquiry = client.deterministic_inquiry()
        identity = {field: inquiry[field] for field in ("company_name", "contact_name", "contact_email")}
        def transport(url, payload, headers):
            self.assertEqual(client.GROQ_URL, url)
            self.assertEqual(client.MODEL, payload["model"])
            self.assertEqual("none", payload["tool_choice"])
            self.assertTrue(payload["response_format"]["json_schema"]["strict"])
            self.assertNotIn(self.token, json.dumps(payload))
            self.assertNotIn(self.key, json.dumps(payload))
            return 200, {"model": client.MODEL, "choices": [{"finish_reason": "stop", "message": {"role": "assistant", "content": json.dumps({"action": "submit_inquiry", "inquiry": inquiry, "questions": []})}}], "usage": {"total_tokens": 123}}
        action, usage = client.generate_inquiry("Fictional company asks for 50 software seats; proposed USD10000.", identity, transport)
        self.assertEqual("submit_inquiry", action["action"])
        self.assertEqual({"total_tokens": 123}, usage)

    def test_model_cannot_choose_arbitrary_actions_invent_identity_or_submit_missing_required_fields(self):
        inquiry = client.deterministic_inquiry()
        identity = {field: inquiry[field] for field in ("company_name", "contact_name", "contact_email")}
        for action in ({"action": "execute_python", "inquiry": inquiry, "questions": []}, {"action": "submit_inquiry", "inquiry": {**inquiry, "contact_email": "invented@example.test"}, "questions": []}, {"action": "submit_inquiry", "inquiry": None, "questions": []}):
            with self.assertRaises(client.ClientError):
                client.validate_action(action, identity)
        result = client.validate_action({"action": "request_information", "inquiry": None, "questions": ["What company do you claim to represent?"]}, identity)
        self.assertIsNone(result["inquiry"])

    def test_provider_failure_is_safe_without_retry_or_success_fallback(self):
        inquiry = client.deterministic_inquiry()
        identity = {field: inquiry[field] for field in ("company_name", "contact_name", "contact_email")}
        calls = []
        def transport(*args):
            calls.append(args)
            raise client.ClientError("groq_http_429")
        with self.assertRaises(client.ClientError):
            client.generate_inquiry("Fictional buying objective", identity, transport)
        self.assertEqual(1, len(calls))
        with self.assertRaises(client.ClientError):
            client.generate_inquiry(self.token, identity, transport)

    def test_real_http_transport_identifies_the_client_and_never_puts_bearer_in_body_or_errors(self):
        receipt = {"inquiry_id": 7, "status": "pending_review", "identity": "unverified", "replayed": False}
        response = mock.MagicMock()
        response.__enter__.return_value = response
        response.status = 201
        response.read.return_value = json.dumps(receipt).encode()
        opener = mock.Mock()
        opener.open.return_value = response
        with mock.patch.object(client.urllib.request, "build_opener", return_value=opener) as build:
            status, value = client.http_json(client.api_url("http://127.0.0.1:3100"), client.deterministic_inquiry(), {"Authorization": "Bearer " + self.token})
        request = opener.open.call_args.args[0]
        self.assertEqual("LeadCurrent-PurchasingAgent/1.0", request.get_header("User-agent"))
        self.assertNotIn(self.token, request.data.decode())
        self.assertIsInstance(build.call_args.args[0], client.NoRedirect)
        self.assertEqual((201, receipt), (status, value))
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = client.main(["--mode", "deterministic", "--idempotency-key", self.token])
        self.assertEqual(1, result)
        self.assertNotIn(self.token, output.getvalue())


if __name__ == "__main__":
    unittest.main()
