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
        statusBarController?.onPreviewRecoveryAction = { [weak self] in
            self?.performRecoveryPreview()
        }
        statusBarController?.onPreviewRecoveryAction = { [weak self] in
            self?.performRecoveryPreview()
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
            hotkeyManager.registerDoubleTap(modifier: settingsManager.doubleTapModifier) { [weak self] in
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
        // Conversion is still attempted: CGEvent posting works with only
        // Input Monitoring granted (⌘C/⌘V round-trip still converts),
        // and smart conversion simply abstains without AX.
        let status = PermissionMonitor.systemProbe()
        NSLog("[LangSwitcher] performConversion() permissions: ax=\(status.accessibilityGranted) im=\(status.inputMonitoringGranted)")
        
        if !status.isFullyGranted {
            NSLog("[LangSwitcher] Missing permission: \(String(describing: status.firstMissing)). Will attempt conversion anyway (CGEvent may work with Input Monitoring only).")
            if !hasShownPermissionAlert {
                hasShownPermissionAlert = true
                showAccessibilityAlert()
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
        guard let corrected = convertWordLeftOfCursor(using: { [weak self] text in
            self?.textConverter.convertIfWrongLayout(text)
        }) else { return }
        settingsManager.incrementConversionCount()
        logConversion(input: corrected.input, output: corrected.output, mode: "lastWord")
        switchLayoutIfNeeded(targetLayoutID: corrected.targetLayoutID, conversionOccurred: true)
        playFeedback()
        showConversionNotification(input: corrected.input, output: corrected.output)
    }
    
    /// Shared core for word-left-of-cursor flows: select one word left and
    /// apply the given decision. The manual Last Word flow decides with
    /// `convertIfWrongLayout`; the automatic Space flow with `autoCorrectWord`
    /// (Issue #5 rules). Returns the pair plus target layout, or nil if abstained.
    private func convertWordLeftOfCursor(
        using decide: (String) -> TextConverter.ConversionResult?
    ) -> (input: String, output: String, targetLayoutID: String?)? {
        var captured: (input: String, output: String, targetLayoutID: String?)?
        let success = accessibilityService.selectAndReplaceLastWord { (text: String) -> String? in
            NSLog("[LangSwitcher] convertWordLeftOfCursor got: '\(text)'")
            guard let info = decide(text) else { return nil }
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
        // Issue #6: secure fields, non-text focus and excluded apps veto.
        // Unknown focus fails closed (nil role denies).
        let focus = accessibilityService.focusedFieldRole()
        let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard AutoCorrectionGate.allowsAutoCorrection(
            role: focus?.role,
            subrole: focus?.subrole,
            bundleID: frontmostBundleID
        ) else {
            NSLog("[LangSwitcher] performSpaceAutoCorrection: vetoed by AutoCorrectionGate")
            return
        }
        // Drop overlapping triggers while a correction is running
        guard !autoCorrectInFlight else { return }
        autoCorrectInFlight = true
        
        // Let the Space keystroke land in the target app before selecting
        DispatchQueue.main.asyncAfter(deadline: .now() + autoCorrectSettleDelay) { [weak self] in
            defer { self?.autoCorrectInFlight = false }
            guard let self else { return }
            guard let corrected = self.convertWordLeftOfCursor(using: { [weak self] text in
                self?.textConverter.autoCorrectWord(text)
            }) else { return }
            NSLog("[LangSwitcher] performSpaceAutoCorrection: '\(corrected.input)' → '\(corrected.output)'")
            self.settingsManager.incrementConversionCount()
            self.logConversion(input: corrected.input, output: corrected.output, mode: "autoSpace")
            self.switchLayoutIfNeeded(targetLayoutID: corrected.targetLayoutID, conversionOccurred: true)
        }
    }
    
    /// Greedy Line mode: select to line start and reconstruct it. Thought
    /// Recovery (span level) runs first; the older boundary heuristic stays as
    /// the fallback for lines it abstains on. With `thoughtRecoveryPreview` the
    /// reconstruction is shown for confirmation instead of pasted.
    private func performGreedyLineConversion() {
        if settingsManager.thoughtRecoveryPreview, settingsManager.thoughtRecoveryEnabled {
            performRecoveryPreview()
            return
        }

        var capturedInput: String?
        var capturedOutput: String?
        var capturedTargetLayout: String?
        var usedRecovery = false
        let success = accessibilityService.selectLineAndReplace { [weak self] (lineText: String) -> String? in
            guard let self = self else { return nil }
            NSLog("[LangSwitcher] greedyLine got line: '\(lineText)' (len=\(lineText.count))")
            
            capturedInput = lineText
            if let recovered = self.textConverter.recoverLine(lineText) {
                capturedOutput = recovered.text
                capturedTargetLayout = recovered.targetLayoutID
                usedRecovery = true
                return recovered.text
            }
            // Use convertLineGreedyWithInfo to capture target layout
            let result = self.textConverter.convertLineGreedyWithInfo(lineText)
            capturedOutput = result?.text
            capturedTargetLayout = result?.targetLayoutID
            return result?.text
        }
        
        if success {
            settingsManager.incrementConversionCount()
            if usedRecovery { settingsManager.recoveryCount += 1 }
            logConversion(input: capturedInput, output: capturedOutput, mode: usedRecovery ? "recover" : "greedyLine")
            switchLayoutIfNeeded(targetLayoutID: capturedTargetLayout, conversionOccurred: true)
            playFeedback()
            showConversionNotification(input: capturedInput, output: capturedOutput)
        }
    }
    
    // MARK: - Thought Recovery Preview

    private var recoveryPreviewWindow: NSWindow?
    private var recoveryTargetApp: NSRunningApplication?
    private var recoveryOriginalText: String?
    private var recoveryPlan: ThoughtRecovery.Plan?

    /// Select the line but keep the selection active, decode it and show the
    /// reconstruction with its alternatives. The app the line came from gets the
    /// paste back (or its selection collapsed) once the user decides.
    func performRecoveryPreview() {
        guard recoveryPreviewWindow == nil else { return }
        recoveryTargetApp = NSWorkspace.shared.frontmostApplication

        guard let line = accessibilityService.selectLineKeepingSelection() else {
            resetRecoveryState()
            return
        }
        guard let plan = textConverter.recoveryPlan(for: line) else {
            restorationAfterRecovery(action: .collapse)
            resetRecoveryState()
            return
        }

        recoveryOriginalText = line
        recoveryPlan = plan
        showRecoveryPreview(plan: plan)
    }

    private func showRecoveryPreview(plan: ThoughtRecovery.Plan) {
        NSApp.activate(ignoringOtherApps: true)

        let view = RecoveryPreviewView(
            plan: plan,
            onApply: { [weak self] text in
                self?.applyRecovery(text)
            },
            onCopy: { [weak self] text in
                guard let self = self else { return }
                self.accessibilityService.copyToPasteboard(text)
                self.closeRecoveryPreview()
                self.restorationAfterRecovery(action: .collapse)
                self.resetRecoveryState()
            },
            onRevert: { [weak self] in
                self?.revertRecovery()
            },
            onCancel: { [weak self] in
                guard let self = self else { return }
                self.closeRecoveryPreview()
                self.restorationAfterRecovery(action: .collapse)
                self.resetRecoveryState()
            }
        )
        .environmentObject(l10n)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = l10n.t("recovery.title")
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        recoveryPreviewWindow = window
    }

    /// Paste the chosen reconstruction into the app the line came from.
    private func applyRecovery(_ text: String) {
        let original = recoveryOriginalText
        let target = recoveryPlan?.primaryTargetLayoutID
        closeRecoveryPreview()
        restorationAfterRecovery(action: .paste(text))

        settingsManager.incrementConversionCount()
        settingsManager.recoveryCount += 1
        logConversion(input: original, output: text, mode: "recover")
        switchLayoutIfNeeded(targetLayoutID: target, conversionOccurred: true)
        playFeedback()
        showConversionNotification(input: original, output: text)
        resetRecoveryState()
    }

    /// Undo: keep the original text and teach the personal dictionary so it is
    /// never rewritten again (the idea document's undo loop).
    private func revertRecovery() {
        let original = recoveryOriginalText
        closeRecoveryPreview()
        restorationAfterRecovery(action: .collapse)

        if let original = original {
            let learned = UserDictionary.shared.learnWords(in: original)
            NSLog("[LangSwitcher] revertRecovery: learned words=\(learned)")
        }
        settingsManager.recoveryRevertCount += 1
        resetRecoveryState()
    }

    private enum RecoveryRestoration {
        case paste(String)
        case collapse
    }

    /// Put the target app back in front and finish the interaction there. The
    /// selection made when the preview opened is still active, so pasting
    /// replaces exactly the decoded line.
    private func restorationAfterRecovery(action: RecoveryRestoration) {
        guard let target = recoveryTargetApp else { return }
        target.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            switch action {
            case .paste(let text):
                self.accessibilityService.pasteReplacingSelection(text)
            case .collapse:
                self.accessibilityService.collapseSelection()
            }
        }
    }

    private func closeRecoveryPreview() {
        recoveryPreviewWindow?.orderOut(nil)
        recoveryPreviewWindow = nil
    }

    private func resetRecoveryState() {
        recoveryTargetApp = nil
        recoveryOriginalText = nil
        recoveryPlan = nil
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
