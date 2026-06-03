//
//  CDAttributedStringKey.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 6/18/18.
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

public typealias CDAttributedStringKey = NSAttributedString.Key

extension NSAttributedString.Key {
    static let cdMarkdownRoundedBackground = NSAttributedString.Key("CDMarkdownKit.roundedBackground")
    static let cdMarkdownImageURL = NSAttributedString.Key("CDMarkdownKit.imageURL")

    /// Applied to heading ranges. Value: `Int` (1–6 corresponding to H1–H6).
    static let cdMarkdownHeadingLevel = NSAttributedString.Key("CDMarkdownKit.headingLevel")

    /// Applied to inline code and fenced code block ranges. Value: `true as AnyObject`.
    /// Distinct from `.cdMarkdownRoundedBackground` — that key drives drawing; this drives AT.
    static let cdMarkdownIsCode = NSAttributedString.Key("CDMarkdownKit.isCode")

    /// Applied to blockquote ranges. Value: `true as AnyObject`.
    static let cdMarkdownIsBlockquote = NSAttributedString.Key("CDMarkdownKit.isBlockquote")

    /// Applied to fenced code block ranges when a language hint is present.
    /// Value: `String` — the language identifier exactly as written after the opening fence
    /// (e.g. `"swift"`, `"python"`, `"js"`). Not present when no hint is given.
    static let cdMarkdownCodeLanguage = NSAttributedString.Key("CDMarkdownKit.codeLanguage")

    /// Optional title string from a reference link definition.
    /// Value: `String` — the title text (without surrounding quotes/parens).
    /// Present only when the definition included a title.
    static let cdMarkdownLinkTitle = NSAttributedString.Key("CDMarkdownKit.linkTitle")
}
