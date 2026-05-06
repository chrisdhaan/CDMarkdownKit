import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownHeaderTests {

    let parser = CDMarkdownParser()

    @Test func hashProducesH1() {
        let result = parser.parse("# Heading 1")
        var hasLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.pointSize > 17 { hasLargeFont = true }
        }
        #expect(hasLargeFont)
    }

    @Test func doubleHashProducesH2() {
        let result = parser.parse("## Heading 2")
        var hasLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.pointSize > 15 { hasLargeFont = true }
        }
        #expect(hasLargeFont)
    }

    @Test func tripleHashProducesH3() {
        let result = parser.parse("### Heading 3")
        var hasLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.pointSize > 13 { hasLargeFont = true }
        }
        #expect(hasLargeFont)
    }

    @Test func hashWithoutSpaceIsNotHeader() {
        let result = parser.parse("#NoSpace")
        var hasLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.pointSize > 17 { hasLargeFont = true }
        }
        #expect(!hasLargeFont)
    }

    @Test func headerHashIsStripped() {
        let result = parser.parse("# Heading")
        #expect(!result.string.hasPrefix("#"))
    }
}
