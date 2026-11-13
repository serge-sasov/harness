#!/usr/bin/env python3
"""Validate a harness OpenAPI 3.x specification.

The harness architecture stage requires one canonical OpenAPI 3.x file per
API-NNN. This validator is intentionally dependency-light: JSON is parsed with
the standard library, YAML requires PyYAML (the same dependency as the e2e data
validator).
"""
import argparse
import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

API_ID_RE = re.compile(r"API-\d{3}")
OPENAPI_VERSION_RE = re.compile(r"^3\.\d+\.\d+$")
HTTP_METHODS = {
    "get",
    "put",
    "post",
    "delete",
    "options",
    "head",
    "patch",
    "trace",
}


def load_document(path):
    suffix = path.suffix.lower()
    text = path.read_text(encoding="utf-8-sig")
    if suffix == ".json":
        return json.loads(text)
    return yaml.safe_load(text)


def main():
    parser = argparse.ArgumentParser(description="Validate a harness OpenAPI 3.x file.")
    parser.add_argument("spec_path")
    args = parser.parse_args()

    errors = []
    warnings = []
    path = Path(args.spec_path)
    document = None

    if not path.exists():
        errors.append(f"OpenAPI file not found: {path}")
    else:
        try:
            document = load_document(path)
        except Exception as exc:
            errors.append(f"parse error: {exc}")

    if document is not None:
        if not isinstance(document, dict):
            errors.append("top-level document must be a mapping")
        else:
            if "swagger" in document:
                errors.append("Swagger 2.0 is not supported; use OpenAPI 3.x")
            version = str(document.get("openapi", ""))
            if not OPENAPI_VERSION_RE.fullmatch(version):
                errors.append(f"openapi must be 3.x.y, got {version!r}")

            api_id = str(document.get("x-harness-api-id", ""))
            if not API_ID_RE.fullmatch(api_id):
                errors.append(f"x-harness-api-id must be API-NNN, got {api_id!r}")

            info = document.get("info")
            if not isinstance(info, dict):
                errors.append("info must be a mapping")
            else:
                for key in ("title", "version"):
                    value = info.get(key)
                    if not isinstance(value, str) or not value.strip():
                        errors.append(f"info.{key} must be a non-empty string")

            components = document.get("components")
            if components is not None and not isinstance(components, dict):
                errors.append("components must be a mapping")

            paths = document.get("paths")
            if not isinstance(paths, dict) or not paths:
                errors.append("paths must be a non-empty mapping")
            else:
                operation_ids = set()
                operation_count = 0
                for path_key, path_item in paths.items():
                    if not isinstance(path_key, str) or not path_key.startswith("/"):
                        errors.append(f"path {path_key!r} must start with '/'")
                    if not isinstance(path_item, dict):
                        errors.append(f"paths[{path_key!r}] must be a mapping")
                        continue
                    if "$ref" in path_item:
                        warnings.append(f"paths[{path_key!r}] uses a top-level $ref; operation checks skipped")
                        continue
                    for method, operation in path_item.items():
                        if method.lower() not in HTTP_METHODS:
                            continue
                        operation_count += 1
                        if not isinstance(operation, dict):
                            errors.append(f"{method.upper()} {path_key} must be a mapping")
                            continue
                        operation_id = operation.get("operationId")
                        if not isinstance(operation_id, str) or not operation_id.strip():
                            errors.append(f"{method.upper()} {path_key} has no operationId")
                        elif operation_id in operation_ids:
                            errors.append(f"duplicate operationId: {operation_id}")
                        else:
                            operation_ids.add(operation_id)
                        responses = operation.get("responses")
                        if not isinstance(responses, dict) or not responses:
                            errors.append(f"{method.upper()} {path_key} has no responses")
                if operation_count == 0:
                    errors.append("no HTTP operations found under paths")

    for warning in warnings:
        print(f"WARN: {warning}")
    for error in errors:
        print(f"ERROR: {error}")
    print(f"checked {path}: {len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
