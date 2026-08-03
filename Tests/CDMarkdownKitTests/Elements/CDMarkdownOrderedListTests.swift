import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownOrderedListTests {

    let parser = CDMarkdownParser()

    @Test func singleItemHasHeadIndent() {
        let result = parser.parse("1. First item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func markerNumberIsPreserved() {
        let result = parser.parse("42. Some item")
        #expect(result.string.hasPrefix("42."))
    }

    @Test func multipleItemsAreRendered() {
        let result = parser.parse("1. First\n2. Second\n3. Third")
        #expect(result.string.contains("1."))
        #expect(result.string.contains("2."))
        #expect(result.string.contains("3."))
    }

    @Test func whitespaceAfterMarkerNormalized() {
        // "1.   item" (three spaces) should normalize to "1. item" (one space)
        let result = parser.parse("1.   item")
        #expect(result.string == "1. item")
    }

    @Test func indentedItemStillRecognizedAlongsideFlushLeftItem() {
        // Under the dedent-based whitespace handling, a document containing at least one
        // flush-left line leaves other lines' indentation untouched -- including indentation
        // in front of an ordered-list marker. The ordered-list regex must still match it (this
        // only restores the ability to parse the indented item, not nesting -- CDMarkdownOrderedList
        // has no indent-level concept, so the leading indentation itself is preserved as-is,
        // unlike CDMarkdownList which strips/consumes it to derive a nesting level).
        //
        // Extra spaces after the marker are used here so a passing test can only mean the line
        // was actually matched and run through CDMarkdownOrderedList.match() (which normalizes
        // the marker/content spacer to a single space) -- not that the raw text simply happened
        // to already look right.
        let result = parser.parse("1. item\n   2.    nested")
        #expect(result.string.contains("2. nested"))
        #expect(!result.string.contains("2.    nested"))

        var hasHeadIndentOnSecondLine = false
        let secondLineRange = (result.string as NSString).range(of: "2. nested")
        result.enumerateAttribute(.paragraphStyle,
                                  in: secondLineRange) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndentOnSecondLine = true
            }
        }
        #expect(hasHeadIndentOnSecondLine)
    }

    @Test func doesNotMatchUnorderedList() {
        let result = parser.parse("* bullet")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        // CDMarkdownList (not CDMarkdownOrderedList) must still handle this
        #expect(hasHeadIndent)
    }
}
