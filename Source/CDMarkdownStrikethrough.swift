//
//  CDMarkdownStrikethrough.swift
//  CDMarkdownKit
//
//  Created by Théo Arrouye on 9/1/22.
//
//  Copyright © 2022 Théo Arrouye
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
    open var underlineStyle: NSUnderlineStyle?
    open var underlineColor: CDColor?
    open var strikethroughStyle: NSUnderlineStyle
    open var strikethroughColor: CDColor?
    
    open var regex: String {
        return CDMarkdownStrikethrough.regex
    }
    
    public init(font: CDFont? = nil,
                customLineStyle: NSUnderlineStyle? = nil,
                strikethroughColor: CDColor? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.strikethroughStyle = customLineStyle ?? .single
        self.strikethroughColor = strikethroughColor
    }
    
    public func addAttributes(_ attributedString: NSMutableAttributedString, range: NSRange) {
        var adjustedAttributes = attributes
        
        adjustedAttributes.addStrikethroughStyle(strikethroughStyle)
        if let stColor = strikethroughColor {
            adjustedAttributes.addStrikethroughColor(stColor)
        }
        
        attributedString.addAttributes(adjustedAttributes, range: range)
    }
    
}
