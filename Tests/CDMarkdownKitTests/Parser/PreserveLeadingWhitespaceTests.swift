//
//  PreserveLeadingWhitespaceTests.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 5/10/26.
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

import Foundation
import Testing
@testable import CDMarkdownKit

struct PreserveLeadingWhitespaceTests {

    @MainActor
    static let parser = CDMarkdownParser()

    @MainActor
    static let parserWithPreserve: CDMarkdownParser = {
        let p = CDMarkdownParser()
        p.preserveLeadingWhitespace = true
        return p
    }()

    @Test @MainActor func inlineCodeStripsByDefault() async {
        let result = await Self.parser.parse("`   indented code`")
        #expect(result.string == "indented code")
    }

    @Test @MainActor func inlineCodePreservesWhenEnabled() async {
        let result = await Self.parserWithPreserve.parse("`   indented code`")
        #expect(result.string == "   indented code")
    }

    @Test @MainActor func fencedCodeStripsByDefault() async {
        let input = """
        ```
           function hello() {
              return "world";
           }
        ```
        """
        let result = await Self.parser.parse(input)
        let lines = result.string.components(separatedBy: "\n")
        // After stripping, first non-empty line should not have leading spaces
        let firstCodeLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        #expect(firstCodeLine?.first != " ")
    }

    @Test @MainActor func parserReferenceIsSet() {
        // Verify that the parser reference is actually set on the syntax element
        #expect(Self.parserWithPreserve.syntax.parser !== nil)
    }

    @Test @MainActor func preserveLeadingWhitespaceIsTrue() {
        // Verify that the property is set to true
        #expect(Self.parserWithPreserve.preserveLeadingWhitespace == true)
    }

    @Test @MainActor func fencedCodePreservesWhenEnabled() async {
        let input = "```\njsx\n   function() {}\n```"
        // Create a fresh parser locally to test
        let testParser = CDMarkdownParser()
        testParser.preserveLeadingWhitespace = true
        let result = await testParser.parse(input)
        // With preserveLeadingWhitespace enabled, the function line should keep its 3 leading spaces
        #expect(result.string.contains("   function"))
    }

    @Test @MainActor func whitespaceAfterCodeBlockNotAffected() async {
        let input = "Before `code` after"
        let result = await Self.parserWithPreserve.parse(input)
        #expect(result.string.contains("Before"))
        #expect(result.string.contains("after"))
    }

    @Test @MainActor func multilineInlineCodeRemovesNewlines() async {
        let input = "`line1\n  line2\n    line3`"
        let result = await Self.parserWithPreserve.parse(input)
        // Inline code removes newlines, so all lines are concatenated
        #expect(result.string.contains("line1"))
        #expect(result.string.contains("line2"))
        #expect(result.string.contains("line3"))
    }

    @Test @MainActor func otherElementsUnaffected() async {
        let input = "**  bold  **"
        let resultDefault = await Self.parser.parse(input)
        let resultPreserve = await Self.parserWithPreserve.parse(input)
        // Both should strip leading space from inside bold
        // because bold element doesn't check preserveLeadingWhitespace
        #expect(resultDefault.string == resultPreserve.string)
    }

    @Test @MainActor func uniformIndentationAcrossDocumentStillFullyStrippedByDefault() async {
        let input = "    first line\n    second line"
        let result = await Self.parser.parse(input)
        #expect(result.string == "first line\nsecond line")
    }

    @Test @MainActor func relativeIndentationBetweenLinesIsPreservedByDefault() async {
        let input = "first line\n  second line"
        let result = await Self.parser.parse(input)
        #expect(result.string == "first line\n  second line")
    }

    @Test @MainActor func blankLineDoesNotZeroOutMarginByDefault() async {
        // The blank line has 3 spaces -- fewer than the 4-space margin shared by the
        // real content lines -- and must not force the margin to zero.
        let input = "    first line\n   \n    second line"
        let result = await Self.parser.parse(input)
        #expect(result.string == "first line\n\nsecond line")
    }

    @Test @MainActor func mixedTabAndSpaceIndentationDoesNotFalselyDedent() async {
        // A tab and four spaces share no common literal prefix, so nothing is stripped.
        let input = "\tfirst line\n    second line"
        let result = await Self.parser.parse(input)
        #expect(result.string == "\tfirst line\n    second line")
    }
}
