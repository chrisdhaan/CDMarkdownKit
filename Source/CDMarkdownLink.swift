//
//  CDMarkdownLink.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
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

open class CDMarkdownLink: CDMarkdownLinkElement {

    fileprivate static let regex = "[^!{1}]\\[([^\\[]*?)\\]\\(([^\\)]*)\\)"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        return CDMarkdownLink.regex
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .dotMatchesLineSeparators)
    }

    public init(font: CDFont? = nil,
                color: CDColor? = CDColor.blue,
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

    open func formatText(_ attributedString: NSMutableAttributedString,
                         range: NSRange,
                         link: String) {
        guard let encodedLink = link.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
            else {
                return
        }
        guard let url = URL(string: link) ?? URL(string: encodedLink) else { return }

        attributedString.addLink(url,
                                 toRange: range)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 3 else { return }

        let nsString = attributedString.string as NSString
        let linkStartInResult = nsString.range(of: "(",
                                               options: .backwards,
                                               range: match.range).location
        let linkRange = NSRange(location: linkStartInResult,
                                length: match.range.length + match.range.location - linkStartInResult - 1)
        let linkURLString = nsString.substring(with: NSRange(location: linkRange.location + 1,
                                                             length: linkRange.length - 1))

        // deleting trailing markdown
        // needs to be called before formattingBlock to support modification of length
        attributedString.deleteCharacters(in: NSRange(location: linkRange.location - 1,
                                                      length: linkRange.length + 2))

        // deleting leading markdown
        // needs to be called before formattingBlock to provide a stable range
        attributedString.deleteCharacters(in: NSRange(location: match.range.location + 1,
                                                      length: 1))
        let formatRange = NSRange(location: match.range.location + 1,
                                  length: linkStartInResult - match.range.location - 3)

        formatText(attributedString,
                   range: formatRange,
                   link: linkURLString)
        addAttributes(attributedString,
                      range: formatRange,
                      link: linkURLString)
    }

    open func addAttributes(_ attributedString: NSMutableAttributedString,
                            range: NSRange,
                            link: String) {
        attributedString.addAttributes(attributes,
                                       range: range)
    }
}
