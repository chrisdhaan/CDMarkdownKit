import Testing
import Foundation
@testable import CDMarkdownKit

#if os(iOS) || os(macOS) || os(tvOS)

@MainActor
@Suite struct CDMarkdownImageTests {

    let parser = CDMarkdownParser()

    @Test func exclamationBracketIsImage() {
        // ![alt](url) should be matched as an image, not a link
        let result = parser.parse("![alt](https://example.com/image.png)")
        // Image syntax should be consumed (no raw markdown left)
        #expect(!result.string.contains("!["))
    }

    @Test func curlyBracketIsNotImage() {
        // {[alt](url) should NOT be treated as an image (was matched by old buggy [!{1}] regex)
        let result = parser.parse("{[text](https://example.com)")
        // The { character should remain in the output unchanged
        #expect(result.string.contains("{"))
    }

    @Test func digitBracketIsNotImage() {
        // 1[alt](url) should NOT be treated as an image (was matched by old buggy [!{1}] regex)
        let result = parser.parse("1[text](https://example.com)")
        // The digit should remain
        #expect(result.string.contains("1"))
    }

    @Test func imageAndLinkAreDistinct() {
        // A link immediately after an image syntax should parse independently
        let result = parser.parse("![img](https://example.com/img.png) and [link](https://example.com)")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(foundLink)
    }
}

#endif
