import XCTest
@testable import LangSwitcher

final class CrossAppVerificationTests: XCTestCase {

    // MARK: - support(for:) (Issue #8: cross-app verification)

    func testTerminalIsKnownLimited() {
        XCTAssertEqual(
            CrossAppVerification.support(for: "com.apple.Terminal"),
            .limited)
    }

    func testITermIsKnownLimited() {
        XCTAssertEqual(
            CrossAppVerification.support(for: "com.googlecode.iterm2"),
            .limited)
    }

    func testUnknownAppIsFullSupport() {
        XCTAssertEqual(
            CrossAppVerification.support(for: "com.example.editor"),
            .full)
    }

    func testNilBundleIDIsUnverifiable() {
        // No frontmost app or unreadable bundle — cannot verify
        XCTAssertNil(CrossAppVerification.statusKey(for: nil))
        XCTAssertEqual(
            CrossAppVerification.support(for: nil),
            .unverifiable)
    }

    // MARK: - statusKey(for:)

    func testStatusKeys() {
        XCTAssertEqual(
            CrossAppVerification.statusKey(for: "com.apple.Terminal"),
            "permissions.crossAppLimited")
        XCTAssertEqual(
            CrossAppVerification.statusKey(for: "com.example.editor"),
            "permissions.crossAppFull")
        XCTAssertNil(CrossAppVerification.statusKey(for: nil))
    }

    // MARK: - FrontmostApp

    func testFrontmostAppEquatable() {
        XCTAssertEqual(
            FrontmostApp(bundleID: "a", localizedName: "A"),
            FrontmostApp(bundleID: "a", localizedName: "A"))
        XCTAssertNotEqual(
            FrontmostApp(bundleID: "a", localizedName: "A"),
            FrontmostApp(bundleID: "b", localizedName: "A"))
    }

    func testFrontmostAppDisplayNameFallsBack() {
        XCTAssertEqual(
            FrontmostApp(bundleID: "com.example.x", localizedName: "X").displayName,
            "X")
        XCTAssertEqual(
            FrontmostApp(bundleID: "com.example.x", localizedName: nil).displayName,
            "com.example.x")
        XCTAssertEqual(
            FrontmostApp(bundleID: nil, localizedName: nil).displayName,
            "—")
    }
}
