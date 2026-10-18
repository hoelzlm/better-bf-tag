#!/usr/bin/env python3
"""ux-10: extract every Key('...')/Semantics label mentioned in docs/design/screens/*.md
and check whether it still appears somewhere under apps/*/lib.

Usage: python3 docs/design/tools/check_keys.py
Prints a found/missing table (markdown) to stdout.
"""
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SCREENS_DIR = REPO_ROOT / "docs" / "design" / "screens"
LIB_DIRS = [REPO_ROOT / "apps" / "web" / "lib", REPO_ROOT / "apps" / "mobile" / "lib"]

# Matches: `key-name`, 'key-name', Key('key-name'), Key("key-name")
KEY_PATTERN = re.compile(r"`([a-zA-Z][a-zA-Z0-9_-]*(?:-\{[a-zA-Z0-9_.]+\})?)`")
EXCLUDE_SUFFIXES = (".dart", ".md", ".html", ".png", ".yaml", ".json")


def extract_candidates(text: str) -> set[str]:
    candidates = set()
    for m in KEY_PATTERN.finditer(text):
        token = m.group(1)
        if any(token.endswith(suf) for suf in EXCLUDE_SUFFIXES):
            continue
        # skip tokens that are clearly not key-like (no hyphen/underscore AND short, generic words)
        if "-" not in token and "_" not in token:
            continue
        candidates.add(token)
    return candidates


def key_base(token: str) -> str:
    """Strip a trailing templated id segment: 'alarm-vehicle-{vehicle.id}' -> 'alarm-vehicle-'"""
    return re.sub(r"\{[a-zA-Z0-9_.]+\}", "", token)


def grep_present(base: str) -> bool:
    # search literal base string (without the braces) across apps/*/lib
    pattern = re.escape(base)
    try:
        result = subprocess.run(
            ["grep", "-rlE", pattern] + [str(d) for d in LIB_DIRS],
            capture_output=True, text=True, timeout=30,
        )
        return bool(result.stdout.strip())
    except Exception:
        return False


def main() -> int:
    rows = []
    all_candidates: dict[str, set[str]] = {}
    for md_file in sorted(SCREENS_DIR.glob("*.md")):
        text = md_file.read_text(encoding="utf-8")
        for token in extract_candidates(text):
            all_candidates.setdefault(token, set()).add(md_file.name)

    missing = 0
    found = 0
    for token in sorted(all_candidates):
        base = key_base(token)
        present = grep_present(base)
        status = "FOUND" if present else "MISSING"
        if present:
            found += 1
        else:
            missing += 1
        sources = ", ".join(sorted(all_candidates[token]))
        rows.append((token, status, sources))

    print("| Key/Label | Status | Mentioned in |")
    print("|---|---|---|")
    for token, status, sources in rows:
        print(f"| `{token}` | {status} | {sources} |")
    print()
    print(f"Summary: {found} found, {missing} missing (out of {len(rows)} candidate tokens).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
