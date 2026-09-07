import Foundation
import Carbon

// MARK: - Keyboard Layout Model

struct KeyboardLayout: Identifiable, Hashable, Codable {
    let id: String           // e.g. "com.apple.keylayout.US"
    let localizedName: String // e.g. "U.S." or "Russian"
    let languageCode: String  // e.g. "en", "ru"
    
    var displayName: String {
        "\(localizedName) (\(languageCode.uppercased()))"
    }
}

// MARK: - Layout Pair

struct LayoutPair: Identifiable, Hashable, Codable {
    var id: String { "\(source.id)->\(target.id)" }
    let source: KeyboardLayout
    let target: KeyboardLayout
}

// MARK: - Layout Character Maps
// Standard QWERTY <-> various layout mappings for physical key positions

enum LayoutCharacterMap {
    
    // Standard US QWERTY keyboard
    static let qwertyUS: [Character: Character] = {
        let chars = "`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?"
        var map: [Character: Character] = [:]
        for (i, c) in chars.enumerated() {
            map[c] = c
        }
        return map
    }()
    
    // Russian (standard) keyboard — mapped to same physical keys as US QWERTY
    static let russian: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let russian = Array("ё1234567890-=йцукенгшщзхъ\\фывапролджэячсмитьбю.Ё!\"№;%:?*()_+ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, russian.count) {
            map[qwerty[i]] = russian[i]
        }
        return map
    }()
    
    // German QWERTZ
    static let german: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let german = Array("^1234567890ß´qwertzuiopü+#asdfghjklöäyxcvbnm,.-°!\"§$%&/()=?`QWERTZUIOPÜ*'ASDFGHJKLÖÄYXCVBNM;:_")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, german.count) {
            map[qwerty[i]] = german[i]
        }
        return map
    }()
    
    // French AZERTY
    static let french: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let french = Array("²&é\"'(-è_çà)=azertyuiop^$*qsdfghjklmùwxcvbn,;:!³1234567890°+AZERTYUIOP¨£µQSDFGHJKLM%WXCVBN?./§")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, french.count) {
            map[qwerty[i]] = french[i]
        }
        return map
    }()
    
    // Ukrainian
    static let ukrainian: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let ukr    = Array("'1234567890-=йцукенгшщзхї\\фівапролджєячсмитьбю.₴!\"№;%:?*()_+ЙЦУКЕНГШЩЗХЇ/ФІВАПРОЛДЖЄЯЧСМИТЬБЮ,")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, ukr.count) {
            map[qwerty[i]] = ukr[i]
        }
        return map
    }()
    
    // Spanish
    static let spanish: [Character: Character] = {
        let qwerty  = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let spanish = Array("º1234567890'¡qwertyuiop`+çasdfghjklñ´zxcvbnm,.-ª!\"·$%&/()=?¿QWERTYUIOP^*ÇASDFGHJKLÑ¨ZXCVBNM;:_")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, spanish.count) {
            map[qwerty[i]] = spanish[i]
        }
        return map
    }()
    
    // Polish Pro ("Polish" on modern macOS, id com.apple.keylayout.PolishPro)
    // QWERTY base identical to US — unmodified keys produce the same characters.
    // Polish diacritics (ą ć ę ł ń ó ś ź ż) live on the Option layer — see Issue #3.
    // Base conversion therefore reuses the US QWERTY mapping.
    static let polishPro: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        var map: [Character: Character] = [:]
        for c in qwerty {
            map[c] = c
        }
        return map
    }()
    
    // Polish QWERTZ ("Polish – QWERTZ", id com.apple.keylayout.Polish)
    // Traditional QWERTZ variant: y↔z swapped vs QWERTY, rest of base identical.
    // (Dedicated Polish-letter keys and Option-layer diacritics — see Issue #3.)
    static let polishQWERTZ: [Character: Character] = {
        let qwerty = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")
        let polish = Array("`1234567890-=qwertzuiop[]\\asdfghjkl;'yxcvbnm,./~!@#$%^&*()_+QWERTZUIOP{}|ASDFGHJKL:\"YXCVBNM<>?")
        var map: [Character: Character] = [:]
        for i in 0..<min(qwerty.count, polish.count) {
            map[qwerty[i]] = polish[i]
        }
        return map
    }()
    
    // Polish Option-layer diacritics → QWERTY base key (Issue #3).
    // On Polish Pro each diacritic is a single Option chord on its base key;
    // the only exception is ź on X (ż took Z). Capitals add Shift.
    // Used source-side only: PL diacritic → physical key → target layout char.
    // Target-side synthesis from a plain base letter is intentionally
    // unsupported (diacritic intent is unrecoverable from the base letter);
    // Option-chord recovery — the user's ⌥-chords landing as the ACTIVE
    // layout's own ⌥-layer characters — is a separate path handled by the
    // Option-layer maps below (see ukrainianOption / polishProOption).
    // Note: for the QWERTZ variant this resolves to QWERTY base keys as an
    // approximation (its dedicated diacritic keys have no public keylayout
    // data to derive exact physical positions from).
    static let polishDiacriticBases: [Character: Character] = [
        "ą": "a", "ć": "c", "ę": "e", "ł": "l", "ń": "n",
        "ó": "o", "ś": "s", "ź": "x", "ż": "z",
        "Ą": "A", "Ć": "C", "Ę": "E", "Ł": "L", "Ń": "N",
        "Ó": "O", "Ś": "S", "Ź": "X", "Ż": "Z",
    ]
    
    // Option-layer (⌥) character maps, keyed by the same physical QWERTY key
    // as the base maps above.
    //
    // Why these exist: when the user types Polish text while a Cyrillic layout
    // is active (the Polish↔Ukrainian working pair), the Polish-diacritic
    // chords are Option chords — ą=⌥+A, ś=⌥+S, etc. on Polish Pro. Pressing
    // those same chords on Ukrainian-PC produces Ukrainian-PC's own Option
    // characters (⌥+A=ƒ, ⌥+S=ы, ⌥+E=ќ …). Those characters land in the text
    // and a base-layer-only conversion leaves them unmapped — the user sees
    // „mąka” convert to „mƒkф” instead of „mąka”. Mapping Option characters
    // by physical key closes that gap: ƒ (⌥+A on Ukrainian-PC) → ą (⌥+A on
    // Polish Pro). Layer data below was extracted from the real macOS layouts
    // via UCKeyTranslate.
    
    // Ukrainian-PC Option layer — letter keys a–z (real extraction).
    // Most entries are symbols; the ones that matter for Polish typing are
    // ƒ(⌥+a) ќ(⌥+e) ы(⌥+s) ў(⌥+o) ∆(⌥+l) ≠(⌥+c) љ(⌥+n) ≈(⌥+x) ђ(⌥+z).
    static let ukrainianOption: [Character: Character] = [
        "a": "ƒ", "b": "и", "c": "≠", "d": "ћ", "e": "ќ", "f": "÷", "g": "©",
        "h": "}", "i": "ѕ", "j": "°", "k": "љ", "l": "∆", "m": "~", "n": "™",
        "o": "ў", "p": "‘", "q": "ј", "r": "®", "s": "ы", "t": "ё", "u": "ґ",
        "v": "µ", "w": "џ", "x": "≈", "y": "њ", "z": "ђ",
    ]
    
    // Polish Pro Option-layer diacritics as a forward physical-key map.
    // Derived from polishDiacriticBases (ą→a inverted to a→ą) so both the
    // source-side fold and the target-side synthesis share one source of
    // truth. Covers exactly the 9 canonical diacritics; Polish Pro's other
    // Option entries are symbols with no role in language text.
    static let polishProOption: [Character: Character] = {
        var map: [Character: Character] = [:]
        for (diacritic, base) in polishDiacriticBases where diacritic.isLowercase {
            map[base] = diacritic
        }
        return map
    }()
    
    // Option-layer maps keyed by layout identifier pattern.
    // Order matters just like allMaps — specific patterns before general ones.
    static let optionMaps: [(pattern: String, map: [Character: Character])] = [
        ("ukrainian", ukrainianOption),
        ("polishpro", polishProOption),
    ]
    
    /// Get the Option-layer (⌥) character map for a given layout identifier.
    /// Returns nil when the layout has no Option layer worth converting
    /// (every other layout's Option layer only holds symbols).
    static func optionCharacterMap(for layoutID: String) -> [Character: Character]? {
        let lowered = layoutID.lowercased()
        for (pattern, map) in optionMaps where lowered.contains(pattern) {
            return map
        }
        return nil
    }
    
    // Map of layout identifier patterns to their character maps
    // IMPORTANT: Order matters! More specific patterns must come BEFORE less specific ones.
    // e.g., "russian" must come before "us" because "russian" contains "us" as substring.
    // e.g., "polishpro" must come before "polish" because "polishpro" contains "polish".
    static let allMaps: [(pattern: String, map: [Character: Character])] = [
        ("russian", russian),
        ("ukrainian", ukrainian),
        ("german", german),
        ("french", french),
        ("spanish", spanish),
        ("polishpro", polishPro),
        ("polish", polishQWERTZ),
        ("british", qwertyUS),    // Close enough for conversion
        ("abc", qwertyUS),        // ABC keyboard is same as US
        ("us", qwertyUS),         // Must be LAST among Latin layouts — "us" is substring of "russian" etc.
    ]
    
    /// Get character map for a given layout identifier
    static func characterMap(for layoutID: String) -> [Character: Character]? {
        let lowered = layoutID.lowercased()
        for (pattern, map) in allMaps {
            if lowered.contains(pattern) {
                NSLog("[LangSwitcher] characterMap: '\(layoutID)' matched pattern '\(pattern)'")
                return map
            }
        }
        NSLog("[LangSwitcher] characterMap: no match for '\(layoutID)'")
        return nil
    }
}
