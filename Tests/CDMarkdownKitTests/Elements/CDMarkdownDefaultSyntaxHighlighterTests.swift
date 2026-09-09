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

struct CDMarkdownDefaultSyntaxHighlighterGenericTests {

    private let highlighter = CDMarkdownDefaultSyntaxHighlighter()

    private func types(_ code: String, _ language: String?) -> [CDMarkdownSyntaxTokenType] {
        highlighter.tokens(in: code, language: language).map(\.type)
    }

    private func substrings(_ code: String, _ language: String?, _ type: CDMarkdownSyntaxTokenType) -> [String] {
        let units = Array(code.utf16)
        return highlighter.tokens(in: code, language: language)
            .filter { $0.type == type }
            .compactMap { tok in
                guard tok.range.location >= 0,
                      tok.range.location + tok.range.length <= units.count else { return nil }
                return String(utf16CodeUnits: Array(units[tok.range.location ..< tok.range.location + tok.range.length]),
                              count: tok.range.length)
            }
    }

    @Test func nilLanguageProducesNoTokens() {
        #expect(highlighter.tokens(in: "let x = 1", language: nil).isEmpty)
    }

    @Test func unknownLanguageProducesNoTokens() {
        #expect(highlighter.tokens(in: "PROGRAM MAIN\nEND", language: "fortran").isEmpty)
    }

    @Test func emptyCodeProducesNoTokens() {
        #expect(highlighter.tokens(in: "", language: "js").isEmpty)
    }

    @Test func genericLexerClassifiesKeywordsStringsCommentsNumbers() {
        let code = "function add(a) { return a + 1; } // done\nconst s = \"hi\";"
        #expect(substrings(code, "js", .keyword).contains("function"))
        #expect(substrings(code, "js", .keyword).contains("return"))
        #expect(substrings(code, "js", .keyword).contains("const"))
        #expect(substrings(code, "js", .comment).contains("// done"))
        #expect(substrings(code, "js", .string).contains("\"hi\""))
        #expect(substrings(code, "js", .number).contains("1"))
        #expect(substrings(code, "js", .function).contains("add"))
    }

    @Test func genericLexerClassifiesBlockCommentsAndTypes() {
        let code = "/* header */\nMyType value = new MyType();"
        #expect(substrings(code, "java", .comment).contains("/* header */"))
        #expect(substrings(code, "java", .type).contains("MyType"))
        #expect(substrings(code, "java", .keyword).contains("new"))
    }

    @Test func genericLexerHandlesHashLineComments() {
        #expect(substrings("x = 1  # trailing", "js", .comment).contains("# trailing"))
    }

    @Test func unterminatedStringTerminatesAndDoesNotCrash() {
        let code = "const s = \"never closed\nnext line"
        let tokens = highlighter.tokens(in: code, language: "js")
        // The string token runs to end-of-line, not past it, and offsets stay in bounds.
        let units = code.utf16.count
        #expect(tokens.allSatisfy { $0.range.location + $0.range.length <= units })
        #expect(substrings(code, "js", .string).contains { $0.hasPrefix("\"never closed") })
    }

    @Test func unterminatedBlockCommentTerminatesAndDoesNotCrash() {
        let code = "code /* open forever"
        let tokens = highlighter.tokens(in: code, language: "c")
        #expect(tokens.contains { $0.type == .comment })
        #expect(tokens.allSatisfy { $0.range.location + $0.range.length <= code.utf16.count })
    }

    @Test func nonASCIIInsideStringsKeepsRangesValidUTF16() {
        let code = "let s = \"caf\u{00E9} \u{1F600}\" // \u{1F44D}"
        let tokens = highlighter.tokens(in: code, language: "js")
        let units = code.utf16.count
        #expect(!tokens.isEmpty)
        #expect(tokens.allSatisfy { $0.range.location >= 0 && $0.range.location + $0.range.length <= units })
    }

    @Test func largeInputTerminatesQuickly() {
        let code = String(repeating: "const x = 1; // c\n", count: 5000)
        let start = Date()
        _ = highlighter.tokens(in: code, language: "js")
        #expect(Date().timeIntervalSince(start) < 5.0)
    }
}
