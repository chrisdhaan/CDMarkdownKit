import Foundation
import Testing
@testable import CDMarkdownKit

#if os(iOS) || os(macOS) || os(tvOS)

    @MainActor
    struct CDMarkdownImageTests {

        let parser = CDMarkdownParser()

        @Test func exclamationBracketIsImage() async {
            // ![alt](url) should be matched as an image, not a link
            let result = await parser.parse("![alt](https://example.com/image.png)")
            // Image syntax should be consumed (no raw markdown left)
            #expect(!result.string.contains("!["))
        }

        @Test func curlyBracketIsNotImage() async {
            // {[alt](url) should NOT be treated as an image (was matched by old buggy [!{1}] regex)
            let result = await parser.parse("{[text](https://example.com)")
            // The { character should remain in the output unchanged
            #expect(result.string.contains("{"))
        }

        @Test func digitBracketIsNotImage() async {
            // 1[alt](url) should NOT be treated as an image (was matched by old buggy [!{1}] regex)
            let result = await parser.parse("1[text](https://example.com)")
            // The digit should remain
            #expect(result.string.contains("1"))
        }

        @Test func imageAndLinkAreDistinct() async {
            // A link immediately after an image syntax should parse independently
            let result = await parser.parse("![img](https://example.com/img.png) and [link](https://example.com)")
            var foundLink = false
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if v != nil {
                    foundLink = true
                }
            }
            #expect(foundLink)
        }

        @Test func imageURLContainingParenthesesIsNotCorrupted() async {
            let parser = CDMarkdownParser()
            let result = await parser.parse("![alt](http://example.com/foo(bar))")
            var linkURL: URL?
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                if let url = value as? URL {
                    linkURL = url
                }
            }
            #expect(linkURL?.absoluteString.hasPrefix("http://example.com/foo(bar") == true)
        }

        @Test func imageAttachmentReceivesLinkAttribute() async {
            let parser = CDMarkdownParser()
            let result = await parser.parse("![alt](http://example.com/image.png)")
            var foundLink = false
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, range, _ in
                if value is URL, range.length > 0 {
                    foundLink = true
                }
            }
            #expect(foundLink)
        }
    }

#endif
