#!/usr/bin/env python3
"""Checks a design studio page: every drawn part names a component.

  tools/studio_check.py <studio.html> [--fix]

The page's data (`<script id="data">`) lists components (`groups[].items[]`)
and screens (`screens[].items[]`), each with an `html` fragment. In a screen,
every child of the phone (`.ph`) and every child of `.main` inside it carries
`data-c` with the names of the components it draws, separated by spaces;
`Text` and `Layout` stand for plain text and wrappers. A component's own drawing may tag the components it is built from.

Fails on an untagged part or a tag naming a component the page does not list
(an app's page also knows the Forge components of its `forgeIndex`). `uses`
(what a screen or component draws) and `usedIn` (the screens a component is
drawn on) are built from the tags: a difference fails, and `--fix` writes
them. `usedBy` is kept by hand.
"""

import json
import re
import sys
from html.parser import HTMLParser

PLAIN = {"Text", "Layout"}
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}
SKIP = {"style", "script"}


class Parts(HTMLParser):
    """Collects the tags of a fragment and its untagged parts."""

    def __init__(self, screen):
        super().__init__()
        self.screen, self.stack, self.tags, self.untagged = screen, [], [], []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        classes = (attrs.get("class") or "").split()
        if "data-c" in attrs:
            self.tags.extend(attrs["data-c"].split() or [""])
        elif self.screen and tag not in SKIP and self.stack:
            parent = self.stack[-1]
            if "main" not in classes and ("ph" in parent[1] or "main" in parent[1]):
                self.untagged.append(f"<{tag} class=\"{' '.join(classes)}\">")
        if tag not in VOID:
            self.stack.append((tag, classes))

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i][0] == tag:
                del self.stack[i:]
                break


def main():
    args = [a for a in sys.argv[1:] if a != "--fix"]
    fix = "--fix" in sys.argv[1:]
    if len(args) != 1:
        sys.exit(__doc__)
    page = open(args[0], encoding="utf-8").read()
    found = re.search(r'(<script[^>]*id="data"[^>]*>)(.*?)(</script>)', page, re.S)
    if not found:
        sys.exit(f"{args[0]}: no <script id=\"data\">")
    data = json.loads(found.group(2))
    components = [item for group in data.get("groups", []) for item in group["items"]]
    screens = [item for group in data.get("screens", []) for item in group["items"]]
    own = {c["name"] for c in components}
    forge = data.get("forgeIndex", {}).get("items", [])
    known = own | PLAIN | {i["name"] for i in forge}
    problems, used_in = [], {name: [] for name in known}

    def check(item, screen):
        parts = Parts(screen)
        parts.feed(item.get("html", ""))
        label = item.get("name") or item.get("title") or "?"
        for part in parts.untagged:
            problems.append(f"{label}: untagged part {part}")
        for name in sorted(set(parts.tags) - known):
            problems.append(f"{label}: tag names no component: {name!r}")
        uses = sorted(set(parts.tags) & known - PLAIN - {label})
        if screen:
            for name in uses:
                used_in[name].append(item.get("title") or label)
        return ", ".join(uses)

    wanted = [(item, "uses", check(item, False)) for item in components]
    wanted += [(item, "uses", check(item, True)) for item in screens]
    wanted += [(item, "usedIn", sorted(set(used_in[item["name"]]))) for item in components + forge]
    stale = 0
    for item, key, value in wanted:
        if (item.get(key) or type(value)()) != value:
            stale += 1
            if fix:
                item[key] = value
            else:
                problems.append(f"{item.get('name') or item.get('title')}: `{key}` does not match the tags (run with --fix)")
    if fix and stale:
        text = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
        open(args[0], "w", encoding="utf-8").write(page[: found.start(2)] + text + page[found.end(2) :])
    for line in problems:
        print(line)
    print(f"{args[0]}: {len(components)} components, {len(screens)} screens, {len(problems)} problems" + (f", {stale} lists rewritten" if fix and stale else ""))
    sys.exit(1 if problems else 0)


main()
