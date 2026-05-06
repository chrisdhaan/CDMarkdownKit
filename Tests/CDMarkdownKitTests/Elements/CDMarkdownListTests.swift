import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownListTests {

    let parser = CDMarkdownParser()

    @Test func asteriskBulletProducesList() {
        let result = parser.parse("* item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 { hasHeadIndent = true }
        }
        #expect(hasHeadIndent)
    }

    @Test func dashBulletProducesList() {
        let result = parser.parse("- item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 { hasHeadIndent = true }
        }
        #expect(hasHeadIndent)
    }

    @Test func plusBulletProducesList() {
        let result = parser.parse("+ item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 { hasHeadIndent = true }
        }
        #expect(hasHeadIndent)
    }

    @Test func listMarkerIsReplaced() {
        let result = parser.parse("* item")
        #expect(!result.string.contains("*"))
    }
}
