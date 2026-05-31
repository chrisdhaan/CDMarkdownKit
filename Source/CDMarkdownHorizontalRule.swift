//
//  CDMarkdownHorizontalRule.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 5/30/26.
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

/// Open class: subclasses could add non-Sendable properties, so Sendable cannot be synthesized.
extension CDMarkdownHorizontalRule: @unchecked Sendable {}

/// Renders horizontal rules using `---`, `***`, or `___` syntax with optional spacing.
open class CDMarkdownHorizontalRule: CDMarkdownElement, CDMarkdownStyle {

    // Matches a line containing only 3+ dashes, asterisks, or underscores,
    // optionally with spaces between them, with optional surrounding whitespace.
    // Groups: group 1 = entire matched content (used to determine which character was used)
    fileprivate static let regex = "^[ \\t]*([-*_])(?:[ \\t]*\\1){2,}[ \\t]*$"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    /// The string that replaces the markdown horizontal rule syntax.
    /// Default: "────────"  (8 box-drawing horizontal rule characters, U+2500)
    open var separatorString: String = "────────"

    open var regex: String {
        CDMarkdownHorizontalRule.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex,
                                options: .anchorsMatchLines)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        let fullRange = match.nsRange(atIndex: 0)
        attributedString.replaceCharacters(in: fullRange, with: separatorString)
        let replacedRange = NSRange(location: fullRange.location,
                                    length: (separatorString as NSString).length)
        attributedString.addAttributes(attributes, range: replacedRange)
    }
}
