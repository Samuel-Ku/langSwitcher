import XCTest
@testable import LangSwitcher

final class LayoutMapperTests: XCTestCase {
    
    // MARK: - LayoutCharacterMap.characterMap(for:)
    
    func testCharacterMapMatchesUSLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.US")
        XCTAssertNotNil(map, "US layout should be recognized")
    }
    
    func testCharacterMapMatchesRussianLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Russian")
        XCTAssertNotNil(map, "Russian layout should be recognized")
    }
    
    func testCharacterMapMatchesUkrainianLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Ukrainian")
        XCTAssertNotNil(map, "Ukrainian layout should be recognized")
    }
    
    func testCharacterMapMatchesGermanLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.German")
        XCTAssertNotNil(map, "German layout should be recognized")
    }
    
    func testCharacterMapMatchesFrenchLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.French")
        XCTAssertNotNil(map, "French layout should be recognized")
    }
    
    func testCharacterMapMatchesSpanishLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Spanish")
        XCTAssertNotNil(map, "Spanish layout should be recognized")
    }
    
    func testCharacterMapMatchesBritishLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.British")
        XCTAssertNotNil(map, "British layout should be recognized")
    }
    
    func testCharacterMapMatchesABCLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.ABC")
        XCTAssertNotNil(map, "ABC layout should be recognized")
    }
    
    func testCharacterMapReturnsNilForUnknownLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Japanese")
        XCTAssertNil(map, "Unsupported layout should return nil")
    }
    
    // CRITICAL: Pattern ordering — "russian" contains "us" so Russian must match "russian" not "us"
    func testRussianDoesNotMatchUSPattern() {
        let ruMap = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Russian")
        let usMap = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.US")
        // Russian map should have Cyrillic characters; US map should not
        XCTAssertNotNil(ruMap)
        XCTAssertNotNil(usMap)
        // Check that 'q' maps to 'й' in Russian, not to 'q' (which would mean US matched)
        XCTAssertEqual(ruMap?[Character("q")], Character("й"),
                       "Russian layout should map 'q' to 'й', not keep it as 'q'")
        XCTAssertEqual(usMap?[Character("q")], Character("q"),
                       "US layout should map 'q' to 'q'")
    }
    
    // MARK: - LayoutMapper.convert() — EN → RU
    
    func testConvertENtoRU_privet() {
        let result = LayoutMapper.convert(
            text: "ghbdtn",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "привет")
    }
    
    func testConvertENtoRU_hello() {
        // "руддщ" typed on Russian when meaning "hello" on QWERTY
        let result = LayoutMapper.convert(
            text: "hello",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "руддщ")
    }
    
    func testConvertENtoRU_kakDela() {
        let result = LayoutMapper.convert(
            text: "rfr ltkf",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "как дела")
    }
    
    func testConvertENtoRU_drug() {
        let result = LayoutMapper.convert(
            text: "lheu",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "друг")
    }
    
    func testConvertENtoRU_longPhrase() {
        let result = LayoutMapper.convert(
            text: "ghbdtn rfr ltkf lheu",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "привет как дела друг")
    }
    
    func testConvertENtoRU_upperCase() {
        let result = LayoutMapper.convert(
            text: "GHBDTN",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "ПРИВЕТ")
    }
    
    func testConvertENtoRU_mixedCase() {
        let result = LayoutMapper.convert(
            text: "Ghbdtn",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "Привет")
    }
    
    func testConvertENtoRU_withPunctuation() {
        let result = LayoutMapper.convert(
            text: "ghbdtn!",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        // '!' on QWERTY position maps to '!' in Russian? Check: Shift+1 = '!' in QWERTY, = '!' in Russian
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.hasPrefix("привет"))
    }
    
    func testConvertENtoRU_numbers() {
        // Numbers are at the same positions, should pass through
        let result = LayoutMapper.convert(
            text: "123",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "123")
    }
    
    func testConvertENtoRU_spacesPreserved() {
        let result = LayoutMapper.convert(
            text: "  ghbdtn  ",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "  привет  ")
    }
    
    // MARK: - LayoutMapper.convert() — RU → EN
    
    func testConvertRUtoEN_rullo() {
        // "руддщ" → "hello"
        let result = LayoutMapper.convert(
            text: "руддщ",
            from: "com.apple.keylayout.Russian",
            to: "com.apple.keylayout.US"
        )
        XCTAssertEqual(result, "hello")
    }
    
    func testConvertRUtoEN_privet() {
        // "привет" → "ghbdtn"
        let result = LayoutMapper.convert(
            text: "привет",
            from: "com.apple.keylayout.Russian",
            to: "com.apple.keylayout.US"
        )
        XCTAssertEqual(result, "ghbdtn")
    }
    
    func testConvertRUtoEN_upperCase() {
        let result = LayoutMapper.convert(
            text: "РУДДЩ",
            from: "com.apple.keylayout.Russian",
            to: "com.apple.keylayout.US"
        )
        XCTAssertEqual(result, "HELLO")
    }
    
    // MARK: - Round-trip tests (EN→RU→EN should return original)
    
    func testRoundTrip_ENtoRUandBack() {
        let original = "ghbdtn rfr ltkf"
        let toRU = LayoutMapper.convert(
            text: original,
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertNotNil(toRU)
        let backToEN = LayoutMapper.convert(
            text: toRU!,
            from: "com.apple.keylayout.Russian",
            to: "com.apple.keylayout.US"
        )
        XCTAssertEqual(backToEN, original)
    }
    
    func testRoundTrip_RUtoENandBack() {
        let original = "привет мир"
        let toEN = LayoutMapper.convert(
            text: original,
            from: "com.apple.keylayout.Russian",
            to: "com.apple.keylayout.US"
        )
        XCTAssertNotNil(toEN)
        let backToRU = LayoutMapper.convert(
            text: toEN!,
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(backToRU, original)
    }
    
    // MARK: - Edge Cases
    
    func testConvertEmptyString() {
        let result = LayoutMapper.convert(
            text: "",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "")
    }
    
    func testConvertSingleCharacter() {
        let result = LayoutMapper.convert(
            text: "q",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "й")
    }
    
    func testConvertOnlySpaces() {
        let result = LayoutMapper.convert(
            text: "   ",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "   ")
    }
    
    func testConvertNilForUnknownSourceLayout() {
        let result = LayoutMapper.convert(
            text: "test",
            from: "com.apple.keylayout.Japanese",
            to: "com.apple.keylayout.US"
        )
        XCTAssertNil(result)
    }
    
    func testConvertNilForUnknownTargetLayout() {
        let result = LayoutMapper.convert(
            text: "test",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Japanese"
        )
        XCTAssertNil(result)
    }
    
    // MARK: - German (QWERTZ) conversions
    
    func testConvertENtoDE_yz() {
        // QWERTY 'y' → QWERTZ 'z' and vice versa
        let result = LayoutMapper.convert(
            text: "y",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.German"
        )
        XCTAssertEqual(result, "z")
    }
    
    func testConvertENtoDE_zy() {
        let result = LayoutMapper.convert(
            text: "z",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.German"
        )
        XCTAssertEqual(result, "y")
    }
    
    // MARK: - French (AZERTY) conversions
    
    func testConvertENtoFR_qwertyToAzerty() {
        // QWERTY 'q' → AZERTY 'a'
        let result = LayoutMapper.convert(
            text: "q",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.French"
        )
        XCTAssertEqual(result, "a")
    }
    
    func testConvertENtoFR_aToQ() {
        // QWERTY 'a' → AZERTY 'q'
        let result = LayoutMapper.convert(
            text: "a",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.French"
        )
        XCTAssertEqual(result, "q")
    }
    
    // MARK: - Ukrainian conversions
    
    func testConvertENtoUK_privet() {
        // Ukrainian uses a similar layout to Russian but with some differences
        let result = LayoutMapper.convert(
            text: "ghbdsn",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertNotNil(result)
        // In Ukrainian: g→п, h→р, b→и, d→в, s→і, n→т
        XCTAssertEqual(result, "привіт")
    }
    
    // MARK: - Polish layouts (Issue #2: Base Polish ↔ Ukrainian conversion)
    //
    // macOS ships two Polish layouts:
    // - "Polish" (id com.apple.keylayout.PolishPro) = QWERTY, base identical to US.
    //   Diacritics (ą ć ę ł ń ó ś ź ż) live on the Option layer — covered by Issue #3.
    // - "Polish – QWERTZ" (id com.apple.keylayout.Polish) = QWERTZ, y↔z swapped.
    //
    // Base conversion covers unmodified keys only (A–Z, 0–9, punctuation).
    
    func testCharacterMapMatchesPolishProLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.PolishPro")
        XCTAssertNotNil(map, "PolishPro layout should be recognized")
    }
    
    func testCharacterMapMatchesPolishQWERTZLayout() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Polish")
        XCTAssertNotNil(map, "Polish QWERTZ layout should be recognized")
    }
    
    func testPolishProBaseIdenticalToUS() {
        let plMap = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.PolishPro")
        let usMap = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.US")
        XCTAssertNotNil(plMap)
        XCTAssertNotNil(usMap)
        // Unmodified base letters must match US QWERTY
        for char in ["a", "q", "w", "e", "s", "z", "m"] {
            XCTAssertEqual(plMap?[Character(char)], usMap?[Character(char)],
                           "PolishPro '\(char)' should match US")
        }
    }
    
    func testPolishProDoesNotMatchUSPattern() {
        // PolishPro must resolve to its own map, not fall through to "us"
        // (no substring collision today, but guards against future reordering)
        let plMap = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.PolishPro")
        XCTAssertNotNil(plMap)
        // PolishPro base is QWERTY-identical, so spot-check a letter stays Latin
        XCTAssertEqual(plMap?[Character("q")], Character("q"))
    }
    
    func testPolishQWERTZSwapsYZ() {
        let map = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Polish")
        XCTAssertNotNil(map)
        XCTAssertEqual(map?[Character("y")], Character("z"),
                       "Polish QWERTZ: QWERTY-y key produces 'z'")
        XCTAssertEqual(map?[Character("z")], Character("y"),
                       "Polish QWERTZ: QWERTY-z key produces 'y'")
        XCTAssertEqual(map?[Character("Y")], Character("Z"))
        XCTAssertEqual(map?[Character("Z")], Character("Y"))
    }
    
    func testPolishProAndQWERTZAreDistinct() {
        let proMap = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.PolishPro")
        let qwMap = LayoutCharacterMap.characterMap(for: "com.apple.keylayout.Polish")
        XCTAssertNotNil(proMap)
        XCTAssertNotNil(qwMap)
        // The only base difference is y↔z
        XCTAssertNotEqual(proMap?[Character("y")], qwMap?[Character("y")],
                          "PolishPro vs QWERTZ must differ on 'y'")
    }
    
    func testConvertENtoPLPro_identity() {
        // QWERTY-identical bases: EN→PLPro is identity for plain ASCII letters
        let result = LayoutMapper.convert(
            text: "hello",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.PolishPro"
        )
        XCTAssertEqual(result, "hello")
    }
    
    func testConvertENtoPLQWERTZ_yz() {
        let resultY = LayoutMapper.convert(
            text: "y",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Polish"
        )
        XCTAssertEqual(resultY, "z")
        let resultZ = LayoutMapper.convert(
            text: "z",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Polish"
        )
        XCTAssertEqual(resultZ, "y")
    }
    
    func testConvertPLProtoUK_privit() {
        // "ghbdsn" typed with PolishPro (same physical keys as US) → Ukrainian "привіт"
        let result = LayoutMapper.convert(
            text: "ghbdsn",
            from: "com.apple.keylayout.PolishPro",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertEqual(result, "привіт")
    }
    
    func testConvertUKtoPLPro_privit() {
        // Ukrainian "привіт" typed with Ukrainian layout, viewed through PolishPro → "ghbdsn"
        let result = LayoutMapper.convert(
            text: "привіт",
            from: "com.apple.keylayout.Ukrainian",
            to: "com.apple.keylayout.PolishPro"
        )
        XCTAssertEqual(result, "ghbdsn")
    }
    
    func testConvertPLQWERTZtoUK_yzDiscriminator() {
        // Physical QWERTY-y key: Polish QWERTZ shows 'z', Ukrainian shows 'н'
        let fromQWERTZ = LayoutMapper.convert(
            text: "z",
            from: "com.apple.keylayout.Polish",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertEqual(fromQWERTZ, "н")
        // Same letter through PolishPro (QWERTY-z key) → Ukrainian 'я'
        let fromPro = LayoutMapper.convert(
            text: "z",
            from: "com.apple.keylayout.PolishPro",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertEqual(fromPro, "я")
    }
    
    func testConvertUKtoPLQWERTZ_yzDiscriminator() {
        // Ukrainian 'н' lives on QWERTY-y key → Polish QWERTZ shows 'z'
        let result = LayoutMapper.convert(
            text: "н",
            from: "com.apple.keylayout.Ukrainian",
            to: "com.apple.keylayout.Polish"
        )
        XCTAssertEqual(result, "z")
    }
    
    func testRoundTrip_PLProtoUKandBack() {
        let original = "ghbdsn"
        let toUK = LayoutMapper.convert(
            text: original,
            from: "com.apple.keylayout.PolishPro",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertNotNil(toUK)
        let backToPL = LayoutMapper.convert(
            text: toUK!,
            from: "com.apple.keylayout.Ukrainian",
            to: "com.apple.keylayout.PolishPro"
        )
        XCTAssertEqual(backToPL, original)
    }
    
    func testDetectSourceLayout_PolishVsUkrainian() {
        // Latin text → PolishPro source
        let latin = LayoutMapper.detectSourceLayout(
            text: "hello",
            candidateLayouts: ["com.apple.keylayout.PolishPro", "com.apple.keylayout.Ukrainian"]
        )
        XCTAssertEqual(latin, "com.apple.keylayout.PolishPro")
        // Cyrillic text → Ukrainian source
        let cyrillic = LayoutMapper.detectSourceLayout(
            text: "привіт",
            candidateLayouts: ["com.apple.keylayout.PolishPro", "com.apple.keylayout.Ukrainian"]
        )
        XCTAssertEqual(cyrillic, "com.apple.keylayout.Ukrainian")
    }
    
    // MARK: - Polish diacritics (Issue #3: modifier characters)
    //
    // On Polish Pro every diacritic is a single Option chord on its base key:
    // ą=Opt+A, ć=Opt+C, ę=Opt+E, ł=Opt+L, ń=Opt+N, ó=Opt+O, ś=Opt+S,
    // ź=Opt+X (exception — ż took Z), ż=Opt+Z. Capitals add Shift.
    // Conversion folds each diacritic through its physical base key:
    // PL diacritic → UK letter; UK → PL base letters never synthesize
    // (diacritic intent on a plain base letter is unrecoverable). The one
    // exception is Option-chord recovery: when the user typed Polish on a
    // Cyrillic layout, the chords land as that layout's OWN ⌥-layer
    // characters and are recovered through physical keys — see the
    // Option-chord tests below.
    
    func testPolishDiacriticBases_lowercase() {
        let bases = LayoutCharacterMap.polishDiacriticBases
        let expected: [Character: Character] = [
            "ą": "a", "ć": "c", "ę": "e", "ł": "l", "ń": "n",
            "ó": "o", "ś": "s", "ź": "x", "ż": "z",
        ]
        XCTAssertEqual(bases.filter { $0.key.isLowercase }.count, 9,
                       "Must cover all 9 lowercase Polish diacritics")
        for (diacritic, base) in expected {
            XCTAssertEqual(bases[diacritic], base,
                           "'\(diacritic)' must fold to base key '\(base)'")
        }
    }
    
    func testPolishDiacriticBases_uppercase() {
        let bases = LayoutCharacterMap.polishDiacriticBases
        let expected: [Character: Character] = [
            "Ą": "A", "Ć": "C", "Ę": "E", "Ł": "L", "Ń": "N",
            "Ó": "O", "Ś": "S", "Ź": "X", "Ż": "Z",
        ]
        for (diacritic, base) in expected {
            XCTAssertEqual(bases[diacritic], base,
                           "'\(diacritic)' must fold to base key '\(base)'")
        }
    }
    
    func testPolishDiacriticBases_zWithDotVsAcute() {
        // The one non-intuitive pair: ż lives on Z, ź lives on X
        let bases = LayoutCharacterMap.polishDiacriticBases
        XCTAssertEqual(bases["ż"], "z")
        XCTAssertEqual(bases["ź"], "x")
        XCTAssertEqual(bases["Ż"], "Z")
        XCTAssertEqual(bases["Ź"], "X")
    }
    
    func testConvertPLProToUK_pangram() {
        // "Zażółć gęślą jaźń" — classic Polish pangram covering all 9 diacritics
        let result = LayoutMapper.convert(
            text: "Zażółć gęślą jaźń",
            from: "com.apple.keylayout.PolishPro",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertEqual(result, "Яфящдс пуідф офчт")
    }
    
    func testConvertPLProToUK_czesc() {
        let result = LayoutMapper.convert(
            text: "cześć",
            from: "com.apple.keylayout.PolishPro",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertEqual(result, "сяуіс")
    }
    
    func testConvertPLProToUK_uppercaseDiacritics() {
        let result = LayoutMapper.convert(
            text: "ŁÓDŹ",
            from: "com.apple.keylayout.PolishPro",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertEqual(result, "ДЩВЧ")
    }
    
    func testConvertPLProToEN_diacriticsStripped() {
        // Same physical keys through US layout yield plain ASCII.
        // Note: Ź lives on X (ż took Z), so ŁÓDŹ folds to LODX, not LODZ —
        // this is physical-key truth, not transliteration.
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "cześć",
                from: "com.apple.keylayout.PolishPro",
                to: "com.apple.keylayout.US"
            ),
            "czesc"
        )
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "ŁÓDŹ",
                from: "com.apple.keylayout.PolishPro",
                to: "com.apple.keylayout.US"
            ),
            "LODX"
        )
    }
    
    func testConvertPLProToUK_trailingPunctuation() {
        // Punctuation preservation still applies around folded diacritics
        let result = LayoutMapper.convert(
            text: "cześć!",
            from: "com.apple.keylayout.PolishPro",
            to: "com.apple.keylayout.Ukrainian"
        )
        XCTAssertEqual(result, "сяуіс!")
    }
    
    func testConvertUKtoPLPro_neverSynthesizesDiacritics() {
        // "ф" lives on the A key: without Option intent we must emit base "a", not "ą"
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "ф",
                from: "com.apple.keylayout.Ukrainian",
                to: "com.apple.keylayout.PolishPro"
            ),
            "a"
        )
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "іч",
                from: "com.apple.keylayout.Ukrainian",
                to: "com.apple.keylayout.PolishPro"
            ),
            "sx"
        )
    }
    
    // MARK: - Option-chord recovery (Polish typed on a Cyrillic layout)
    //
    // Typing Polish while Ukrainian-PC is active: Polish diacritics are
    // Option chords on Polish Pro (ą=⌥+A), but the active layout emits its
    // own ⌥-layer characters for the same chords (⌥+A on Ukrainian-PC = ƒ,
    // ⌥+E = ќ, ⌥+S = ы, ⌥+N = ™ …). Those land in the text as junk and must
    // map by physical key to the Polish ⌥-layer output: ƒ→ą, ќ→ę, ™→ń, …
    
    func testOptionCharacterMap_ukrainianAndPolishPro() {
        XCTAssertNotNil(LayoutCharacterMap.optionCharacterMap(for: "com.apple.keylayout.Ukrainian"))
        XCTAssertNotNil(LayoutCharacterMap.optionCharacterMap(for: "com.apple.keylayout.Ukrainian-PC"))
        XCTAssertNotNil(LayoutCharacterMap.optionCharacterMap(for: "com.apple.keylayout.PolishPro"))
        XCTAssertNil(LayoutCharacterMap.optionCharacterMap(for: "com.apple.keylayout.US"),
                     "Layouts without a convertible Option layer must return nil")
    }
    
    func testConvertUAtoPLPro_restoresAllNinePolishDiacritics() {
        // Each ⌥-chord on Ukrainian-PC (as-if Polish Pro) → the Polish diacritic
        // that the same physical key produces on Polish Pro's Option layer.
        let chords: [(typed: String, expected: String)] = [
            ("ƒ", "ą"),   // ⌥+a
            ("≠", "ć"),   // ⌥+c
            ("ќ", "ę"),   // ⌥+e
            ("∆", "ł"),   // ⌥+l
            ("™", "ń"),   // ⌥+n
            ("ў", "ó"),   // ⌥+o
            ("ы", "ś"),   // ⌥+s
            ("≈", "ź"),   // ⌥+x
            ("ђ", "ż"),   // ⌥+z
        ]
        for (typed, expected) in chords {
            XCTAssertEqual(
                LayoutMapper.convert(
                    text: typed,
                    from: "com.apple.keylayout.Ukrainian",
                    to: "com.apple.keylayout.PolishPro"
                ),
                expected,
                "'\(typed)' must restore '\(expected)'"
            )
        }
    }
    
    func testConvertUAtoPLPro_wordWithDiacritics() {
        // Polish "mąka" typed on Ukrainian-PC (m→ь, ⌥+a→ƒ, k→л, a→ф)
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "ьƒлф",
                from: "com.apple.keylayout.Ukrainian",
                to: "com.apple.keylayout.PolishPro"
            ),
            "mąka"
        )
        // Polish "cześć" typed on Ukrainian-PC (c→с, z→я, e→у, ⌥+s→ы, ⌥+c→≠)
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "сяуы≠",
                from: "com.apple.keylayout.Ukrainian",
                to: "com.apple.keylayout.PolishPro"
            ),
            "cześć"
        )
    }
    
    func testConvertUAtoPLPro_optionChordOnPlainKeyFallsBackToBase() {
        // љ is Ukrainian-PC ⌥+K; Polish Pro has no language letter on ⌥+K,
        // so the chord falls back to the base key K → "k" (never junk).
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "љ",
                from: "com.apple.keylayout.Ukrainian",
                to: "com.apple.keylayout.PolishPro"
            ),
            "k"
        )
    }
    
    func testConvertUAtoPLPro_reverseDirectionStillFolds() {
        // Real Polish text converted the other way must NOT ride the Option
        // path: ą folds through its base key to ф, not to Ukrainian-PC's ⌥+A ƒ.
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "mąka",
                from: "com.apple.keylayout.PolishPro",
                to: "com.apple.keylayout.Ukrainian"
            ),
            "ьфлф"
        )
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "cześć",
                from: "com.apple.keylayout.PolishPro",
                to: "com.apple.keylayout.Ukrainian"
            ),
            "сяуіс"
        )
    }
    
    func testConvertPLQWERTZtoUK_diacritics() {
        // Same folding rule applies to the QWERTZ variant (approximation:
        // diacritics resolve to QWERTY base keys, see KeyboardLayout.swift)
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "ź",
                from: "com.apple.keylayout.Polish",
                to: "com.apple.keylayout.Ukrainian"
            ),
            "ч"
        )
        XCTAssertEqual(
            LayoutMapper.convert(
                text: "ż",
                from: "com.apple.keylayout.Polish",
                to: "com.apple.keylayout.Ukrainian"
            ),
            "я"
        )
    }
    
    // MARK: - detectSourceLayout
    
    func testDetectSourceLayout_CyrillicText() {
        let detected = LayoutMapper.detectSourceLayout(
            text: "привет",
            candidateLayouts: ["com.apple.keylayout.US", "com.apple.keylayout.Russian"]
        )
        XCTAssertEqual(detected, "com.apple.keylayout.Russian")
    }
    
    func testDetectSourceLayout_LatinText() {
        let detected = LayoutMapper.detectSourceLayout(
            text: "hello",
            candidateLayouts: ["com.apple.keylayout.US", "com.apple.keylayout.Russian"]
        )
        XCTAssertEqual(detected, "com.apple.keylayout.US")
    }
    
    func testDetectSourceLayout_WrongLayoutLatin() {
        // "ghbdtn" is Latin — should detect as US source
        let detected = LayoutMapper.detectSourceLayout(
            text: "ghbdtn",
            candidateLayouts: ["com.apple.keylayout.US", "com.apple.keylayout.Russian"]
        )
        XCTAssertEqual(detected, "com.apple.keylayout.US")
    }
    
    func testDetectSourceLayout_WrongLayoutCyrillic() {
        // "руддщ" is Cyrillic — should detect as Russian source
        let detected = LayoutMapper.detectSourceLayout(
            text: "руддщ",
            candidateLayouts: ["com.apple.keylayout.US", "com.apple.keylayout.Russian"]
        )
        XCTAssertEqual(detected, "com.apple.keylayout.Russian")
    }
    
    func testDetectSourceLayout_EmptyText() {
        let detected = LayoutMapper.detectSourceLayout(
            text: "",
            candidateLayouts: ["com.apple.keylayout.US", "com.apple.keylayout.Russian"]
        )
        // Empty text should return nil or first layout (score 0 for all)
        // Implementation returns nil when bestScore is 0
        XCTAssertNil(detected)
    }
    
    func testDetectSourceLayout_SingleCandidate() {
        let detected = LayoutMapper.detectSourceLayout(
            text: "hello",
            candidateLayouts: ["com.apple.keylayout.US"]
        )
        XCTAssertEqual(detected, "com.apple.keylayout.US")
    }
    
    func testDetectSourceLayout_NoCandidates() {
        let detected = LayoutMapper.detectSourceLayout(
            text: "hello",
            candidateLayouts: []
        )
        XCTAssertNil(detected)
    }
    
    func testDetectSourceLayout_OnlyNumbers() {
        let detected = LayoutMapper.detectSourceLayout(
            text: "12345",
            candidateLayouts: ["com.apple.keylayout.US", "com.apple.keylayout.Russian"]
        )
        // Numbers exist in both layouts — should pick one with higher score
        XCTAssertNotNil(detected)
    }
    
    // MARK: - Large Dataset: EN→RU word pairs
    
    func testConvertENtoRU_largeDataset() {
        let pairs: [(input: String, expected: String)] = [
            ("ghbdtn", "привет"),
            ("rfr ltkf", "как дела"),
            ("lheu", "друг"),
            ("vbh", "мир"),
            ("cjkywt", "солнце"),
            ("rjvgm.nth", "компьютер"),
            ("ghjuhfvvf", "программа"),
            ("ntrcn", "текст"),
            ("rkfdbfnehf", "клавиатура"),
            ("hf,jnf", "работа"),
            ("ljv", "дом"),
            ("xfq", "чай"),
            ("rjit", "коше"),  // кошe through mapping
            ("cjj,otybt", "сообщение"),
            ("cnhjrf", "строка"),
            (",erdf", "буква"),
            ("zyfrjvsq", "янакомый"),  // 'z' maps to 'я' on Russian keyboard, not 'з'
            ("cghfdjxybr", "справочник"),
        ]
        
        for pair in pairs {
            let result = LayoutMapper.convert(
                text: pair.input,
                from: "com.apple.keylayout.US",
                to: "com.apple.keylayout.Russian"
            )
            XCTAssertEqual(result, pair.expected,
                           "Failed: '\(pair.input)' should convert to '\(pair.expected)', got '\(result ?? "nil")'")
        }
    }
    
    // MARK: - Large Dataset: RU→EN word pairs
    
    func testConvertRUtoEN_largeDataset() {
        let pairs: [(input: String, expected: String)] = [
            ("руддщ", "hello"),
            ("цщкдв", "world"),
            ("еуыештп", "testing"),  // 'г' (at 'g' key) not 'е' (at 't' key)
            ("зкщпкфь", "program"),
            ("ьфсщы", "macos"),
            ("ызусшфд", "special"),
            ("лунищфкв", "keyboard"),
            ("дфнщге", "layout"),
            ("ыцшеср", "switch"),
            ("сщтмуке", "convert"),
        ]
        
        for pair in pairs {
            let result = LayoutMapper.convert(
                text: pair.input,
                from: "com.apple.keylayout.Russian",
                to: "com.apple.keylayout.US"
            )
            XCTAssertEqual(result, pair.expected,
                           "Failed: '\(pair.input)' should convert to '\(pair.expected)', got '\(result ?? "nil")'")
        }
    }
    
    // MARK: - Special characters and symbols
    
    func testConvertSpecialChars_brackets() {
        // '[' in US QWERTY → 'х' in Russian
        let result = LayoutMapper.convert(
            text: "[",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "х")
    }
    
    func testConvertSpecialChars_semicolon() {
        // ';' in US QWERTY → 'ж' in Russian
        let result = LayoutMapper.convert(
            text: ";",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "ж")
    }
    
    func testConvertSpecialChars_apostrophe() {
        // '\'' in US QWERTY → 'э' in Russian
        let result = LayoutMapper.convert(
            text: "'",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "э")
    }
    
    func testConvertSpecialChars_backtick() {
        // '`' in US QWERTY → 'ё' in Russian (non-letter → letter = converts)
        let result = LayoutMapper.convert(
            text: "`",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "ё")
    }
    
    // MARK: - Punctuation preservation
    // Non-letter chars that map to non-letter chars are preserved as-is.
    // This prevents "?" becoming "," or "/" becoming "." during conversion.
    
    func testPunctuationPreserved_questionMark() {
        // '?' (Shift+/) in QWERTY maps to ',' in Russian (Shift+/ physical key)
        // But both are non-letter → preserve '?'
        let result = LayoutMapper.convert(
            text: "ghbdtn?",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "привет?")
    }
    
    func testPunctuationPreserved_questionMarkAlone() {
        let result = LayoutMapper.convert(
            text: "?",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "?")
    }
    
    func testPunctuationPreserved_exclamationMark() {
        // '!' (Shift+1) in QWERTY maps to '!' in Russian (same) — both non-letter → preserve
        let result = LayoutMapper.convert(
            text: "ghbdtn!",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "привет!")
    }
    
    func testPunctuationPreserved_slash() {
        // '/' in QWERTY maps to '.' in Russian — both non-letter → preserve '/'
        let result = LayoutMapper.convert(
            text: "/",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "/")
    }
    
    func testPunctuationStillConverts_semicolonToLetter() {
        // ';' → 'ж' (non-letter → letter) — must still convert
        let result = LayoutMapper.convert(
            text: ";",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "ж")
    }
    
    func testPunctuationStillConverts_commaToLetter() {
        // ',' → 'б' (non-letter → letter) — must still convert
        let result = LayoutMapper.convert(
            text: ",",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "б")
    }
    
    func testPunctuationStillConverts_dotToLetter() {
        // '.' → 'ю' (non-letter → letter) — must still convert
        let result = LayoutMapper.convert(
            text: ".",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "ю")
    }
    
    func testPunctuationPreserved_fullPhrase() {
        // "ghbdtn rfr ltkf?" should become "привет как дела?" (not "привет как дела,")
        let result = LayoutMapper.convert(
            text: "ghbdtn rfr ltkf?",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "привет как дела?")
    }
    
    func testPunctuationPreserved_numbersUnchanged() {
        // Numbers are non-letter → non-letter, so they stay as-is (same as before)
        let result = LayoutMapper.convert(
            text: "123",
            from: "com.apple.keylayout.US",
            to: "com.apple.keylayout.Russian"
        )
        XCTAssertEqual(result, "123")
    }
}
