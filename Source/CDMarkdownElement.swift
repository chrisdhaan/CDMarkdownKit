//
//  CDMarkdownElement.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
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

/// Base protocol for all Markdown elements, providing regex-based parsing.
///
/// Conform to this protocol to define custom Markdown syntax. You must provide a regex pattern
/// and implement ``match(_:attributedString:)`` to handle matches. The default ``parse(_:)``
/// implementation scans the string and calls ``match(_:attributedString:)`` for each match.
///
/// See ``CDMarkdownCommonElement``, ``CDMarkdownLevelElement``, and ``CDMarkdownLinkElement``
/// for specialized protocols that simplify common use cases.
@MainActor
public protocol CDMarkdownElement: AnyObject {

    /// The regular expression pattern to match this element's syntax.
    ///
    /// This pattern is used by ``regularExpression()`` to find matches in the Markdown input.
    var regex: String { get }

    /// Returns the compiled regular expression for this element.
    ///
    /// - Returns: An `NSRegularExpression` compiled from ``regex``.
    /// - Throws: Any error from `NSRegularExpression` initialization (e.g., invalid regex).
    ///
    /// The default implementation caches the compiled expression, so repeated calls do not
    /// recompile. Subclasses can override for custom caching or compilation logic.
    func regularExpression() throws -> NSRegularExpression

    /// Parses the attributed string and applies matches for this element.
    ///
    /// - Parameter attributedString: The `NSMutableAttributedString` being built by the parser.
    ///
    /// The default implementation repeatedly finds matches using ``regularExpression()`` and
    /// calls ``match(_:attributedString:)`` for each one, tracking position to avoid re-scanning
    /// already-processed matches. Override this if your element requires custom parsing logic
    /// or needs to interact with the parsing pipeline.
    func parse(_ attributedString: NSMutableAttributedString)

    /// Processes a single regex match and updates the attributed string.
    ///
    /// - Parameters:
    ///   - match: The `NSTextCheckingResult` from a successful regex match.
    ///   - attributedString: The `NSMutableAttributedString` being built by the parser.
    ///
    /// Your implementation should examine the match range, extract the matched text, apply
    /// formatting (fonts, colors, paragraph styles), and optionally replace the matched range
    /// with a modified version (e.g., stripping delimiters like `**` for bold).
    func match(_ match: NSTextCheckingResult,
               attributedString: NSMutableAttributedString)
}

public extension CDMarkdownElement {

    func parse(_ attributedString: NSMutableAttributedString) {
        var location = 0
        do {
            let regex = try regularExpression()
            while let regexMatch =
                regex.firstMatch(in: attributedString.string,
                                 options: .withoutAnchoringBounds,
                                 range: NSRange(location: location,
                                                length: attributedString.length - location)) {
                let oldLength = attributedString.length
                match(regexMatch,
                      attributedString: attributedString)
                let newLength = attributedString.length
                let nextLocation = regexMatch.range.location + regexMatch.range.length + newLength - oldLength
                // A zero-length match combined with a match() that doesn't change the
                // string's length would leave location unchanged, re-finding the same
                // match forever. Force at least one character of forward progress. If
                // that would push past the end of the string (a zero-length match can
                // sit at the very last position, where there's no room left to search),
                // stop instead of clamping: clamping to the end would leave location
                // equal to the match's own start, letting a zero-width assertion there
                // re-match forever just as before.
                let advancedLocation = max(nextLocation, regexMatch.range.location + 1)
                if advancedLocation > newLength {
                    break
                }
                location = advancedLocation
            }
        } catch {}
    }
}
