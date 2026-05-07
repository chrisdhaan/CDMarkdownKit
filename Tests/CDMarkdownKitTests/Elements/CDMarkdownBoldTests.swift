import Testing
import Foundation
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownBoldTests {

    let parser = CDMarkdownParser()

    @Test func doubleAsteriskProducesBold() {
        let result = parser.parse("**bold**")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(hasBold)
    }

    @Test func doubleUnderscoreProducesBold() {
        let result = parser.parse("__bold__")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(hasBold)
    }

    @Test func singleAsteriskIsNotBold() {
        let result = parser.parse("*not bold*")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }

    @Test func boldDelimitersAreStripped() {
        let result = parser.parse("**bold**")
        #expect(!result.string.contains("*"))
    }
}
