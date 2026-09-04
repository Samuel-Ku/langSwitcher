import XCTest
import Cocoa
@testable import LangSwitcher

final class HotkeyManagerTests: XCTestCase {
    
    // MARK: - isPlainSpaceEvent (Issue #4: automatic correction on Space)
    //
    // The Space flow must trigger only on a plain word-separating Space:
    // no Command/Option/Control modifiers (⌘Space = Spotlight, ⌥Space = NBSP,
    // ⌃Space = input switcher) and no key-repeat events from a held Space.
    
    func testPlainSpaceTriggers() {
        XCTAssertTrue(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x31, modifierFlags: [], isRepeat: false))
    }
    
    func testSpaceWithShiftStillTriggers() {
        // Shift+Space still inserts a word separator in most apps
        XCTAssertTrue(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x31, modifierFlags: .shift, isRepeat: false))
    }
    
    func testSpaceWithCommandIgnored() {
        XCTAssertFalse(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x31, modifierFlags: .command, isRepeat: false))
    }
    
    func testSpaceWithOptionIgnored() {
        // Option+Space types a non-breaking space — not a word boundary
        XCTAssertFalse(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x31, modifierFlags: .option, isRepeat: false))
    }
    
    func testSpaceWithControlIgnored() {
        XCTAssertFalse(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x31, modifierFlags: .control, isRepeat: false))
    }
    
    func testSpaceRepeatIgnored() {
        XCTAssertFalse(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x31, modifierFlags: [], isRepeat: true))
    }
    
    func testReturnIsNotSpace() {
        XCTAssertFalse(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x24, modifierFlags: [], isRepeat: false))
    }
    
    func testOtherKeyIsNotSpace() {
        XCTAssertFalse(HotkeyManager.isPlainSpaceEvent(
            keyCode: 0x00, modifierFlags: [], isRepeat: false))
    }
}
