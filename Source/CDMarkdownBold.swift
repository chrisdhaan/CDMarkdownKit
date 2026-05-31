//
//  CDMarkdownBold.swift
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

// Open class: subclasses could add non-Sendable properties, so Sendable cannot be synthesized.
extension CDMarkdownBold: @unchecked Sendable {}

/// Renders bold text using **text** or __text__ syntax.
open class CDMarkdownBold: CDMarkdownCommonElement {

    fileprivate static let regex = "()(\\*\\*|__)(.*?)(\\2)"

    /// The font to apply to bold text.
    open var font: CDFont?
    /// The text color for bold text.
    open var color: CDColor?
    /// The background color for bold text.
    open var backgroundColor: CDColor?
    /// The paragraph style for bold text.
    open var paragraphStyle: NSParagraphStyle?
    /// The underline color for bold text.
    open var underlineColor: CDColor?
    /// The underline style for bold text.
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        CDMarkdownBold.regex
    }

    /// Creates a new bold element with optional custom styling.
    public init(font: CDFont? = nil,
                customBoldFont: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        if let customBoldFont {
            self.font = customBoldFont
        } else {
            self.font = font?.bold()
        }

        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }
}
