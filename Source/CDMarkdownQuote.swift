//
//  CDMarkdownQuote.swift
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

/// Renders blockquotes using > syntax.
@MainActor
open class CDMarkdownQuote: CDMarkdownLevelElement {

    fileprivate static let regex = "^(\\>{1,%@})\\s*(.+)$"

    /// The font for blockquote text.
    open var font: CDFont?
    /// The maximum nesting level for blockquotes.
    open var maxLevel: Int
    /// The indicator character or string used for blockquotes.
    open var indicator: String
    /// The string used for indenting nested blockquote levels.
    open var separator: String
    /// The text color for blockquotes.
    open var color: CDColor?
    /// The background color for blockquotes.
    open var backgroundColor: CDColor?
    /// The paragraph style for blockquotes.
    open var paragraphStyle: NSParagraphStyle?
    /// The underline color for blockquotes.
    open var underlineColor: CDColor?
    /// The underline style for blockquotes.
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
        return String(format: CDMarkdownQuote.regex,
                      level)
    }

    /// Creates a new blockquote element with optional custom styling.
    public init(font: CDFont? = nil,
                maxLevel: Int = 0,
                indicator: String = ">",
                separator: String = "  ",
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.maxLevel = maxLevel
        self.indicator = indicator
        self.separator = separator
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func formatText(_ attributedString: NSMutableAttributedString,
                         range: NSRange,
                         level: Int) {
        var string = (0 ..< level).reduce("") { (string: String, _: Int) -> String in
            return "\(string)\(separator)"
        }
        string = "\(string)\(indicator) "
        attributedString.replaceCharacters(in: range,
                                           with: string)
    }

    open func addAttributes(_ attributedString: NSMutableAttributedString,
                            range: NSRange,
                            level: Int) {
        attributedString.addAttributes(attributesForLevel(level - 1), range: range)
        attributedString.addAttribute(.cdMarkdownIsBlockquote,
                                      value: true as AnyObject,
                                      range: range)
    }
}
