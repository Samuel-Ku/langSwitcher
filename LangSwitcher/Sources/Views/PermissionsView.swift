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

            crossAppSection

            Spacer()
        }
        .padding()
        .onAppear { monitor.startPolling() }
        .onDisappear { monitor.stopPolling() }
    }

    // MARK: - Cross-App Verification (Issue #8)

    /// Live view of the frontmost app and how well conversion is expected
    /// to work there — lets the user tell a permission problem from an
    /// app limitation. Refreshes with the same poll as the permissions.
    @ViewBuilder
    private var crossAppSection: some View {
        let app = FrontmostAppProbe.current

        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(l10n.t("permissions.crossAppTitle"))
                    .font(.subheadline)
                    .bold()

                HStack {
                    Text(l10n.t("permissions.crossAppFrontmost"))
                    Spacer()
                    Text(app.displayName)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)

                if let key = CrossAppVerification.statusKey(for: app.bundleID) {
                    Label(l10n.t(key), systemImage: appSupportIcon(app.bundleID))
                        .font(.caption)
                        .foregroundStyle(appSupportColor(app.bundleID))
                }
            }
            .padding(4)
        }
    }

    private func appSupportIcon(_ bundleID: String?) -> String {
        switch CrossAppVerification.support(for: bundleID) {
        case .full: return "checkmark.circle"
        case .limited: return "exclamationmark.triangle"
        case .unverifiable: return "questionmark.circle"
        }
    }

    private func appSupportColor(_ bundleID: String?) -> Color {
        switch CrossAppVerification.support(for: bundleID) {
        case .full: return .green
        case .limited: return .orange
        case .unverifiable: return .secondary
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func permissionRow(_ kind: PermissionKind) -> some View {
        let granted = monitor.status.isGranted(kind)

        GroupBox {
            HStack {
                Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(granted ? .green : .orange)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(l10n.t(kind.titleKey))
                        .font(.body)
                        .bold()
                    Text(l10n.t(granted ? kind.grantedKey : kind.missingKey))
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
        if let url = URL(string: "x-apple.systempreferences:\(kind.settingsPane)") {
            NSWorkspace.shared.open(url)
        }
    }
}
