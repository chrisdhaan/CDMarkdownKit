//
//  CDMarkdownLink.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright (c) 2016-2017 Christopher de Haan <contact@christopherdehaan.me>
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

import UIKit

open class CDMarkdownLink: CDMarkdownLinkElement {

    fileprivate static let regex = "\\[([^\\[]*?)\\]\\(([^\\)]*)\\)"

    open var font: UIFont?
    open var color: UIColor?
    open var backgroundColor: UIColor?

    open var regex: String {
        return CDMarkdownLink.regex
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
    }

    public init(font: UIFont? = nil, color: UIColor? = UIColor.blue, backgroundColor: UIColor? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
    }

    open func formatText(_ attributedString: NSMutableAttributedString, range: NSRange,
                         link: String) {
        guard let encodedLink = link.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
            else {
                return
        }
        guard let url = URL(string: link) ?? URL(string: encodedLink) else { return }
        attributedString.addAttribute(NSAttributedStringKey.link, value: url, range: range)
    }

    open func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {

        guard match.numberOfRanges == 3 else {
            return
        }
        let nsString = attributedString.string as NSString
        let textRange = match.range(at: 1)
        let linkText = nsString.substring(with: textRange)
        let linkURLString = nsString.substring(with: match.range(at: 2))

        //Replace entire match with linkText first, to provide stable range
        attributedString.replaceCharacters(in: match.range(at: 0), with: linkText)

        let formatRange = NSRange(location: match.range.location,
                                  length: textRange.length)
        formatText(attributedString, range: formatRange, link: linkURLString)
        addAttributes(attributedString, range: formatRange, link: linkURLString)
    }

    open func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange,
                            link: String) {
        //Use surrounding font/color attributes on a link
    }
}
