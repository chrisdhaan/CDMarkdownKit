import Testing
import Foundation
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownEscapingTests {

    let parser = CDMarkdownParser()

    @Test func codeSpanContentIsNotBold() {
        // `**text**` inside backticks must NOT produce bold
        let result = parser.parse("`**text**`")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }

    @Test func codeSpanContentIsNotItalic() {
        let result = parser.parse("`*text*`")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(!hasItalic)
    }

    @Test func nestedBoldInsideCodeFenceIsPlain() {
        let result = parser.parse("```\n**not bold**\n```")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }

    // MARK: - Backslash escaping negative cases

    @Test func backslashEscapedAsteriskDoesNotTriggerItalic() {
        // \* should produce a literal * and NOT open an italic span
        let result = parser.parse("\\*not italic\\*")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(!hasItalic)
        #expect(result.string.contains("*"))
    }

    @Test func backslashEscapedUnderscoreDoesNotTriggerItalic() {
        // \_ should produce a literal _ and NOT open an italic span
        let result = parser.parse("\\_not italic\\_")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(!hasItalic)
        #expect(result.string.contains("_"))
    }

    @Test func backslashEscapedBacktickDoesNotTriggerCode() {
        // \` should produce a literal ` and NOT open a code span
        let result = parser.parse("\\`not code\\`")
        // Code spans apply a distinct foreground color (red); plain text should not have it
        var hasCodeColor = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let color = v as? CDColor, color == CDColor.codeTextRed() { hasCodeColor = true }
        }
        #expect(!hasCodeColor)
        #expect(result.string.contains("`"))
    }

    @Test func backslashEscapedBracketDoesNotTriggerLink() {
        // \[ should not open a link span (no URL present either, to avoid auto-detection)
        let result = parser.parse("\\[not a link")
        var hasLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { hasLink = true }
        }
        #expect(!hasLink)
        #expect(result.string.contains("["))
    }
}
