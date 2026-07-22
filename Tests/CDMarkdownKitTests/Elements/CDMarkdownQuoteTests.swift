import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownQuoteTests {

    let parser = CDMarkdownParser()

    @Test func greaterThanProducesBlockquote() {
        let result = parser.parse("> quote")
        // Blockquote should be recognized and tagged with the blockquote attribute.
        // (Note: a level-1 blockquote's rendered text legitimately still starts with
        // ">" -- that's the indicator character reused as-is from the raw syntax -- so
        // checking for the presence of the parsed attribute is the meaningful signal here,
        // not the leading character of the string.)
        var foundQuote = false
        result.enumerateAttribute(.cdMarkdownIsBlockquote, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                foundQuote = true
            }
        }
        #expect(foundQuote)
    }

    @Test func multipleQuoteLevels() {
        let result = parser.parse("> level 1\n>> level 2")
        #expect(result.length > 0)
    }

    @Test func quoteMarkerIsReplaced() {
        // A level-2 quote's raw ">>" marker run is collapsed into a single separator
        // plus indicator ("  > "), so the rendered text no longer starts with the raw
        // two-character ">>" marker.
        let result = parser.parse(">> quote")
        #expect(!result.string.hasPrefix(">>"))
    }

    @Test func topLevelQuoteHasNoExtraIndentPrefix() {
        let parser = CDMarkdownParser()
        let result = parser.parse("> quote")
        #expect(result.string == "> quote")
    }

    @Test func nestedMarkdownInQuoteWorks() {
        let result = parser.parse("> **bold** quote")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(hasBold)
    }
}
