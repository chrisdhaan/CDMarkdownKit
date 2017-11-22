//
//  CDMarkdownQuote.swift
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

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownQuote: CDMarkdownLevelElement {
    
    fileprivate static let regex = "^(\\>{1,%@})\\s*(.+)$"
    
    open var maxLevel: Int
    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var separator: String
    open var indicator: String
    
    open var regex: String {
        let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
        return String(format: CDMarkdownQuote.regex,
                      level)
    }
    
    public init(font: CDFont? = nil,
                maxLevel: Int = 0,
                indicator: String = ">",
                separator: String = "  ",
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil) {
        self.maxLevel = maxLevel
        self.indicator = indicator
        self.separator = separator
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
    }
    
    open func formatText(_ attributedString: NSMutableAttributedString,
                         range: NSRange,
                         level: Int) {
        var string = (0..<level).reduce("") { (string: String, _: Int) -> String in
            return "\(string)\(separator)"
        }
        string = "\(string)\(indicator) "
        attributedString.replaceCharacters(in: range,
                                           with: string)
    }
}
