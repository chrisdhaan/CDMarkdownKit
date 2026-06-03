import SwiftUI

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
public struct CDMarkdownText: View {

    private let string: String
    private let explicitParser: CDMarkdownParser?
    @Environment(\.markdownParser) private var environmentParser
    @Environment(\.markdownTheme) private var environmentTheme
    @State private var attributedString: AttributedString = AttributedString()

    private var parser: CDMarkdownParser {
        explicitParser ?? environmentParser ?? CDMarkdownParser(theme: environmentTheme)
    }

    /// Creates a view that renders `string` as Markdown using `parser`.
    public init(_ string: String, parser: CDMarkdownParser? = nil) {
        self.string = string
        self.explicitParser = parser
    }

    /// Creates a Markdown text view styled with `theme`.
    public init(_ string: String, theme: CDMarkdownTheme) {
        self.init(string, parser: CDMarkdownParser(theme: theme))
    }

    public var body: some View {
        Text(attributedString)
            .task(id: string) {
                let nsAttributed = await parser.parse(string)
                #if os(macOS)
                    attributedString = (try? AttributedString(nsAttributed, including: \.appKit)) ?? AttributedString(string)
                #else
                    attributedString = (try? AttributedString(nsAttributed, including: \.uiKit)) ?? AttributedString(string)
                #endif
            }
    }
}
