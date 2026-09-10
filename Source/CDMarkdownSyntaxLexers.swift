//
//  CDMarkdownSyntaxLexers.swift
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

extension CDMarkdownSyntaxScanner {

    /// Advances from the current index over a numeric literal: an optional `0x` / `0b` / `0o`
    /// radix prefix, digit-separator underscores, a fractional part, and a signed `e` / `E`
    /// exponent. Shared by the generic and Swift lexers so both classify numbers identically;
    /// each caller emits its own `.number` token.
    mutating func scanNumber() {
        // 0x / 0b / 0o prefix
        if peek() == 0x30,
           let prefix = peek(1),
           (prefix | 0x20) == 0x78 || (prefix | 0x20) == 0x62 || (prefix | 0x20) == 0x6F {
            advance()
            advance()
            while let unit = peek(), CDMarkdownSyntaxScanner.isHexDigit(unit) || unit == 0x5F {
                advance()
            }
            return
        }
        while let unit = peek(), CDMarkdownSyntaxScanner.isDigit(unit) || unit == 0x5F {
            advance()
        }
        if peek() == 0x2E, let next = peek(1), CDMarkdownSyntaxScanner.isDigit(next) {
            advance()
            while let unit = peek(), CDMarkdownSyntaxScanner.isDigit(unit) || unit == 0x5F {
                advance()
            }
        }
        if let exponent = peek(), (exponent | 0x20) == 0x65 { // e / E exponent
            var lookahead = 1
            if let sign = peek(1), sign == 0x2B || sign == 0x2D {
                lookahead = 2
            }
            if let digit = peek(lookahead), CDMarkdownSyntaxScanner.isDigit(digit) {
                for _ in 0 ..< lookahead {
                    advance()
                }
                while let unit = peek(), CDMarkdownSyntaxScanner.isDigit(unit) || unit == 0x5F {
                    advance()
                }
            }
        }
    }
}

/// Common scanning scaffolding for the built-in lexers. Each conformer supplies a `scanner`
/// cursor, a `tokens` accumulator, and its own `scan()` dispatch switch plus keyword set;
/// everything else — comment, sigil, number, and identifier consumption — lives here, so the
/// two lexers cannot drift in how they classify the same construct.
protocol CDMarkdownSyntaxLexing {

    var scanner: CDMarkdownSyntaxScanner { get set }
    var tokens: [CDMarkdownSyntaxToken] { get set }
}

extension CDMarkdownSyntaxLexing {

    /// Appends a token spanning `start ..< scanner.index`, or nothing when that range is empty.
    mutating func emit(_ start: Int, _ type: CDMarkdownSyntaxTokenType) {
        let length = scanner.index - start
        guard length > 0 else { return }
        tokens.append(CDMarkdownSyntaxToken(range: NSRange(location: start, length: length), type: type))
    }

    /// Consumes a `//` or `#` comment to the end of the line.
    mutating func consumeLineComment() {
        let start = scanner.index
        while let unit = scanner.peek(), unit != 0x0A, unit != 0x0D {
            scanner.advance()
        }
        emit(start, .comment)
    }

    /// Consumes a `/* … */` block comment. When `nesting` is true (Swift) an inner `/*` raises
    /// the depth so its matching `*/` is required to close; when false (C-family) the first
    /// `*/` closes it. Either way an unterminated comment stops safely at end-of-input.
    mutating func consumeBlockComment(nesting: Bool) {
        let start = scanner.index
        scanner.advance()
        scanner.advance() // consume /*
        var depth = 1
        while let unit = scanner.peek() {
            if nesting, unit == 0x2F, scanner.peek(1) == 0x2A {
                depth += 1
                scanner.advance()
                scanner.advance()
                continue
            }
            if unit == 0x2A, scanner.peek(1) == 0x2F {
                depth -= 1
                scanner.advance()
                scanner.advance()
                if depth == 0 {
                    break
                }
                continue
            }
            scanner.advance()
        }
        emit(start, .comment)
    }

    /// Consumes an `@name` / `#name` sigil and emits it as `.attribute`.
    mutating func consumeSigilName() {
        let start = scanner.index
        scanner.advance() // @ or #
        while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isIdentifierBody(unit) {
            scanner.advance()
        }
        emit(start, .attribute)
    }

    /// Consumes a numeric literal and emits it as `.number`.
    mutating func consumeNumber() {
        let start = scanner.index
        scanner.scanNumber()
        emit(start, .number)
    }

    /// Consumes an identifier run and classifies it: a `keywords` word not preceded by `.`
    /// becomes `.keyword`, a capitalised word becomes `.type`, a word immediately followed
    /// by `(` becomes `.function`; anything else emits no token and renders in the base colour.
    mutating func consumeIdentifier(keywords: Set<String>) {
        let start = scanner.index
        // A keyword-looking word used as a member (`promise.then`, `obj.default`) is not a
        // keyword. Both lexers share this rule, so their identifier classification matches.
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

        if keywords.contains(word), !precededByDot {
            emit(start, .keyword)
        } else if let first = word.utf16.first, CDMarkdownSyntaxScanner.isUppercaseASCII(first) {
            emit(start, .type)
        } else if isCall {
            emit(start, .function)
        }
        // else: no token — renders in base colour
    }
}

/// Generic C-family lexer: `//` `#` line comments, `/* */` block comments, `'`/`"` strings,
/// numbers, a shared keyword set, capitalised identifiers as types, `name(` as functions,
/// `@name` as attributes. Deliberately lossy — good enough for colouring, never throws.
struct CDMarkdownGenericSyntaxLexer: CDMarkdownSyntaxLexing {

    var scanner: CDMarkdownSyntaxScanner
    var tokens: [CDMarkdownSyntaxToken] = []

    init(_ code: String) {
        scanner = CDMarkdownSyntaxScanner(code)
    }

    /// C-family / JS / TS / Java / Kotlin / Go / Rust / C# / Swift-family keywords only.
    /// Python / Ruby / Lua-only words (`end`, `begin`, `def`, `print`, `then`, `elif`,
    /// `not`, `and`, `or`, `with`, `lambda`, `pass`, `none`, `match`) were removed:
    /// `cFamilyHints` never routes those languages here, and the words collide with
    /// ordinary identifiers in the supported ones (C++ `v.end()`, Java `int end = 0`).
    private static let keywords: Set<String> = [
        "if", "else", "for", "while", "do", "switch", "case", "default", "break",
        "continue", "return", "goto", "function", "func", "fn",
        "class", "struct", "enum", "interface", "trait", "protocol", "impl", "extends",
        "implements", "namespace", "package", "module", "import", "export", "from",
        "using", "include", "require", "public", "private", "protected", "internal",
        "static", "final", "abstract", "virtual", "override", "const", "let", "var",
        "val", "new", "delete", "this", "self", "super", "null", "nil", "true",
        "false", "void", "int", "long", "short", "float", "double", "bool", "boolean",
        "char", "byte", "string", "typeof", "instanceof", "sizeof", "typedef", "in",
        "of", "as", "is", "try", "catch", "finally", "throw", "throws", "async", "await",
        "yield", "defer", "unsafe", "where"
    ]

    mutating func scan() -> [CDMarkdownSyntaxToken] {
        while let unit = scanner.peek() {
            switch unit {
            case 0x2F where scanner.peek(1) == 0x2F: // //
                consumeLineComment()
            case 0x2F where scanner.peek(1) == 0x2A: // /*
                consumeBlockComment(nesting: false)
            case 0x23: // #
                consumeLineComment()
            case 0x22, 0x27: // " '
                consumeString(delimiter: unit)
            case 0x40: // @
                consumeSigilName()
            case _ where CDMarkdownSyntaxScanner.isDigit(unit):
                consumeNumber()
            case _ where CDMarkdownSyntaxScanner.isIdentifierStart(unit):
                consumeIdentifier(keywords: Self.keywords)
            default:
                scanner.advance()
            }
        }
        return tokens
    }

    private mutating func consumeString(delimiter: UInt16) {
        let start = scanner.index
        // A `'` only opens a string when a closing `'` follows within a short same-line
        // window. Otherwise it's a Rust lifetime (`&'a str`), a C++ digit separator
        // (`1'000'000`), or a stray quote — advance one unit and emit no token.
        if delimiter == 0x27, !singleQuoteOpensString() {
            scanner.advance()
            return
        }
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

    /// True when a closing `'` occurs within ~8 code units on the same line as the
    /// opening `'` at the current index — the mark of a char literal rather than a
    /// Rust lifetime or a C++ digit separator.
    private func singleQuoteOpensString() -> Bool {
        var offset = 1
        while offset <= 8, let unit = scanner.peek(offset) {
            if unit == 0x0A || unit == 0x0D {
                return false
            }
            if unit == 0x27 {
                return true
            }
            offset += 1
        }
        return false
    }
}
