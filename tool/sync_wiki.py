#!/usr/bin/env python3
"""Mirror reviewed handbook sources into an existing GitHub Wiki checkout.

Usage: python3 tool/sync_wiki.py ../steering-engine.wiki [--check]
Does not clone, commit, push, delete files, or handle credentials.
"""

import argparse
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1] / "doc/wiki"
    target = args.checkout.resolve()
    expected = "github.com/kleberandrade/steering-engine.wiki"
    origin = subprocess.check_output(
        ["git", "-C", str(target), "remote", "get-url", "origin"], text=True
    ).strip().removesuffix(".git").removesuffix("/")
    if not origin.endswith(expected) and not origin.endswith(expected.replace("/", ":", 1)):
        parser.error("Target must be the steering-engine.wiki Git checkout")
    stale = []
    for path in sorted(source.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(source)
        destination = target / relative
        content = path.read_bytes()
        if path.suffix == ".md":
            text = content.decode()
            # Wiki URLs omit .md; repository guides retain ordinary file links.
            text = re.sub(r"\]\(([A-Za-z0-9_-]+)\.md(#[^)]*)?\)",
                          lambda m: "](" + m[1] + (m[2] or "") + ")", text)
            text = re.sub(r"\]\((\.\./[^)]+)\)",
                          lambda m: "](https://github.com/kleberandrade/steering-engine/blob/main/doc/"
                          + m[1][3:] + ")", text)
            # Absolute raw image URLs work independently of the current wiki page.
            text = text.replace(
                "](images/", "](https://raw.githubusercontent.com/wiki/kleberandrade/steering-engine/images/"
            )
            content = text.encode()
        if not destination.exists() or destination.read_bytes() != content:
            stale.append(str(relative))
            if not args.check:
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(content)
    print(("Out of date: " if args.check else "Updated: ") + str(len(stale)))
    for name in stale:
        print(name)
    if args.check and stale:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
