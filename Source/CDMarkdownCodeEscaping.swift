//
//  CDMarkdownCodeEscaping.swift
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

open class CDMarkdownCodeEscaping: CDMarkdownElement {
    
    fileprivate static let regex = "(?<!\\\\)(?:\\\\\\\\)*+(`+)(.*?[^`].*?)(\\1)(?!`)"
    
    open var regex: String {
        return CDMarkdownCodeEscaping.regex
    }
    
    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .dotMatchesLineSeparators)
    }
    
    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        let range = match.rangeAt(2)
        // escaping all characters
        let matchString = attributedString.attributedSubstring(from: range).string
        let escapedString = Array<UInt16>(matchString.utf16)
            .map { (value: UInt16) -> String in String(format: "%04x",
                                                       value) }
            .reduce("") { (string: String, character: String) -> String in
                return "\(string)\(character)"
        }
        attributedString.replaceCharacters(in: range,
                                           with: escapedString)
    }
}
