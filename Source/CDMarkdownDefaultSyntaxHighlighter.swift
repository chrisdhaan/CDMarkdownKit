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
            var lexer = CDMarkdownSwiftSyntaxLexer(code)
            return lexer.scan()
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
        "go", "golang", "rs", "rust", "dart",
        "objc", "objective-c", "objectivec", "obj-c", "m", "mm", "php"
    ]

    static func family(for language: String) -> CDMarkdownSyntaxLanguageFamily {
        if language == "swift" || language == "swiftpm" {
            return .swift
        }
        if cFamilyHints.contains(language) {
            return .cFamily
        }
        return .unsupported
    }
}
