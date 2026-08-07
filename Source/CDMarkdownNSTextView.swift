#if os(macOS)

    import Cocoa

    /// A read-only `NSTextView` subclass that renders `NSAttributedString` output from
    /// `CDMarkdownParser` with optional rounded-corner backgrounds for code spans.
    ///
    /// Use ``CDMarkdownNSTextView`` to display Markdown-formatted text with automatic link handling.
    /// Set the attributed text using ``setAttributedString(_:)`` with an `NSAttributedString`
    /// produced by ``CDMarkdownParser``. Links are opened automatically by `NSWorkspace`.
    @MainActor
    open class CDMarkdownNSTextView: NSTextView {

        /// The custom layout manager used for rendering with rounded-corner backgrounds.
        open var customLayoutManager: CDMarkdownNSLayoutManager!

        /// The custom text storage that holds the attributed text and layout information.
        open var customTextStorage: NSTextStorage!

        /// When `true`, all background color regions (code blocks, syntax blocks, etc.) are drawn with rounded corners.
        /// When `false` (default), backgrounds are drawn as rectangles. Set to `true` for a softer appearance.
        open var roundAllCorners: Bool = false {
            didSet {
                customLayoutManager?.roundAllCorners = roundAllCorners
            }
        }

        // MARK: - Initializers

        override public init(frame: NSRect) {
            let container = NSTextContainer()
            let layoutManager = CDMarkdownNSLayoutManager()
            let textStorage = NSTextStorage()
            textStorage.addLayoutManager(layoutManager)
            layoutManager.addTextContainer(container)

            super.init(frame: frame, textContainer: container)

            customLayoutManager = layoutManager
            customTextStorage = textStorage
            configure()
        }

        public required init?(coder: NSCoder) {
            super.init(coder: coder)

            let container = NSTextContainer()
            let layoutManager = CDMarkdownNSLayoutManager()
            let textStorage = NSTextStorage()
            textStorage.addLayoutManager(layoutManager)
            layoutManager.addTextContainer(container)

            customLayoutManager = layoutManager
            customTextStorage = textStorage
            configure()
        }

        // MARK: - Configuration

        /// Configures the text view's custom layout manager and text storage.
        ///
        /// Called automatically during initialization. This method sets up the ``CDMarkdownNSLayoutManager``
        /// and `NSTextStorage` for rendering with rounded-corner backgrounds.
        open func configure() {
            isEditable = false
            isSelectable = true // required for link clicks on macOS
        }

        // MARK: - Text Management

        /// Sets the attributed string to be displayed.
        ///
        /// - Parameter attributedString: The `NSAttributedString` to display. Typically produced by `CDMarkdownParser.parse(_:)`.
        open func setAttributedString(_ attributedString: NSAttributedString) {
            customTextStorage.setAttributedString(attributedString)
        }
    }

#endif
