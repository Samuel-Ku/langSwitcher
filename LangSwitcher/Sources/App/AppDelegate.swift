import Cocoa
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    let settingsManager = SettingsManager.shared
    let conversionLogStore = ConversionLogStore.shared
    private var statusBarController: StatusBarController?
    private let hotkeyManager = HotkeyManager()
    private let accessibilityService = AccessibilityService()
    private lazy var textConverter = TextConverter(settingsManager: settingsManager)
    
    private var l10n: LocalizationManager { LocalizationManager.shared }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[LangSwitcher] App launched. Bundle: \(Bundle.main.bundlePath)")
        NSLog("[LangSwitcher] Executable: \(Bundle.main.executablePath ?? "unknown")")
        NSLog("[LangSwitcher] PID: \(ProcessInfo.processInfo.processIdentifier)")
        
        // Setup status bar
        statusBarController = StatusBarController(settingsManager: settingsManager)
        statusBarController?.onConvertAction = { [weak self] in
            self?.performConversion()
        }
        
        // Register hotkey
        registerHotkey()
        
        // Check accessibility permissions and log status
        let trusted = AccessibilityService.hasAccessibilityPermission
        NSLog("[LangSwitcher] Initial AXIsProcessTrusted = \(trusted)")
        if !trusted {
            NSLog("[LangSwitcher] Requesting accessibility permission prompt...")
            AccessibilityService.requestAccessibilityPermission()
        }
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        // Listen for settings changes to re-register hotkey
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeySettingsChanged),
            name: .hotkeySettingsChanged,
            object: nil
        )
    }
    
    // MARK: - Hotkey Registration
    
    func registerHotkey() {
        if settingsManager.useDoubleShift {
            hotkeyManager.registerDoubleShift { [weak self] in
                Task { @MainActor in
                    self?.performConversion()
                }
            }
        } else {
            hotkeyManager.register(
                keyCode: settingsManager.hotkeyKeyCode,
                modifiers: settingsManager.hotkeyModifierFlags
            ) { [weak self] in
                Task { @MainActor in
                    self?.performConversion()
                }
            }
        }
        
        // Automatic correction on Space (Issue #4) — re-registered together
        // with the hotkey because register*() calls reset all monitors.
        if settingsManager.autoCorrectOnSpace {
            hotkeyManager.registerSpaceMonitor { [weak self] in
                Task { @MainActor in
                    self?.performSpaceAutoCorrection()
                }
            }
        } else {
            hotkeyManager.stopSpaceMonitor()
        }
    }
    
    @objc private func hotkeySettingsChanged() {
        registerHotkey()
    }
    
    // MARK: - Core Conversion Logic
    
    /// Track whether we've already shown the permission alert this session
    private var hasShownPermissionAlert = false
    
    func performConversion() {
        let hasPerm = AccessibilityService.hasAccessibilityPermission
        NSLog("[LangSwitcher] performConversion() called, hasAccessibilityPermission=\(hasPerm)")
        
        if !hasPerm {
            NSLog("[LangSwitcher] AXIsProcessTrusted=false. Will attempt conversion anyway (CGEvent may work with Input Monitoring).")
            if !hasShownPermissionAlert {
                hasShownPermissionAlert = true
                NSLog("[LangSwitcher] TIP: If conversion doesn't work, remove the app from Accessibility list in System Settings and re-add it. Also check Input Monitoring.")
            }
        }
        
        // Try clipboard-based approach first (works when text is selected)
        var capturedInput: String?
        var capturedOutput: String?
        var capturedTargetLayout: String?
        let success = accessibilityService.getAndReplaceSelectedText { [weak self] (text: String) -> String? in
            NSLog("[LangSwitcher] getAndReplaceSelectedText got text: '\(text)' (len=\(text.count))")
            capturedInput = text
            if let info = self?.textConverter.convertSelectedTextWithInfo(text) {
                capturedOutput = info.text
                capturedTargetLayout = info.targetLayoutID
                NSLog("[LangSwitcher] convertSelectedText returned: \(info.text)")
                return info.text
            }
            NSLog("[LangSwitcher] convertSelectedText returned: nil")
            return nil
        }
        
        if success {
            NSLog("[LangSwitcher] Direct conversion succeeded")
            settingsManager.incrementConversionCount()
            logConversion(input: capturedInput, output: capturedOutput, mode: "direct")
            switchLayoutIfNeeded(targetLayoutID: capturedTargetLayout, conversionOccurred: true)
            playFeedback()
            showConversionNotification(input: capturedInput, output: capturedOutput)
        } else {
            NSLog("[LangSwitcher] No selected text, trying smart conversion after short delay...")
            usleep(50_000) // 50ms
            performSmartConversion()
        }
    }
    
    /// When no text is selected, use the configured smart conversion mode
    private func performSmartConversion() {
        let mode = settingsManager.smartConversionMode
        NSLog("[LangSwitcher] performSmartConversion() mode=\(mode.displayName)")
        
        switch mode {
        case .disabled:
            NSLog("[LangSwitcher] Smart conversion is disabled")
            return
            
        case .lastWord:
            performLastWordConversion()
            
        case .greedyLine:
            performGreedyLineConversion()
        }
    }
    
    /// Last Word mode: select one word left, convert if it looks wrong
    private func performLastWordConversion() {
        guard let corrected = convertWordLeftOfCursor() else { return }
        settingsManager.incrementConversionCount()
        logConversion(input: corrected.input, output: corrected.output, mode: "lastWord")
        switchLayoutIfNeeded(targetLayoutID: corrected.targetLayoutID, conversionOccurred: true)
        playFeedback()
        showConversionNotification(input: corrected.input, output: corrected.output)
    }
    
    /// Shared core for word-left-of-cursor flows: select one word left and
    /// convert it if and only if it looks like the wrong layout.
    /// Returns the input/output pair plus target layout, or nil if abstained.
    private func convertWordLeftOfCursor() -> (input: String, output: String, targetLayoutID: String?)? {
        var captured: (input: String, output: String, targetLayoutID: String?)?
        let success = accessibilityService.selectAndReplaceLastWord { [weak self] (text: String) -> String? in
            NSLog("[LangSwitcher] convertWordLeftOfCursor got: '\(text)'")
            guard let info = self?.textConverter.convertIfWrongLayout(text) else { return nil }
            captured = (text, info.text, info.targetLayoutID)
            return info.text
        }
        guard success, let corrected = captured else { return nil }
        return corrected
    }
    
    /// Automatic correction on Space (Issue #4): after a plain Space lands,
    /// convert the word left of the cursor if it looks like the wrong layout.
    /// Silent by design — no sound or notification per keystroke; the changed
    /// word itself is the confirmation. Undo arrives with Issue #7.
    private var autoCorrectInFlight = false
    
    /// Delay letting the Space keystroke land in the target app before selecting
    private let autoCorrectSettleDelay: TimeInterval = 0.15
    
    func performSpaceAutoCorrection() {
        guard settingsManager.autoCorrectOnSpace else { return }
        // Never steal Spaces typed in our own windows (Settings search etc.)
        guard !NSApp.isActive else { return }
        // Drop overlapping triggers while a correction is running
        guard !autoCorrectInFlight else { return }
        autoCorrectInFlight = true
        
        // Let the Space keystroke land in the target app before selecting
        DispatchQueue.main.asyncAfter(deadline: .now() + autoCorrectSettleDelay) { [weak self] in
            defer { self?.autoCorrectInFlight = false }
            guard let self else { return }
            guard let corrected = self.convertWordLeftOfCursor() else { return }
            NSLog("[LangSwitcher] performSpaceAutoCorrection: '\(corrected.input)' → '\(corrected.output)'")
            self.settingsManager.incrementConversionCount()
            self.logConversion(input: corrected.input, output: corrected.output, mode: "autoSpace")
            self.switchLayoutIfNeeded(targetLayoutID: corrected.targetLayoutID, conversionOccurred: true)
        }
    }
    
    /// Greedy Line mode: select to line start, find boundary, convert wrong-layout tail
    private func performGreedyLineConversion() {
        var capturedInput: String?
        var capturedOutput: String?
        var capturedTargetLayout: String?
        let success = accessibilityService.selectLineAndReplace { [weak self] (lineText: String) -> String? in
            guard let self = self else { return nil }
            NSLog("[LangSwitcher] greedyLine got line: '\(lineText)' (len=\(lineText.count))")
            
            capturedInput = lineText
            // Use convertLineGreedyWithInfo to capture target layout
            let result = self.textConverter.convertLineGreedyWithInfo(lineText)
            capturedOutput = result?.text
            capturedTargetLayout = result?.targetLayoutID
            return result?.text
        }
        
        if success {
            settingsManager.incrementConversionCount()
            logConversion(input: capturedInput, output: capturedOutput, mode: "greedyLine")
            switchLayoutIfNeeded(targetLayoutID: capturedTargetLayout, conversionOccurred: true)
            playFeedback()
            showConversionNotification(input: capturedInput, output: capturedOutput)
        }
    }
    
    // MARK: - Conversion Logging
    
    private func logConversion(input: String?, output: String?, mode: String) {
        guard settingsManager.loggingEnabled else { return }
        guard let input = input, let output = output else { return }
        
        let layouts = settingsManager.enabledLayouts
        let layoutIDs = layouts.map(\.id)
        
        let sourceLayout = LayoutMapper.detectSourceLayout(text: input, candidateLayouts: layoutIDs) ?? "unknown"
        let targetLayout = layouts.first(where: { $0.id != sourceLayout })?.id ?? "unknown"
        
        conversionLogStore.log(
            inputText: input,
            outputText: output,
            sourceLayout: sourceLayout,
            targetLayout: targetLayout,
            conversionMode: mode
        )
        
        // Trim old entries if max is set
        let maxEntries = settingsManager.logMaxEntries
        if maxEntries > 0 {
            conversionLogStore.trimToMaxEntries(maxEntries)
        }
    }
    
    // MARK: - Layout Switch
    
    /// Switch system keyboard layout to the target after conversion, based on user's setting.
    private func switchLayoutIfNeeded(targetLayoutID: String?, conversionOccurred: Bool) {
        guard let targetLayoutID = targetLayoutID else { return }
        
        switch settingsManager.layoutSwitchMode {
        case .always:
            KeyboardLayoutDetector.switchToLayout(targetLayoutID)
        case .ifLastWordConverted, .ifAnyWordConverted:
            if conversionOccurred {
                KeyboardLayoutDetector.switchToLayout(targetLayoutID)
            }
        }
    }
    
    // MARK: - Notifications
    
    /// Show a macOS notification about the conversion result.
    private func showConversionNotification(input: String?, output: String?) {
        guard settingsManager.showNotifications else { return }
        guard let input = input, let output = output else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "LangSwitcher"
        content.body = "\(input) → \(output)"
        content.sound = nil // Sound is handled separately by playSounds setting
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("[LangSwitcher] Failed to show notification: \(error)")
            }
        }
    }
    
    // MARK: - Feedback
    
    private func playFeedback() {
        if settingsManager.playSounds {
            NSSound(named: .init("Tink"))?.play()
        }
    }
    
    private func showAccessibilityAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = l10n.t("alert.accessibilityTitle")
        alert.informativeText = l10n.t("alert.accessibilityMessage")
        alert.alertStyle = .warning
        alert.addButton(withTitle: l10n.t("alert.openSystemSettings"))
        alert.addButton(withTitle: l10n.t("alert.continueAnyway"))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hotkeySettingsChanged = Notification.Name("hotkeySettingsChanged")
}
