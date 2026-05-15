//
//  CDMarkdownList.swift
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

extension CDMarkdownList: @unchecked Sendable {}

/// Renders unordered lists using *, -, or + syntax.
open class CDMarkdownList: CDMarkdownLevelElement {

    fileprivate static let regex = "^\\s*([\\*\\+\\-]{1,%@})[ \t]+(.+)$"

    /// The font for list item text.
    open var font: CDFont?
    /// The maximum nesting level for lists.
    open var maxLevel: Int
    /// The bullet character or string used for list items.
    open var indicator: String
    /// The string used for indenting nested list levels.
    open var separator: String
    /// The text color for list items.
    open var color: CDColor?
    /// The background color for list items.
    open var backgroundColor: CDColor?
    /// The paragraph style for list items.
    open var paragraphStyle: NSParagraphStyle?
    /// The underline color for list items.
    open var underlineColor: CDColor?
    /// The underline style for list items.
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
        return String(format: CDMarkdownList.regex,
                      level)
    }

    /// Creates a new list element with optional custom styling.
    public init(font: CDFont? = nil,
                maxLevel: Int = 0,
                indicator: String = "•",
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
        if let paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 2
            paragraphStyle.paragraphSpacingBefore = 0
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.lineSpacing = 1.0
            self.paragraphStyle = paragraphStyle
        }
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func formatText(_ attributedString: NSMutableAttributedString,
                         range: NSRange,
                         level: Int) {
        var string = (0 ..< level).reduce("") { string, _ -> String in
            return "\(string)\(separator)"
        }
        string = "\(string)\(indicator) "
        attributedString.replaceCharacters(in: range,
                                           with: string)
    }

    open func addFullAttributes(_ attributedString: NSMutableAttributedString,
                                range: NSRange,
                                level: Int) {
        let indicatorSize = "\(indicator) ".sizeWithAttributes(attributes)
        let separatorSize = separator.sizeWithAttributes(attributes)
        let floatLevel = CGFloat(level)
        guard let paragraphStyle else { return }
        let updatedParagraphStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        updatedParagraphStyle.headIndent = indicatorSize.width + (separatorSize.width * floatLevel)

        attributedString.addParagraphStyle(updatedParagraphStyle,
                                           toRange: range)
    }

    open func addAttributes(_ attributedString: NSMutableAttributedString,
                            range: NSRange,
                            level: Int) {
        attributedString.addAttributes(attributesForLevel(level - 1),
                                       range: range)
    }
}
