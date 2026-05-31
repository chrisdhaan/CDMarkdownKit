import Testing
import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@Suite
@MainActor
struct CDMarkdownHorizontalRuleTests {

    let parser = CDMarkdownParser()

    @Test func dashSyntaxReplaced() {
        let result = parser.parse("---")
        #expect(!result.string.contains("-"))
        #expect(result.length > 0)
    }

    @Test func asteriskSyntaxReplaced() {
        let result = parser.parse("***")
        #expect(!result.string.contains("*"))
    }

    @Test func underscoreSyntaxReplaced() {
        let result = parser.parse("___")
        #expect(!result.string.contains("_"))
    }

    @Test func spacedDashesSyntaxReplaced() {
        let result = parser.parse("- - -")
        #expect(!result.string.contains("-"))
    }

    @Test func fiveOrMoreCharactersAllowed() {
        let result = parser.parse("-----")
        #expect(!result.string.contains("-"))
    }

    @Test func twoDashesNotHorizontalRule() {
        // Two characters should NOT match (requires 3+)
        let result = parser.parse("--")
        #expect(result.string.contains("-"))
    }

    @Test func contentBeforeIsPreserved() {
        let input = "Above\n---\nBelow"
        let result = parser.parse(input)
        #expect(result.string.contains("Above"))
        #expect(result.string.contains("Below"))
    }

    @Test func customSeparatorString() {
        let parser = CDMarkdownParser()
        parser.horizontalRule.separatorString = "---"
        let result = parser.parse("***")
        #expect(result.string.contains("---"))
    }
}
