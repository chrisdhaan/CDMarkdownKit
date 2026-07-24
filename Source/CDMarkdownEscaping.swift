//
//  CDMarkdownEscaping.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright © 2016-2026 Christopher de Haan <contact@christopherdehaan.me>
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

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

@MainActor
open class CDMarkdownEscaping: CDMarkdownElement {

    fileprivate static let regex = "\\\\."

    open var regex: String {
        CDMarkdownEscaping.regex
    }

    open func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex,
                                options: .dotMatchesLineSeparators)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        // The escaped character may be a single UTF-16 unit or a surrogate pair (e.g. most
        // emoji); replace the whole match (backslash + character) with one "\xxxx" group per
        // UTF-16 unit so CDMarkdownUnescaping can decode multi-unit characters together.
        let characterRange = NSRange(location: match.range.location + 1,
                                     length: match.range.length - 1)
        let matchString = attributedString.attributedSubstring(from: characterRange).string
        let escapedString = matchString.utf16.map { unit -> String in
            "\\" + String(format: "%04x", unit)
        }.joined()
        attributedString.replaceCharacters(in: match.range,
                                           with: escapedString)
    }
}
