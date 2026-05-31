import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownTaskListTests {

    let parser = CDMarkdownParser()

    @Test func uncheckedItemRendersUncheckedMarker() {
        let result = parser.parse("- [ ] Buy milk")
        #expect(result.string.hasPrefix("☐ "))
        #expect(result.string.contains("Buy milk"))
    }

    @Test func checkedItemRendersCheckedMarker() {
        let result = parser.parse("- [x] Buy milk")
        #expect(result.string.hasPrefix("☑ "))
        #expect(result.string.contains("Buy milk"))
    }

    @Test func checkedItemUppercaseX() {
        let result = parser.parse("- [X] Buy milk")
        #expect(result.string.hasPrefix("☑ "))
    }

    @Test func asteriskMarkerSupported() {
        let result = parser.parse("* [ ] Task")
        #expect(result.string.hasPrefix("☐ "))
    }

    @Test func plusMarkerSupported() {
        let result = parser.parse("+ [x] Done")
        #expect(result.string.hasPrefix("☑ "))
    }

    @Test func plainListItemNotConsumed() {
        // A plain bullet without checkbox syntax must still be handled by CDMarkdownList
        let result = parser.parse("- plain item")
        #expect(!result.string.hasPrefix("☐"))
        #expect(!result.string.hasPrefix("☑"))
    }

    @Test func multipleTaskItems() {
        let input = "- [ ] First\n- [x] Second\n- [ ] Third"
        let result = parser.parse(input)
        #expect(result.string.contains("☐"))
        #expect(result.string.contains("☑"))
    }

    @Test func hasHeadIndent() {
        let result = parser.parse("- [ ] Item with a long enough text to wrap")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func customMarkerStrings() {
        let parser = CDMarkdownParser()
        parser.taskList.uncheckedMarker = "[ ] "
        parser.taskList.checkedMarker = "[x] "
        let result = parser.parse("- [ ] Item")
        #expect(result.string.hasPrefix("[ ] "))
    }
}
