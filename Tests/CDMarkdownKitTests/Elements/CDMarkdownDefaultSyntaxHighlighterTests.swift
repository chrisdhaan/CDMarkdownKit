import Foundation
import Testing
@testable import CDMarkdownKit

struct CDMarkdownSyntaxHighlightingTypesTests {

    @Test func tokenTypeIsCaseIterableAndStable() {
        // Guards the vocabulary: adding/removing a case is a deliberate API change.
        #expect(CDMarkdownSyntaxTokenType.allCases.count == 7)
        #expect(Set(CDMarkdownSyntaxTokenType.allCases) == [
            .keyword, .type, .string, .comment, .number, .function, .attribute
        ])
    }

    @Test func tokenEquatableComparesRangeAndType() {
        let a = CDMarkdownSyntaxToken(range: NSRange(location: 0, length: 3), type: .keyword)
        let b = CDMarkdownSyntaxToken(range: NSRange(location: 0, length: 3), type: .keyword)
        let c = CDMarkdownSyntaxToken(range: NSRange(location: 0, length: 3), type: .string)
        #expect(a == b)
        #expect(a != c)
    }
}
