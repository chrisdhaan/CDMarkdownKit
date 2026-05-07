import Testing
import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownQuoteTests {

    let parser = CDMarkdownParser()

    @Test func greaterThanProducesBlockquote() {
        let result = parser.parse("> quote")
        // Blockquote should be parsed and marker replaced
        #expect(!result.string.hasPrefix(">"))
    }

    @Test func multipleQuoteLevels() {
        let result = parser.parse("> level 1\n>> level 2")
        #expect(result.length > 0)
    }

    @Test func quoteMarkerIsReplaced() {
        let result = parser.parse("> quote")
        #expect(!result.string.hasPrefix(">"))
    }

    @Test func nestedMarkdownInQuoteWorks() {
        let result = parser.parse("> **bold** quote")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(hasBold)
    }
}
