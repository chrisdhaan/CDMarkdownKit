//
//  CDMarkdownStrikethrough.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 10/16/22.

//  Copyright © 2016-2022 Christopher de Haan <contact@christopherdehaan.me>
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

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownStrikethrough: CDMarkdownCommonElement {

    fileprivate static let regex = "()(~~)(.*?)(\\2)"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var strikethroughColor: CDColor?
    open var strikethroughStyle: NSUnderlineStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        return CDMarkdownStrikethrough.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                strikethroughColor: CDColor? = nil,
                strikethroughStyle: NSUnderlineStyle? = .single,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.strikethroughColor = strikethroughColor
        self.strikethroughStyle = strikethroughStyle
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    public func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange) {
        var adjustedAttributes = attributes

        if let strikethroughColor = strikethroughColor {
            adjustedAttributes.addStrikethroughColor(strikethroughColor)
        }
        if let strikethroughStyle = strikethroughStyle {
            adjustedAttributes.addStrikethroughStyle(strikethroughStyle)
        }

        attributedString.addAttributes(adjustedAttributes, range: range)
    }

}
