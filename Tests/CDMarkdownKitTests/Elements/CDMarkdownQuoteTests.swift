import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownQuoteTests {

    let parser = CDMarkdownParser()

    @Test func greaterThanProducesBlockquote() async {
        let result = await parser.parse("> quote")
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

    @Test func multipleQuoteLevels() async {
        let result = await parser.parse("> level 1\n>> level 2")
        #expect(result.length > 0)
    }

    @Test func quoteMarkerIsReplaced() async {
        // A level-2 quote's raw ">>" marker run is collapsed into a single separator
        // plus indicator ("  > "), so the rendered text no longer starts with the raw
        // two-character ">>" marker.
        let result = await parser.parse(">> quote")
        #expect(!result.string.hasPrefix(">>"))
    }

    @Test func topLevelQuoteHasNoExtraIndentPrefix() async {
        let parser = CDMarkdownParser()
        let result = await parser.parse("> quote")
        #expect(result.string == "> quote")
    }

    @Test func indentedQuoteStillRecognizedAlongsideFlushLeftText() async {
        // Under the dedent-based whitespace handling, a document containing at least one
        // flush-left line leaves other lines' indentation untouched -- including indentation
        // in front of a blockquote marker. The quote regex must still match it.
        let result = await parser.parse("Text\n  > quoted line")
        var foundQuote = false
        result.enumerateAttribute(.cdMarkdownIsBlockquote, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                foundQuote = true
            }
        }
        #expect(foundQuote)
    }

    @Test func nestedMarkdownInQuoteWorks() async {
        let result = await parser.parse("> **bold** quote")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(hasBold)
    }
}
