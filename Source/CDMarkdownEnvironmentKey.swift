import SwiftUI

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
private struct CDMarkdownParserKey: EnvironmentKey {
    static let defaultValue: CDMarkdownParser = MainActor.assumeIsolated { CDMarkdownParser() }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
extension EnvironmentValues {
    /// The `CDMarkdownParser` used by `CDMarkdownText` and `CDMarkdownView`
    /// when no parser is provided explicitly.
    public var markdownParser: CDMarkdownParser {
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
