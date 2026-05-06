import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownQuoteTests {

    let parser = CDMarkdownParser()

    @Test func greaterThanProducesBlockquote() {
        let result = parser.parse("> quote")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 { hasHeadIndent = true }
        }
        #expect(hasHeadIndent)
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
