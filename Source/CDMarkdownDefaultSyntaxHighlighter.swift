//
//  CDMarkdownDefaultSyntaxHighlighter.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/10/16.
//
//  Copyright © 2016-2026 Christopher de Haan <contact@christopherdehaan.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// The built-in ``CDMarkdownSyntaxHighlighter``: a small, dependency-free tokenizer
/// covering Swift and a generic C-family set. Any other (or absent) language yields no
/// tokens, so the block renders as plain monospace. Supply your own highlighter via
/// ``CDMarkdownSyntax/syntaxHighlighter`` for broader language coverage.
public struct CDMarkdownDefaultSyntaxHighlighter: CDMarkdownSyntaxHighlighter, Sendable {

    public init() {}

    public func tokens(in code: String, language: String?) -> [CDMarkdownSyntaxToken] {
        guard let language, !code.isEmpty else { return [] }
        switch CDMarkdownSyntaxLanguageFamily.family(for: language.lowercased()) {
        case .swift:
            // Swift has its own dedicated lexer, wired in a later change; until then
            // Swift blocks yield no tokens and render as plain monospace.
            return []
        case .cFamily:
            var lexer = CDMarkdownGenericSyntaxLexer(code)
            return lexer.scan()
        case .unsupported:
            return []
        }
    }
}

/// Maps a lowercased fence language hint to the lexer that should handle it.
enum CDMarkdownSyntaxLanguageFamily {
    case swift
    case cFamily
    case unsupported

    private static let cFamilyHints: Set<String> = [
        "js", "jsx", "mjs", "cjs", "javascript", "node",
        "ts", "tsx", "typescript",
        "java", "kt", "kotlin", "scala", "groovy",
        "c", "h", "cpp", "cc", "cxx", "c++", "hpp", "hh",
        "cs", "csharp", "c#",
        "go", "golang", "rs", "rust", "dart", "swiftpm",
        "objc", "objective-c", "objectivec", "obj-c", "m", "mm", "php"
    ]

    static func family(for language: String) -> CDMarkdownSyntaxLanguageFamily {
        if language == "swift" {
            return .swift
        }
        if cFamilyHints.contains(language) {
            return .cFamily
        }
        return .unsupported
    }
}

/// A forward-only cursor over a string's UTF-16 code units. NSRange is UTF-16, so scanning
/// in code units means every emitted range is a valid NSRange with no bridging surprises.
struct CDMarkdownSyntaxScanner {

    let units: [UInt16]
    var index: Int = 0

    init(_ string: String) {
        units = Array(string.utf16)
    }

    var isAtEnd: Bool { index >= units.count }

    func peek(_ ahead: Int = 0) -> UInt16? {
        let target = index + ahead
        return target < units.count ? units[target] : nil
    }

    mutating func advance() {
        index += 1
    }

    /// ASCII helpers — non-ASCII (>= 0x80) counts as an identifier character so that
    /// Unicode identifiers are consumed as one run and never split a surrogate pair.
    static func isDigit(_ unit: UInt16) -> Bool {
        unit >= 0x30 && unit <= 0x39
    }

    static func isHexDigit(_ unit: UInt16) -> Bool {
        isDigit(unit) || (unit | 0x20) >= 0x61 && (unit | 0x20) <= 0x66
    }

    static func isIdentifierStart(_ unit: UInt16) -> Bool {
        unit == 0x5F || unit >= 0x80 || ((unit | 0x20) >= 0x61 && (unit | 0x20) <= 0x7A)
    }

    static func isIdentifierBody(_ unit: UInt16) -> Bool {
        isIdentifierStart(unit) || isDigit(unit)
    }

    static func isUppercaseASCII(_ unit: UInt16) -> Bool {
        unit >= 0x41 && unit <= 0x5A
    }
}

/// Generic C-family lexer: `//` `#` line comments, `/* */` block comments, `'`/`"` strings,
/// numbers, a shared keyword set, capitalised identifiers as types, `name(` as functions,
/// `@name` as attributes. Deliberately lossy — good enough for colouring, never throws.
struct CDMarkdownGenericSyntaxLexer {

    private var scanner: CDMarkdownSyntaxScanner
    private var tokens: [CDMarkdownSyntaxToken] = []

    init(_ code: String) {
        scanner = CDMarkdownSyntaxScanner(code)
    }

    fileprivate static let keywords: Set<String> = [
        "if", "else", "for", "while", "do", "switch", "case", "default", "break",
        "continue", "return", "goto", "function", "func", "fn", "def", "lambda",
        "class", "struct", "enum", "interface", "trait", "protocol", "impl", "extends",
        "implements", "namespace", "package", "module", "import", "export", "from",
        "using", "include", "require", "public", "private", "protected", "internal",
        "static", "final", "abstract", "virtual", "override", "const", "let", "var",
        "val", "new", "delete", "this", "self", "super", "null", "nil", "none", "true",
        "false", "void", "int", "long", "short", "float", "double", "bool", "boolean",
        "char", "byte", "string", "typeof", "instanceof", "sizeof", "typedef", "in",
        "of", "as", "is", "try", "catch", "finally", "throw", "throws", "async", "await",
        "yield", "defer", "unsafe", "match", "where", "with", "pass", "print",
        "not", "and", "or", "then", "end", "begin", "elif"
    ]

    mutating func scan() -> [CDMarkdownSyntaxToken] {
        while let unit = scanner.peek() {
            switch unit {
            case 0x2F where scanner.peek(1) == 0x2F: // //
                consumeLineComment()
            case 0x2F where scanner.peek(1) == 0x2A: // /*
                consumeBlockComment()
            case 0x23: // #
                consumeLineComment()
            case 0x22, 0x27: // " '
                consumeString(delimiter: unit)
            case 0x40: // @
                consumeSigilName(type: .attribute)
            case _ where CDMarkdownSyntaxScanner.isDigit(unit):
                consumeNumber()
            case _ where CDMarkdownSyntaxScanner.isIdentifierStart(unit):
                consumeIdentifier(swiftMemberSuppression: false)
            default:
                scanner.advance()
            }
        }
        return tokens
    }

    private mutating func emit(_ start: Int, _ type: CDMarkdownSyntaxTokenType) {
        let length = scanner.index - start
        guard length > 0 else { return }
        tokens.append(CDMarkdownSyntaxToken(range: NSRange(location: start, length: length), type: type))
    }

    private mutating func consumeLineComment() {
        let start = scanner.index
        while let unit = scanner.peek(), unit != 0x0A, unit != 0x0D {
            scanner.advance()
        }
        emit(start, .comment)
    }

    private mutating func consumeBlockComment() {
        let start = scanner.index
        scanner.advance()
        scanner.advance() // consume /*
        while let unit = scanner.peek() {
            if unit == 0x2A, scanner.peek(1) == 0x2F {
                scanner.advance()
                scanner.advance() // consume */
                break
            }
            scanner.advance()
        }
        emit(start, .comment)
    }

    private mutating func consumeString(delimiter: UInt16) {
        let start = scanner.index
        // Swift-style triple quote is handled by the Swift lexer; here treat "" as empty.
        scanner.advance() // opening delimiter
        while let unit = scanner.peek() {
            if unit == 0x5C { // backslash escape
                scanner.advance()
                if !scanner.isAtEnd {
                    scanner.advance()
                }
                continue
            }
            if unit == 0x0A || unit == 0x0D {
                break
            } // unterminated — stop at line end
            scanner.advance()
            if unit == delimiter {
                break
            } // closing delimiter consumed
        }
        emit(start, .string)
    }

    private mutating func consumeSigilName(type: CDMarkdownSyntaxTokenType) {
        let start = scanner.index
        scanner.advance() // @ or #
        while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isIdentifierBody(unit) {
            scanner.advance()
        }
        emit(start, type)
    }

    private mutating func consumeNumber() {
        let start = scanner.index
        // 0x / 0b / 0o prefix
        if scanner.peek() == 0x30,
           let prefix = scanner.peek(1),
           (prefix | 0x20) == 0x78 || (prefix | 0x20) == 0x62 || (prefix | 0x20) == 0x6F {
            scanner.advance()
            scanner.advance()
            while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isHexDigit(unit) || unit == 0x5F {
                scanner.advance()
            }
            emit(start, .number)
            return
        }
        while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isDigit(unit) || unit == 0x5F {
            scanner.advance()
        }
        if scanner.peek() == 0x2E, let next = scanner.peek(1), CDMarkdownSyntaxScanner.isDigit(next) {
            scanner.advance()
            while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isDigit(unit) || unit == 0x5F {
                scanner.advance()
            }
        }
        if let exponent = scanner.peek(), (exponent | 0x20) == 0x65 { // e / E exponent
            var lookahead = 1
            if let sign = scanner.peek(1), sign == 0x2B || sign == 0x2D {
                lookahead = 2
            }
            if let digit = scanner.peek(lookahead), CDMarkdownSyntaxScanner.isDigit(digit) {
                for _ in 0 ..< lookahead {
                    scanner.advance()
                }
                while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isDigit(unit) || unit == 0x5F {
                    scanner.advance()
                }
            }
        }
        emit(start, .number)
    }

    private mutating func consumeIdentifier(swiftMemberSuppression: Bool) {
        let start = scanner.index
        let precededByDot = start > 0 && scanner.units[start - 1] == 0x2E
        while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isIdentifierBody(unit) {
            scanner.advance()
        }
        let length = scanner.index - start
        let word = String(utf16CodeUnits: Array(scanner.units[start ..< start + length]), count: length)

        // function call: identifier immediately followed by '(' (skipping spaces)
        var lookahead = scanner.index
        while lookahead < scanner.units.count, scanner.units[lookahead] == 0x20 {
            lookahead += 1
        }
        let isCall = lookahead < scanner.units.count && scanner.units[lookahead] == 0x28

        if Self.keywords.contains(word), !(swiftMemberSuppression && precededByDot) {
            emit(start, .keyword)
        } else if let first = word.utf16.first, CDMarkdownSyntaxScanner.isUppercaseASCII(first) {
            emit(start, .type)
        } else if isCall {
            emit(start, .function)
        }
        // else: no token — renders in base colour
    }
}
