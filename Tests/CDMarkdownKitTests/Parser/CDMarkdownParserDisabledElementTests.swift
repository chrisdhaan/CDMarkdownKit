import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownParserDisabledElementTests {

    @Test func disabledHeaderProducesNoLargeFont() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownHeader.self)
        let result = parser.parse("# Heading")
        var foundLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize > 17 { foundLargeFont = true }
        }
        #expect(!foundLargeFont)
        #expect(result.string.contains("#"))
    }

    @Test func disabledBoldProducesNoBold() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownBold.self)
        let result = parser.parse("**bold**")
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(!foundBold)
    }

    @Test func reenablingElementRestoresBehavior() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownBold.self)
        parser.enable(CDMarkdownBold.self)
        let result = parser.parse("**bold**")
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(foundBold)
    }

    @Test func disablingNonexistentTypeIsNoop() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownOrderedList.self)
        parser.disable(CDMarkdownOrderedList.self)
        let result = parser.parse("1. Item")
        #expect(result.string.contains("1."))
    }
}
