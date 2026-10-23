"""Development/CI contract validation; never contacts Rails, a provider or a customer."""
from pathlib import Path
from copy import deepcopy
import yaml
from jsonschema import Draft202012Validator
from openapi_spec_validator import validate

path = Path(__file__).resolve().parents[1] / "docs/api/agent-inquiries.openapi.yaml"
with path.open(encoding="utf-8") as source:
    spec = yaml.safe_load(source)
validate(spec)
schemas = spec["components"]["schemas"]


def validator(name):
    return Draft202012Validator({"$ref": "#/components/schemas/" + name, "components": {"schemas": schemas}})


operation = spec["paths"]["/api/v1/agent_inquiries"]["post"]
request = validator("InquiryRequest")
example = operation["requestBody"]["content"]["application/json"]["example"]
request.validate(example)
minimal = {name: example[name] for name in schemas["InquiryRequest"]["required"]}
request.validate(minimal)
nullable = {name: None for name in schemas["InquiryRequest"]["properties"]}
nullable.update(minimal)
request.validate(nullable)
for field, value in [("organization_id", 1), ("contact_email", "not-an-email"), ("quantity", True), ("currency", "GBP"), ("message", "\x00"), ("company_name", " "), ("stated_budget", "10.001")]:
    invalid = deepcopy(example)
    invalid[field] = value
    if request.is_valid(invalid):
        raise ValueError("Contract incorrectly accepted invalid example: " + field)
missing_currency = deepcopy(example)
del missing_currency["currency"]
if request.is_valid(missing_currency):
    raise ValueError("Contract accepted stated budget without currency")
checked = 0
for code, response in operation["responses"].items():
    content = response["content"]["application/json"]
    name = "InquiryReceipt" if code in ("200", "201") else "ApiError"
    values = [content["example"]] if "example" in content else [entry["value"] for entry in content["examples"].values()]
    for value in values:
        validator(name).validate(value)
        checked += 1
print(f"OpenAPI 3.1 valid; full/minimal/nullable request examples, 8 invalid cases and {checked} response examples checked.")
