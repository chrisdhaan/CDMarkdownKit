//
//  CDMarkdownCode.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/10/16.
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

open class CDMarkdownSyntax: CDMarkdownCommonElement {
    
    fileprivate static let regex = "(\\s+|^)(`{3})(\\s*[^`]*?\\s*)(\\2)(?!`)"
    
    open var font: UIFont?
    open var color: UIColor?
    open var backgroundColor: UIColor?
    
    open var regex: String {
        return CDMarkdownSyntax.regex
    }
    
    public init(font: UIFont?,
                color: UIColor? = UIColor.syntaxTextGray(),
                backgroundColor: UIColor? = UIColor.syntaxBackgroundGray()) {
        if let defaultFont = font {
            self.font = defaultFont;
        } else {
            #if os(iOS)
                self.font = UIFont(name: "Menlo-Regular", size: UIFont.smallSystemFontSize)
            #else
                self.font = UIFont(name: "Menlo-Regular", size: 20)
            #endif
        }
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
    }
    
    open func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange) {
        let matchString: String = attributedString.attributedSubstring(from: range).string
        guard let unescapedString = matchString.unescapeUTF16() else { return }
        attributedString.replaceCharacters(in: range, with: unescapedString)
        let replacedRange = NSRange(location: range.location, length: unescapedString.characters.count)
        attributedString.addAttributes(attributes, range: replacedRange)
        let mutableString = attributedString.mutableString
        mutableString.replaceOccurrences(of: "\n", with: "", options: [], range: NSRange(location:replacedRange.location, length:1))
    }
}
