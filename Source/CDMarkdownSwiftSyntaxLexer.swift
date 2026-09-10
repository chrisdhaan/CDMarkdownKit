//
//  CDMarkdownSwiftSyntaxLexer.swift
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

/// Swift lexer: the generic behaviour plus `"""` multi-line strings, `\( … )`
/// interpolation delimiters, `@attributes`, `#directives`, nested `/* */` block
/// comments, and suppression of keyword-looking identifiers used as members
/// (`xs.repeat`). Deliberately lossy — good enough for colouring, never throws.
struct CDMarkdownSwiftSyntaxLexer {

    private var scanner: CDMarkdownSyntaxScanner
    private var tokens: [CDMarkdownSyntaxToken] = []

    init(_ code: String) {
        scanner = CDMarkdownSyntaxScanner(code)
    }

    private static let keywords: Set<String> = [
        "associatedtype", "borrowing", "class", "consuming", "deinit", "enum", "extension",
        "fileprivate", "func", "import", "init", "inout", "internal", "let", "open",
        "operator", "private", "precedencegroup", "protocol", "public", "rethrows",
        "static", "struct", "subscript", "typealias", "var", "actor", "nonisolated",
        "distributed", "break", "case", "catch", "continue", "default", "defer", "do",
        "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
        "switch", "where", "while", "as", "false", "is", "nil", "self", "Self", "super",
        "throws", "true", "try", "async", "await", "some", "any", "each", "consume",
        "copy", "discard", "convenience", "dynamic", "final", "indirect", "infix", "lazy",
        "mutating", "nonmutating", "optional", "override", "postfix", "prefix", "required",
        "unowned", "weak", "willSet", "didSet", "get", "set"
    ]

    mutating func scan() -> [CDMarkdownSyntaxToken] {
        while let unit = scanner.peek() {
            switch unit {
            case 0x2F where scanner.peek(1) == 0x2F: // //
                consumeLineComment()
            case 0x2F where scanner.peek(1) == 0x2A: // /*
                consumeBlockComment()
            case 0x22 where scanner.peek(1) == 0x22 && scanner.peek(2) == 0x22: // """
                consumeMultiLineString()
            case 0x22: // "
                consumeString()
            case 0x40, 0x23: // @ or #
                consumeSigilName()
            case _ where CDMarkdownSyntaxScanner.isDigit(unit):
                consumeNumber()
            case _ where CDMarkdownSyntaxScanner.isIdentifierStart(unit):
                consumeIdentifier()
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
        var depth = 1 // Swift block comments nest
        while let unit = scanner.peek() {
            if unit == 0x2F, scanner.peek(1) == 0x2A {
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

    private mutating func consumeString() {
        let start = scanner.index
        scanner.advance() // opening "
        while let unit = scanner.peek() {
            if unit == 0x5C { // backslash: escape or \( interpolation
                scanner.advance()
                if scanner.peek() == 0x28 {
                    skipBalancedParens()
                } else if !scanner.isAtEnd {
                    scanner.advance()
                }
                continue
            }
            if unit == 0x0A || unit == 0x0D {
                break
            } // unterminated — stop at line end
            scanner.advance()
            if unit == 0x22 {
                break
            } // closing delimiter consumed
        }
        emit(start, .string)
    }

    private mutating func consumeMultiLineString() {
        let start = scanner.index
        scanner.advance()
        scanner.advance()
        scanner.advance() // opening """
        while let unit = scanner.peek() {
            if unit == 0x5C {
                scanner.advance()
                if scanner.peek() == 0x28 {
                    skipBalancedParens()
                } else if !scanner.isAtEnd {
                    scanner.advance()
                }
                continue
            }
            if unit == 0x22, scanner.peek(1) == 0x22, scanner.peek(2) == 0x22 {
                scanner.advance()
                scanner.advance()
                scanner.advance()
                break
            }
            scanner.advance()
        }
        emit(start, .string)
    }

    /// Consumes a balanced `( … )` run starting at the current `(`. Used to skip past
    /// a `\( … )` interpolation segment so the surrounding literal stays one string run.
    private mutating func skipBalancedParens() {
        guard scanner.peek() == 0x28 else { return }
        var depth = 0
        while let unit = scanner.peek() {
            if unit == 0x28 {
                depth += 1
            }
            if unit == 0x29 {
                depth -= 1
                scanner.advance()
                if depth == 0 {
                    return
                }
                continue
            }
            scanner.advance()
        }
    }

    private mutating func consumeSigilName() {
        let start = scanner.index
        scanner.advance() // @ or #
        while let unit = scanner.peek(), CDMarkdownSyntaxScanner.isIdentifierBody(unit) {
            scanner.advance()
        }
        emit(start, .attribute)
    }

    private mutating func consumeNumber() {
        let start = scanner.index
        cdMarkdownScanNumber(&scanner)
        emit(start, .number)
    }

    private mutating func consumeIdentifier() {
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

        if Self.keywords.contains(word), !precededByDot {
            emit(start, .keyword)
        } else if let first = word.utf16.first, CDMarkdownSyntaxScanner.isUppercaseASCII(first) {
            emit(start, .type)
        } else if isCall {
            emit(start, .function)
        }
        // else: no token — renders in base colour
    }
}
