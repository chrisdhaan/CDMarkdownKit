//
//  CDMarkdownSyntaxHighlighting.swift
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

/// Semantic classification of a run of characters inside a fenced code block.
///
/// This is the single source of truth for token kinds: it both keys the caller's
/// colour map (``CDMarkdownSyntax/syntaxColors`` / ``CDMarkdownTheme/codeSyntaxColors``)
/// and is the output vocabulary of ``CDMarkdownSyntaxHighlighter``.
public enum CDMarkdownSyntaxTokenType: Hashable, Sendable, CaseIterable {
    /// Language keywords: `func`, `let`, `if`, `return`, `class`, `import`, …
    case keyword
    /// Type names — capitalised identifiers and built-in types.
    case type
    /// String and character literals, including multi-line forms.
    case string
    /// Line (`//`, `#`) and block (`/* … */`) comments.
    case comment
    /// Numeric literals: `42`, `0xFF`, `3.14`, `1_000`, `1e9`.
    case number
    /// An identifier immediately followed by `(`.
    case function
    /// `@`-prefixed (`@MainActor`) and `#`-prefixed (`#if`, `#selector`) tokens.
    case attribute
}

/// One classified range within a fenced code block's decoded source text.
public struct CDMarkdownSyntaxToken: Equatable, Sendable {

    /// UTF-16 range into the decoded code string the highlighter was handed
    /// (the language-hint line has already been removed).
    public let range: NSRange

    /// The semantic kind of this run.
    public let type: CDMarkdownSyntaxTokenType

    /// Creates a classified token range.
    public init(range: NSRange, type: CDMarkdownSyntaxTokenType) {
        self.range = range
        self.type = type
    }
}

/// Produces typed token ranges for a fenced code block.
///
/// Assign a custom implementation to ``CDMarkdownSyntax/syntaxHighlighter`` to wrap an
/// external engine (Splash, Highlightr, tree-sitter, …) without CDMarkdownKit taking a
/// dependency on it. The built-in default is ``CDMarkdownDefaultSyntaxHighlighter``.
public protocol CDMarkdownSyntaxHighlighter {

    /// Classifies runs of `code`.
    ///
    /// - Parameters:
    ///   - code: the decoded block source, with the language-hint line already removed.
    ///   - language: the language hint from the opening fence, lowercased
    ///     (or `nil` when the fence carried no hint).
    /// - Returns: non-overlapping tokens in ascending `range.location` order. Return an
    ///   empty array when the language is unsupported — the block then renders as plain
    ///   monospace. Characters not covered by any token render in the block's base colour.
    func tokens(in code: String, language: String?) -> [CDMarkdownSyntaxToken]
}
