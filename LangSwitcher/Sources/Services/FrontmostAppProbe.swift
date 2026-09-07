import Foundation
import AppKit

// MARK: - Frontmost App Probe (Issue #8)
//
// Thin AppKit glue for the cross-app verification UI. Policy lives in
// CrossAppVerification; this only asks NSWorkspace who is frontmost.

enum FrontmostAppProbe {

    /// The app currently receiving keystrokes, or nil when there is no
    /// frontmost GUI app (headless contexts, transient states).
    @MainActor static var current: FrontmostApp {
        let app = NSWorkspace.shared.frontmostApplication
        return FrontmostApp(
            bundleID: app?.bundleIdentifier,
            localizedName: app?.localizedName
        )
    }
}
