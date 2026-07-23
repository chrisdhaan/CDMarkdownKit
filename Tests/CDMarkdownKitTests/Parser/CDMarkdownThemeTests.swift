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

    @Test func headerColorFallsBackToParserDefaultWhenThemeDoesNotSpecifyOne() {
        let defaultParser = CDMarkdownParser()
        let defaultHeaderColor = defaultParser.header.color

        let themedParser = CDMarkdownParser(theme: .default)
        #expect(themedParser.header.color == defaultHeaderColor)
    }
}
