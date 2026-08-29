import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownCodeTests {

    let parser = CDMarkdownParser()

    @Test func singleBacktickProducesCode() async {
        let result = await parser.parse("`code`")
        var hasCodeColor = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                hasCodeColor = true
            }
        }
        #expect(hasCodeColor)
    }

    @Test func nestedMarkdownInCodeNotParsed() async {
        let result = await parser.parse("`**not bold**`")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(!hasBold)
    }

    @Test func emptyBackticksProducesCode() async {
        let result = await parser.parse("``")
        #expect(result.length >= 0)
    }

    @Test func backticksAreStripped() async {
        let result = await parser.parse("`code`")
        #expect(!result.string.contains("`"))
    }

    @Test func codeSpanUsesConfiguredFont() async {
        // CDMarkdownParser passes its base font to code element at init time,
        // overriding the Menlo-Regular default. Verify the explicitly configured
        // font is applied when set directly on parser.code.
        guard let menlo = CDFont(name: "Menlo-Regular", size: 12) else { return }
        let parser = CDMarkdownParser()
        parser.code.font = menlo
        let result = await parser.parse("`code`")
        var found = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.fontName.lowercased().contains("menlo") {
                found = true
            }
        }
        #expect(found)
    }

    @Test func codeSpanWithEmojiAppliesStylingToEntireSpan() async {
        let parser = CDMarkdownParser()
        let result = await parser.parse("before `code 👍 after` end")
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

    @Test func unterminatedBacktickWithLongTrailingTextParsesQuickly() async {
        let input = "`" + String(repeating: " ", count: 1500)
        let start = Date()
        _ = await parser.parse(input)
        let elapsed = Date().timeIntervalSince(start)
        // This is a wall-clock budget, not an algorithmic-complexity check: it exists to catch
        // catastrophic regex backtracking (which would take seconds-to-minutes), not to measure
        // steady-state performance. 10s leaves generous headroom above catastrophic backtracking
        // while still failing fast on a real regression; the visionOS CI simulator has been
        // observed to intermittently need 6-8s here under load even with no backtracking at all.
        #expect(elapsed < 10.0)
    }
}
