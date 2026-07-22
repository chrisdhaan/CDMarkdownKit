import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownSquashNewlinesTests {

    @Test func defaultSquashNewlinesIsTrue() {
        let parser = CDMarkdownParser()
        #expect(parser.squashNewlines == true)
    }

    @Test func squashNewlinesTrueCollapsesConsecutiveNewlines() {
        // Given: two newlines between paragraphs
        let parser = CDMarkdownParser()
        // squashNewlines defaults to true
        let input = "first\n\nsecond"
        // When
        let result = parser.parse(input)
        // Then: no run of two or more consecutive newlines in the output
        let hasConsecutiveNewlines = result.string.contains("\n\n")
        #expect(!hasConsecutiveNewlines)
        // And: both words survive
        #expect(result.string.contains("first"))
        #expect(result.string.contains("second"))
    }

    @Test func squashNewlinesCollapsesCRLFBlankLines() {
        let parser = CDMarkdownParser()
        parser.squashNewlines = true
        let result = parser.parse("Line1\r\n\r\n\r\nLine2")
        // Note: "\r\n\r\n\r\n" never contains a bare "\n\n" substring (each \n is preceded
        // by \r), so that check alone can't distinguish squashed from unsquashed CRLF runs.
        // Assert the CRLF run actually collapsed to a single "\n" instead.
        #expect(!result.string.contains("\n\n"))
        #expect(!result.string.contains("\r"))
        #expect(result.string.contains("Line1\nLine2"))
    }

    @Test func squashNewlinesFalsePropertyRoundtrips() {
        // Verify the property can be toggled off
        let parser = CDMarkdownParser()
        parser.squashNewlines = false
        #expect(parser.squashNewlines == false)
    }

    @Test func squashNewlinesTrueDoesNotAffectSingleNewlines() {
        // A single \n between lines must be preserved
        let parser = CDMarkdownParser()
        let input = "line one\nline two"
        let result = parser.parse(input)
        #expect(result.string.contains("\n"))
    }

    @Test func squashNewlinesFalsePreservesConsecutiveNewlines() {
        // When squashNewlines is disabled, \n\n must survive into the output
        let parser = CDMarkdownParser()
        parser.squashNewlines = false
        let input = "first\n\nsecond"
        let result = parser.parse(input)
        #expect(result.string.contains("\n\n"))
    }
}
