import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownParserInsertionTests {

    @Test func insertBeforeKnownElementPositionsCorrectly() async {
        let parser = CDMarkdownParser()
        let noOpElement = CDMarkdownBold()
        parser.insertCustomElement(noOpElement, before: CDMarkdownItalic.self)
        let result = await parser.parse("**bold**")
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold {
                foundBold = true
            }
        }
        #expect(foundBold)
    }

    @Test func insertBeforeUnknownElementFallsBackToAppend() {
        let parser = CDMarkdownParser()
        class UnknownElement: CDMarkdownBold, @unchecked Sendable {}
        let element = CDMarkdownBold()
        let countBefore = parser.customElements.count
        parser.insertCustomElement(element, before: UnknownElement.self)
        #expect(parser.customElements.count == countBefore + 1)
    }

    @Test func insertAfterKnownElementPositionsCorrectly() async {
        let parser = CDMarkdownParser()
        let noOpElement = CDMarkdownBold()
        parser.insertCustomElement(noOpElement, after: CDMarkdownHeader.self)
        let result = await parser.parse("# Heading")
        var foundHeading = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize > 17 {
                foundHeading = true
            }
        }
        #expect(foundHeading)
    }

    @Test func insertAfterUnknownElementFallsBackToAppend() {
        let parser = CDMarkdownParser()
        class UnknownElement: CDMarkdownBold, @unchecked Sendable {}
        let element = CDMarkdownBold()
        let countBefore = parser.customElements.count
        parser.insertCustomElement(element, after: UnknownElement.self)
        #expect(parser.customElements.count == countBefore + 1)
    }
}
