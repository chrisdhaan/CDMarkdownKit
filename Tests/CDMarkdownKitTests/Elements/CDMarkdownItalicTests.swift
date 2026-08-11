import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownItalicTests {

    let parser = CDMarkdownParser()

    @Test func singleAsteriskProducesItalic() async {
        let result = await parser.parse("*italic*")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic {
                hasItalic = true
            }
        }
        #expect(hasItalic)
    }

    @Test func singleUnderscoreProducesItalic() async {
        let result = await parser.parse("_italic_")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic {
                hasItalic = true
            }
        }
        #expect(hasItalic)
    }

    @Test func doubleAsteriskIsNotItalic() async {
        let result = await parser.parse("**not italic**")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic {
                hasItalic = true
            }
        }
        #expect(!hasItalic)
    }

    @Test func italicDelimitersAreStripped() async {
        let result = await parser.parse("*italic*")
        #expect(!result.string.contains("*"))
    }
}
