//
//  CDMarkdownStyle.swift
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

// Styling protocol for all MarkdownElements
public protocol CDMarkdownStyle {

    var font: CDFont? { get }
    var color: CDColor? { get }
    var backgroundColor: CDColor? { get }
    var paragraphStyle: NSParagraphStyle? { get }
    var underlineColor: CDColor? { get }
    var underlineStyle: NSUnderlineStyle? { get }
    var attributes: [CDAttributedStringKey: AnyObject] { get }
}

public extension CDMarkdownStyle {

    var attributes: [CDAttributedStringKey: AnyObject] {
        var attributes = [CDAttributedStringKey: AnyObject]()

        if let font = font {
            attributes.addFont(font)
        }
        if let color = color {
            attributes.addForegroundColor(color)
        }
        if let backgroundColor = backgroundColor {
            attributes.addBackgroundColor(backgroundColor)
        }
        if let paragraphStyle = paragraphStyle {
            attributes.addParagraphStyle(paragraphStyle)
        }
        if let underlineColor = underlineColor {
            attributes.addUnderlineColor(underlineColor)
        }
        if let underlineStyle = underlineStyle {
            attributes.addUnderlineStyle(underlineStyle)
        }

        return attributes
    }
}
