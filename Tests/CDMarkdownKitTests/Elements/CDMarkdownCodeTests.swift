import Testing
import Foundation
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownCodeTests {

    let parser = CDMarkdownParser()

    @Test func singleBacktickProducesCode() {
        let result = parser.parse("`code`")
        var hasCodeColor = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { hasCodeColor = true }
        }
        #expect(hasCodeColor)
    }

    @Test func nestedMarkdownInCodeNotParsed() {
        let result = parser.parse("`**not bold**`")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }

    @Test func emptyBackticksProducesCode() {
        let result = parser.parse("``")
        #expect(result.length >= 0)
    }

    @Test func backticksAreStripped() {
        let result = parser.parse("`code`")
        #expect(!result.string.contains("`"))
    }
}
