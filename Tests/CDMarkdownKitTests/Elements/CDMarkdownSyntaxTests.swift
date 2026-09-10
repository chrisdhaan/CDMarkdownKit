import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownSyntaxTests {

    let parser = CDMarkdownParser()

    @Test func tripleBacktickProducesFencedCode() async {
        let result = await parser.parse("```\ncode\n```")
        var hasCodeColor = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                hasCodeColor = true
            }
        }
        #expect(hasCodeColor)
    }

    @Test func fencedCodeProtectsMarkdown() async {
        let result = await parser.parse("```\n**not bold**\n```")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(!hasBold)
    }

    @Test func languageHintIsStripped() async {
        let result = await parser.parse("```swift\ncode\n```")
        #expect(!result.string.contains("swift"))
    }

    @Test func fencesAreStripped() async {
        let result = await parser.parse("```\ncode\n```")
        #expect(!result.string.contains("```"))
    }

    @Test func fencedCodeUsesConfiguredFont() async {
        // CDMarkdownParser passes its base font to syntax element at init time,
        // overriding the Menlo-Regular default. Verify the explicitly configured
        // font is applied when set directly on parser.syntax.
        guard let menlo = CDFont(name: "Menlo-Regular", size: 12) else { return }
        let parser = CDMarkdownParser()
        parser.syntax.font = menlo
        let result = await parser.parse("```\ncode\n```")
        var found = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.fontName.lowercased().contains("menlo") {
                found = true
            }
        }
        #expect(found)
    }

    @Test func syntaxWithLanguageHintWritesCodeLanguageAttribute() async {
        let result = await parser.parse("```swift\nlet x = 1\n```")
        var foundLanguage: String?
        result.enumerateAttribute(.cdMarkdownCodeLanguage,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let lang = value as? String {
                foundLanguage = lang
            }
        }
        #expect(foundLanguage == "swift")
    }

    @Test func syntaxWithoutLanguageHintHasNoCodeLanguageAttribute() async {
        let result = await parser.parse("```\nlet x = 1\n```")
        var foundLanguage: String?
        result.enumerateAttribute(.cdMarkdownCodeLanguage,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let lang = value as? String {
                foundLanguage = lang
            }
        }
        #expect(foundLanguage == nil)
    }

    @Test func syntaxLanguageHintIsStrippedFromContent() async {
        let result = await parser.parse("```python\nprint('hello')\n```")
        #expect(!result.string.contains("python"))
        #expect(result.string.contains("print"))
    }

    @Test func syntaxLanguageHintIsCaseSensitive() async {
        let result = await parser.parse("```Swift\nlet x = 1\n```")
        var foundLanguage: String?
        result.enumerateAttribute(.cdMarkdownCodeLanguage,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let lang = value as? String {
                foundLanguage = lang
            }
        }
        #expect(foundLanguage == "Swift")
    }

    @Test func fencedBlockWithEmojiAppliesStylingToEntireSpan() async {
        let parser = CDMarkdownParser()
        let result = await parser.parse("```\ncode 👍 after\n```")
        guard let range = result.string.range(of: "code 👍 after") else {
            Issue.record("expected decoded fenced block text not found")
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

    @Test func unterminatedFenceWithLongTrailingTextParsesQuickly() async {
        let input = "```\n" + String(repeating: " ", count: 1500)
        let start = Date()
        _ = await parser.parse(input)
        let elapsed = Date().timeIntervalSince(start)
        // See CDMarkdownCodeTests.unterminatedBacktickWithLongTrailingTextParsesQuickly() for why
        // this budget is 10s rather than a tighter value: it's a catastrophic-backtracking guard,
        // not a steady-state performance check, and the visionOS CI simulator has been observed to
        // intermittently need several seconds here under load even with no backtracking at all.
        #expect(elapsed < 10.0)
    }

    @Test func fencedCodeBlockAtEndOfDocumentExtendsBackgroundUnderTrailingNewline() async {
        let parser = CDMarkdownParser()
        parser.syntax.backgroundColor = CDColor.syntaxBackgroundGray()
        let result = await parser.parse("```\ncode```\n")
        let lastIndex = result.length - 1

        // Verify the trailing newline has the background color applied (not the parser's default .clear).
        // This directly tests that the fix allows the backgroundColor to be extended to the trailing newline
        // when the code block ends at end-of-document.
        let trailingNewlineColor = result.attribute(.backgroundColor, at: lastIndex, effectiveRange: nil) as? CDColor
        #expect(trailingNewlineColor == CDColor.syntaxBackgroundGray())
    }

    @Test func swiftBlockAppliesTokenColorFromPalette() async {
        let parser = CDMarkdownParser()
        parser.syntax.syntaxColors = [.keyword: CDColor.red]
        let result = await parser.parse("```swift\nlet value = 1\n```")

        guard let letRange = result.string.range(of: "let") else {
            Issue.record("decoded 'let' not found")
            return
        }
        let color = result.attribute(.foregroundColor,
                                     at: NSRange(letRange, in: result.string).location,
                                     effectiveRange: nil) as? CDColor
        #expect(color == CDColor.red)

        // A non-keyword token keeps the block's base colour, not red.
        guard let valueRange = result.string.range(of: "value") else {
            Issue.record("decoded 'value' not found")
            return
        }
        let valueColor = result.attribute(.foregroundColor,
                                          at: NSRange(valueRange, in: result.string).location,
                                          effectiveRange: nil) as? CDColor
        #expect(valueColor != CDColor.red)
    }

    @Test func emptyPaletteLeavesAttributesUnchanged() async {
        // Backward-compat guard: with no palette, the attribute output must match
        // what the parser produced before this feature existed.
        let control = CDMarkdownParser()
        let subject = CDMarkdownParser()
        subject.syntax.syntaxColors = [:] // explicit default

        let md = "```swift\nlet x = 1 // note\n```"
        let a = await control.parse(md)
        let b = await subject.parse(md)

        #expect(a.string == b.string)
        var mismatches = 0
        a.enumerateAttributes(in: NSRange(location: 0, length: a.length)) { attrs, range, _ in
            let other = b.attributes(at: range.location, effectiveRange: nil)
            if (attrs[.foregroundColor] as? CDColor) != (other[.foregroundColor] as? CDColor) {
                mismatches += 1
            }
        }
        #expect(mismatches == 0)
    }

    @Test func blockWithoutLanguageHintIsNotHighlighted() async {
        let parser = CDMarkdownParser()
        parser.syntax.syntaxColors = [.keyword: CDColor.red]
        let result = await parser.parse("```\nlet x = 1\n```")
        var sawRed = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let c = v as? CDColor, c == CDColor.red {
                sawRed = true
            }
        }
        #expect(!sawRed)
    }

    @Test func malformedHighlighterRangesDoNotCrash() async {
        struct BadHighlighter: CDMarkdownSyntaxHighlighter {
            func tokens(in code: String, language: String?) -> [CDMarkdownSyntaxToken] {
                [
                    CDMarkdownSyntaxToken(range: NSRange(location: -5, length: 3), type: .keyword),
                    CDMarkdownSyntaxToken(range: NSRange(location: 0, length: 9999), type: .string),
                    CDMarkdownSyntaxToken(range: NSRange(location: 1, length: 2), type: .number)
                ]
            }
        }
        let parser = CDMarkdownParser()
        parser.syntax.syntaxColors = [.keyword: .red, .string: .green, .number: .blue]
        parser.syntax.syntaxHighlighter = BadHighlighter()
        let result = await parser.parse("```swift\nabc\n```")
        #expect(result.length > 0) // no crash, no throw; out-of-bounds tokens dropped
    }

    @Test func tokenColorWinsOverBaseSyntaxColor() async {
        let parser = CDMarkdownParser()
        parser.syntax.color = CDColor.gray
        parser.syntax.syntaxColors = [.keyword: CDColor.red]
        let result = await parser.parse("```swift\nreturn 1\n```")
        guard let r = result.string.range(of: "return") else { Issue.record("no 'return'")
            return
        }
        let color = result.attribute(.foregroundColor, at: NSRange(r, in: result.string).location, effectiveRange: nil) as? CDColor
        #expect(color == CDColor.red)
    }
}
