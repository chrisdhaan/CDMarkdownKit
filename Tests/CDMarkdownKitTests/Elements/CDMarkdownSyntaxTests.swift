import Testing
import Foundation
@testable import CDMarkdownKit

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
}
