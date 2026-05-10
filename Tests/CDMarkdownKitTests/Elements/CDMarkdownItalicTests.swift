import Testing
import Foundation
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownItalicTests {

    let parser = CDMarkdownParser()

    @Test func singleAsteriskProducesItalic() {
        let result = parser.parse("*italic*")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(hasItalic)
    }

    @Test func singleUnderscoreProducesItalic() {
        let result = parser.parse("_italic_")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(hasItalic)
    }

    @Test func doubleAsteriskIsNotItalic() {
        let result = parser.parse("**not italic**")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(!hasItalic)
    }

    @Test func italicDelimitersAreStripped() {
        let result = parser.parse("*italic*")
        #expect(!result.string.contains("*"))
    }
}
