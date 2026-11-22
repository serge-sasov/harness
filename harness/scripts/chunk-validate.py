#!/usr/bin/env python3
"""Validate a harness chunk ledger (docs/chunks/T-XXX.json).

Deterministic checks: schema, unique ids, parent links and depth, states,
exclusive ownership, produced files inside the owned set, sha256 of produced
files, coverage of the task card artifacts, and role write areas.

Exit codes: 0 = valid, 1 = invalid, 2 = usage or IO error.

Examples:
    python chunk-validate.py docs/chunks/T-008.json
    python chunk-validate.py docs/chunks/T-008.json --json
    python chunk-validate.py --self-test
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile

STATES = {"pending", "in_progress", "done", "failed", "blocked"}
STATES_WITH_ISSUE = {"blocked"}
DEFAULT_BUDGET = {
    "max_write_kb": 16,
    "max_session_kb": 48,
    "context_stop_pct": 65,
    "max_turns": 40,
    "max_input_tokens": 76000,
    "max_wall_min": 60,
}
REQUIRED_CHUNK = [
    "id", "parent", "stage", "role", "depth", "title", "state", "owns",
    "inputs", "brief", "acceptance", "produced", "base_commit", "attempts",
    "usage", "issues",
]
ROLE_AREAS = {
    "orchestrator": [
        "docs/plan.md", "docs/tasks/**", "docs/checkpoints/**", "docs/bugs/**",
        "docs/activity.puml", "docs/activity.svg", "README.md", ".gitignore",
    ],
    "analyst": ["docs/analysis/**"],
    "ux-designer": ["docs/ux/**"],
    "architect": ["docs/architecture/**"],
    "coder": [
        "src/**", "backend/**", "frontend/**", "tests/**", "scripts/**",
        "Dockerfile", "docker-compose*.yml", "Makefile", ".gitignore",
        "requirements.txt", "pyproject.toml", ".env.example", "alembic.ini",
        "sources.yaml", "docs/ux/prototype/**",
    ],
    "qa": ["docs/qa/**"],
    "qa-vision": ["docs/qa/**"],
    "doc-writer": ["docs/guides/**", "README.md", "docs/architecture/adr-*.md"],
    "harness": [],
}
COMMON_AREAS = ["docs/chunks/**", "docs/issues/**"]
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def fwd(path: str) -> str:
    return path.replace("\\", "/")


def glob_to_regex(glob: str) -> re.Pattern:
    g = fwd(glob)
    out = ["^"]
    i = 0
    while i < len(g):
        ch = g[i]
        if ch == "*":
            if i + 1 < len(g) and g[i + 1] == "*":
                out.append(".*")
                i += 1
            else:
                out.append("[^/]*")
        elif ch == "?":
            out.append("[^/]")
        else:
            out.append(re.escape(ch))
        i += 1
    out.append("$")
    return re.compile("".join(out))


def witness(glob: str) -> str:
    """A concrete path that the glob should match, used for overlap tests."""
    g = fwd(glob)
    return g.replace("**", "_w_").replace("*", "_w").replace("?", "w")


def path_matches(path: str, pattern: str) -> bool:
    return bool(glob_to_regex(pattern).match(fwd(path).lstrip("./")))


def globs_overlap(a: str, b: str) -> bool:
    if fwd(a) == fwd(b):
        return True
    if glob_to_regex(a).match(witness(b)):
        return True
    if glob_to_regex(b).match(witness(a)):
        return True
    return False


def covers(owner: str, target: str) -> bool:
    """True when every path matching target also matches owner."""
    if fwd(owner) == fwd(target):
        return True
    return bool(glob_to_regex(owner).match(witness(target)))


def list_files(root: str) -> list[str]:
    skip = {".git", "node_modules", "bin", "obj", "__pycache__", "target", "dist", ".venv", ".idea"}
    found: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skip and not d.startswith(".harness-backup")]
        for name in filenames:
            found.append(fwd(os.path.relpath(os.path.join(dirpath, name), root)))
    return found


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for block in iter(lambda: fh.read(65536), b""):
            h.update(block)
    return h.hexdigest()


def read_card_artifacts(root: str, task: str) -> list[str] | None:
    tasks_dir = os.path.join(root, "docs", "tasks")
    if not os.path.isdir(tasks_dir):
        return None
    candidates = sorted(
        n for n in os.listdir(tasks_dir)
        if n.startswith(task) and n.endswith(".md") and n.lower() != "readme.md"
    )
    if not candidates:
        return None
    card = os.path.join(tasks_dir, candidates[0])
    with open(card, encoding="utf-8-sig") as fh:
        for line in fh:
            m = re.match(r"^\|\s*artifacts\s*\|\s*(.*?)\s*\|\s*$", line, re.I)
            if not m:
                continue
            value = m.group(1).replace("`", "")
            items: list[str] = []
            for piece in value.split(","):
                item = piece.strip()
                if not item or item == "-":
                    continue
                if ".." in item:
                    items.extend(expand_range(item))
                else:
                    items.append(fwd(item))
            return items
    return []


def expand_range(item: str) -> list[str]:
    left, _, right = item.partition("..")
    lm = re.match(r"^(?P<dir>.*/)?(?P<pre>[^/]*?)(?P<num>\d+)(?P<ext>\.[A-Za-z0-9]+)$", left)
    rm = re.match(r"^(?P<pre>[^/]*?)(?P<num>\d+)(?P<ext>\.[A-Za-z0-9]+)$", right)
    if not lm or not rm:
        return [fwd(item)]
    directory = lm.group("dir") or ""
    pre = rm.group("pre") or lm.group("pre")
    ext = rm.group("ext")
    width = len(lm.group("num"))
    low, high = int(lm.group("num")), int(rm.group("num"))
    return ["%s%s%0*d%s" % (directory, pre, width, n, ext) for n in range(low, high + 1)]


def norm_rel(root: str, path: str) -> str:
    return fwd(os.path.relpath(path, root))


def validate(ledger_path: str, root: str | None, check_hash: bool = True) -> dict:
    errors: list[dict] = []
    warnings: list[dict] = []

    def err(code: str, message: str, chunk: str | None = None) -> None:
        item = {"code": code, "message": message}
        if chunk:
            item["chunk"] = chunk
        errors.append(item)

    def warn(code: str, message: str, chunk: str | None = None) -> None:
        item = {"code": code, "message": message}
        if chunk:
            item["chunk"] = chunk
        warnings.append(item)

    ledger_path = os.path.abspath(ledger_path)
    if not root:
        root = os.path.dirname(os.path.dirname(os.path.dirname(ledger_path)))
    root = os.path.abspath(root)

    try:
        with open(ledger_path, encoding="utf-8-sig") as fh:
            data = json.load(fh)
    except FileNotFoundError:
        err("E_JSON", "ledger not found: %s" % ledger_path)
        return {"valid": False, "errors": errors, "warnings": warnings}
    except json.JSONDecodeError as exc:
        err("E_JSON", "invalid JSON: %s" % exc)
        return {"valid": False, "errors": errors, "warnings": warnings}

    if not isinstance(data, dict):
        err("E_SCHEMA", "top level must be an object")
        return {"valid": False, "errors": errors, "warnings": warnings}

    task = str(data.get("task", "")).strip()
    if not re.match(r"^T-\d{3,}$", task):
        err("E_TASK_ID", "task must look like T-XXX, got %r" % task)
    else:
        if os.path.basename(ledger_path) != task + ".json":
            err("E_TASK_ID", "file name must be %s.json" % task)

    budget = data.get("budget")
    if not isinstance(budget, dict):
        err("E_SCHEMA", "budget object is required")
        budget = dict(DEFAULT_BUDGET)
    else:
        for key, default in DEFAULT_BUDGET.items():
            value = budget.get(key, default)
            if not isinstance(value, (int, float)) or value <= 0:
                err("E_BUDGET", "budget.%s must be a positive number" % key)

    chunks = data.get("chunks")
    if not isinstance(chunks, list) or not chunks:
        err("E_SCHEMA", "chunks must be a non-empty list")
        return {"valid": False, "task": task, "errors": errors, "warnings": warnings}

    baseline = data.get("baseline", [])
    if baseline is None:
        baseline = []
    if not isinstance(baseline, list) or any(not isinstance(x, str) for x in baseline):
        err("E_SCHEMA", "baseline must be a list of path strings")
        baseline = []

    index: dict[str, dict] = {}
    for position, chunk in enumerate(chunks):
        label = "#%d" % position
        if not isinstance(chunk, dict):
            err("E_SCHEMA", "chunk %s must be an object" % label)
            continue
        missing = [key for key in REQUIRED_CHUNK if key not in chunk]
        if missing:
            err("E_SCHEMA", "chunk %s missing fields: %s" % (label, ", ".join(missing)),
                str(chunk.get("id") or label))
            continue
        cid = str(chunk["id"])
        if not ID_RE.match(cid):
            err("E_SCHEMA", "invalid chunk id %r" % cid, cid)
            continue
        if cid in index:
            err("E_DUP_ID", "duplicate chunk id %r" % cid, cid)
            continue
        index[cid] = chunk

        if chunk["state"] not in STATES:
            err("E_STATE", "state must be one of %s" % sorted(STATES), cid)
        depth = chunk["depth"]
        if not isinstance(depth, int) or not 1 <= depth <= 3:
            err("E_DEPTH", "depth must be an integer 1..3, got %r" % depth, cid)
        if not isinstance(chunk["owns"], list):
            err("E_SCHEMA", "owns must be a list", cid)
        if not isinstance(chunk["produced"], list):
            err("E_SCHEMA", "produced must be a list", cid)
        if not isinstance(chunk["inputs"], list):
            err("E_SCHEMA", "inputs must be a list", cid)
        if not isinstance(chunk["acceptance"], list):
            err("E_SCHEMA", "acceptance must be a list", cid)
        if not isinstance(chunk["usage"], dict):
            err("E_SCHEMA", "usage must be an object", cid)
        for key in ("in", "out", "cr"):
            if key not in chunk["usage"]:
                err("E_SCHEMA", "usage.%s is required" % key, cid)
        if chunk["state"] == "done" and not chunk["produced"] and (chunk["owns"] or []):
            err("E_STATE", "a done chunk with an owned set must list produced files", cid)
        if chunk["state"] in STATES_WITH_ISSUE and not chunk["issues"]:
            err("E_STATE", "a blocked chunk must reference an issue", cid)

    for cid, chunk in index.items():
        parent = chunk["parent"]
        if parent is None:
            if chunk["depth"] != 1:
                err("E_DEPTH", "a top-level chunk must have depth 1, got %r" % chunk["depth"], cid)
            continue
        if parent not in index:
            err("E_PARENT", "parent %r does not exist" % parent, cid)
            continue
        if parent == cid:
            err("E_PARENT", "chunk cannot be its own parent", cid)
            continue
        parent_chunk = index[parent]
        if chunk["depth"] != parent_chunk["depth"] + 1:
            err("E_DEPTH", "depth must be parent depth + 1 (%d), got %r"
                % (parent_chunk["depth"] + 1, chunk["depth"]), cid)
        for key in ("role", "stage"):
            if chunk[key] != parent_chunk[key]:
                err("E_PARENT_INHERIT",
                    "%s must equal the parent's %s (%r)" % (key, key, parent_chunk[key]), cid)

    for cid in index:
        seen = {cid}
        node = index[cid]
        while node["parent"]:
            nxt = node["parent"]
            if nxt in seen:
                err("E_CYCLE", "parent chain forms a cycle", cid)
                break
            seen.add(nxt)
            node = index.get(nxt)
            if node is None:
                break

    def ancestors(cid: str) -> set[str]:
        chain: set[str] = set()
        node = index.get(cid)
        while node and node["parent"]:
            chain.add(node["parent"])
            node = index.get(node["parent"])
        return chain

    ids = sorted(index)
    chains = {cid: ancestors(cid) for cid in ids}
    for i, left_id in enumerate(ids):
        for right_id in ids[i + 1:]:
            if left_id in chains[right_id] or right_id in chains[left_id]:
                continue
            left, right = index[left_id], index[right_id]
            for a in left["owns"] or []:
                for b in right["owns"] or []:
                    if globs_overlap(str(a), str(b)):
                        err("E_OWN_OVERLAP", "owns overlap: %r vs %r" % (a, b),
                            "%s/%s" % (left_id, right_id))

    for cid, chunk in index.items():
        owns = [str(x) for x in chunk["owns"] or []]
        area = ROLE_AREAS.get(str(chunk["role"]).strip())
        if area is None:
            err("E_STAGE_ROLE", "unknown role %r" % chunk["role"], cid)
            area = []
        allowed = area + COMMON_AREAS
        for pattern in owns:
            if not any(covers(ok, pattern) for ok in allowed):
                err("E_ROLE_AREA", "owns %r is outside the role write area (%s)"
                    % (pattern, ", ".join(allowed)), cid)
        if not owns and chunk["depth"] > 1:
            warn("W_NO_OWNS", "a child chunk has no owns set", cid)
        for item in chunk["produced"] or []:
            if not isinstance(item, dict) or "path" not in item:
                err("E_SCHEMA", "produced entries need path and sha256", cid)
                continue
            path = fwd(str(item["path"]))
            if owns and not any(path_matches(path, pattern) for pattern in owns):
                err("E_PRODUCED_OUTSIDE", "produced %r is outside owns" % path, cid)
            absolute = os.path.join(root, path.replace("/", os.sep))
            if check_hash:
                if not os.path.isfile(absolute):
                    err("E_PRODUCED_MISSING", "produced file does not exist: %s" % path, cid)
                else:
                    expected = str(item.get("sha256", "")).lower()
                    actual = sha256_file(absolute)
                    if expected != actual:
                        err("E_HASH_MISMATCH", "sha256 mismatch for %s (ledger %s, file %s)"
                            % (path, expected[:12] or "-", actual[:12]), cid)
        limit = float(budget.get("max_write_kb", DEFAULT_BUDGET["max_write_kb"]))
        for item in chunk["produced"] or []:
            if not isinstance(item, dict) or "path" not in item:
                continue
            absolute = os.path.join(root, fwd(str(item["path"])).replace("/", os.sep))
            if os.path.isfile(absolute):
                size_kb = os.path.getsize(absolute) / 1024.0
                if size_kb > limit:
                    warn("W_BUDGET_WRITE", "%s is %.1f KB, above max_write_kb %.1f"
                         % (item["path"], size_kb, limit), cid)

    artifacts = read_card_artifacts(root, task) if task else None
    if artifacts is None:
        warn("W_NO_CARD", "task card not found; coverage not checked")
    elif artifacts:
        top = [c for c in index.values() if c["parent"] is None]
        owns_all = [str(x) for c in top for x in c["owns"] or []]
        existing = list_files(root)
        for pattern in artifacts:
            if any(ch in pattern for ch in "*?["):
                matched = [f for f in existing if path_matches(f, pattern)]
                for found in matched:
                    if any(path_matches(found, b) for b in baseline):
                        continue
                    if not any(path_matches(found, own) for own in owns_all):
                        err("E_COVERAGE",
                            "%r matches card artifact %r but no top-level chunk owns it"
                            % (found, pattern))
            elif not any(covers(own, pattern) for own in owns_all):
                err("E_COVERAGE",
                    "card artifact %r is not covered by any top-level owns" % pattern)
        for own in owns_all:
            if not any(covers(pattern, own) for pattern in artifacts):
                err("E_OWN_OUTSIDE_CARD",
                    "owns %r is outside the card artifacts" % own)

    return {
        "valid": not errors,
        "task": task,
        "chunks": len(index),
        "errors": errors,
        "warnings": warnings,
    }


def print_human(result: dict) -> None:
    status = "VALID" if result.get("valid") else "INVALID"
    print("%s %s (%d chunks)" % (status, result.get("task", "?"), result.get("chunks", 0)))
    for item in result.get("errors", []):
        where = " [%s]" % item["chunk"] if item.get("chunk") else ""
        print("  FAIL %s%s: %s" % (item["code"], where, item["message"]))
    for item in result.get("warnings", []):
        where = " [%s]" % item["chunk"] if item.get("chunk") else ""
        print("  warn %s%s: %s" % (item["code"], where, item["message"]))


def self_test() -> int:
    failures = 0
    tmp = tempfile.mkdtemp(prefix="chunk-validate-")
    try:
        docs = os.path.join(tmp, "docs")
        os.makedirs(os.path.join(docs, "tasks"))
        os.makedirs(os.path.join(docs, "chunks"))
        os.makedirs(os.path.join(tmp, "backend", "src"))
        with open(os.path.join(docs, "tasks", "T-900-test.md"), "w", encoding="utf-8") as fh:
            fh.write("# T-900\n\n| Field | Value |\n|---|---|\n"
                     "| title | test |\n| artifacts | `backend/**` |\n")
        produced = os.path.join(tmp, "backend", "src", "a.py")
        with open(produced, "w", encoding="utf-8") as fh:
            fh.write("print(1)\n")
        digest = sha256_file(produced)

        def base(owns=None, produced_list=None, state="done"):
            return {
                "task": "T-900",
                "version": 1,
                "budget": dict(DEFAULT_BUDGET),
                "chunks": [{
                    "id": "C1", "parent": None, "stage": "I-01", "role": "coder",
                    "depth": 1, "title": "core", "state": state,
                    "owns": owns if owns is not None else ["backend/**"],
                    "inputs": ["docs/tasks/T-900-test.md"],
                    "brief": "docs/chunks/T-900/C1.brief.md",
                    "acceptance": ["works"],
                    "produced": produced_list if produced_list is not None else [
                        {"path": "backend/src/a.py", "sha256": digest}],
                    "base_commit": "abc1234", "attempts": 1,
                    "usage": {"in": 1, "out": 1, "cr": 0, "min": 1},
                    "issues": [], "started": None, "finished": None,
                }],
            }

        cases = [
            ("valid", base(), True),
            ("owns overlap", base() | {"chunks": [base()["chunks"][0], dict(
                base()["chunks"][0], id="C2", owns=["backend/src/**"],
                produced=[], state="pending")]}, False),
            ("produced outside owns", base(
                produced_list=[{"path": "backend/src/a.py", "sha256": digest}],
                owns=["scripts/**"]), False),
            ("hash mismatch", base(
                produced_list=[{"path": "backend/src/a.py", "sha256": "0" * 64}]), False),
            ("coverage gap", base(owns=["scripts/**"]) | {"chunks": [dict(
                base()["chunks"][0], owns=["scripts/**"], produced=[],
                state="pending")]}, False),
            ("bad state", base(state="finished"), False),
            ("bad depth", base() | {"chunks": [dict(base()["chunks"][0], depth=4)]}, False),
            ("role area", base() | {"chunks": [dict(
                base()["chunks"][0], role="architect", produced=[],
                state="pending")]}, False),
            ("parent inherit", base() | {"chunks": [base()["chunks"][0], dict(
                base()["chunks"][0], id="C1a", parent="C1", depth=2,
                role="architect", owns=["backend/src/**"], produced=[],
                state="pending")]}, False),
            ("blocked without issue", base(state="blocked"), False),
            ("deep child ok", base() | {"chunks": [base()["chunks"][0], dict(
                base()["chunks"][0], id="C1a", parent="C1", depth=2,
                owns=["backend/src/**"], produced=[], state="pending")]}, True),
            ("baseline exempts legacy files", base() | {
                "baseline": ["backend/src/a.py"],
                "chunks": [dict(base()["chunks"][0], owns=["backend/other/**"],
                                produced=[], state="pending")]}, True),
        ]
        for name, payload, expected in cases:
            path = os.path.join(docs, "chunks", "T-900.json")
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(payload, fh)
            result = validate(path, tmp, check_hash=True)
            ok = bool(result["valid"]) == expected
            print("%s %s" % ("PASS" if ok else "FAIL", name))
            if not ok:
                failures += 1
                print_human(result)

        with open(os.path.join(docs, "chunks", "T-901.json"), "w", encoding="utf-8") as fh:
            fh.write("{ not json")
        result = validate(os.path.join(docs, "chunks", "T-901.json"), tmp)
        ok = not result["valid"] and result["errors"][0]["code"] == "E_JSON"
        print("%s invalid json" % ("PASS" if ok else "FAIL"))
        failures += 0 if ok else 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print("self-test: %d failure(s)" % failures)
    return 0 if failures == 0 else 1


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Validate a harness chunk ledger.")
    parser.add_argument("ledger", nargs="?", help="path to docs/chunks/T-XXX.json")
    parser.add_argument("--root", default=None, help="repository root (default: inferred)")
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    parser.add_argument("--no-hash", action="store_true",
                        help="skip sha256 verification of produced files")
    parser.add_argument("--self-test", action="store_true", help="run built-in cases")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()
    if not args.ledger:
        parser.print_usage(sys.stderr)
        return 2

    result = validate(args.ledger, args.root, check_hash=not args.no_hash)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print_human(result)
    return 0 if result["valid"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
