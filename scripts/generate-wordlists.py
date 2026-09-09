#!/usr/bin/env python3
"""
Generate LangSwitcher/Sources/Services/WordlistData.swift.

Builds per-language frequency wordlists used by LanguageWordlists to
confirm/veto wrong-layout conversion decisions:

  Sources:
  - Frequency ranking: hermitdave/FrequencyWords (OpenSubtitles 2016/2018
    top-50k lists, https://github.com/hermitdave/FrequencyWords)
  - Validation: LibreOffice hunspell dictionaries
    (https://github.com/LibreOffice/dictionaries/tree/master/<lang>)

  Pipeline per language:
  1. Take the frequency list, keep words matching the language alphabet,
     lowercase, deduplicate (preserving frequency order).
  2. Keep only words present in the hunspell dictionary — this drops
     code-switched foreign words (e.g. Russian "привет" leaking into the
     Ukrainian subtitle corpus), misspellings, and transliterations.
  3. Emit as Swift raw-string blocks inside `enum WordlistData`.

  Encodings: pl_PL is ISO-8859-2; all others UTF-8.

Usage:
  python3 scripts/generate-wordlists.py
"""
import re
import urllib.request
import pathlib
import sys

FREQ_URL = "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content"
DIC_URL = "https://raw.githubusercontent.com/LibreOffice/dictionaries/master"

LANGS = {
    "polish": {
        "freq": f"{FREQ_URL}/2016/pl/pl_50k.txt",
        "dic": f"{DIC_URL}/pl_PL/pl_PL.dic",
        "dic_enc": "iso-8859-2",
        "alphabet": r"[a-ząćęłńóśźż]+",
    },
    "ukrainian": {
        "freq": f"{FREQ_URL}/2018/uk/uk_50k.txt",
        "dic": f"{DIC_URL}/uk_UA/uk_UA.dic",
        "dic_enc": "utf-8",
        "alphabet": r"[а-яїієґ']+",
    },
    "english": {
        "freq": f"{FREQ_URL}/2016/en/en_50k.txt",
        "dic": f"{DIC_URL}/en/en_US.dic",
        "dic_enc": "utf-8",
        "alphabet": r"[a-z]+",
    },
    "russian": {
        "freq": f"{FREQ_URL}/2018/ru/ru_50k.txt",
        "dic": f"{DIC_URL}/ru_RU/ru_RU.dic",
        "dic_enc": "utf-8",
        "alphabet": r"[а-яё]+",
    },
}

HEADER = '''import Foundation

// MARK: - Embedded Wordlists
//
// GENERATED FILE — do not edit by hand. Regenerate with:
//   python3 scripts/generate-wordlists.py
//
// Most frequent Polish, Ukrainian, English and Russian dictionary words
// (top of the OpenSubtitles 2016/2018 frequency lists,
// hermitdave/FrequencyWords), filtered against the LibreOffice hunspell
// dictionaries so only real dictionary words remain: code-switched
// loanwords like "привет" in the Ukrainian corpus, misspellings and
// transliterations are dropped. One word per line, frequency-ordered,
// deduplicated. Used by LanguageWordlists to confirm/veto wrong-layout
// conversion decisions (see LanguageWordlists.swift).

enum WordlistData {
'''


def fetch(url: str, dest: pathlib.Path) -> None:
    if dest.exists() and dest.stat().st_size > 0:
        return  # cached
    print(f"fetching {url}")
    urllib.request.urlretrieve(url, dest)


def load_dic(path: pathlib.Path, enc: str) -> set:
    words = set()
    with open(path, encoding=enc, errors="replace") as f:
        next(f)  # first line = entry count
        for line in f:
            w = line.split("/")[0].strip().lower()
            if w:
                words.add(w)
    return words


def load_freq(path: pathlib.Path, alphabet: str) -> list:
    out, seen = [], set()
    for line in open(path, encoding="utf-8"):
        w = line.split()[0].strip().lower()
        if re.fullmatch(alphabet, w) and w not in seen:
            out.append(w)
            seen.add(w)
    return out


def main() -> int:
    cache = pathlib.Path("/tmp/langswitcher_wordlists")
    cache.mkdir(exist_ok=True)

    blocks = []
    for name, cfg in LANGS.items():
        freq_path = cache / f"{name}_freq.txt"
        dic_path = cache / f"{name}_dic.dic"
        fetch(cfg["freq"], freq_path)
        fetch(cfg["dic"], dic_path)

        dic = load_dic(dic_path, cfg["dic_enc"])
        freq = load_freq(freq_path, cfg["alphabet"])
        filtered = [w for w in freq if w in dic]
        print(f"{name}: freq={len(freq)} dic={len(dic)} filtered={len(filtered)}")
        if not filtered:
            print(f"ERROR: empty list for {name}", file=sys.stderr)
            return 1
        blocks.append((name, filtered))

    out = [HEADER]
    for name, words in blocks:
        out.append(f'    /// {name.capitalize()} words filtered against the {name} hunspell dictionary\n')
        out.append(f'    static let {name} = #"""\n')
        out.append("\n".join(words))
        out.append('\n"""#\n\n')
    out.append("}\n")

    dest = pathlib.Path(__file__).resolve().parent.parent / \
        "LangSwitcher/Sources/Services/WordlistData.swift"
    dest.write_text("".join(out), encoding="utf-8")
    print(f"wrote {dest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
