import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownTableTests {

    let parser = CDMarkdownParser()

    /// Minimal two-column GFM table
    let simpleTable = """
    | Header 1 | Header 2 |
    | -------- | -------- |
    | Cell A   | Cell B   |
    | Cell C   | Cell D   |
    """

    @Test func tableProducesTabStops() async {
        let result = await parser.parse(simpleTable)
        var hasTabStops = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, !style.tabStops.isEmpty {
                hasTabStops = true
            }
        }
        #expect(hasTabStops)
    }

    @Test func tableHeaderIsBold() async {
        let result = await parser.parse(simpleTable)
        var foundBold = false
        // Header row is first; check the font of the first character
        result.enumerateAttribute(.font,
                                  in: NSRange(location: 0, length: result.length)) { value, range, stop in
            if let font = value as? CDFont, font.isBold, range.location == 0 {
                foundBold = true
                stop.pointee = true
            }
        }
        #expect(foundBold)
    }

    @Test func tableDataIsNotBold() async {
        let result = await parser.parse(simpleTable)
        // The data rows start after the header row; find the first \n and check after it
        guard let newlineRange = result.string.range(of: "\n") else {
            #expect(Bool(false), "No newline found")
            return
        }
        let afterHeader = result.string.distance(from: result.string.startIndex,
                                                 to: newlineRange.upperBound)
        var foundBold = false
        result.enumerateAttribute(.font,
                                  in: NSRange(location: afterHeader,
                                              length: result.length - afterHeader)) { value, _, _ in
            if let font = value as? CDFont, font.isBold {
                foundBold = true
            }
        }
        #expect(!foundBold)
    }

    @Test func tableCellContentIsPreserved() async {
        let result = await parser.parse(simpleTable)
        #expect(result.string.contains("Header 1"))
        #expect(result.string.contains("Cell A"))
        #expect(result.string.contains("Cell D"))
    }

    @Test func tableWithoutLeadingTrailingPipes() async {
        let input = """
        Header 1 | Header 2
        -------- | --------
        Cell A   | Cell B
        """
        let result = await parser.parse(input)
        var hasTabStops = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, !style.tabStops.isEmpty {
                hasTabStops = true
            }
        }
        #expect(hasTabStops)
    }

    @Test func nonTableTextIsUnaffected() async {
        // Text with pipes but no valid separator row (no dashes)
        let input = """
        | Hello | world |
        | This | is | not | a | table |
        """
        let result = await parser.parse(input)
        // Without a proper separator row, the pipes should be preserved as text
        #expect(result.string.contains("|"))
        // The text should not be transformed into a table (would remove pipes)
        #expect(result.string.contains("Hello"))
        #expect(result.string.contains("world"))
    }

    @Test func tableCellWithBoldContent() async {
        let input = """
        | Header |
        | ------ |
        | **bold text** |
        """
        let result = await parser.parse(input)
        var foundBold = false
        result.enumerateAttribute(.font,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold {
                foundBold = true
            }
        }
        #expect(foundBold)
    }

    @Test func tableCellWithItalicContent() async {
        let input = """
        | Header |
        | ------ |
        | *italic text* |
        """
        let result = await parser.parse(input)
        var foundItalic = false
        result.enumerateAttribute(.font,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isItalic {
                foundItalic = true
            }
        }
        #expect(foundItalic)
    }

    @Test func tableCellWithLinkContent() async {
        let input = """
        | Header |
        | ------ |
        | [GitHub](https://github.com) |
        """
        let result = await parser.parse(input)
        var foundLink = false
        result.enumerateAttribute(.link,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil {
                foundLink = true
            }
        }
        #expect(foundLink)
    }

    @Test func tableCellWithInlineCode() async {
        let input = """
        | Header |
        | ------ |
        | `code` |
        """
        let result = await parser.parse(input)
        var foundCode = false
        result.enumerateAttribute(.cdMarkdownRoundedBackground,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let rounded = value as? Bool, rounded {
                foundCode = true
            }
        }
        #expect(foundCode)
    }

    @Test func tableCellWithInlineCodeRendersOriginalText() async {
        let input = """
        | Header |
        | ------ |
        | `code` |
        """
        let result = await parser.parse(input)
        #expect(result.string.contains("code"))
        #expect(!result.string.contains("0063"))
    }

    @Test func tableNonFinalColumnWithInlineCodeMeasuresRenderedWidth() async {
        let codeContent = "abcdefghijklmnopqrst"
        let input = """
        | A | Code | B |
        | --- | ---- | --- |
        | 1 | `\(codeContent)` | 2 |
        """
        let result = await parser.parse(input)

        guard let tableStyle = result.attribute(.paragraphStyle,
                                                at: 0,
                                                effectiveRange: nil) as? NSParagraphStyle,
            tableStyle.tabStops.count == 3 else {
            #expect(Bool(false), "Expected a paragraph style with 3 tab stops")
            return
        }

        // Column 0's measured width is unaffected by the bug (it contains no inline code),
        // so it's a reliable baseline: tabStops[1].location == columnWidths[0].
        let column0Width = tableStyle.tabStops[1].location
        let actualColumn1Width = tableStyle.tabStops[2].location - column0Width

        // The correct column width comes from the *rendered* (unescaped) cell text, not
        // the UTF16-hex-escaped placeholder Phase 1 produces for the backtick span.
        let expectedColumn1Width = codeContent.sizeWithAttributes(parser.table.attributes).width +
            parser.table.columnPadding

        #expect(abs(actualColumn1Width - expectedColumn1Width) < 1.0)
    }

    @Test func raggedTableWithWiderLaterRowKeepsAllCells() async {
        let raggedTable = """
        | A | B |
        | --- | --- |
        | 1 | 2 |
        | 3 | 4 | 5 |
        """
        let result = await parser.parse(raggedTable)
        #expect(result.string.contains("5"))
    }
}
