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
            let (layoutManager, textStorage) = Self.makeLayoutManagerAndTextStorage()
            textStorage.addLayoutManager(layoutManager)
            layoutManager.addTextContainer(container)

            super.init(frame: frame, textContainer: container)

            customLayoutManager = layoutManager
            customTextStorage = textStorage
            configure()
        }

        public required init?(coder: NSCoder) {
            super.init(coder: coder)

            // `super.init(coder:)` has already created and attached AppKit's own default
            // text container/layout manager/text storage to `self`. Unlike `init(frame:)`,
            // there's no way to hand a pre-wired container into `super.init(coder:)`, so
            // instead we reuse the text container AppKit already created and swap in our
            // own layout manager as its active layout manager. `replaceLayoutManager(_:)`
            // pulls the *old* layout manager's text storage association onto the new one,
            // so `addLayoutManager(_:)` must run afterward to make our own text storage
            // the active one instead.
            let (layoutManager, textStorage) = Self.makeLayoutManagerAndTextStorage()
            textContainer?.replaceLayoutManager(layoutManager)
            textStorage.addLayoutManager(layoutManager)

            customLayoutManager = layoutManager
            customTextStorage = textStorage
            configure()
        }

        /// Constructs a fresh, not-yet-wired ``CDMarkdownNSLayoutManager``/`NSTextStorage`
        /// pair for use by either initializer; each initializer wires them into the text
        /// system in the order its own initialization path requires.
        private static func makeLayoutManagerAndTextStorage() -> (CDMarkdownNSLayoutManager, NSTextStorage) {
            (CDMarkdownNSLayoutManager(), NSTextStorage())
        }

        // MARK: - Configuration

        /// Configures the text view for read-only Markdown display.
        ///
        /// Called automatically during initialization, after the custom text system
        /// (``customLayoutManager``/``customTextStorage``) has already been wired up.
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
