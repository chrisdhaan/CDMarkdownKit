import Foundation
import Testing
#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownParserStyleTests {

    @Test func boldForegroundColorIsApplied() async {
        // Given
        let parser = CDMarkdownParser()
        parser.bold.color = CDColor.red
        // When
        let result = await parser.parse("**bold**")
        // Then
        var found = false
        result.enumerateAttribute(.foregroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.red {
                found = true
            }
        }
        #expect(found)
    }

    @Test func boldBackgroundColorIsApplied() async {
        // Given
        let parser = CDMarkdownParser()
        parser.bold.backgroundColor = CDColor.yellow
        // When
        let result = await parser.parse("**bold**")
        // Then
        var found = false
        result.enumerateAttribute(.backgroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.yellow {
                found = true
            }
        }
        #expect(found)
    }

    @Test func italicForegroundColorIsApplied() async {
        // Given
        let parser = CDMarkdownParser()
        parser.italic.color = CDColor.blue
        // When
        let result = await parser.parse("*italic*")
        // Then
        var found = false
        result.enumerateAttribute(.foregroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.blue {
                found = true
            }
        }
        #expect(found)
    }

    @Test func codeBackgroundColorIsApplied() async {
        // Given
        let parser = CDMarkdownParser()
        parser.code.backgroundColor = CDColor.green
        // When
        let result = await parser.parse("`code`")
        // Then
        var found = false
        result.enumerateAttribute(.backgroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.green {
                found = true
            }
        }
        #expect(found)
    }

    @Test func boldUnderlineStyleIsApplied() async {
        // Given
        let parser = CDMarkdownParser()
        parser.bold.underlineStyle = .single
        // When
        let result = await parser.parse("**underlined bold**")
        // Then
        var found = false
        result.enumerateAttribute(.underlineStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil {
                found = true
            }
        }
        #expect(found)
    }
}
