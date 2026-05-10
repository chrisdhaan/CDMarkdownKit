import Testing
import Foundation
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownAutomaticLinkTests {

    let parser = CDMarkdownParser()

    // CDMarkdownAutomaticLink uses NSDataDetector, which is unavailable on watchOS.
    // On watchOS the element returns an empty regex and matches nothing.
    #if !os(watchOS)

    @Test func bareHttpsUrlProducesLink() {
        // Given
        let input = "https://example.com"
        // When
        let result = parser.parse(input)
        // Then
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(foundLink)
    }

    @Test func bareHttpUrlProducesLink() {
        // Given
        let input = "http://example.com"
        // When
        let result = parser.parse(input)
        // Then
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(foundLink)
    }

    @Test func urlEmbeddedInTextProducesLink() {
        // Given
        let input = "Visit https://example.com for more info"
        // When
        let result = parser.parse(input)
        // Then
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(foundLink)
    }

    @Test func plainTextHasNoAutoLink() {
        // Given
        let input = "Hello, world. No URL here."
        // When
        let result = parser.parse(input)
        // Then
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(!foundLink)
    }

    @Test func urlTextIsPreservedInString() {
        // Unlike [text](url) links where the syntax is stripped, bare URLs remain
        // visible in the output string — only the .link attribute is added.
        // Given
        let input = "https://example.com"
        // When
        let result = parser.parse(input)
        // Then
        #expect(result.string.contains("example.com"))
    }

    #endif
}
