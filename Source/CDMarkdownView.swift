import SwiftUI

// MARK: - iOS / tvOS / visionOS

#if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
    public struct CDMarkdownView: UIViewRepresentable {

        private let string: String
        private let explicitParser: CDMarkdownParser?
        @Environment(\.markdownParser) private var environmentParser
        @Environment(\.markdownTheme) private var environmentTheme
        public var onLinkTap: ((URL) -> Void)?

        private var parser: CDMarkdownParser {
            Self.resolveParser(explicit: explicitParser, environment: environmentParser, theme: environmentTheme)
        }

        /// Picks the parser `makeUIView`/`updateUIView` render with: an explicitly-injected
        /// parser always wins, then an environment-injected one, falling back to a fresh parser
        /// built from `theme`. Pulled out as a pure, `internal` function so it's reachable from
        /// `@testable import` without hosting the view — this project has no SwiftUI
        /// view-inspection dependency.
        internal static func resolveParser(
            explicit: CDMarkdownParser?,
            environment: CDMarkdownParser?,
            theme: CDMarkdownTheme
        ) -> CDMarkdownParser {
            explicit ?? environment ?? CDMarkdownParser(theme: theme)
        }

        /// Creates a full-fidelity Markdown view with rounded-corner support.
        public init(_ string: String,
                    parser: CDMarkdownParser? = nil,
                    onLinkTap: ((URL) -> Void)? = nil) {
            self.string = string
            self.explicitParser = parser
            self.onLinkTap = onLinkTap
        }

        /// Creates a full-fidelity Markdown view styled with `theme`.
        public init(_ string: String,
                    theme: CDMarkdownTheme,
                    onLinkTap: ((URL) -> Void)? = nil) {
            self.init(string, parser: CDMarkdownParser(theme: theme), onLinkTap: onLinkTap)
        }

        public func makeUIView(context: Context) -> CDMarkdownTextView {
            let textView = Self.configuredTextView()
            textView.delegate = context.coordinator
            return textView
        }

        /// Builds and configures the text view `makeUIView` returns, overriding
        /// `CDMarkdownTextView.configure()`'s scrolling/selection/editing defaults for this
        /// view's rounded-corner, tap-to-follow-link presentation. Pulled out as a pure,
        /// `internal` function (independent of `Context`) so it's testable via `@testable import`.
        internal static func configuredTextView() -> CDMarkdownTextView {
            let textView = CDMarkdownTextView(frame: .zero)
            textView.configure() // sets up customLayoutManager for rounded corners
            textView.isScrollEnabled = false // override configure()'s default of true
            textView.isSelectable = true // override configure()'s default of false
            #if os(visionOS)
                textView.isEditable = false // configure() only handles this on iOS
            #endif
            textView.backgroundColor = .clear
            return textView
        }

        public func updateUIView(_ uiView: CDMarkdownTextView, context: Context) {
            context.coordinator.onLinkTap = onLinkTap
            context.coordinator.parseTask?.cancel()
            context.coordinator.parseTask = Task { @MainActor in
                let result = await parser.parse(string)
                guard !Task.isCancelled else { return }
                uiView.attributedText = result
            }
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator(onLinkTap: onLinkTap)
        }

        public class Coordinator: NSObject, UITextViewDelegate {
            var onLinkTap: ((URL) -> Void)?
            var parseTask: Task<Void, Never>?

            init(onLinkTap: ((URL) -> Void)?) {
                self.onLinkTap = onLinkTap
            }

            #if !os(visionOS)
                public func textView(_ textView: UITextView,
                                     shouldInteractWith url: URL,
                                     in characterRange: NSRange,
                                     interaction: UITextItemInteraction) -> Bool {
                    onLinkTap?(url)
                    return onLinkTap == nil // let UIKit handle if no custom handler
                }
            #endif

            #if os(iOS) || os(visionOS)
                @available(iOS 17.0, visionOS 1.0, *)
                public func textView(_ textView: UITextView,
                                     primaryActionFor textItem: UITextItem,
                                     defaultAction: UIAction) -> UIAction? {
                    guard case let .link(url) = textItem.content else { return defaultAction }
                    return Self.primaryAction(forLinkURL: url, onLinkTap: onLinkTap, defaultAction: defaultAction)
                }

                /// Core decision for `textView(_:primaryActionFor:defaultAction:)`, factored out
                /// because `UITextItem` has no public initializer and can't be constructed in
                /// tests — `URL` and `UIAction` can.
                @available(iOS 17.0, visionOS 1.0, *)
                internal static func primaryAction(forLinkURL url: URL,
                                                   onLinkTap: ((URL) -> Void)?,
                                                   defaultAction: UIAction) -> UIAction? {
                    if let handler = onLinkTap {
                        handler(url)
                        return nil // returning nil suppresses UIKit's default open-URL behaviour
                    }
                    return defaultAction
                }
            #endif
        }
    }

    // MARK: - macOS

#elseif os(macOS)
    @available(macOS 12.0, *)
    public struct CDMarkdownView: NSViewRepresentable {

        private let string: String
        private let explicitParser: CDMarkdownParser?
        @Environment(\.markdownParser) private var environmentParser
        @Environment(\.markdownTheme) private var environmentTheme
        public var onLinkTap: ((URL) -> Bool)?

        private var parser: CDMarkdownParser {
            Self.resolveParser(explicit: explicitParser, environment: environmentParser, theme: environmentTheme)
        }

        /// Picks the parser `makeNSView`/`updateNSView` render with: an explicitly-injected
        /// parser always wins, then an environment-injected one, falling back to a fresh parser
        /// built from `theme`. Pulled out as a pure, `internal` function so it's reachable from
        /// `@testable import` without hosting the view — this project has no SwiftUI
        /// view-inspection dependency.
        internal static func resolveParser(
            explicit: CDMarkdownParser?,
            environment: CDMarkdownParser?,
            theme: CDMarkdownTheme
        ) -> CDMarkdownParser {
            explicit ?? environment ?? CDMarkdownParser(theme: theme)
        }

        /// Creates a full-fidelity Markdown view with rounded-corner support.
        public init(_ string: String,
                    parser: CDMarkdownParser? = nil,
                    onLinkTap: ((URL) -> Bool)? = nil) {
            self.string = string
            self.explicitParser = parser
            self.onLinkTap = onLinkTap
        }

        public func makeNSView(context: Context) -> CDMarkdownNSTextView {
            let textView = CDMarkdownNSTextView(frame: .zero)
            textView.delegate = context.coordinator
            return textView
        }

        public func updateNSView(_ nsView: CDMarkdownNSTextView, context: Context) {
            context.coordinator.onLinkTap = onLinkTap
            context.coordinator.parseTask?.cancel()
            context.coordinator.parseTask = Task { @MainActor in
                let result = await parser.parse(string)
                guard !Task.isCancelled else { return }
                nsView.setAttributedString(result)
            }
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator(onLinkTap: onLinkTap)
        }

        public class Coordinator: NSObject, NSTextViewDelegate {
            var onLinkTap: ((URL) -> Bool)?
            var parseTask: Task<Void, Never>?

            init(onLinkTap: ((URL) -> Bool)?) {
                self.onLinkTap = onLinkTap
            }

            public func textView(_ textView: NSTextView,
                                 clickedOnLink link: Any,
                                 at charIndex: Int) -> Bool {
                if let url = link as? URL, let handler = onLinkTap {
                    return handler(url)
                }
                return false
            }
        }
    }
#endif
