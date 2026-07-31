import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownHorizontalRuleTests {

    let parser = CDMarkdownParser()

    @Test func dashSyntaxReplaced() async {
        let result = await parser.parse("---")
        #expect(!result.string.contains("-"))
        #expect(result.length > 0)
    }

    @Test func asteriskSyntaxReplaced() async {
        let result = await parser.parse("***")
        #expect(!result.string.contains("*"))
    }

    @Test func underscoreSyntaxReplaced() async {
        let result = await parser.parse("___")
        #expect(!result.string.contains("_"))
    }

    @Test func spacedDashesSyntaxReplaced() async {
        let result = await parser.parse("- - -")
        #expect(!result.string.contains("-"))
    }

    @Test func fiveOrMoreCharactersAllowed() async {
        let result = await parser.parse("-----")
        #expect(!result.string.contains("-"))
    }

    @Test func twoDashesNotHorizontalRule() async {
        // Two characters should NOT match (requires 3+)
        let result = await parser.parse("--")
        #expect(result.string.contains("-"))
    }

    @Test func contentBeforeIsPreserved() async {
        let input = "Above\n---\nBelow"
        let result = await parser.parse(input)
        #expect(result.string.contains("Above"))
        #expect(result.string.contains("Below"))
    }

    @Test func customSeparatorString() async {
        let parser = CDMarkdownParser()
        parser.horizontalRule.separatorString = "---"
        let result = await parser.parse("***")
        #expect(result.string.contains("---"))
    }
}
