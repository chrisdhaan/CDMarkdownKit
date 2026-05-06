import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownEscapingTests {

    let parser = CDMarkdownParser()

    @Test func codeSpanContentIsNotBold() {
        // `**text**` inside backticks must NOT produce bold
        let result = parser.parse("`**text**`")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }

    @Test func codeSpanContentIsNotItalic() {
        let result = parser.parse("`*text*`")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(!hasItalic)
    }

    @Test func nestedBoldInsideCodeFenceIsPlain() {
        let result = parser.parse("```\n**not bold**\n```")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }
}
