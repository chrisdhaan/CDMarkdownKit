import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
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

    @Test func tableProducesTabStops() {
        let result = parser.parse(simpleTable)
        var hasTabStops = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, !style.tabStops.isEmpty {
                hasTabStops = true
            }
        }
        #expect(hasTabStops)
    }

    @Test func tableHeaderIsBold() {
        let result = parser.parse(simpleTable)
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

    @Test func tableDataIsNotBold() {
        let result = parser.parse(simpleTable)
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
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(!foundBold)
    }

    @Test func tableCellContentIsPreserved() {
        let result = parser.parse(simpleTable)
        #expect(result.string.contains("Header 1"))
        #expect(result.string.contains("Cell A"))
        #expect(result.string.contains("Cell D"))
    }

    @Test func tableWithoutLeadingTrailingPipes() {
        let input = """
        Header 1 | Header 2
        -------- | --------
        Cell A   | Cell B
        """
        let result = parser.parse(input)
        var hasTabStops = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, !style.tabStops.isEmpty {
                hasTabStops = true
            }
        }
        #expect(hasTabStops)
    }

    @Test func nonTableTextIsUnaffected() {
        // Text with pipes but no valid separator row (no dashes)
        let input = """
        | Hello | world |
        | This | is | not | a | table |
        """
        let result = parser.parse(input)
        // Without a proper separator row, the pipes should be preserved as text
        #expect(result.string.contains("|"))
        // The text should not be transformed into a table (would remove pipes)
        #expect(result.string.contains("Hello"))
        #expect(result.string.contains("world"))
    }
}
