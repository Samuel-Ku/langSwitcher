import Foundation

// MARK: - Layout Mapper
// Maps characters from one keyboard layout to another based on physical key positions

final class LayoutMapper {
    
    /// Convert text typed in `sourceLayout` to what it would be in `targetLayout`
    /// by mapping each character through physical key position
    static func convert(
        text: String,
        from sourceLayoutID: String,
        to targetLayoutID: String
    ) -> String? {
        guard let sourceMap = LayoutCharacterMap.characterMap(for: sourceLayoutID) else {
            NSLog("[LangSwitcher] LayoutMapper.convert: no characterMap for source '\(sourceLayoutID)'")
            return nil
        }
        guard let targetMap = LayoutCharacterMap.characterMap(for: targetLayoutID) else {
            NSLog("[LangSwitcher] LayoutMapper.convert: no characterMap for target '\(targetLayoutID)'")
            return nil
        }
        
        // Build reverse source map: character -> physical key position (QWERTY index)
        // Source map is: qwerty_char -> source_layout_char
        // We need: source_layout_char -> qwerty_char
        let reverseSource = Dictionary(sourceMap.map { ($0.value, $0.key) }, uniquingKeysWith: { first, _ in first })
        
        // For each character in input:
        // 1. Find which physical key produced it in source layout (reverse lookup)
        // 2. Map that physical key to target layout character
        //
        // Punctuation preservation rule:
        // If the source char is NOT a letter and the converted result is also NOT a letter,
        // keep the original character. This handles cases like "?" -> "," where the user
        // intentionally typed "?" and it should stay "?", not become ",".
        // But ";" -> "ж" still converts because the target is a letter.
        //
        // Polish diacritics (Issue #3): Option-layer chars (ą ć ę ł ń ó ś ź ż)
        // are absent from the base reverse map, so when the source is Polish
        // they fold through LayoutCharacterMap.polishDiacriticBases to their
        // physical base key first. Diacritics are letters, so they always
        // convert (the punctuation rule never fires for them).
        let isPolishSource = sourceLayoutID.lowercased().contains("polish")
        
        // Option-chord characters (⌥ layer): a user typing Polish text while a
        // Cyrillic layout is active presses the Polish-diacritic chords
        // (ą=⌥+A on Polish Pro), but the active layout emits its OWN ⌥-layer
        // characters (⌥+A on Ukrainian-PC = ƒ). Those land in the text and
        // must map by physical key too: reverse source ⌥-layer char → key →
        // target ⌥-layer char (ƒ → ą). Fall back to the target's base key
        // when its ⌥-layer has no useful output for that key.
        //
        // Branch order matters: the Polish-source fold above comes FIRST.
        // A foldable diacritic (ą in Polish-source text) is real, correctly
        // typed text and folds to its base key (ą → ф on Ukrainian) — it must
        // NOT ride the option path to the target's ⌥-layer (ƒ). Option-layer
        // chars are only reached when nothing else could explain them: they
        // are ⌥-chord artifacts from typing one language's chords on another
        // layout, which is exactly the Ukrainian→Polish recovery case.
        let sourceOptionMap = LayoutCharacterMap.optionCharacterMap(for: sourceLayoutID) ?? [:]
        let reverseSourceOption = Dictionary(sourceOptionMap.map { ($0.value, $0.key) }, uniquingKeysWith: { first, _ in first })
        let targetOptionMap = LayoutCharacterMap.optionCharacterMap(for: targetLayoutID) ?? [:]
        
        var result = ""
        var unmappedCount = 0
        for char in text {
            if let physicalKey = reverseSource[char],
               let targetChar = targetMap[physicalKey] {
                // Punctuation preservation: if source is non-letter and target is also non-letter,
                // the user likely typed this punctuation intentionally — keep it as-is
                if !char.isLetter && !targetChar.isLetter {
                    result.append(char)
                } else {
                    result.append(targetChar)
                }
            } else if isPolishSource,
                      let baseKey = LayoutCharacterMap.polishDiacriticBases[char],
                      let targetChar = targetMap[baseKey] {
                result.append(targetChar)
            } else if let optionKey = reverseSourceOption[char] {
                // ⌥-layer char on the source layout (e.g. ƒ from ⌥+A on
                // Ukrainian-PC). Prefer the target layout's ⌥-layer letter at
                // the same physical key (ą); else drop to its base key (a).
                if let targetOptionChar = targetOptionMap[optionKey], targetOptionChar.isLetter {
                    result.append(targetOptionChar)
                } else if let targetBaseChar = targetMap[optionKey] {
                    result.append(targetBaseChar)
                } else {
                    result.append(char)
                }
            } else {
                // Character not in mapping (e.g., space, numbers that don't change, emoji)
                result.append(char)
                if char.isLetter {
                    unmappedCount += 1
                }
            }
        }
        
        NSLog("[LangSwitcher] LayoutMapper.convert: '\(text)' -> '\(result)' (unmappedLetters=\(unmappedCount))")
        return result
    }
    
    /// Try to detect which layout a text was likely typed in
    /// Returns the layout ID with the highest confidence
    static func detectSourceLayout(
        text: String,
        candidateLayouts: [String]
    ) -> String? {
        // Simple heuristic: check which layout's character set contains most of the characters
        var bestMatch: String?
        var bestScore = 0
        
        for layoutID in candidateLayouts {
            guard let map = LayoutCharacterMap.characterMap(for: layoutID) else {
                NSLog("[LangSwitcher] detectSourceLayout: no characterMap for '\(layoutID)'")
                continue
            }
            let layoutChars = Set(map.values)
            let score = text.filter { layoutChars.contains($0) }.count
            NSLog("[LangSwitcher] detectSourceLayout: layout '\(layoutID)' score=\(score) for '\(text)'")
            if score > bestScore {
                bestScore = score
                bestMatch = layoutID
            }
        }
        
        NSLog("[LangSwitcher] detectSourceLayout: best match = '\(bestMatch ?? "nil")' (score=\(bestScore))")
        return bestMatch
    }
}
