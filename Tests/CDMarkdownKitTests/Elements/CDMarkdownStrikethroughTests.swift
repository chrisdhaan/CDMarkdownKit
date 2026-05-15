import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownStrikethroughTests {

    let parser = CDMarkdownParser()

    @Test func doubleTildeProducesStrikethrough() {
        let result = parser.parse("~~strikethrough~~")
        var hasStrikethrough = false
        result.enumerateAttribute(.strikethroughStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { hasStrikethrough = true }
        }
        #expect(hasStrikethrough)
    }

    @Test func singleTildeIsNotStrikethrough() {
        let result = parser.parse("~not strikethrough~")
        var hasStrikethrough = false
        result.enumerateAttribute(.strikethroughStyle, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { hasStrikethrough = true }
        }
        #expect(!hasStrikethrough)
    }

    @Test func strikethroughDelimitersAreStripped() {
        let result = parser.parse("~~strikethrough~~")
        #expect(!result.string.contains("~"))
    }

    @Test func strikethroughCanContainOtherMarkdown() {
        let result = parser.parse("~~**bold strikethrough**~~")
        // Strikethrough with nested markdown should parse without error
        #expect(result.length > 0)
    }

    @Test func customStrikethroughColorIsApplied() {
        let parser = CDMarkdownParser()
        parser.strikethrough.strikethroughColor = CDColor.red
        let result = parser.parse("~~text~~")
        var found = false
        result.enumerateAttribute(.strikethroughColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.red { found = true }
        }
        #expect(found)
    }

    @Test func customStrikethroughStyleIsDouble() {
        let parser = CDMarkdownParser()
        parser.strikethrough.strikethroughStyle = .double
        let result = parser.parse("~~text~~")
        var foundDouble = false
        result.enumerateAttribute(.strikethroughStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            let raw = (value as? NSNumber)?.intValue ?? (value as? Int ?? -1)
            if raw == NSUnderlineStyle.double.rawValue { foundDouble = true }
        }
        #expect(foundDouble)
    }
}
