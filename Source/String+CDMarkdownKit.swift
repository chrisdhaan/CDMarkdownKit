//
//  String+CDMarkdownKit.swift
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

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

internal extension String {

    // Converts each character to its UTF16 form in hexadecimal value (e.g. "H" -> "0048")
    func escapeUTF16() -> String {
        return Array(utf16).map {
            String(format: "%04x",
                   $0)
            }.reduce("") {
                return $0 + $1
        }
    }

    // Converts each 4 digit characters to its String form  (e.g. "0048" -> "H")
    func unescapeUTF16() -> String? {
        var utf16Array = [UInt16]()
        stride(from: 0,
               to: count,
               by: 4).forEach {
            let startIdx = index(startIndex,
                                 offsetBy: $0)
            if ($0 + 4) <= count {
                let endIdx = index(startIndex,
                                   offsetBy: $0 + 4)
                let hex4 = self[startIdx..<endIdx]

                if let utf16 = UInt16(hex4,
                                      radix: 16) {
                    utf16Array.append(utf16)
                }
            }
        }

        return String(utf16CodeUnits: utf16Array,
                      count: utf16Array.count)
    }

    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }

    func characterCount() -> Int {
        return self.count
    }

    func sizeWithAttributes(_ attributes: [CDAttributedStringKey: Any]? = nil) -> CGSize {
#if os(macOS)
        return self.size(withAttributes: attributes)
#else
        return self.size(withAttributes: attributes)
#endif
    }
}
