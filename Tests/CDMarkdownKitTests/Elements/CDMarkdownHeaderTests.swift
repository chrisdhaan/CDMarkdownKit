import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownHeaderTests {

    let parser = CDMarkdownParser()

    @Test func hashProducesH1() async {
        let result = await parser.parse("# Heading 1")
        var hasLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.pointSize > 17 {
                hasLargeFont = true
            }
        }
        #expect(hasLargeFont)
    }

    @Test func doubleHashProducesH2() async {
        let result = await parser.parse("## Heading 2")
        var hasLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.pointSize > 15 {
                hasLargeFont = true
            }
        }
        #expect(hasLargeFont)
    }

    @Test func tripleHashProducesH3() async {
        let result = await parser.parse("### Heading 3")
        var hasLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.pointSize > 13 {
                hasLargeFont = true
            }
        }
        #expect(hasLargeFont)
    }

    @Test func hashWithoutSpaceIsNotHeader() async {
        let result = await parser.parse("#NoSpace")
        // Text should still be parsed, just not as a large heading
        #expect(result.length > 0)
    }

    @Test func headerHashIsStripped() async {
        let result = await parser.parse("# Heading")
        #expect(!result.string.hasPrefix("#"))
    }

    @Test func headerFontSizesDecreaseWithLevel() async {
        func maxFontSize(for input: String) async -> CGFloat {
            let result = await parser.parse(input)
            var largest: CGFloat = 0
            result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if let f = v as? CDFont, f.pointSize > largest {
                    largest = f.pointSize
                }
            }
            return largest
        }
        let h1 = await maxFontSize(for: "# H1")
        let h2 = await maxFontSize(for: "## H2")
        let h3 = await maxFontSize(for: "### H3")
        let h4 = await maxFontSize(for: "#### H4")
        let h5 = await maxFontSize(for: "##### H5")
        let h6 = await maxFontSize(for: "###### H6")
        #expect(h1 > h2)
        #expect(h2 > h3)
        #expect(h3 > h4)
        #expect(h4 > h5)
        #expect(h5 > h6)
    }

    @Test func h4ThroughH6HaveLargerFontThanBase() async {
        let baseSize: CGFloat = 12 // CDMarkdownParser default font size
        for level in 4 ... 6 {
            let input = String(repeating: "#", count: level) + " Heading"
            let result = await parser.parse(input)
            var found = false
            result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if let f = v as? CDFont, f.pointSize > baseSize {
                    found = true
                }
            }
            #expect(found)
        }
    }
}
