#!/usr/bin/env python3
"""Export a REAL harvested error set from the LangSwitcher conversion log.

Reads the app's SQLite conversion log (defaults to the standard Application
Support location) and emits the pairs.json envelope understood by
tools/real_eval/main.swift:

    {
      "layoutIDs": [...],          # EN + any two Cyrillic-capable layouts
      "learnedWords": [...],       # words taught by reverts (UserDefaults)
      "pairs": [ {"input": ..., "expected": ..., "revert": bool}, ... ]
    }

Labels (no manual annotation needed):
  - mode = "recover":  input_text is the wrong-layout line, output_text is
    what the app pasted — i.e. the DECODER'S OWN ANSWER, not ground truth.
    Metrics against it measure self-consistency, not correctness.
  - is_correct = 0 on a recover row: the user reverted, so `input` is the
    correct text and must not be rewritten again (revert flag).
  - mode != "recover": the pre-recovery line was wrong-layout and the old
    single-word converter fixed it — usable as a weak ground-truth pair.

Anonymization: nothing is printed here. The exporter writes pairs.json only;
inspect it locally, never paste raw text into reports.

Usage:
    python3 tools/real_eval/export_pairs.py [path-to-sqlite] > pairs.json
"""

import json
import os
import sqlite3
import subprocess
import sys

DEFAULT_DB = os.path.expanduser(
    "~/Library/Application Support/LangSwitcher/conversion_log.sqlite"
)


def learned_words() -> list:
    """Words taught by reverts (UserDictionary stores them in UserDefaults)."""
    try:
        raw = subprocess.run(
            ["defaults", "export", "com.langswitcher.app", "-"],
            capture_output=True,
            timeout=10,
            check=False,
        ).stdout
        # Apple's binary plist; parse the one key we need without extra deps.
        import plistlib

        data = plistlib.loads(raw)
    except Exception:
        data = {}
    words = data.get("userDictionaryWords") or []
    return [w for w in words if isinstance(w, str)]


def layout_ids(rows) -> list:
    seen = []
    for r in rows:
        for key in ("source_layout", "target_layout"):
            v = r[key]
            if v and v not in seen:
                seen.append(v)
    if not seen:
        # Same defaults the decoder harness uses.
        return ["com.apple.keylayout.US", "com.apple.keylayout.Ukrainian-PC"]
    return seen


def main() -> int:
    db_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DB
    if not os.path.exists(db_path):
        print(f"error: log db not found: {db_path}", file=sys.stderr)
        return 2

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    rows = [
        dict(r)
        for r in conn.execute(
            "SELECT input_text, output_text, source_layout, target_layout, "
            "conversion_mode, is_correct FROM conversion_log ORDER BY id"
        )
    ]
    conn.close()

    pairs = []
    for r in rows:
        inp = (r["input_text"] or "").strip()
        out = (r["output_text"] or "").strip()
        if not inp:
            continue
        reverted = r["conversion_mode"] == "recover" and r["is_correct"] == 0
        if reverted:
            # input is what the user restored — it must never change.
            pairs.append({"input": inp, "expected": inp, "revert": True})
        else:
            pairs.append({"input": inp, "expected": out or inp, "revert": False})

    envelope = {
        "layoutIDs": layout_ids(rows),
        "learnedWords": learned_words(),
        "pairs": pairs,
    }
    json.dump(envelope, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
