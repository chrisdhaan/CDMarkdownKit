import CoreGraphics
import Foundation
import ImageIO
import Testing
#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownParserTests {

    let parser = CDMarkdownParser()

    @Test func parseBoldText() {
        // Given
        let input = "Hello **world**"
        // When
        let result = parser.parse(input)
        // Then
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let font = value as? CDFont, font.isBold, range.location == 6 {
                foundBold = true
            }
        }
        #expect(foundBold)
    }

    @Test func parseItalicText() {
        // Given
        let input = "Hello *world*"
        // When
        let result = parser.parse(input)
        // Then
        var foundItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let font = value as? CDFont, font.isItalic, range.location == 6 {
                foundItalic = true
            }
        }
        #expect(foundItalic)
    }

    @Test func parseLinkURL() {
        // Given
        let input = "[GitHub](https://github.com)"
        // When
        let result = parser.parse(input)
        // Then
        var foundURL = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundURL = true }
        }
        #expect(foundURL)
    }

    @Test func parseStrikethroughText() {
        // Given
        let input = "Hello ~~world~~"
        // When
        let result = parser.parse(input)
        // Then
        var foundStrikethrough = false
        result.enumerateAttribute(.strikethroughStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundStrikethrough = true }
        }
        #expect(foundStrikethrough)
    }

    @Test func codeSpanNotParsedAsMarkdown() {
        // Content inside backticks must not be treated as bold/italic/etc.
        // Given
        let input = "`**not bold**`"
        // When
        let result = parser.parse(input)
        // Then
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(!foundBold)
    }

    @Test func backslashEscapePreservesCharacter() {
        // Given: \* should produce a literal *, not trigger italic
        let input = "\\*not italic"
        // When
        let result = parser.parse(input)
        // Then
        #expect(result.string.contains("*"))
    }

    @Test func parseHeader() {
        // Given
        let input = "# Heading One"
        // When
        let result = parser.parse(input)
        // Then: the header text should have a larger font than the base font
        var foundLargerFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize > 17 { foundLargerFont = true }
        }
        #expect(foundLargerFont)
    }

    @Test func emptyStringReturnsEmptyResult() {
        let result = parser.parse("")
        #expect(result.length == 0)
    }

    @Test func plainTextHasNoMarkdownAttributes() {
        let input = "Hello, world."
        let result = parser.parse(input)
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundLink = true }
        }
        #expect(!foundLink)
    }

    @Test func asyncParseReturnsAttributedString() async {
        // Given
        let input = "Hello **async** world"
        // When
        let result = await parser.parse(input)
        // Then
        #expect(result.length > 0)
        #expect(result.string.contains("Hello"))
    }

    @Test func asyncParseFindsBoldText() async {
        // Given
        let input = "Hello **async** world"
        // When
        let result = await parser.parse(input)
        // Then
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(foundBold)
    }

    // MARK: - Multi-element document tests

    @Test func boldAndItalicInSameParagraph() {
        // Given
        let input = "**bold** and _italic_ text"
        // When
        let result = parser.parse(input)
        // Then
        var foundBold = false
        var foundItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont {
                if font.isBold { foundBold = true }
                if font.isItalic { foundItalic = true }
            }
        }
        #expect(foundBold)
        #expect(foundItalic)
    }

    @Test func codeAndBoldInSameParagraph() {
        // Given
        let input = "`code` and **bold**"
        // When
        let result = parser.parse(input)
        // Then: code applies a foreground color; bold applies a bold font
        var foundBold = false
        var foundCodeColor = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        result.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundCodeColor = true }
        }
        #expect(foundBold)
        #expect(foundCodeColor)
    }

    @Test func headerAndParagraphProduceDifferentFontSizes() {
        // Given
        let input = "# Heading\nNormal **bold** text"
        // When
        let result = parser.parse(input)
        // Then: header font is larger than body font — at least two distinct sizes
        var fontSizes = Set<CGFloat>()
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont { fontSizes.insert(font.pointSize) }
        }
        #expect(fontSizes.count >= 2)
    }

    #if !os(watchOS)
        @Test func bracketLinkAndBareUrlBothLinked() {
            // Given: a bracket-style link and a separate bare URL in the same string
            let input = "[GitHub](https://github.com) and https://example.com"
            // When
            let result = parser.parse(input)
            // Then: two distinct link attribute runs
            var linkedRuns = 0
            result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
                if value != nil { linkedRuns += 1 }
            }
            #expect(linkedRuns >= 2)
        }
    #endif

    @Test func fullDocumentParsesAllElements() {
        // A kitchen-sink document — verifies the pipeline handles all element
        // types together without crashing or producing an empty result.
        // Given
        let input = """
        # Welcome

        This is **bold** and _italic_ text.

        > A blockquote with `inline code`.

        - Item one
        - Item two

        ```
        let x = 42
        ```

        Visit [the docs](https://example.com) for more.
        """
        // When
        let result = parser.parse(input)
        // Then: output is non-empty and key text survives parsing
        #expect(result.length > 0)
        #expect(result.string.contains("Welcome"))
        #expect(result.string.contains("bold"))
        #expect(result.string.contains("italic"))
        #expect(result.string.contains("the docs"))
    }

    @Test func parseAcceptsNSAttributedStringInput() {
        // Given: an NSAttributedString carrying a pre-existing custom attribute
        let customKey = NSAttributedString.Key("com.test.preexisting")
        let input = NSMutableAttributedString(string: "**bold** text")
        input.addAttribute(customKey, value: "marker" as AnyObject,
                           range: NSRange(location: 0, length: input.length))
        // When: the NSAttributedString overload is used directly
        let result = parser.parse(input as NSAttributedString)
        // Then: markdown is parsed AND the pre-existing attribute survives
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { foundBold = true }
        }
        var foundCustom = false
        result.enumerateAttribute(customKey, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundCustom = true }
        }
        #expect(foundBold)
        #expect(foundCustom)
    }

    @Test func asyncParseLoadsLocalImage() async {
        #if os(iOS) || os(tvOS) || os(macOS)
            // Build a minimal 1×1 PNG via Core Graphics so no bundle resource is needed
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let ctx = CGContext(data: nil, width: 1, height: 1,
                                      bitsPerComponent: 8, bytesPerRow: 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
                let cgImage = ctx.makeImage() else { return }
            let mutableData = NSMutableData()
            guard let dest = CGImageDestinationCreateWithData(mutableData,
                                                              "public.png" as CFString, 1, nil) else { return }
            CGImageDestinationAddImage(dest, cgImage, nil)
            guard CGImageDestinationFinalize(dest) else { return }

            let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString + ".png")
            guard (try? (mutableData as Data).write(to: tmpURL)) != nil else { return }
            defer { try? FileManager.default.removeItem(at: tmpURL) }

            // When: async parse with an image reference pointing at the local file
            let input = "![test](\(tmpURL.absoluteString))"
            let result = await parser.parse(input)

            // Then: resolveImages should have replaced the placeholder with a real attachment
            var foundAttachment = false
            result.enumerateAttribute(.attachment, in: NSRange(location: 0, length: result.length)) { v, _, _ in
                if v is NSTextAttachment { foundAttachment = true }
            }
            #expect(foundAttachment)
        #endif
    }
}
