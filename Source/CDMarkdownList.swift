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

/// Renders unordered lists using *, -, or + syntax.
@MainActor
open class CDMarkdownList: CDMarkdownLevelElement {

    fileprivate static let regex = "^([ \\t]*)([\\*\\+\\-]{1,%@})[ \t]+(.+)$"

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

    /// Nesting level is `markerLength + indentLevel`. Under default settings the parser dedents
    /// the whole document (stripping only whitespace common to every line) before this regex
    /// runs, so a list item indented relative to another line elsewhere in the document keeps
    /// that indentation and nests correctly. A single indented item with no such sibling has no
    /// relative indentation to preserve and is still fully stripped;
    /// `CDMarkdownParser.preserveLeadingWhitespace = true` preserves indentation unconditionally.
    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 4 else { return }

        let indentRange = match.nsRange(atIndex: 1)
        let markerRange = match.nsRange(atIndex: 2)
        let contentRange = match.nsRange(atIndex: 3)
        let indentString = (attributedString.string as NSString).substring(with: indentRange)
        let level = markerRange.length + indentLevel(for: indentString)

        addFullAttributes(attributedString,
                          range: match.nsRange(atIndex: 0),
                          level: level)
        addAttributes(attributedString,
                      range: contentRange,
                      level: level)
        let formatRange = NSRange(location: indentRange.location,
                                  length: contentRange.location - indentRange.location)
        formatText(attributedString,
                   range: formatRange,
                   level: level)
    }

    private func indentLevel(for indentString: String) -> Int {
        let tabCount = indentString.filter { $0 == "\t" }.count
        let spaceCount = indentString.count - tabCount
        let separatorWidth = max(separator.count, 1)
        return tabCount + (spaceCount / separatorWidth)
    }

    open func formatText(_ attributedString: NSMutableAttributedString,
                         range: NSRange,
                         level: Int) {
        var string = (0 ..< (level - 1)).reduce("") { string, _ -> String in
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
        let floatLevel = CGFloat(level - 1)
        guard let paragraphStyle = self.paragraphStyle else { return }
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
