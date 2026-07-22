import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownListTests {

    let parser = CDMarkdownParser()

    @Test func asteriskBulletProducesList() {
        let result = parser.parse("* item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func dashBulletProducesList() {
        let result = parser.parse("- item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func plusBulletProducesList() {
        let result = parser.parse("+ item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func listMarkerIsReplaced() {
        let result = parser.parse("* item")
        #expect(!result.string.contains("*"))
    }

    @Test func listBulletCharacterIsPresent() {
        // The default indicator is "•"; verify it replaces the markdown marker
        let result = parser.parse("* item")
        #expect(result.string.contains("•"))
    }

    @Test func topLevelListItemHasNoExtraIndentPrefix() {
        let result = parser.parse("* item")
        #expect(result.string == "• item")
    }

    /// Reads the paragraphStyle attribute effective at the start of the (single-line)
    /// paragraph, matching how UIKit/AppKit text layout actually resolves per-paragraph
    /// attributes such as headIndent (from the first character of the paragraph). A plain
    /// full-range `enumerateAttribute` scan would instead report whichever attribute run is
    /// enumerated *last* -- which for a list item is the content-text run, not the
    /// marker/indicator run -- because `CDMarkdownList.addAttributes` (unchanged by this fix,
    /// and out of scope per the task's scoping decision) re-applies the instance's own base
    /// paragraphStyle over the content-only range after `addFullAttributes` sets the
    /// level-derived headIndent over the full match. That re-application doesn't affect real
    /// rendering (paragraph attributes are resolved from the paragraph's first character), but
    /// it does mean "last enumerated value" is not a reliable proxy for the effective indent.
    private func effectiveHeadIndent(of attributed: NSAttributedString) -> CGFloat {
        guard attributed.length > 0,
              let style = attributed.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            return 0
        }
        return style.headIndent
    }

    @Test func indentedListItemNestsDeeperThanTopLevelWhenPreservingWhitespace() {
        let nestingParser = CDMarkdownParser()
        nestingParser.preserveLeadingWhitespace = true

        let topLevel = nestingParser.parse("* item")
        let nested = nestingParser.parse("  * item")

        #expect(effectiveHeadIndent(of: nested) > effectiveHeadIndent(of: topLevel))
    }

    @Test func indentationNestingRequiresPreserveLeadingWhitespace() {
        // Under default settings, leading whitespace is stripped before CDMarkdownList
        // ever sees it, so indentation-based nesting is a documented no-op unless the
        // caller opts in via preserveLeadingWhitespace.
        let defaultParser = CDMarkdownParser()
        let topLevel = defaultParser.parse("* item")
        let indented = defaultParser.parse("  * item")

        #expect(effectiveHeadIndent(of: indented) == effectiveHeadIndent(of: topLevel))
    }
}
