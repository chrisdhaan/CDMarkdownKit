//
//  CDMarkdownParser+Dedent.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 8/3/26.
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

extension CDMarkdownParser {

    /// Strips only the whitespace common to every non-blank line (a dedent, like Python's
    /// `textwrap.dedent` or Swift's own multi-line string literals) rather than stripping every
    /// line's leading whitespace outright. This still cleans up incidental uniform indentation
    /// (e.g. markdown embedded in indented Swift source) while preserving the *relative*
    /// indentation that nested list markers depend on. Blank/whitespace-only lines are excluded
    /// from the margin computation and always normalized to empty, so a stray blank line can't
    /// zero out the margin for the rest of the document.
    static func dedent(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")

        func isBlank(_ line: String) -> Bool {
            line.allSatisfy { $0 == " " || $0 == "\t" || $0 == "\r" }
        }

        func leadingWhitespace(of line: String) -> String {
            let end = line.firstIndex { $0 != " " && $0 != "\t" } ?? line.endIndex
            return String(line[line.startIndex ..< end])
        }

        func commonPrefix(_ lhs: String, _ rhs: String) -> String {
            var result = ""
            for (left, right) in zip(lhs, rhs) {
                guard left == right else { break }
                result.append(left)
            }
            return result
        }

        let nonBlankLines = lines.filter { !isBlank($0) }
        var margin = ""
        if let first = nonBlankLines.first {
            margin = leadingWhitespace(of: first)
            for line in nonBlankLines.dropFirst() {
                margin = commonPrefix(margin, leadingWhitespace(of: line))
                if margin.isEmpty {
                    break
                }
            }
        }

        let marginLength = margin.count
        return lines.map { line in
            isBlank(line)
                ? String(line.filter { $0 != " " && $0 != "\t" })
                : String(line.dropFirst(marginLength))
        }.joined(separator: "\n")
    }
}
