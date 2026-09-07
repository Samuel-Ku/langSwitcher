import Foundation

// MARK: - Localization Manager
// Custom runtime localization system — no Apple .lproj/.strings.
// Allows instant language switching without app restart.
// Contributors add new languages by copying Strings_en.swift.

@MainActor
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    /// Available languages: code + native name
    static let availableLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("ru", "Русский"),
        ("pl", "Polski"),
        ("ua", "Українська"),
    ]

    /// Currently active language code
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
        }
    }

    /// Registry: language code -> [key: localized string]
    private var registry: [String: [String: String]] = [:]

    // MARK: - Init

    private init() {
        // Read persisted choice, or detect system language
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           Self.availableLanguages.contains(where: { $0.code == saved }) {
            self.currentLanguage = saved
        } else {
            // Auto-detect: walk the user's preferred languages in order and
            // take the first one we support. Match on the language subtag
            // ("uk-UA" -> "uk") so secondary preferences don't shadow the
            // primary one, and alias macOS's "uk" to our "ua" code.
            let preferred = Locale.preferredLanguages // e.g. ["uk-UA", "en-US"]
            var detected: String? = nil
            for localeID in preferred {
                let lowered = localeID.lowercased()
                let subtag = lowered.split(separator: "-").first.map(String.init) ?? lowered
                let code = subtag == "uk" ? "ua" : subtag
                if Self.availableLanguages.contains(where: { $0.code == code }) {
                    detected = code
                    break
                }
            }
            self.currentLanguage = detected ?? "en"
            // Persist the initial choice
            UserDefaults.standard.set(self.currentLanguage, forKey: "appLanguage")
        }
    }

    // MARK: - Registration

    /// Called by each Strings_xx file to register its dictionary
    func register(language: String, strings: [String: String]) {
        registry[language] = strings
    }

    // MARK: - Lookup

    /// Translate a key. Falls back to English, then returns the key itself.
    func t(_ key: String) -> String {
        if let value = registry[currentLanguage]?[key] {
            return value
        }
        if let value = registry["en"]?[key] {
            return value
        }
        return key
    }
}
