//
//  NSMutableAttributedString+CDMarkdownKit.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/30/18.
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

internal extension NSMutableAttributedString {

    func addFont(_ font: CDFont,
                 toRange range: NSRange) {
#if swift(>=4.2)
        self.addAttribute(NSAttributedString.Key.font,
                          value: font,
                          range: range)
#elseif swift(>=4.0)
        self.addAttribute(NSAttributedStringKey.font,
                          value: font,
                          range: range)
#else
        self.addAttribute(NSFontAttributeName,
                          value: font,
                          range: range)
#endif
    }

    func addForegroundColor(_ foregroundColor: CDColor,
                            toRange range: NSRange) {
#if swift(>=4.2)
        self.addAttribute(NSAttributedString.Key.foregroundColor,
                          value: foregroundColor,
                          range: range)
#elseif swift(>=4.0)
        self.addAttribute(NSAttributedStringKey.foregroundColor,
                          value: foregroundColor,
                          range: range)
#else
        self.addAttribute(NSForegroundColorAttributeName,
                          value: foregroundColor,
                          range: range)
#endif
    }

    func addBackgroundColor(_ backgroundColor: CDColor,
                            toRange range: NSRange) {
#if swift(>=4.2)
        self.addAttribute(NSAttributedString.Key.backgroundColor,
                          value: backgroundColor,
                          range: range)
#elseif swift(>=4.0)
        self.addAttribute(NSAttributedStringKey.backgroundColor,
                          value: backgroundColor,
                          range: range)
#else
        self.addAttribute(NSBackgroundColorAttributeName,
                          value: backgroundColor,
                          range: range)
#endif
    }

    func addParagraphStyle(_ paragraphStyle: NSParagraphStyle,
                           toRange range: NSRange) {
#if swift(>=4.2)
        self.addAttribute(NSAttributedString.Key.paragraphStyle,
                          value: paragraphStyle,
                          range: range)
#elseif swift(>=4.0)
        self.addAttribute(NSAttributedStringKey.paragraphStyle,
                          value: paragraphStyle,
                          range: range)
#else
        self.addAttribute(NSParagraphStyleAttributeName,
                          value: paragraphStyle,
                          range: range)
#endif
    }

    func addLink(_ link: URL,
                 toRange range: NSRange) {
#if swift(>=4.2)
        self.addAttribute(NSAttributedString.Key.link,
                          value: link,
                          range: range)
#elseif swift(>=4.0)
        self.addAttribute(NSAttributedStringKey.link,
                          value: link,
                          range: range)
#else
        self.addAttribute(NSLinkAttributeName,
                          value: link,
                          range: range)
#endif
    }

    func removeBackgroundColor(atRange range: NSRange) {
#if swift(>=4.2)
        self.removeAttribute(NSAttributedString.Key.backgroundColor,
                             range: range)
#elseif swift(>=4.0)
        self.removeAttribute(NSAttributedStringKey.backgroundColor,
                             range: range)
#else
        self.removeAttribute(NSBackgroundColorAttributeName,
                             range: range)
#endif
    }
}
