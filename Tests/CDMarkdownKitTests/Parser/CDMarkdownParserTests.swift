import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownParserTests {

    let parser = CDMarkdownParser()

    @Test func parseBoldText() {
        // Given
        let input = "Hello **world**"
        // When
        let result = parser.parse(input)
        // Then
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let font = value as? CDFont, font.isBold, range.location == 6 {
                foundBold = true
            }
        }
        #expect(foundBold)
    }

    @Test func parseItalicText() {
        // Given
        let input = "Hello *world*"
        // When
        let result = parser.parse(input)
        // Then
        var foundItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let font = value as? CDFont, font.isItalic, range.location == 6 {
                foundItalic = true
            }
        }
        #expect(foundItalic)
    }

    @Test func parseLinkURL() {
        // Given
        let input = "[GitHub](https://github.com)"
        // When
        let result = parser.parse(input)
        // Then
        var foundURL = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundURL = true }
        }
        #expect(foundURL)
    }

    @Test func parseStrikethroughText() {
        // Given
        let input = "Hello ~~world~~"
        // When
        let result = parser.parse(input)
        // Then
        var foundStrikethrough = false
        result.enumerateAttribute(.strikethroughStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundStrikethrough = true }
        }
        #expect(foundStrikethrough)
    }

    @Test func codeSpanNotParsedAsMarkdown() {
        // Content inside backticks must not be treated as bold/italic/etc.
        // Given
        let input = "`**not bold**`"
        // When
        let result = parser.parse(input)
        // Then
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(!foundBold)
    }

    @Test func backslashEscapePreservesCharacter() {
        // Given: \* should produce a literal *, not trigger italic
        let input = "\\*not italic"
        // When
        let result = parser.parse(input)
        // Then
        #expect(result.string.contains("*"))
    }

    @Test func parseHeader() {
        // Given
        let input = "# Heading One"
        // When
        let result = parser.parse(input)
        // Then: the header text should have a larger font than the base font
        var foundLargerFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize > 17 { foundLargerFont = true }
        }
        #expect(foundLargerFont)
    }

    @Test func emptyStringReturnsEmptyResult() {
        let result = parser.parse("")
        #expect(result.length == 0)
    }

    @Test func plainTextHasNoMarkdownAttributes() {
        let input = "Hello, world."
        let result = parser.parse(input)
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundLink = true }
        }
        #expect(!foundLink)
    }
}
