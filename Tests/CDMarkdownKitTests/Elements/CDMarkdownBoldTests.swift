import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownBoldTests {

    let parser = CDMarkdownParser()

    @Test func doubleAsteriskProducesBold() async {
        let result = await parser.parse("**bold**")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(hasBold)
    }

    @Test func doubleUnderscoreProducesBold() async {
        let result = await parser.parse("__bold__")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(hasBold)
    }

    @Test func singleAsteriskIsNotBold() async {
        let result = await parser.parse("*not bold*")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold {
                hasBold = true
            }
        }
        #expect(!hasBold)
    }

    @Test func boldDelimitersAreStripped() async {
        let result = await parser.parse("**bold**")
        #expect(!result.string.contains("*"))
    }

    @Test func boldSpansMultipleWords() async {
        // Verify the bold font covers the full span, not just the first word
        let result = await parser.parse("**hello world**")
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
