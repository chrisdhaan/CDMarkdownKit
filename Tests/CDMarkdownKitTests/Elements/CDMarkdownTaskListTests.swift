import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownTaskListTests {

    let parser = CDMarkdownParser()

    @Test func uncheckedItemRendersUncheckedMarker() async {
        let result = await parser.parse("- [ ] Buy milk")
        #expect(result.string.hasPrefix("☐ "))
        #expect(result.string.contains("Buy milk"))
    }

    @Test func checkedItemRendersCheckedMarker() async {
        let result = await parser.parse("- [x] Buy milk")
        #expect(result.string.hasPrefix("☑ "))
        #expect(result.string.contains("Buy milk"))
    }

    @Test func checkedItemUppercaseX() async {
        let result = await parser.parse("- [X] Buy milk")
        #expect(result.string.hasPrefix("☑ "))
    }

    @Test func asteriskMarkerSupported() async {
        let result = await parser.parse("* [ ] Task")
        #expect(result.string.hasPrefix("☐ "))
    }

    @Test func plusMarkerSupported() async {
        let result = await parser.parse("+ [x] Done")
        #expect(result.string.hasPrefix("☑ "))
    }

    @Test func plainListItemNotConsumed() async {
        // A plain bullet without checkbox syntax must still be handled by CDMarkdownList
        let result = await parser.parse("- plain item")
        #expect(!result.string.hasPrefix("☐"))
        #expect(!result.string.hasPrefix("☑"))
    }

    @Test func multipleTaskItems() async {
        let input = "- [ ] First\n- [x] Second\n- [ ] Third"
        let result = await parser.parse(input)
        #expect(result.string.contains("☐"))
        #expect(result.string.contains("☑"))
    }

    @Test func hasHeadIndent() async {
        let result = await parser.parse("- [ ] Item with a long enough text to wrap")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func customMarkerStrings() async {
        let parser = CDMarkdownParser()
        parser.taskList.uncheckedMarker = "[ ] "
        parser.taskList.checkedMarker = "[x] "
        let result = await parser.parse("- [ ] Item")
        #expect(result.string.hasPrefix("[ ] "))
    }
}
