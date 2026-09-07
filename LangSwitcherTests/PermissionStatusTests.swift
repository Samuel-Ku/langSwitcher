import XCTest
@testable import LangSwitcher

final class PermissionStatusTests: XCTestCase {

    // MARK: - computed (Issue #8: permissions and cross-app verification)

    func testBothGranted() {
        let status = PermissionStatus(
            accessibilityGranted: true,
            inputMonitoringGranted: true
        )
        XCTAssertTrue(status.isFullyGranted)
        XCTAssertNil(status.firstMissing)
    }

    func testAccessibilityMissing() {
        let status = PermissionStatus(
            accessibilityGranted: false,
            inputMonitoringGranted: true
        )
        XCTAssertFalse(status.isFullyGranted)
        XCTAssertEqual(status.firstMissing, .accessibility)
    }

    func testInputMonitoringMissing() {
        let status = PermissionStatus(
            accessibilityGranted: true,
            inputMonitoringGranted: false
        )
        XCTAssertFalse(status.isFullyGranted)
        XCTAssertEqual(status.firstMissing, .inputMonitoring)
    }

    func testBothMissingReportsAccessibilityFirst() {
        let status = PermissionStatus(
            accessibilityGranted: false,
            inputMonitoringGranted: false
        )
        XCTAssertEqual(status.firstMissing, .accessibility)
    }

    func testIsGrantedPerKind() {
        let status = PermissionStatus(
            accessibilityGranted: false,
            inputMonitoringGranted: true
        )
        XCTAssertFalse(status.isGranted(.accessibility))
        XCTAssertTrue(status.isGranted(.inputMonitoring))
    }

    func testEquatable() {
        XCTAssertEqual(
            PermissionStatus(accessibilityGranted: true, inputMonitoringGranted: false),
            PermissionStatus(accessibilityGranted: true, inputMonitoringGranted: false))
        XCTAssertNotEqual(
            PermissionStatus(accessibilityGranted: true, inputMonitoringGranted: false),
            PermissionStatus(accessibilityGranted: true, inputMonitoringGranted: true))
    }

    // MARK: - PermissionKind

    func testPermissionKindCases() {
        // Order matters for the UI: accessibility first (primary requirement)
        XCTAssertEqual(PermissionKind.allCases, [.accessibility, .inputMonitoring])
    }
}
