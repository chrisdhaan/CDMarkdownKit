import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownListTests {

    let parser = CDMarkdownParser()

    @Test func asteriskBulletProducesList() async {
        let result = await parser.parse("* item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func dashBulletProducesList() async {
        let result = await parser.parse("- item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func plusBulletProducesList() async {
        let result = await parser.parse("+ item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let s = v as? NSParagraphStyle, s.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func listMarkerIsReplaced() async {
        let result = await parser.parse("* item")
        #expect(!result.string.contains("*"))
    }

    @Test func listBulletCharacterIsPresent() async {
        // The default indicator is "•"; verify it replaces the markdown marker
        let result = await parser.parse("* item")
        #expect(result.string.contains("•"))
    }

    @Test func topLevelListItemHasNoExtraIndentPrefix() async {
        let result = await parser.parse("* item")
        #expect(result.string == "• item")
    }

    /// Reads the paragraphStyle attribute effective at the start of the (single-line)
    /// paragraph, matching how UIKit/AppKit text layout actually resolves per-paragraph
    /// attributes such as headIndent (from the first character of the paragraph). A plain
    /// full-range `enumerateAttribute` scan would instead report whichever attribute run is
    /// enumerated *last* -- the content-text run, not the marker/indicator run -- since
    /// `CDMarkdownList.addAttributes` re-applies the instance's own base paragraphStyle over
    /// the content-only range after `addFullAttributes` sets the level-derived headIndent over
    /// the full match, making "last enumerated value" an unreliable proxy for the effective indent.
    private func effectiveHeadIndent(of attributed: NSAttributedString, atCharacterIndex index: Int = 0) -> CGFloat {
        guard attributed.length > index,
              let style = attributed.attribute(.paragraphStyle, at: index, effectiveRange: nil) as? NSParagraphStyle else {
            return 0
        }
        return style.headIndent
    }

    @Test func indentedListItemNestsDeeperThanTopLevelWhenPreservingWhitespace() async {
        let nestingParser = CDMarkdownParser()
        nestingParser.preserveLeadingWhitespace = true

        let topLevel = await nestingParser.parse("* item")
        let nested = await nestingParser.parse("  * item")

        #expect(effectiveHeadIndent(of: nested) > effectiveHeadIndent(of: topLevel))
    }

    @Test func indentationNestingRequiresPreserveLeadingWhitespace() async {
        // A single indented line has no sibling line to establish *relative* indentation
        // against -- its whole leading whitespace run is the whole-document dedent margin, so
        // it's still fully stripped under default settings. Multi-line nesting (see
        // nestedListItemIndentsDeeperThanParentUnderDefaultSettings) works without opting in;
        // this single-line case specifically does not, and preserveLeadingWhitespace remains
        // the way to force it.
        let defaultParser = CDMarkdownParser()
        let topLevel = await defaultParser.parse("* item")
        let indented = await defaultParser.parse("  * item")

        #expect(effectiveHeadIndent(of: indented) == effectiveHeadIndent(of: topLevel))
    }

    @Test func nestedListItemIndentsDeeperThanParentUnderDefaultSettings() async {
        // Two lines in one parse call: the parent has no leading whitespace, so the
        // whole-document margin is zero and the nested item's 2-space indent survives.
        let result = await parser.parse("* item\n  * nested item")
        let nsString = result.string as NSString
        let newlineRange = nsString.range(of: "\n")
        #expect(newlineRange.location != NSNotFound)
        let secondLineStart = newlineRange.location + newlineRange.length

        let topLevelIndent = effectiveHeadIndent(of: result)
        let nestedIndent = effectiveHeadIndent(of: result, atCharacterIndex: secondLineStart)
        #expect(nestedIndent > topLevelIndent)
    }

    @Test func blankLinesBeforeListItemDoNotAddSpuriousIndentationWhenSquashNewlinesDisabled() async {
        let noSquashParser = CDMarkdownParser()
        noSquashParser.squashNewlines = false

        let result = await noSquashParser.parse("Some text.\n\n\n* item")
        let nsString = result.string as NSString
        let markerRange = nsString.range(of: "• item")
        #expect(markerRange.location != NSNotFound)

        let indentedIndent = effectiveHeadIndent(of: result, atCharacterIndex: markerRange.location)
        let topLevelParsed = await noSquashParser.parse("* item")
        let topLevelIndent = effectiveHeadIndent(of: topLevelParsed)
        #expect(indentedIndent == topLevelIndent)
    }
}
