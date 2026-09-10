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
struct CDMarkdownSwiftSyntaxLexer: CDMarkdownSyntaxLexing {

    var scanner: CDMarkdownSyntaxScanner
    var tokens: [CDMarkdownSyntaxToken] = []

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
                consumeBlockComment(nesting: true)
            case 0x22 where scanner.peek(1) == 0x22 && scanner.peek(2) == 0x22: // """
                consumeMultiLineString()
            case 0x22: // "
                consumeString()
            case 0x40, 0x23: // @ or #
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
}
