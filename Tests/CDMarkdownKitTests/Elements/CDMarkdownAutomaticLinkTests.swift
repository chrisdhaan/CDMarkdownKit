import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownAutomaticLinkTests {

    let parser = CDMarkdownParser()

    // CDMarkdownAutomaticLink uses NSDataDetector, which is unavailable on watchOS.
    // On watchOS the element returns an empty regex and matches nothing.
    #if !os(watchOS)

        @Test func bareHttpsUrlProducesLink() async {
            // Given
            let input = "https://example.com"
            // When
            let result = await parser.parse(input)
            // Then
            var foundLink = false
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if v != nil {
                    foundLink = true
                }
            }
            #expect(foundLink)
        }

        @Test func bareHttpUrlProducesLink() async {
            // Given
            let input = "http://example.com"
            // When
            let result = await parser.parse(input)
            // Then
            var foundLink = false
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if v != nil {
                    foundLink = true
                }
            }
            #expect(foundLink)
        }

        @Test func urlEmbeddedInTextProducesLink() async {
            // Given
            let input = "Visit https://example.com for more info"
            // When
            let result = await parser.parse(input)
            // Then
            var foundLink = false
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if v != nil {
                    foundLink = true
                }
            }
            #expect(foundLink)
        }

        @Test func plainTextHasNoAutoLink() async {
            // Given
            let input = "Hello, world. No URL here."
            // When
            let result = await parser.parse(input)
            // Then
            var foundLink = false
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if v != nil {
                    foundLink = true
                }
            }
            #expect(!foundLink)
        }

        @Test func urlTextIsPreservedInString() async {
            // Unlike [text](url) links where the syntax is stripped, bare URLs remain
            // visible in the output string — only the .link attribute is added.
            // Given
            let input = "https://example.com"
            // When
            let result = await parser.parse(input)
            // Then
            #expect(result.string.contains("example.com"))
        }

    #endif
}
