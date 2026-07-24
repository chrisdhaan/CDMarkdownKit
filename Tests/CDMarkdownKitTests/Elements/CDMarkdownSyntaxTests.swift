import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownSyntaxTests {

    let parser = CDMarkdownParser()

    @Test func tripleBacktickProducesFencedCode() {
        let result = parser.parse("```\ncode\n```")
        var hasCodeColor = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                hasCodeColor = true
            }
        }
        #expect(hasCodeColor)
    }

    @Test func fencedCodeProtectsMarkdown() {
        let result = parser.parse("```\n**not bold**\n```")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(!hasBold)
    }

    @Test func languageHintIsStripped() {
        let result = parser.parse("```swift\ncode\n```")
        #expect(!result.string.contains("swift"))
    }

    @Test func fencesAreStripped() {
        let result = parser.parse("```\ncode\n```")
        #expect(!result.string.contains("```"))
    }

    @Test func fencedCodeUsesConfiguredFont() {
        // CDMarkdownParser passes its base font to syntax element at init time,
        // overriding the Menlo-Regular default. Verify the explicitly configured
        // font is applied when set directly on parser.syntax.
        guard let menlo = CDFont(name: "Menlo-Regular", size: 12) else { return }
        let parser = CDMarkdownParser()
        parser.syntax.font = menlo
        let result = parser.parse("```\ncode\n```")
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

    @Test func fencedBlockWithEmojiAppliesStylingToEntireSpan() {
        let parser = CDMarkdownParser()
        let result = parser.parse("```\ncode 👍 after\n```")
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
}
