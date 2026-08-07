import SwiftUI
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownTextTests {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func convertProducesPlainTextWithMarkdownStripped() async {
        let nsAttributed = await CDMarkdownParser().parse("Hello **world**")
        let converted = CDMarkdownText.convert(nsAttributed, fallback: "Hello **world**")
        #expect(String(converted.characters) == "Hello world")
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
    @Test func convertPreservesBoldFormatting() async {
        let nsAttributed = await CDMarkdownParser().parse("Hello **world**")
        let converted = CDMarkdownText.convert(nsAttributed, fallback: "Hello **world**")

        let boldRunExists = converted.runs.contains { run in
            let substring = String(converted[run.range].characters)
            guard substring == "world" else { return false }
            #if os(macOS)
                return run.appKit.font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
            #else
                return run.uiKit.font?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false
            #endif
        }
        #expect(boldRunExists)
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

    #if !os(watchOS)
        @available(iOS 16.0, tvOS 16.0, macOS 13.0, visionOS 1.0, *)
        @Test func markdownThemeModifierPropagatesThroughLiveViewHierarchy() {
            final class ThemeBox {
                var captured: CDMarkdownTheme?
            }
            struct ThemeCapturingView: View {
                @Environment(\.markdownTheme) var theme
                let box: ThemeBox
                var body: some View {
                    box.captured = theme
                    return Color.clear.frame(width: 1, height: 1)
                }
            }

            var theme = CDMarkdownTheme.default
            theme.fontColor = .red
            let box = ThemeBox()

            let renderer = ImageRenderer(content: ThemeCapturingView(box: box).markdownTheme(theme))
            _ = renderer.cgImage

            #expect(box.captured?.fontColor == theme.fontColor)
        }
    #endif
}
