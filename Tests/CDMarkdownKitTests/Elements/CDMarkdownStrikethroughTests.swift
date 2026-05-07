import Testing
import Foundation
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownStrikethroughTests {

    let parser = CDMarkdownParser()

    @Test func doubleTildeProducesStrikethrough() {
        let result = parser.parse("~~strikethrough~~")
        var hasStrikethrough = false
        result.enumerateAttribute(.strikethroughStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { hasStrikethrough = true }
        }
        #expect(hasStrikethrough)
    }

    @Test func singleTildeIsNotStrikethrough() {
        let result = parser.parse("~not strikethrough~")
        var hasStrikethrough = false
        result.enumerateAttribute(.strikethroughStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { hasStrikethrough = true }
        }
        #expect(!hasStrikethrough)
    }

    @Test func strikethroughDelimitersAreStripped() {
        let result = parser.parse("~~strikethrough~~")
        #expect(!result.string.contains("~"))
    }

    @Test func strikethroughCanContainOtherMarkdown() {
        let result = parser.parse("~~**bold strikethrough**~~")
        // Strikethrough with nested markdown should parse without error
        #expect(result.length > 0)
    }
}
