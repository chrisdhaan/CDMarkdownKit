//
//  CDMarkdownStyle.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright © 2016-2018 Christopher de Haan <contact@christopherdehaan.me>
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

// Styling protocol for all MarkdownElements
public protocol CDMarkdownStyle {

    var font: CDFont? { get }
    var color: CDColor? { get }
    var backgroundColor: CDColor? { get }
    var paragraphStyle: NSParagraphStyle? { get }
    var attributes: [CDAttributesKey: AnyObject] { get }
}

public extension CDMarkdownStyle {

    var attributes: [CDAttributesKey: AnyObject] {
        var attributes = [CDAttributesKey: AnyObject]()
#if swift(>=4.2)
        if let font = font {
            attributes[NSAttributedString.Key.font] = font
        }
        if let color = color {
            attributes[NSAttributedString.Key.foregroundColor] = color
        }
        if let backgroundColor = backgroundColor {
            attributes[NSAttributedString.Key.backgroundColor] = backgroundColor
        }
        if let paragraphStyle = paragraphStyle {
            attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        }
#elseif swift(>=4.0)
        if let font = font {
            attributes[NSAttributedStringKey.font] = font
        }
        if let color = color {
            attributes[NSAttributedStringKey.foregroundColor] = color
        }
        if let backgroundColor = backgroundColor {
            attributes[NSAttributedStringKey.backgroundColor] = backgroundColor
        }
        if let paragraphStyle = paragraphStyle {
            attributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
        }
#else
        if let font = font {
            attributes[NSFontAttributeName] = font
        }
        if let color = color {
            attributes[NSForegroundColorAttributeName] = color
        }
        if let backgroundColor = backgroundColor {
            attributes[NSBackgroundColorAttributeName] = backgroundColor
        }
        if let paragraphStyle = paragraphStyle {
            attributes[NSParagraphStyleAttributeName] = paragraphStyle
        }
#endif
        return attributes
    }
}
