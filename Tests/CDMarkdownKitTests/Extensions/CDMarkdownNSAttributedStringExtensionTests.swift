import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownNSAttributedStringExtensionTests {

    @Test func enumerateLinkAttributeFindsLink() {
        // Given: a parsed attributed string with a link
        let parser = CDMarkdownParser()
        let result = parser.parse("[GitHub](https://github.com)")
        // When: using the internal enumerateLinkAttribute helper
        var foundLink = false
        result.enumerateLinkAttribute(in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundLink = true }
        }
        // Then
        #expect(foundLink)
    }

    @Test func enumerateLinkAttributeOnPlainTextFindsNothing() {
        // Given: plain attributed string with no link attribute
        let plain = NSAttributedString(string: "no links here")
        // When
        var foundLink = false
        plain.enumerateLinkAttribute(in: NSRange(location: 0, length: plain.length)) { value, _, _ in
            if value != nil { foundLink = true }
        }
        // Then
        #expect(!foundLink)
    }

    @Test func enumerateLinkAttributeReturnsURL() {
        // Verify the value yielded by the enumerator is a URL (not just non-nil)
        let parser = CDMarkdownParser()
        let result = parser.parse("[Docs](https://example.com)")
        var foundURL = false
        result.enumerateLinkAttribute(in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value is URL { foundURL = true }
        }
        #expect(foundURL)
    }
}
