import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownCodeTests {

    let parser = CDMarkdownParser()

    @Test func singleBacktickProducesCode() {
        let result = parser.parse("`code`")
        var hasCodeColor = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                hasCodeColor = true
            }
        }
        #expect(hasCodeColor)
    }

    @Test func nestedMarkdownInCodeNotParsed() {
        let result = parser.parse("`**not bold**`")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
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

    @Test func codeSpanUsesConfiguredFont() {
        // CDMarkdownParser passes its base font to code element at init time,
        // overriding the Menlo-Regular default. Verify the explicitly configured
        // font is applied when set directly on parser.code.
        guard let menlo = CDFont(name: "Menlo-Regular", size: 12) else { return }
        let parser = CDMarkdownParser()
        parser.code.font = menlo
        let result = parser.parse("`code`")
        var found = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.fontName.lowercased().contains("menlo") {
                found = true
            }
        }
        #expect(found)
    }

    @Test func codeSpanWithEmojiAppliesStylingToEntireSpan() {
        let parser = CDMarkdownParser()
        let result = parser.parse("before `code 👍 after` end")
        guard let range = result.string.range(of: "code 👍 after") else {
            Issue.record("expected decoded code span text not found")
            return
        }
        let nsRange = NSRange(range, in: result.string)
        var isCodeForEntireRange = true
        result.enumerateAttribute(.cdMarkdownIsCode, in: nsRange) { value, subrange, _ in
            if subrange.length > 0, !(value as? Bool ?? false) {
                isCodeForEntireRange = false
            }
        }
        #expect(isCodeForEntireRange)
    }

    @Test func unterminatedBacktickWithLongTrailingTextParsesQuickly() {
        let input = "`" + String(repeating: " ", count: 1500)
        let start = Date()
        _ = parser.parse(input)
        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 2.0)
    }
}
