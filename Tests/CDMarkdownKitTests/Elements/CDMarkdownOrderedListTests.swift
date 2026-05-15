import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
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
