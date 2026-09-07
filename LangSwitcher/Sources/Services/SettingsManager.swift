import Foundation
import SwiftUI

// MARK: - Smart Conversion Mode
/// Determines behavior when no text is selected and the hotkey is pressed

enum SmartConversionMode: Int, CaseIterable, Codable {
    case lastWord = 0      // Convert only last word (current behavior)
    case greedyLine = 1    // Select to line start, find boundary, convert wrong-layout tail
    case disabled = 2      // No smart conversion — only works with explicit selection
    
    @MainActor var displayName: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .lastWord: return l10n.t("smartMode.lastWord.name")
        case .greedyLine: return l10n.t("smartMode.greedyLine.name")
        case .disabled: return l10n.t("smartMode.disabled.name")
        }
    }
    
    @MainActor var description: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .lastWord: return l10n.t("smartMode.lastWord.desc")
        case .greedyLine: return l10n.t("smartMode.greedyLine.desc")
        case .disabled: return l10n.t("smartMode.disabled.desc")
        }
    }
}

// MARK: - Layout Switch Mode
/// Controls whether the keyboard layout is automatically switched after a hotkey-triggered conversion

enum LayoutSwitchMode: Int, CaseIterable, Codable {
    case always = 0           // Always switch layout when hotkey is pressed
    case ifLastWordConverted = 1  // Switch if the last word was in wrong layout and got reconverted
    case ifAnyWordConverted = 2   // Switch if any word in the converted text needed reconversion
    
    @MainActor var displayName: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .always: return l10n.t("layoutSwitchMode.always.name")
        case .ifLastWordConverted: return l10n.t("layoutSwitchMode.ifLastWord.name")
        case .ifAnyWordConverted: return l10n.t("layoutSwitchMode.ifAnyWord.name")
        }
    }
    
    @MainActor var description: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .always: return l10n.t("layoutSwitchMode.always.desc")
        case .ifLastWordConverted: return l10n.t("layoutSwitchMode.ifLastWord.desc")
        case .ifAnyWordConverted: return l10n.t("layoutSwitchMode.ifAnyWord.desc")
        }
    }
}

// MARK: - Hotkey Mode (UI-facing)
/// Which shortcut style triggers conversion (Issue #7)

enum DoubleTapHotkeyMode: Int, CaseIterable {
    case doubleShift = 0
    case doubleOption = 1
    case custom = 2
}

// MARK: - Settings Manager
// Persists user preferences via UserDefaults

@MainActor
final class SettingsManager: ObservableObject {
    
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Published Properties
    
    @Published var enabledLayouts: [KeyboardLayout] {
        didSet { saveLayouts() }
    }
    
    /// true = double-tap modifier mode (double Shift / double Option), false = regular modifier+key hotkey
    @Published var useDoubleShift: Bool {
        didSet {
            defaults.set(useDoubleShift, forKey: Keys.useDoubleShift)
            NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
        }
    }
    
    /// Which modifier double-tap triggers conversion: ⇧⇧ or ⌥⌥ (Issue #7).
    /// Only meaningful when `useDoubleShift` is true.
    @Published var doubleTapModifier: DoubleTapModifier {
        didSet {
            defaults.set(doubleTapModifier.rawValue, forKey: Keys.doubleTapModifier)
            NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
        }
    }
    
    @Published var hotkeyKeyCode: UInt16 {
        didSet {
            defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode)
            if !useDoubleShift {
                NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
            }
        }
    }
    
    @Published var hotkeyModifiers: UInt {
        didSet {
            defaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers)
            if !useDoubleShift {
                NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
            }
        }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    
    @Published var showNotifications: Bool {
        didSet { defaults.set(showNotifications, forKey: Keys.showNotifications) }
    }
    
    @Published var playSounds: Bool {
        didSet { defaults.set(playSounds, forKey: Keys.playSounds) }
    }
    
    @Published var smartConversionMode: SmartConversionMode {
        didSet { defaults.set(smartConversionMode.rawValue, forKey: Keys.smartConversionMode) }
    }
    
    @Published var layoutSwitchMode: LayoutSwitchMode {
        didSet { defaults.set(layoutSwitchMode.rawValue, forKey: Keys.layoutSwitchMode) }
    }
    
    @Published var conversionCount: Int {
        didSet { defaults.set(conversionCount, forKey: Keys.conversionCount) }
    }
    
    /// Whether conversion logging is enabled. Default: OFF (privacy first).
    @Published var loggingEnabled: Bool {
        didSet { defaults.set(loggingEnabled, forKey: Keys.loggingEnabled) }
    }
    
    /// Automatically convert the last word when Space is pressed,
    /// if it looks like the wrong layout (Issue #4). Default: OFF —
    /// rewriting text unprompted must be opt-in. Posts the hotkey
    /// notification so AppDelegate re-registers the Space monitor.
    @Published var autoCorrectOnSpace: Bool {
        didSet {
            defaults.set(autoCorrectOnSpace, forKey: Keys.autoCorrectOnSpace)
            NotificationCenter.default.post(name: .hotkeySettingsChanged, object: nil)
        }
    }
    
    /// Max number of log entries to keep. 0 = unlimited. Default: 100.
    @Published var logMaxEntries: Int {
        didSet { defaults.set(logMaxEntries, forKey: Keys.logMaxEntries) }
    }
    
    // MARK: - Computed
    
    /// UI-facing hotkey mode (Issue #7): ⇧⇧ / ⌥⌥ / custom shortcut.
    /// Writes to `useDoubleShift` + `doubleTapModifier` so the stored
    /// preference format stays backward compatible.
    var doubleTapHotkeyMode: DoubleTapHotkeyMode {
        get {
            guard useDoubleShift else { return .custom }
            return doubleTapModifier == .shift ? .doubleShift : .doubleOption
        }
        set {
            switch newValue {
            case .doubleShift:
                useDoubleShift = true
                doubleTapModifier = .shift
            case .doubleOption:
                useDoubleShift = true
                doubleTapModifier = .option
            case .custom:
                useDoubleShift = false
            }
        }
    }
    
    var hotkeyModifierFlags: NSEvent.ModifierFlags {
        get { NSEvent.ModifierFlags(rawValue: hotkeyModifiers) }
        set { hotkeyModifiers = newValue.rawValue }
    }
    
    var hotkeyDescription: String {
        if useDoubleShift {
            return doubleTapModifier.displayString
        }
        let mods = HotkeyManager.modifierFlagsToString(hotkeyModifierFlags)
        let key = HotkeyManager.keyCodeToString(hotkeyKeyCode)
        return "\(mods)\(key)"
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let enabledLayouts = "enabledLayouts"
        static let useDoubleShift = "useDoubleShift"
        static let doubleTapModifier = "doubleTapModifier"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let playSounds = "playSounds"
        static let smartConversionMode = "smartConversionMode"
        static let layoutSwitchMode = "layoutSwitchMode"
        static let conversionCount = "conversionCount"
        static let loggingEnabled = "loggingEnabled"
        static let logMaxEntries = "logMaxEntries"
        static let autoCorrectOnSpace = "autoCorrectOnSpace"
    }
    
    // MARK: - Init
    
    private init() {
        // Default: double-shift mode
        let savedUseDoubleShift = defaults.object(forKey: Keys.useDoubleShift) as? Bool
        self.useDoubleShift = savedUseDoubleShift ?? true  // Default ON
        
        // Which modifier to double-tap (Issue #7). Backward-compatible:
        // missing key → Shift (the historical behavior).
        let savedDoubleTapModifier = defaults.object(forKey: Keys.doubleTapModifier) as? Int
        self.doubleTapModifier = DoubleTapModifier(rawValue: savedDoubleTapModifier ?? 0) ?? .shift
        
        // Fallback hotkey settings (Option+S) for regular mode
        let savedKeyCode = defaults.object(forKey: Keys.hotkeyKeyCode) as? Int
        self.hotkeyKeyCode = UInt16(savedKeyCode ?? 0x01) // 0x01 = S key
        
        let savedMods = defaults.object(forKey: Keys.hotkeyModifiers) as? UInt
        self.hotkeyModifiers = savedMods ?? NSEvent.ModifierFlags.option.rawValue
        
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showNotifications = defaults.object(forKey: Keys.showNotifications) as? Bool ?? true
        self.playSounds = defaults.object(forKey: Keys.playSounds) as? Bool ?? true
        let savedSmartMode = defaults.object(forKey: Keys.smartConversionMode) as? Int
        self.smartConversionMode = SmartConversionMode(rawValue: savedSmartMode ?? 1) ?? .greedyLine // Default: greedy
        
        let savedLayoutSwitchMode = defaults.object(forKey: Keys.layoutSwitchMode) as? Int
        self.layoutSwitchMode = LayoutSwitchMode(rawValue: savedLayoutSwitchMode ?? 0) ?? .always // Default: always
        
        self.conversionCount = defaults.integer(forKey: Keys.conversionCount)
        self.loggingEnabled = defaults.object(forKey: Keys.loggingEnabled) as? Bool ?? false  // Default: OFF
        self.logMaxEntries = defaults.object(forKey: Keys.logMaxEntries) as? Int ?? 100       // Default: 100
        self.autoCorrectOnSpace = defaults.object(forKey: Keys.autoCorrectOnSpace) as? Bool ?? false  // Default: OFF
        
        // Load layouts
        if let data = defaults.data(forKey: Keys.enabledLayouts),
           let layouts = try? JSONDecoder().decode([KeyboardLayout].self, from: data),
           !layouts.isEmpty {
            self.enabledLayouts = layouts
        } else {
            self.enabledLayouts = KeyboardLayoutDetector.getInstalledLayouts()
        }
    }
    
    // MARK: - Methods
    
    func refreshSystemLayouts() {
        enabledLayouts = KeyboardLayoutDetector.getInstalledLayouts()
    }
    
    func incrementConversionCount() {
        conversionCount += 1
    }
    
    private func saveLayouts() {
        if let data = try? JSONEncoder().encode(enabledLayouts) {
            defaults.set(data, forKey: Keys.enabledLayouts)
        }
    }
}
