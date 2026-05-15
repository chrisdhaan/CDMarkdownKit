//
//  CDMarkdownLevelElement.swift
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

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

/// Protocol for block-level Markdown elements with multiple levels of nesting (e.g., headers, lists).
public protocol CDMarkdownLevelElement: CDMarkdownElement, CDMarkdownStyle {

    /// The maximum nesting level supported by this element (e.g., 6 for headers).
    var maxLevel: Int { get }

    /// Formats text content by removing or replacing level markers.
    func formatText(_ attributedString: NSMutableAttributedString,
                    range: NSRange,
                    level: Int)
    /// Applies styling attributes to the entire element block.
    func addFullAttributes(_ attributedString: NSMutableAttributedString,
                           range: NSRange,
                           level: Int)
    /// Applies styling attributes to the element's content text.
    func addAttributes(_ attributedString: NSMutableAttributedString,
                       range: NSRange,
                       level: Int)
    /// Returns style attributes specific to the given nesting level.
    func attributesForLevel(_ level: Int) -> [CDAttributedStringKey: AnyObject]
}

public extension CDMarkdownLevelElement {

    func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex,
                                options: .anchorsMatchLines)
    }

    func addFullAttributes(_ attributedString: NSMutableAttributedString,
                           range: NSRange,
                           level: Int) {}

    func addAttributes(_ attributedString: NSMutableAttributedString,
                       range: NSRange,
                       level: Int) {
        attributedString.addAttributes(attributesForLevel(level - 1),
                                       range: range)
    }

    func attributesForLevel(_ level: Int) -> [CDAttributedStringKey: AnyObject] {
        self.attributes
    }

    func match(_ match: NSTextCheckingResult,
               attributedString: NSMutableAttributedString) {
        let level = match.nsRange(atIndex: 1).length
        addFullAttributes(attributedString,
                          range: match.nsRange(atIndex: 0),
                          level: level)
        addAttributes(attributedString,
                      range: match.nsRange(atIndex: 2),
                      level: level)
        let range = NSRange(location: match.nsRange(atIndex: 1).location,
                            length: match.nsRange(atIndex: 2).location - match.nsRange(atIndex: 1).location)
        formatText(attributedString,
                   range: range,
                   level: level)
    }
}
