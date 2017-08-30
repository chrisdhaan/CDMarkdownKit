//
//  CDMarkdownHeader.swift
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

open class CDMarkdownHeader: CDMarkdownLevelElement {
    
    fileprivate static let regex = "^\\s*(#{1,%@})\\s*(.+)$\n*"
    fileprivate struct CDMarkdownHeadingHashes {
        static let one      = 3
        static let two      = 2
        static let three    = 1
        static let four     = 0
        static let five     = -1
        static let six      = -2
        static let zero     = -3
    }
    
    open var maxLevel: Int
    open var font: UIFont?
    open var color: UIColor?
    open var backgroundColor: UIColor?
    open var fontIncrease: Int
    
    open var regex: String {
        let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
        return String(format: CDMarkdownHeader.regex, level)
    }
    
    public init(font: UIFont? = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize),
                maxLevel: Int = 0, fontIncrease: Int = 2, color: UIColor? = nil,
                backgroundColor: UIColor? = nil) {
        self.maxLevel = maxLevel
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.fontIncrease = fontIncrease
    }
    
    open func formatText(_ attributedString: NSMutableAttributedString, range: NSRange, level: Int) {
        attributedString.deleteCharacters(in: range)
        
        let string = attributedString.mutableString
        if range.location-2 > 0 && string.substring(with:NSRange(location:range.location-2, length:2)) == "\n\n" {
            string.deleteCharacters(in: NSRange(location:range.location-1, length:1))
        }
    }
    
    open func attributesForLevel(_ level: Int) -> [String: AnyObject] {
        var attributes = self.attributes
        var fontMultiplier: CGFloat
        switch level {
        case 0:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.one)
        case 1:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.two)
        case 2:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.three)
        case 3:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.four)
        case 4:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.five)
        case 5:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.six)
        case 6:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.zero)
        default:
            fontMultiplier = CGFloat(CDMarkdownHeadingHashes.four)
        }
        if let font = font {
            let headerFontSize: CGFloat = font.pointSize + (CGFloat(fontMultiplier) * CGFloat(fontIncrease))
            attributes[NSFontAttributeName] = font.withSize(headerFontSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 6
            paragraphStyle.paragraphSpacingBefore = 12
            attributes[NSParagraphStyleAttributeName] = paragraphStyle
        }
        return attributes
    }
}
