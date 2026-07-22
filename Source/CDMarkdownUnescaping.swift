//
//  CDMarkdownUnescaping.swift
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
open class CDMarkdownUnescaping: CDMarkdownElement {

    fileprivate static let regex = "(?:\\\\[0-9a-z]{4})+"

    open var regex: String {
        CDMarkdownUnescaping.regex
    }

    open func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex,
                                options: .dotMatchesLineSeparators)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        // May span multiple consecutive "\xxxx" groups (e.g. both halves of a surrogate
        // pair); strip the backslashes and decode all the hex digits together so
        // String(utf16CodeUnits:count:) can recombine a valid pair correctly.
        let matchString = attributedString.attributedSubstring(from: match.range).string
        let hexOnly = matchString.replacingOccurrences(of: "\\", with: "")
        guard let unescapedString = hexOnly.unescapeUTF16() else { return }
        attributedString.replaceCharacters(in: match.range,
                                           with: unescapedString)
    }
}
