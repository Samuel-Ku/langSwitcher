import Foundation

// MARK: - Language Wordlists
//
// Dictionary evidence for wrong-layout decisions, built on the embedded
// frequency lists in WordlistData. Two jobs:
//
// 1. VETO — if text is already correct Polish or Ukrainian, converting it
//    would garble real words. looksLikeWrongLayout must refuse. This is the
//    false-positive guard the script-switch heuristic lacked: it flips
//    correct "hello"/"cześć" (any Latin text looked "wrong" when a Cyrillic
//    layout was enabled) into "do not touch".
// 2. CONFIRM — if a conversion result is real Polish/Ukrainian, strengthen
//    the script-switch signal (currently required for the greedy boundary).
//    Absence of a word in the list is weak evidence and never blocks.
//
// Russian needs no list here: Russian-origin words are filtered from the
// Ukrainian list, and the Cyrillic alphabet itself plus coverage scoring
// already handles EN↔RU.

@MainActor
enum LanguageWordlists {

    // MARK: - Data (lazily parsed once)

    private static let polishWords: Set<String> = {
        Set(WordlistData.polish.split(separator: "\n").map(String.init))
    }()

    private static let ukrainianWords: Set<String> = {
        Set(WordlistData.ukrainian.split(separator: "\n").map(String.init))
    }()

    // MARK: - Public API

    /// Coverage = share of the word's alphabetic tokens found in `list`.
    /// Single-token words: 1.0 when found, 0.0 when not.
    static func coverage(of text: String, in list: Set<String>) -> Double {
        let tokens = text.lowercased()
            .split { !$0.isLetter && $0 != "'" }
        guard !tokens.isEmpty else { return 0 }
        let hits = tokens.filter { list.contains(String($0)) }.count
        return Double(hits) / Double(tokens.count)
    }

    /// Which of the supported dictionary languages does this text belong to,
    /// and how strongly? Uses per-word coverage; single-token texts score
    /// either 1.0 (hit) or 0.0 (miss) — that's the correct behavior for the
    /// one-word selections this app handles.
    static func bestMatch(for text: String) -> (language: Language, coverage: Double)? {
        var best: (Language, Double)?
        for language in Language.allCases {
            let cov = coverage(of: text, in: words(for: language))
            if cov > 0, best == nil || cov > best!.1 {
                best = (language, cov)
            }
        }
        return best
    }

    /// Should conversion of this text be vetoed because it is already
    /// correct Polish or Ukrainian?
    ///
    /// Multi-word text: full coverage in the language matching its script.
    /// Single word: full coverage AND at least 4 letters. Short words are
    /// too ambiguous ("to"/"nie" exist in PL, "не"/"на" in UA, and both
    /// languages share many 1–3-letter words), but a single ≥4-letter
    /// dictionary hit is decisive: typing "cześć" or "привіт" correctly
    /// and pressing Space (auto flow) would otherwise be garbled into
    /// "сяуы"/"ghbdsn" — the auto flow has no user hotkey press to vouch
    /// for intent, so the dictionary veto is the only protection.
    static func shouldVeto(text: String) -> Bool {
        let tokens = tokenize(text)

        if tokens.count == 1 {
            let word = tokens[0]
            guard word.count >= 4 else { return false }
            let isLatin = word.contains { $0.isLetter && isLatinScript($0) }
            let isCyrillic = word.contains { $0.isLetter && !isLatinScript($0) }
            guard isLatin != isCyrillic else { return false }
            let language: Language = isLatin ? .polish : .ukrainian
            return words(for: language).contains(word)
        }

        guard tokens.count >= 2 else { return false }

        // The candidate language must match the text's script.
        let isLatin = text.contains { $0.isLetter && isLatinScript($0) }
        let isCyrillic = text.contains { $0.isLetter && !isLatinScript($0) }
        guard isLatin != isCyrillic else { return false }

        let language: Language = isLatin ? .polish : .ukrainian
        return coverage(of: text, in: words(for: language)) >= 1.0
    }

    /// Does this converted result look like real Polish or Ukrainian?
    /// Used to CONFIRM a conversion: at least one alphabetic token that is
    /// a dictionary word, and no Cyrillic–Latin mixing (conversion output
    /// is single-script by construction, but stay defensive).
    static func confirmsConversion(_ text: String) -> Bool {
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return false }

        let lists: [Set<String>]
        let isLatin = text.contains { $0.isLetter && isLatinScript($0) }
        if isLatin {
            lists = [words(for: .polish)]
        } else {
            lists = [words(for: .ukrainian)]
        }
        for token in tokens where lists.contains(where: { $0.contains(token) }) {
            return true
        }
        return false
    }

    // MARK: - Internals

    enum Language: CaseIterable {
        case polish
        case ukrainian
    }

    private static func words(for language: Language) -> Set<String> {
        switch language {
        case .polish: return polishWords
        case .ukrainian: return ukrainianWords
        }
    }

    /// Lowercased alphabetic tokens (apostrophes kept inside words:
    /// Ukrainian "з'їсти", don't → split punctuation aside).
    private static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && $0 != "'" }
            .map(String.init)
            .filter { $0.contains(where: \.isLetter) }
    }

    /// Same classification as TextConverter.looksLikeWrongLayout:
    /// letters in the Latin Unicode blocks are Latin, all other letters
    /// (Cyrillic etc.) are non-Latin.
    private static func isLatinScript(_ c: Character) -> Bool {
        c.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 0x300...0x36F,                     // combining marks
                 0x41...0x5A, 0x61...0x7A,          // A–Z a–z
                 0xC0...0xFF,                       // Latin-1 Supplement
                 0x100...0x24F,                     // Latin Extended-A/B
                 0x1E00...0x1EFF:                   // Latin Extended Additional
                return true
            default:
                return false
            }
        }
    }
}
