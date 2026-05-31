import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct AccessibilityTests {

    let parser = CDMarkdownParser()

    @Test func headingWritesHeadingLevelAttribute() async {
        let result = await parser.parse("# Heading One")
        var foundLevel: Int?
        result.enumerateAttribute(.cdMarkdownHeadingLevel,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let level = value as? Int { foundLevel = level }
        }
        #expect(foundLevel == 1)
    }

    @Test func h3WritesLevel3() async {
        let result = await parser.parse("### Third Level")
        var foundLevel: Int?
        result.enumerateAttribute(.cdMarkdownHeadingLevel,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let level = value as? Int { foundLevel = level }
        }
        #expect(foundLevel == 3)
    }

    @Test func inlineCodeWritesCodeAttribute() async {
        let result = await parser.parse("`code`")
        var foundCode = false
        result.enumerateAttribute(.cdMarkdownIsCode,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundCode = true }
        }
        #expect(foundCode)
    }

    @Test func fencedCodeWritesCodeAttribute() async {
        let result = await parser.parse("```\ncode block\n```")
        var foundCode = false
        result.enumerateAttribute(.cdMarkdownIsCode,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundCode = true }
        }
        #expect(foundCode)
    }

    @Test func blockquoteWritesBlockquoteAttribute() async {
        let result = await parser.parse("> quote")
        var foundQuote = false
        result.enumerateAttribute(.cdMarkdownIsBlockquote,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundQuote = true }
        }
        #expect(foundQuote)
    }

    @Test func plainTextHasNoAccessibilityAttributes() async {
        let result = await parser.parse("Hello world")
        var found = false
        result.enumerateAttribute(.cdMarkdownHeadingLevel,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { found = true }
        }
        #expect(!found)
    }
}
