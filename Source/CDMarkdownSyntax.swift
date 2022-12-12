//
//  CDMarkdownCode.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/10/16.
//
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

open class CDMarkdownSyntax: CDMarkdownCommonElement {

    fileprivate static let regex = "(\\s+|^)(`{3})(\\s*[^`]*?\\s*)(\\2)(?!`)"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        return CDMarkdownSyntax.regex
    }

    public init(font: CDFont? = CDFont(name: "Menlo-Regular", size: 12),
                color: CDColor? = CDColor.syntaxTextGray(),
                backgroundColor: CDColor? = CDColor.syntaxBackgroundGray(),
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

    open func addAttributes(_ attributedString: NSMutableAttributedString,
                            range: NSRange) {
        let matchString: String = attributedString.attributedSubstring(from: range).string
        guard let unescapedString = matchString.unescapeUTF16() else { return }
        attributedString.replaceCharacters(in: range,
                                           with: unescapedString)

        let range = NSRange(location: range.location,
                            length: unescapedString.characterCount())
        attributedString.addAttributes(attributes,
                                       range: range)
        // If the previous character was a newline then parser doesn't have to worry about
        // wrapping the background color from the end of the last element to the newline.
        if range.location - 4 >= 0,
            let previousCharacterRange = attributedString.string.range(from: NSRange(location: range.location - 4,
                                                                                     length: 1)),
            attributedString.string[previousCharacterRange] == "\n" {
            // Do nothing
        } else {
            // If the first character in a Syntax Markdown element is \n remove the background
            // color to avoid wrapping the background color from the end of the last element
            // to the newline.
            let removeBackgroundColorAttributeRange = NSRange(location: range.location,
                                                              length: 1)
            if let firstCharacterRange = attributedString.string.range(from: removeBackgroundColorAttributeRange),
                attributedString.string[firstCharacterRange] == "\n" {

                attributedString.removeBackgroundColor(atRange: removeBackgroundColorAttributeRange)
            }
        }
        // If the last character in a Syntax Markdown element is a newline then parser doens't have
        // to worry about wrapping the background color from the end of the element to the newline.
        if let lastCharacterRange = attributedString.string.range(from: NSRange(location: range.location + range.length - 1,
                                                                                length: 1)),
            attributedString.string[lastCharacterRange] == "\n" {
            // Do nothing
        } else {
            // If the next character in a Syntax Markdown element is \n add the background color
            // to fully wrap the background color to the end of the current line.
            let addBackgroundColorAttributeRange = NSRange(location: range.location + range.length,
                                                           length: 1)
            if range.location + range.length + 1 < attributedString.length,
                let nextCharacterRange = attributedString.string.range(from: addBackgroundColorAttributeRange),
                attributedString.string[nextCharacterRange] == "\n",
                let backgroundColor = self.backgroundColor {

                attributedString.addBackgroundColor(backgroundColor,
                                                    toRange: addBackgroundColorAttributeRange)
            }
        }
    }
}
