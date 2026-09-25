// real_eval — score ThoughtRecovery against a REAL harvested error set.
//
// Usage:
//   real_eval <pairs.json> [--raw]
//
// pairs.json format:
//   {
//     "layoutIDs": ["com.apple.keylayout.US", "com.apple.keylayout.Ukrainian-PC"],
//     "learnedWords": ["word1", "word2"],   // optional — words taught by reverts
//     "pairs": [
//       {"input": "ghbdtn", "expected": "привет"},                    // recovery case
//       {"input": "привет", "expected": "привет"},                    // must-not-change case
//       {"input": "ghbdtn", "expected": "привіт", "revert": true}     // reverted recovery
//     ]
//   }
//
// A pair with input == expected contributes only to falseReplacementRate.
// A pair with "revert": true was undone by the user: the printed check marks
// it as KEPT when the decoder leaves it unchanged, and as MISSED when the
// decoder would rewrite it again (exact match against `expected` still counts
// toward the ordinary recovery metrics).
//
// Default output is ANONYMIZED: it shows per-pair verdicts with a stable id,
// shape (lengths, script, digits-kept) and the diff of what would change —
// never the raw text. Pass --raw to print input/output/expected verbatim
// (for your own eyes only; raw user text must not go into reports).
//
// Build (from the repo root):
//   SR=LangSwitcher/Sources
//   swiftc -swift-version 5 -O \
//     -target arm64-apple-macosx13.0 -sdk "$(xcrun --show-sdk-path)" \
//     -o /tmp/tr/real_eval \
//     $SR/Services/{LayoutMapper,LanguageWordlists,WordlistData,ThoughtRecovery,UserDictionary}.swift \
//     $SR/Models/KeyboardLayout.swift \
//     tools/real_eval/main.swift

import Foundation

// MARK: - Decoding

struct PairsFile: Decodable {
    let layoutIDs: [String]
    let learnedWords: [String]?
    let pairs: [Pair]

    struct Pair: Decodable {
        let input: String
        let expected: String
        let revert: Bool?
    }
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("usage: real_eval <pairs.json> [--raw]")
    exit(2)
}
let path = arguments[1]
let raw = arguments.contains("--raw")

let fileData: Data
do {
    fileData = try Data(contentsOf: URL(fileURLWithPath: path))
} catch {
    print("error: cannot read \(path): \(error.localizedDescription)")
    exit(2)
}

// An empty file means the harvest found no rows — that is a valid result
// (zero real error cases), not an error. `sqlite3 -json` prints nothing
// for an empty result set, so tolerate whitespace-only input too.
let decoded: PairsFile
if fileData.allSatisfy({ $0 == 0x20 || $0 == 0x09 || $0 == 0x0a || $0 == 0x0d }) {
    decoded = PairsFile(layoutIDs: ["com.apple.keylayout.US", "com.apple.keylayout.Ukrainian-PC"], learnedWords: [], pairs: [])
    print("note: input file is empty — treating as zero harvested pairs")
} else {
    do {
        decoded = try JSONDecoder().decode(PairsFile.self, from: fileData)
    } catch {
        print("error: cannot parse \(path): \(error)")
        exit(2)
    }
}

// MARK: - Anonymized fingerprint

func fingerprint(_ text: String) -> String {
    let cyrillicLetters: Set<Character> = [
        "а", "б", "в", "г", "ґ", "д", "е", "ё", "є", "ж", "з", "и", "і", "ї", "й",
        "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш",
        "щ", "ъ", "ы", "ь", "э", "ю", "я",
    ]
    let cyrillic = text.filter { cyrillicLetters.contains(Character($0.lowercased())) }.count
    let latin = text.filter { $0.isLetter && $0.isASCII }.count
    let digits = text.filter { $0.isNumber }.count
    let punctuation = text.filter { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }.count
    let words = text.split(separator: " ").count
    var shape: [String] = []
    for token in text.split(separator: " ", omittingEmptySubsequences: false) {
        let letters = token.filter { $0.isLetter }
        if letters.isEmpty { shape.append("-") }
        else { shape.append(String(repeating: letters.first!.isUppercase ? "A" : "a", count: letters.count)) }
    }
    let hadText = !text.isEmpty ? "nonempty" : "empty"
    return "len=\(text.count) words=\(words) cyr=\(cyrillic) lat=\(latin) digits=\(digits) punct=\(punctuation) \(hadText) [\(shape.joined(separator: " "))]"
}

func firstLine(_ text: String) -> String {
    text.split(separator: "\n").first.map(String.init) ?? text
}

// MARK: - Evaluation

@MainActor func run() {
    let layouts = decoded.layoutIDs
    let learned = Set(decoded.learnedWords ?? [])

    print("== real harvested set ==")
    print("  pairs: \(decoded.pairs.count)  layouts: \(layouts.count)  learnedWords: \(learned.count)")
    if decoded.pairs.isEmpty {
        print("  (empty — nothing to score)")
        return
    }

    var pairs: [(input: String, expected: String)] = []
    var revertFlags: [Bool] = []
    for pair in decoded.pairs {
        pairs.append((pair.input, pair.expected))
        revertFlags.append(pair.revert ?? false)
    }

    let metrics = ThoughtRecovery.evaluate(pairs, layoutIDs: layouts, learnedWords: learned)
    print("  exactMatchRate           = \(String(format: "%.3f", metrics.exactMatchRate))")
    print("  characterRecoveryAccuracy= \(String(format: "%.3f", metrics.characterRecoveryAccuracy))")
    print("  falseReplacementRate     = \(String(format: "%.3f", metrics.falseReplacementRate))")

    // Revert-specific accounting: decoder must NOT rewrite reverted lines again.
    var revertedTotal = 0
    var revertedKept = 0
    var revertedMissed: [Int] = []
    for (index, pair) in pairs.enumerated() where revertFlags[index] {
        revertedTotal += 1
        let plan = ThoughtRecovery.decode(pair.input, layoutIDs: layouts, learnedWords: learned)
        if plan.isChanged {
            revertedMissed.append(index)
        } else {
            revertedKept += 1
        }
    }
    if revertedTotal > 0 {
        print("  reverted lines: \(revertedTotal), kept as-is: \(revertedKept), rewritten again: \(revertedMissed.count)")
    }

    print("== per-pair verdicts (anonymized) ==")
    for (index, pair) in pairs.enumerated() {
        let plan = ThoughtRecovery.decode(pair.input, layoutIDs: layouts, learnedWords: learned)
        let isControl = pair.input == pair.expected
        let verdict: String
        if isControl {
            verdict = plan.isChanged ? "FALSE-REPLACEMENT" : "kept"
        } else if plan.reconstructed == pair.expected {
            verdict = "exact"
        } else {
            let accuracy = ThoughtRecovery.characterAccuracy(plan.reconstructed, expected: pair.expected)
            verdict = "partial(\(String(format: "%.2f", accuracy)))"
        }
        var line = "  #\(index) \(revertFlags[index] ? "revert " : "")\(verdict.padding(toLength: 20, withPad: " ", startingAt: 0)) \(fingerprint(firstLine(pair.input)))"
        if raw {
            line += "\n      input:    \(pair.input)"
            line += "\n      expected: \(pair.expected)"
            line += "\n      decoded:  \(plan.reconstructed)"
        } else if plan.isChanged && pair.input != plan.reconstructed {
            let delta = plan.reconstructed.count - pair.input.count
            let signed = delta > 0 ? "+\(delta)" : "\(delta)"
            line += "\n      would change (\(signed) chars) (diff shape: \(fingerprint(plan.reconstructed)))"
        }
        print(line)
    }
    print("== done ==")
}

Task { @MainActor in
    run()
    exit(0)
}
RunLoop.main.run()
