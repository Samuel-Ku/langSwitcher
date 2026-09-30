#!/usr/bin/env python3
"""Verify that project.pbxproj group entries point at files that exist.

Xcode trusts the project file, so a file referenced from the wrong group
(e.g. a Views/ file filed under the Services group) is a CI build failure
that glob-based command-line builds never catch. This checks the inverse:
every PBXFileReference that belongs to a source group must exist at the
path that group implies, and every Swift file on disk must be referenced.

Usage: python3 scripts/verify-pbxproj.py   (exit 1 on any mismatch)
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBX = os.path.join(ROOT, "LangSwitcher.xcodeproj", "project.pbxproj")

# Group path -> directory on disk. Product groups have no directory.
GROUP_DIRS = {
    "App": "LangSwitcher/Sources/App",
    "Views": "LangSwitcher/Sources/Views",
    "Services": "LangSwitcher/Sources/Services",
    "Models": "LangSwitcher/Sources/Models",
    "Localization": "LangSwitcher/Sources/Localization",
    # Assets.xcassets lives outside Sources/; the pbxproj resolves it via the
    # parent LangSwitcher group (which is why CI has always built it fine).
    "Resources": "LangSwitcher/Resources",
    "LangSwitcherTests": "LangSwitcherTests",
}

filerefs = {}
for ref, name in re.findall(
    r"([A-F0-9]{24}) /\* (.+?) \*/ = \{isa = PBXFileReference;", open(PBX).read()
):
    filerefs[ref] = name

errors = []
referenced = set()

for match in re.finditer(
    r"([A-F0-9]{24}) /\* (\w+) \*/ = \{\s*isa = PBXGroup;\s*children = \((.*?)\);\s*(?:path = ([\w.]+);)?",
    open(PBX).read(),
    re.S,
):
    _, group_name, children, group_path = match.groups()
    directory = GROUP_DIRS.get(group_path)
    if directory is None:
        continue
    for ref in re.findall(r"([A-F0-9]{24}) /\* (.+?) \*/", children):
        name = filerefs.get(ref, ref[1])
        if not name.endswith((".swift", ".xcassets")):
            continue
        referenced.add(name)
        full = os.path.join(ROOT, directory, name)
        if not os.path.exists(full):
            errors.append(f"missing: {group_path}/{name}  (referenced {ref})")

on_disk = set()
for base, dirs, files in os.walk(os.path.join(ROOT, "LangSwitcher", "Sources")):
    on_disk.update(f for f in files if f.endswith(".swift"))
on_disk.update(
    f
    for f in os.listdir(os.path.join(ROOT, "LangSwitcherTests"))
    if f.endswith(".swift")
)

orphans = sorted(on_disk - referenced)
for orphan in orphans:
    errors.append(f"on disk but not in project: {orphan}")

for error in errors:
    print(error)
print(f"{len(referenced)} referenced, {len(on_disk)} on disk, {len(errors)} problems")
sys.exit(1 if errors else 0)
