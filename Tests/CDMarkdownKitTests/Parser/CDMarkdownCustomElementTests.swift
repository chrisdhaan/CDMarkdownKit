import Foundation
import Testing
@testable import CDMarkdownKit

/// A minimal CDMarkdownElement that marks ^^text^^ with a custom attribute.
/// Applying attributes doesn't change string length, so the default parse() loop
/// (which tracks location by length delta) works without further changes.
private let highlightKey = NSAttributedString.Key("com.cdmarkdownkit.test.highlight")

private final class HighlightElement: CDMarkdownElement {
    let regex = "\\^\\^(.+?)\\^\\^"

    func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex)
    }

    func match(_ result: NSTextCheckingResult,
               attributedString: NSMutableAttributedString) {
        let contentRange = result.range(at: 1)
        guard contentRange.location != NSNotFound else { return }
        attributedString.addAttribute(highlightKey,
                                      value: "highlighted" as AnyObject,
                                      range: contentRange)
    }
}

extension HighlightElement: @unchecked Sendable {}

@MainActor
struct CDMarkdownCustomElementTests {

    @Test func customElementAppliesAttributeWhenRegisteredAtInit() async {
        // Given: custom element registered at parser init time
        let element = HighlightElement()
        let parser = CDMarkdownParser(customElements: [element])
        // When
        let result = await parser.parse("Hello ^^world^^")
        // Then: highlightKey attribute must appear somewhere in the output
        var found = false
        result.enumerateAttribute(highlightKey,
                                  in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                found = true
            }
        }
        #expect(found)
    }

    @Test func addCustomElementAppliesAttribute() async {
        // Given: custom element added after parser is created
        let parser = CDMarkdownParser()
        let element = HighlightElement()
        parser.addCustomElement(element)
        // When
        let result = await parser.parse("Say ^^hi^^")
        // Then
        var found = false
        result.enumerateAttribute(highlightKey,
                                  in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                found = true
            }
        }
        #expect(found)
    }

    @Test func removeCustomElementStopsApplication() async {
        // Given: element added then removed before parse
        let parser = CDMarkdownParser()
        let element = HighlightElement()
        parser.addCustomElement(element)
        parser.removeCustomElement(element)
        // When
        let result = await parser.parse("Say ^^hi^^")
        // Then: attribute must NOT appear
        var found = false
        result.enumerateAttribute(highlightKey,
                                  in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                found = true
            }
        }
        #expect(!found)
    }

    @Test func customElementDoesNotAffectUnmatchedText() async {
        // Given
        let element = HighlightElement()
        let parser = CDMarkdownParser(customElements: [element])
        // When: input has no ^^ delimiters
        let result = await parser.parse("Hello world")
        // Then
        var found = false
        result.enumerateAttribute(highlightKey,
                                  in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                found = true
            }
        }
        #expect(!found)
    }
}
