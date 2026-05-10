import Testing
import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownParserStyleTests {

    @Test func boldForegroundColorIsApplied() {
        // Given
        let parser = CDMarkdownParser()
        parser.bold.color = CDColor.red
        // When
        let result = parser.parse("**bold**")
        // Then
        var found = false
        result.enumerateAttribute(.foregroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.red { found = true }
        }
        #expect(found)
    }

    @Test func boldBackgroundColorIsApplied() {
        // Given
        let parser = CDMarkdownParser()
        parser.bold.backgroundColor = CDColor.yellow
        // When
        let result = parser.parse("**bold**")
        // Then
        var found = false
        result.enumerateAttribute(.backgroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.yellow { found = true }
        }
        #expect(found)
    }

    @Test func italicForegroundColorIsApplied() {
        // Given
        let parser = CDMarkdownParser()
        parser.italic.color = CDColor.blue
        // When
        let result = parser.parse("*italic*")
        // Then
        var found = false
        result.enumerateAttribute(.foregroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.blue { found = true }
        }
        #expect(found)
    }

    @Test func codeBackgroundColorIsApplied() {
        // Given
        let parser = CDMarkdownParser()
        parser.code.backgroundColor = CDColor.green
        // When
        let result = parser.parse("`code`")
        // Then
        var found = false
        result.enumerateAttribute(.backgroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.green { found = true }
        }
        #expect(found)
    }

    @Test func boldUnderlineStyleIsApplied() {
        // Given
        let parser = CDMarkdownParser()
        parser.bold.underlineStyle = .single
        // When
        let result = parser.parse("**underlined bold**")
        // Then
        var found = false
        result.enumerateAttribute(.underlineStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { found = true }
        }
        #expect(found)
    }
}
