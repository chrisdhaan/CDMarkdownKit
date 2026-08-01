import SwiftUI
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownTextTests {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func cdMarkdownTextInitializesWithString() {
        let view = CDMarkdownText("Hello **world**")
        // Verify the view can be created without crashing
        #expect(type(of: view) == CDMarkdownText.self)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func resolveParserPrefersExplicitOverEnvironmentAndDefault() {
        let explicit = CDMarkdownParser()
        let environment = CDMarkdownParser()
        let resolved = CDMarkdownText.resolveParser(explicit: explicit, environment: environment, theme: .default)
        #expect(resolved === explicit)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func resolveParserPrefersEnvironmentOverDefault() {
        let environment = CDMarkdownParser()
        let resolved = CDMarkdownText.resolveParser(explicit: nil, environment: environment, theme: .default)
        #expect(resolved === environment)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func resolveParserFallsBackToThemedDefault() {
        var theme = CDMarkdownTheme.default
        theme.fontColor = .red
        let resolved = CDMarkdownText.resolveParser(explicit: nil, environment: nil, theme: theme)
        #expect(resolved.fontColor == theme.fontColor)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func environmentKeyDefaultThemeIsUsable() async {
        let env = EnvironmentValues()
        let theme = env.markdownTheme
        let parser = CDMarkdownParser(theme: theme)
        let result = await parser.parse("test")
        #expect(result.length > 0)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func viewModifierSetsParser() {
        let customParser = CDMarkdownParser()
        let view = CDMarkdownText("test").markdownParser(customParser)
        #expect(type(of: view) != CDMarkdownText.self) // wrapped in modifier
    }
}
