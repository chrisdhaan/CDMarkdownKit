import SwiftUI

// MARK: - iOS / tvOS / visionOS

#if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
    public struct CDMarkdownView: UIViewRepresentable {

        private let string: String
        private let explicitParser: CDMarkdownParser?
        @Environment(\.markdownParser) private var environmentParser
        public var onLinkTap: ((URL) -> Void)?

        private var parser: CDMarkdownParser { explicitParser ?? environmentParser }

        /// Creates a full-fidelity Markdown view with rounded-corner support.
        public init(_ string: String,
                    parser: CDMarkdownParser? = nil,
                    onLinkTap: ((URL) -> Void)? = nil) {
            self.string = string
            self.explicitParser = parser
            self.onLinkTap = onLinkTap
        }

        public func makeUIView(context: Context) -> CDMarkdownTextView {
            let textView = CDMarkdownTextView(frame: .zero)
            textView.configure() // sets up customLayoutManager for rounded corners
            textView.isScrollEnabled = false // override configure()'s default of true
            textView.isSelectable = true // override configure()'s default of false
            #if os(visionOS)
                textView.isEditable = false // configure() only handles this on iOS
            #endif
            textView.backgroundColor = .clear
            textView.delegate = context.coordinator
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

            @available(iOS 17.0, tvOS 17.0, visionOS 1.0, *)
            public func textView(_ textView: UITextView,
                                 primaryActionFor textItem: UITextItem,
                                 defaultAction: UIAction) -> UIAction? {
                guard case .link(let url) = textItem.content else { return defaultAction }
                if let handler = onLinkTap {
                    handler(url)
                    return nil  // returning nil suppresses UIKit's default open-URL behaviour
                }
                return defaultAction
            }
        }
    }

    // MARK: - macOS

#elseif os(macOS)
    @available(macOS 12.0, *)
    public struct CDMarkdownView: NSViewRepresentable {

        private let string: String
        private let explicitParser: CDMarkdownParser?
        @Environment(\.markdownParser) private var environmentParser
        public var onLinkTap: ((URL) -> Bool)?

        private var parser: CDMarkdownParser { explicitParser ?? environmentParser }

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
