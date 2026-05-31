import SwiftUI

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
public struct CDMarkdownText: View {

    private let string: String
    @State private var attributedString: AttributedString = AttributedString()
    private let parser: CDMarkdownParser

    /// Creates a view that renders `string` as Markdown using `parser`.
    public init(_ string: String, parser: CDMarkdownParser = CDMarkdownParser()) {
        self.string = string
        self.parser = parser
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
