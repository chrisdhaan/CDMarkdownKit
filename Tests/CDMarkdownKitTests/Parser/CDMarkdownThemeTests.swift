import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownThemeTests {

    @Test func defaultThemeProducesUsableParser() async {
        let parser = CDMarkdownParser(theme: .default)
        let result = await parser.parse("Hello **world**")
        #expect(result.length > 0)
    }

    @Test func themeCodeFontIsApplied() async {
        guard let codeFont = CDFont(name: "Menlo-Regular", size: 16) else {
            #expect(Bool(false), "Failed to create font")
            return
        }
        var theme = CDMarkdownTheme.default
        theme.code = CDMarkdownTheme.InlineTheme(font: codeFont)
        let parser = CDMarkdownParser(theme: theme)
        let result = await parser.parse("`code`")
        var foundExpectedFont = false
        result.enumerateAttribute(.font,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize == 16 {
                foundExpectedFont = true
            }
        }
        #expect(foundExpectedFont)
    }

    @Test func themeColorIsApplied() async {
        var theme = CDMarkdownTheme.default
        theme.bold = CDMarkdownTheme.InlineTheme(color: CDColor.red)
        let parser = CDMarkdownParser(theme: theme)
        let result = await parser.parse("**bold**")
        var foundRed = false
        result.enumerateAttribute(.foregroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.red {
                foundRed = true
            }
        }
        #expect(foundRed)
    }

    @Test func perElementOverrideAfterThemeWins() async {
        var theme = CDMarkdownTheme.default
        theme.bold = CDMarkdownTheme.InlineTheme(color: CDColor.red)
        let parser = CDMarkdownParser(theme: theme)
        parser.bold.color = CDColor.blue // override after init
        let result = await parser.parse("**bold**")
        var foundBlue = false
        result.enumerateAttribute(.foregroundColor,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let color = value as? CDColor, color == CDColor.blue {
                foundBlue = true
            }
        }
        #expect(foundBlue)
    }

    @Test func systemDarkThemeBuildsWithoutCrash() async {
        let parser = CDMarkdownParser(theme: .systemDark)
        let result = await parser.parse("# Heading\n\n`code`\n\n**bold**")
        #expect(result.length > 0)
    }

    @Test func themeHeaderFontSizesAreApplied() async {
        var theme = CDMarkdownTheme.default
        theme.header = CDMarkdownTheme.HeaderTheme(fontSizes: [40, 34, 28, 22, 18, 15])
        let parser = CDMarkdownParser(theme: theme)
        let result = await parser.parse("## Heading 2")
        var foundExpectedSize = false
        result.enumerateAttribute(.font,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize == 34 {
                foundExpectedSize = true
            }
        }
        #expect(foundExpectedSize)
    }

    @Test func headerFontSizesDefaultToNilInTheme() {
        #expect(CDMarkdownTheme.HeaderTheme().fontSizes == nil)
        #expect(CDMarkdownParser(theme: .default).header.fontSizes == nil)
    }

    @Test func headerColorFallsBackToParserDefaultWhenThemeDoesNotSpecifyOne() {
        let defaultParser = CDMarkdownParser()
        let defaultHeaderColor = defaultParser.header.color

        let themedParser = CDMarkdownParser(theme: .default)
        #expect(themedParser.header.color == defaultHeaderColor)
    }

    @Test func codeSyntaxColorsFromThemeReachParserSyntaxElement() async {
        var theme = CDMarkdownTheme.default
        theme.codeSyntaxColors = [.keyword: CDColor.red, .string: CDColor.green]
        let parser = CDMarkdownParser(theme: theme)
        #expect(parser.syntax.syntaxColors[.keyword] == CDColor.red)
        #expect(parser.syntax.syntaxColors[.string] == CDColor.green)

        let result = await parser.parse("```swift\nlet x = 1\n```")
        guard let r = result.string.range(of: "let") else {
            Issue.record("no 'let'")
            return
        }
        let color = result.attribute(.foregroundColor,
                                     at: NSRange(r, in: result.string).location,
                                     effectiveRange: nil) as? CDColor
        #expect(color == CDColor.red)
    }

    @Test func defaultAndSystemDarkThemesHaveEmptyCodeSyntaxColors() {
        #expect(CDMarkdownTheme.default.codeSyntaxColors.isEmpty)
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 4.0, visionOS 1.0, *) {
            #expect(CDMarkdownTheme.systemDark.codeSyntaxColors.isEmpty)
        }
    }

    @Test func codeSyntaxColorsParticipatesInEquatable() {
        var a = CDMarkdownTheme.default
        var b = CDMarkdownTheme.default
        #expect(a == b)
        a.codeSyntaxColors = [.keyword: CDColor.red]
        #expect(a != b)
        b.codeSyntaxColors = [.keyword: CDColor.red]
        #expect(a == b)
    }
}
