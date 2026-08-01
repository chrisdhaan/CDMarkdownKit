import SwiftUI

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
public struct CDMarkdownText: View {

    private let string: String
    private let explicitParser: CDMarkdownParser?
    @Environment(\.markdownParser) private var environmentParser
    @Environment(\.markdownTheme) private var environmentTheme
    @State private var attributedString: AttributedString = AttributedString()

    private var parser: CDMarkdownParser {
        Self.resolveParser(explicit: explicitParser, environment: environmentParser, theme: environmentTheme)
    }

    /// Picks the parser `body` renders with: an explicitly-injected parser always wins,
    /// then an environment-injected one, falling back to a fresh parser built from `theme`.
    /// Pulled out as a pure, `internal` function (rather than left as a `private` computed
    /// property reading `@Environment` directly) so it's reachable from `@testable import`
    /// without hosting the view — this project has no SwiftUI view-inspection dependency.
    internal static func resolveParser(
        explicit: CDMarkdownParser?,
        environment: CDMarkdownParser?,
        theme: CDMarkdownTheme
    ) -> CDMarkdownParser {
        explicit ?? environment ?? CDMarkdownParser(theme: theme)
    }

    /// Captures the identity of the effective parser so `.task` restarts whenever
    /// the string, injected parser instance, or environment theme changes.
    private struct ParseTaskID: Equatable {
        let string: String
        let parserID: ObjectIdentifier?
        let theme: CDMarkdownTheme?
    }

    private var taskID: ParseTaskID {
        if let injectedParser = explicitParser ?? environmentParser {
            ParseTaskID(string: string, parserID: ObjectIdentifier(injectedParser), theme: nil)
        } else {
            ParseTaskID(string: string, parserID: nil, theme: environmentTheme)
        }
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
            .task(id: taskID) {
                let nsAttributed = await parser.parse(string)
                #if os(macOS)
                    attributedString = (try? AttributedString(nsAttributed, including: \.appKit)) ?? AttributedString(string)
                #else
                    attributedString = (try? AttributedString(nsAttributed, including: \.uiKit)) ?? AttributedString(string)
                #endif
            }
    }
}
