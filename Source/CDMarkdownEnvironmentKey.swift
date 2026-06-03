import SwiftUI

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
private struct CDMarkdownParserKey: EnvironmentKey {
    static let defaultValue: CDMarkdownParser? = nil
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
extension EnvironmentValues {
    /// The `CDMarkdownParser` injected via `.markdownParser(_:)`, or `nil` if not set.
    public var markdownParser: CDMarkdownParser? {
        get { self[CDMarkdownParserKey.self] }
        set { self[CDMarkdownParserKey.self] = newValue }
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
extension View {
    /// Sets the `CDMarkdownParser` used by all `CDMarkdownText` and `CDMarkdownView`
    /// views in this subtree.
    public func markdownParser(_ parser: CDMarkdownParser) -> some View {
        environment(\.markdownParser, parser)
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
private struct CDMarkdownThemeKey: EnvironmentKey {
    static let defaultValue: CDMarkdownTheme = .default
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
extension EnvironmentValues {
    public var markdownTheme: CDMarkdownTheme {
        get { self[CDMarkdownThemeKey.self] }
        set { self[CDMarkdownThemeKey.self] = newValue }
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
extension View {
    /// Sets the `CDMarkdownTheme` used by all `CDMarkdownText` and `CDMarkdownView` views
    /// in this subtree that do not have an explicit parser.
    public func markdownTheme(_ theme: CDMarkdownTheme) -> some View {
        environment(\.markdownTheme, theme)
    }
}
