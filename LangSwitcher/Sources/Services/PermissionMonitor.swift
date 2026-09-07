import Foundation
import AppKit
import ApplicationServices
import IOKit
import IOKit.hid

// MARK: - Permission Status (Issue #8)
// Pure model describing what LangSwitcher is allowed to do, plus a thin
// service that observes the real system state. Policy lives here; the
// service only queries.

/// The two TCC permissions LangSwitcher depends on.
enum PermissionKind: CaseIterable {
    /// Accessibility — reading the focused element and simulating ⌘C/⌘V.
    case accessibility
    /// Input Monitoring — global NSEvent monitors used for hotkeys.
    case inputMonitoring
}

/// Snapshot of both permission grants. Pure value: UI and logging compare
/// and render it; nothing here talks to TCC directly.
struct PermissionStatus: Equatable {
    let accessibilityGranted: Bool
    let inputMonitoringGranted: Bool

    /// All required permissions granted.
    var isFullyGranted: Bool {
        accessibilityGranted && inputMonitoringGranted
    }

    /// First missing permission, in UI priority order (Accessibility is
    /// the primary requirement; Input Monitoring only degrades hotkeys).
    var firstMissing: PermissionKind? {
        if !accessibilityGranted { return .accessibility }
        if !inputMonitoringGranted { return .inputMonitoring }
        return nil
    }
}

// MARK: - Permission Monitor

/// Observes the real permission state and publishes it for SwiftUI.
/// Polls on a timer because macOS posts no notification when the user
/// toggles TCC grants; the interval is deliberately lazy (2s) — the UI
/// only needs to converge shortly after the user flips a switch.
@MainActor
final class PermissionMonitor: ObservableObject {

    @Published private(set) var status: PermissionStatus

    private let pollInterval: TimeInterval
    private var timer: Timer?
    private var lastLoggedStatus: PermissionStatus?

    /// Injectable probe for tests; production default queries the system.
    private let probe: () -> PermissionStatus

    init(
        pollInterval: TimeInterval = 2.0,
        probe: (() -> PermissionStatus)? = nil
    ) {
        self.pollInterval = pollInterval
        // MainActor-isolated default; captured here on the main actor
        self.probe = probe ?? Self.systemProbe
        self.status = self.probe()
    }

    deinit {
        timer?.invalidate()
    }

    /// Re-query the system immediately (e.g. "Refresh Status" button).
    func refresh() {
        apply(probe())
    }

    /// Start periodic polling. Safe to call repeatedly.
    func startPolling() {
        guard timer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
            }
        }
        self.timer = timer
    }

    /// Stop periodic polling (e.g. window closed).
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func apply(_ newStatus: PermissionStatus) {
        guard newStatus != status else { return }
        NSLog("[LangSwitcher] Permission status changed: \(status) -> \(newStatus)")
        status = newStatus
    }

    // MARK: - System probes

    /// Production probe. Cheap enough to call every 2 seconds:
    /// AXIsProcessTrusted is a local check; IOHIDCheckAccess is an in-process
    /// request with kIOHIDRequestTypeListenEvent (does not prompt).
    @MainActor static let systemProbe: () -> PermissionStatus = {
        PermissionStatus(
            accessibilityGranted: AccessibilityService.hasAccessibilityPermission,
            inputMonitoringGranted: hasInputMonitoringPermission()
        )
    }

    /// Input Monitoring (TCC kTCCServiceListenEvent). IOHIDCheckAccess only
    /// reports the current grant — it never shows a prompt.
    static func hasInputMonitoringPermission() -> Bool {
        IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    }
}
