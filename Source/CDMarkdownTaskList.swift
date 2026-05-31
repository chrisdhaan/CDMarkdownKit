//
//  CDMarkdownTaskList.swift
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
extension CDMarkdownTaskList: @unchecked Sendable {}

/// Renders GFM task list items using `- [ ]` or `- [x]` syntax.
open class CDMarkdownTaskList: CDMarkdownElement, CDMarkdownStyle {

    // Matches: optional whitespace, list marker (- * +), space, [ ] or [x/X], space, content
    // Group 1: full leading whitespace + marker
    // Group 2: checkbox content (space = unchecked, x/X = checked)
    // Group 3: item text
    fileprivate static let regex = "^([ \\t]*[-*+][ \\t]+)\\[([  xX])\\][ \\t]+(.+)$"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    /// The string used to represent an unchecked item. Default: "☐ "
    open var uncheckedMarker: String = "☐ "
    /// The string used to represent a checked item. Default: "☑ "
    open var checkedMarker: String = "☑ "

    open var regex: String {
        return CDMarkdownTaskList.regex
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
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let style = NSMutableParagraphStyle()
            style.paragraphSpacing = 2
            style.paragraphSpacingBefore = 0
            style.firstLineHeadIndent = 0
            style.lineSpacing = 1.0
            self.paragraphStyle = style
        }
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .anchorsMatchLines)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 4 else { return }

        let fullRange     = match.nsRange(atIndex: 0)
        let markerRange   = match.nsRange(atIndex: 1)  // "- " or "* " etc.
        let checkboxRange = match.nsRange(atIndex: 2)  // " " or "x"
        let contentRange  = match.nsRange(atIndex: 3)  // item text

        let nsString = attributedString.string as NSString
        let checkboxValue = nsString.substring(with: checkboxRange).trimmingCharacters(in: .whitespaces)
        let isChecked = checkboxValue.lowercased() == "x"
        let replacement = isChecked ? checkedMarker : uncheckedMarker

        // Apply style to the content text
        attributedString.addAttributes(attributes, range: contentRange)

        // Compute headIndent so wrapped lines align under item text
        let markerWidth = replacement.sizeWithAttributes(attributes).width
        let updatedStyle = (paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
        updatedStyle.headIndent = markerWidth
        attributedString.addParagraphStyle(updatedStyle, toRange: fullRange)

        // Replace the entire "- [ ] " prefix with the checkbox marker.
        // Build the replacement range: markerRange through the end of the checkbox syntax.
        // The checkbox syntax ends at contentRange.location - 1 (the space before content).
        let prefixRange = NSRange(location: markerRange.location,
                                  length: contentRange.location - markerRange.location)
        attributedString.replaceCharacters(in: prefixRange, with: replacement)
    }
}
