import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var l10n: LocalizationManager
    // Issue #8: live permission status for both TCC grants, auto-refreshed
    // while the tab is visible — no more manual "Refresh Status" guessing.
    @StateObject private var monitor: PermissionMonitor

    init() {
        _monitor = StateObject(wrappedValue: PermissionMonitor())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(l10n.t("permissions.title"))
                .font(.headline)

            Text(l10n.t("permissions.description"))
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(PermissionKind.allCases, id: \.self) { kind in
                permissionRow(kind)
            }

            if let missing = monitor.status.firstMissing {
                howToFix(missing)
            }

            Spacer()
        }
        .padding()
        .onAppear { monitor.startPolling() }
        .onDisappear { monitor.stopPolling() }
    }

    // MARK: - Rows

    @ViewBuilder
    private func permissionRow(_ kind: PermissionKind) -> some View {
        let granted: Bool = {
            switch kind {
            case .accessibility: return monitor.status.accessibilityGranted
            case .inputMonitoring: return monitor.status.inputMonitoringGranted
            }
        }()

        GroupBox {
            HStack {
                Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(granted ? .green : .orange)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(l10n.t(kind == .accessibility
                        ? "permissions.accessibilityTitle"
                        : "permissions.inputMonitoringTitle"))
                        .font(.body)
                        .bold()
                    Text(l10n.t(granted
                        ? (kind == .accessibility
                            ? "permissions.granted"
                            : "permissions.inputMonitoringGranted")
                        : (kind == .accessibility
                            ? "permissions.notGranted"
                            : "permissions.inputMonitoringNotGranted")))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !granted {
                    Button(l10n.t("permissions.grantAccess")) {
                        openSystemSettings(for: kind)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(4)
        }

        if !granted, kind == .accessibility {
            // Keep the original step-by-step guidance for Accessibility —
            // it is the permission users struggle with most.
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text(l10n.t("permissions.howToEnable"))
                        .font(.subheadline)
                        .bold()

                    Text(l10n.t("permissions.step1"))
                    Text(l10n.t("permissions.step2"))
                    Text(l10n.t("permissions.step3"))
                    Text(l10n.t("permissions.step4"))
                }
                .font(.caption)
                .padding(4)
            }
        }
    }

    @ViewBuilder
    private func howToFix(_ kind: PermissionKind) -> some View {
        Button(l10n.t("permissions.openSettings")) {
            openSystemSettings(for: kind)
        }
    }

    // MARK: - Navigation

    private func openSystemSettings(for kind: PermissionKind) {
        let pane: String = {
            switch kind {
            case .accessibility:
                return "com.apple.preference.security?Privacy_Accessibility"
            case .inputMonitoring:
                return "com.apple.preference.security?Privacy_ListenEvent"
            }
        }()
        if let url = URL(string: "x-apple.systempreferences:\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}
