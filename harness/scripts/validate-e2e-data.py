#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

UC_RE = re.compile(r"UC-E2E-\d{3}")
REQ_RE = re.compile(r"R-\d{3}")
ANCHOR_RE = re.compile(r"#fixtures\.([A-Za-z0-9_.-]+)")


def collect_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from collect_strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from collect_strings(item)


def fixture_top_keys(value):
    return {str(key) for key in value} if isinstance(value, dict) else set()


def main():
    parser = argparse.ArgumentParser(description="Validate a harness-e2e/1 dataset.")
    parser.add_argument("yaml_path")
    parser.add_argument("--use-cases-md", default=None)
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    errors = []
    warnings = []
    yaml_ids = set()
    yaml_reqs = set()

    path = Path(args.yaml_path)
    data = None
    if not path.exists():
        errors.append(f"YAML not found: {path}")
    else:
        try:
            data = yaml.safe_load(path.read_text(encoding="utf-8-sig"))
        except Exception as exc:
            errors.append(f"YAML parse error: {exc}")

    if data is not None:
        if not isinstance(data, dict):
            errors.append("top-level YAML must be a mapping")
        else:
            if data.get("schema") != "harness-e2e/1":
                errors.append("schema must be harness-e2e/1")
            use_cases = data.get("use_cases")
            if not isinstance(use_cases, list) or not use_cases:
                errors.append("use_cases must be a non-empty list")
            else:
                for index, use_case in enumerate(use_cases):
                    if not isinstance(use_case, dict):
                        errors.append(f"use_cases[{index}] must be a mapping")
                        continue
                    uid = str(use_case.get("id", ""))
                    if not UC_RE.fullmatch(uid):
                        errors.append(f"use_cases[{index}].id is not UC-E2E-NNN: {uid!r}")
                    if uid in yaml_ids:
                        errors.append(f"duplicate use case id: {uid}")
                    yaml_ids.add(uid)

                    requirements = use_case.get("requirements")
                    if requirements is None:
                        requirements = use_case.get("source_requirements")
                    if not isinstance(requirements, list) or not requirements:
                        warnings.append(f"{uid}: no requirements")
                    else:
                        for requirement in requirements:
                            req = str(requirement)
                            if not REQ_RE.fullmatch(req):
                                errors.append(f"{uid}: invalid requirement id {req!r}")
                            yaml_reqs.add(req)

                    steps = use_case.get("steps")
                    if not isinstance(steps, list) or not steps:
                        errors.append(f"{uid}: steps must be a non-empty list")
                    else:
                        for step_index, step in enumerate(steps):
                            if not isinstance(step, dict):
                                errors.append(f"{uid}: steps[{step_index}] must be a mapping")
                                continue
                            if not step.get("action"):
                                warnings.append(f"{uid}: steps[{step_index}] has no action")
                            if "expected" not in step:
                                warnings.append(f"{uid}: steps[{step_index}] has no expected")

                    if not use_case.get("cleanup"):
                        warnings.append(f"{uid}: cleanup is empty")
                    traceability = use_case.get("traceability")
                    test_ids = traceability.get("test_ids") if isinstance(traceability, dict) else None
                    if not test_ids:
                        warnings.append(f"{uid}: traceability.test_ids is empty")

            fixtures = data.get("fixtures")
            if fixtures is not None and not isinstance(fixtures, dict):
                errors.append("fixtures must be a mapping")
            top_keys = fixture_top_keys(fixtures)
            for text in collect_strings(data):
                for match in ANCHOR_RE.finditer(text):
                    anchor = match.group(1)
                    if anchor.split(".")[0] not in top_keys:
                        errors.append(f"unresolved fixture anchor: #fixtures.{anchor}")

    if args.use_cases_md:
        md_path = Path(args.use_cases_md)
        if not md_path.exists():
            errors.append(f"use-cases Markdown not found: {md_path}")
        else:
            md_text = md_path.read_text(encoding="utf-8-sig")
            md_ids = set(UC_RE.findall(md_text))
            missing_ids = sorted(md_ids - yaml_ids)
            extra_ids = sorted(yaml_ids - md_ids)
            if missing_ids:
                errors.append(f"UC ids in Markdown but not YAML: {', '.join(missing_ids)}")
            if extra_ids:
                errors.append(f"UC ids in YAML but not Markdown: {', '.join(extra_ids)}")
            md_reqs = set(REQ_RE.findall(md_text))
            missing_reqs = sorted(md_reqs - yaml_reqs)
            if missing_reqs:
                target = errors if args.strict else warnings
                target.append(f"requirements in Markdown but not YAML: {', '.join(missing_reqs)}")

    for warning in warnings:
        print(f"WARN: {warning}")
    for error in errors:
        print(f"ERROR: {error}")
    print(
        f"checked {len(yaml_ids)} use case(s), {len(yaml_reqs)} requirement link(s), "
        f"{len(errors)} error(s), {len(warnings)} warning(s)"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
