import Testing
import Foundation
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownSyntaxTests {

    let parser = CDMarkdownParser()

    @Test func tripleBacktickProducesFencedCode() {
        let result = parser.parse("```\ncode\n```")
        var hasCodeColor = false
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { hasCodeColor = true }
        }
        #expect(hasCodeColor)
    }

    @Test func fencedCodeProtectsMarkdown() {
        let result = parser.parse("```\n**not bold**\n```")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
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
            if let f = v as? CDFont, f.fontName.lowercased().contains("menlo") { found = true }
        }
        #expect(found)
    }
}
