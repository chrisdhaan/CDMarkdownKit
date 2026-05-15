import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownBoldTests {

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

    @Test func boldSpansMultipleWords() {
        // Verify the bold font covers the full span, not just the first word
        let result = parser.parse("**hello world**")
        var boldWordCount = 0
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, range, _ in
            if let f = v as? CDFont, f.isBold {
                let substring = (result.string as NSString).substring(with: range)
                boldWordCount += substring.components(separatedBy: " ").filter { !$0.isEmpty }.count
            }
        }
        #expect(boldWordCount >= 2)
    }
}
