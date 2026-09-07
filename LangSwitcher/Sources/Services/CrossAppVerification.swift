import Foundation
import AppKit

// MARK: - Cross-App Verification (Issue #8)
//
// Pure policy: what LangSwitcher can expect when the user presses the
// hotkey in a given application. Terminals are known-limited because the
// clipboard round-trip rewrites command lines; most other apps are fine.
// The UI surfaces this in the Permissions tab so the user can tell whether
// a failure is a permission problem or an app limitation.

/// How well text conversion is expected to work in an app.
enum CrossAppSupport: Equatable {
    /// No known limitation.
    case full
    /// Known limitation — conversion may not work or may misbehave.
    case limited
    /// Support cannot be determined (no frontmost app / unreadable bundle).
    case unverifiable
}

/// The app currently receiving keystrokes, as far as we can tell.
struct FrontmostApp: Equatable {
    let bundleID: String?
    let localizedName: String?

    /// Name shown to the user; falls back to bundle ID, then a dash.
    var displayName: String {
        localizedName ?? bundleID ?? "—"
    }
}

enum CrossAppVerification {

    /// Apps where clipboard-based conversion is known to be limited.
    /// Kept separate from AutoCorrectionGate.defaultExcludedBundleIDs:
    /// that list gates *silent* rewriting (must never touch terminals),
    /// while this one only informs the user that manual conversion there
    /// is unreliable. Extend here as reports come in.
    static let knownLimitedBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
    ]

    /// Expected support level for a bundle ID.
    static func support(for bundleID: String?) -> CrossAppSupport {
        guard let bundleID else { return .unverifiable }
        if knownLimitedBundleIDs.contains(bundleID) {
            return .limited
        }
        return .full
    }

    /// Localization key describing the support level, or nil when
    /// unverifiable (the UI omits the line entirely in that case).
    static func statusKey(for bundleID: String?) -> String? {
        switch support(for: bundleID) {
        case .full: return "permissions.crossAppFull"
        case .limited: return "permissions.crossAppLimited"
        case .unverifiable: return nil
        }
    }
}
