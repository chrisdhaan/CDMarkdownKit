import Testing
import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
@Suite struct CDMarkdownParserInitTests {

    // MARK: - Base font / color applied to plain text

    @Test func customFontAppliedToPlainText() {
        // Given: parser initialized with a distinctive point size
        let customFont = CDFont.systemFont(ofSize: 24)
        let parser = CDMarkdownParser(font: customFont)
        // When
        let result = parser.parse("plain text")
        // Then: every character should carry the 24pt font
        var found = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let f = value as? CDFont, f.pointSize == 24 { found = true }
        }
        #expect(found)
    }

    @Test func customFontColorAppliedToPlainText() {
        // Given
        let parser = CDMarkdownParser(fontColor: CDColor.blue)
        // When
        let result = parser.parse("plain text")
        // Then
        var found = false
        result.enumerateAttribute(.foregroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let c = value as? CDColor, c == CDColor.blue { found = true }
        }
        #expect(found)
    }

    @Test func customBackgroundColorAppliedToPlainText() {
        // Given
        let parser = CDMarkdownParser(backgroundColor: CDColor.yellow)
        // When
        let result = parser.parse("plain text")
        // Then
        var found = false
        result.enumerateAttribute(.backgroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let c = value as? CDColor, c == CDColor.yellow { found = true }
        }
        #expect(found)
    }

    // MARK: - automaticLinkDetectionEnabled

    @Test func automaticLinkDetectionEnabledByDefault() {
        let parser = CDMarkdownParser()
        #expect(parser.automaticLinkDetectionEnabled == true)
    }

    // NSDataDetector (used by CDMarkdownAutomaticLink) is unavailable on watchOS.
    #if !os(watchOS)

    @Test func autoLinkDisabledPreventsLinkAttribute() {
        // Given: bare URL with auto-detection turned off
        let parser = CDMarkdownParser(automaticLinkDetectionEnabled: false)
        // When
        let result = parser.parse("https://example.com")
        // Then: no .link attribute should appear
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(!foundLink)
    }

    @Test func bracketLinkStillWorksWhenAutoLinkDisabled() {
        // [text](url) is processed by CDMarkdownLink (not CDMarkdownAutomaticLink)
        // and must remain functional even when auto-detection is off.
        let parser = CDMarkdownParser(automaticLinkDetectionEnabled: false)
        let result = parser.parse("[GitHub](https://github.com)")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(foundLink)
    }

    #endif
}
