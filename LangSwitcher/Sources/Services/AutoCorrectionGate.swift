import Foundation

// MARK: - Auto-Correction Gate (Issue #6)
// Pure policy: where the silent Space auto-correction may run.
// Secure fields and unknown focus fail closed (deny).

enum AutoCorrectionGate {
    
    /// Roles the auto-correction may touch. Deliberately narrow: Space on
    /// any other focused control (a button, a menu) must never hijack
    /// the selection.
    static let textInputRoles: Set<String> = ["AXTextField", "AXTextArea"]
    
    /// Accessibility identifier marking a password field — appears either
    /// as the role itself or, Safari-style, as the subrole of an AXTextField.
    static let secureIdentifier = "AXSecureTextField"
    
    /// Apps where silent rewriting is dangerous even in plain fields
    /// (shell commands must never be reinterpreted as prose).
    /// No editor UI yet — extend here until #8 surfaces the list.
    static let defaultExcludedBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
    ]
    
    /// True for password fields, via role or subrole.
    static func isSecureField(role: String?, subrole: String?) -> Bool {
        role == secureIdentifier || subrole == secureIdentifier
    }
    
    /// Combined rule for the automatic flow. Manual hotkey conversion
    /// (explicit user intent) bypasses this gate entirely.
    static func allowsAutoCorrection(
        role: String?,
        subrole: String?,
        bundleID: String?,
        excludedBundleIDs: Set<String> = defaultExcludedBundleIDs
    ) -> Bool {
        // Unknown focus (no AX permission, unreadable UI) fails closed
        guard let role, textInputRoles.contains(role) else { return false }
        guard !isSecureField(role: role, subrole: subrole) else { return false }
        // Unknown app is transient (AX already proved readable) — allow
        if let bundleID, excludedBundleIDs.contains(bundleID) { return false }
        return true
    }
}
