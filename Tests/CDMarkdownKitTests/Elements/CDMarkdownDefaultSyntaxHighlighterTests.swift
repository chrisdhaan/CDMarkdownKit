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

    @Test func cppContainerMembersEndAndBeginAreNotKeywords() {
        // `end` / `begin` were pruned from the generic keyword set: as members followed by
        // `(` they classify as `.function`, never `.keyword`.
        let code = "std::vector<int> v; auto a = v.begin(); auto b = v.end();"
        #expect(!substrings(code, "cpp", .keyword).contains("begin"))
        #expect(!substrings(code, "cpp", .keyword).contains("end"))
        #expect(substrings(code, "cpp", .function).contains("begin"))
        #expect(substrings(code, "cpp", .function).contains("end"))
    }

    @Test func jsPromiseThenMemberIsFunctionNotKeyword() {
        let code = "promise.then(x)"
        #expect(!substrings(code, "js", .keyword).contains("then"))
        #expect(substrings(code, "js", .function).contains("then"))
    }

    @Test func keywordLookingMemberAfterDotIsSuppressed() {
        // `default` is a genuine C-family keyword, but not when used as a member.
        let code = "let v = obj.default;"
        #expect(!substrings(code, "js", .keyword).contains("default"))
    }

    @Test func genericLexerDoesNotSwallowRustLifetimeAsString() {
        // Single-quote lifetime must not be scanned as one big `.string`; a real
        // double-quote literal on the same line still is.
        let code = "let x: &'a str = \"hi\";"
        let strings = substrings(code, "rust", .string)
        #expect(strings.contains("\"hi\""))
        #expect(!strings.contains { $0.contains("'a str") })
    }
}

struct CDMarkdownDefaultSyntaxHighlighterSwiftTests {

    private let highlighter = CDMarkdownDefaultSyntaxHighlighter()

    private func substrings(_ code: String, _ type: CDMarkdownSyntaxTokenType) -> [String] {
        let units = Array(code.utf16)
        return highlighter.tokens(in: code, language: "swift")
            .filter { $0.type == type }
            .map { String(utf16CodeUnits: Array(units[$0.range.location ..< $0.range.location + $0.range.length]),
                          count: $0.range.length) }
    }

    @Test func classifiesSwiftKeywordsTypesStringsCommentsNumbers() {
        let code = """
        // greet
        func greet(name: String) -> Int {
            let count = 1_000
            return count
        }
        """
        #expect(substrings(code, .comment).contains("// greet"))
        #expect(substrings(code, .keyword).contains("func"))
        #expect(substrings(code, .keyword).contains("let"))
        #expect(substrings(code, .keyword).contains("return"))
        #expect(substrings(code, .type).contains("String"))
        #expect(substrings(code, .type).contains("Int"))
        #expect(substrings(code, .number).contains("1_000"))
        #expect(substrings(code, .function).contains("greet"))
    }

    @Test func classifiesAttributesAndDirectives() {
        let code = "@MainActor\n#if DEBUG\nlet x = 1\n#endif"
        #expect(substrings(code, .attribute).contains("@MainActor"))
        #expect(substrings(code, .attribute).contains("#if"))
        #expect(substrings(code, .attribute).contains("#endif"))
    }

    @Test func multiLineStringIsOneStringToken() {
        let code = "let s = \"\"\"\nline one\nline two\n\"\"\"\n"
        let strings = substrings(code, .string)
        #expect(strings.contains { $0.contains("line one") && $0.contains("line two") })
    }

    @Test func keywordAsMemberIsNotHighlighted() {
        // `filter` is not a keyword; `repeat` is — after a dot it must not be flagged.
        let code = "let y = xs.repeat\nlet z = xs.map { $0 }"
        #expect(!substrings(code, .keyword).contains("repeat"))
    }

    @Test func interpolationDelimitersAreString() {
        let code = "let s = \"value \\(x) end\""
        // The whole literal is covered by string tokens; `x` inside may be a gap.
        let joined = substrings(code, .string).joined()
        #expect(joined.contains("\"value "))
        #expect(joined.contains(") end\""))
    }

    @Test func unterminatedMultiLineStringDoesNotCrash() {
        let code = "let s = \"\"\"\nnever closed\n"
        let tokens = highlighter.tokens(in: code, language: "swift")
        #expect(tokens.allSatisfy { $0.range.location + $0.range.length <= code.utf16.count })
        #expect(tokens.contains { $0.type == .string })
    }
}
