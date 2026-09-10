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
                needsDisplay = true
            }
        }

        // MARK: - Initializers

        override public init(frame: NSRect) {
            // A manually constructed `NSTextContainer` has no size and does not track its
            // text view's width, which makes AppKit stretch it to its 10,000,000pt maximum.
            // Text would then never wrap, and resizing the view would never re-wrap it.
            let container = NSTextContainer(size: NSSize(width: frame.width,
                                                         height: .greatestFiniteMagnitude))
            container.widthTracksTextView = true
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
            invalidateIntrinsicContentSize()
        }

        // MARK: - Sizing

        /// Reports the height needed to render the current text wrapped to `width`, so
        /// ``CDMarkdownView`` (an `NSViewRepresentable`) can size this view inside a `ScrollView`.
        ///
        /// Measured in a detached layout stack so the query has no side effects on this view's
        /// own text system.
        open func fittingHeight(forWidth width: CGFloat) -> CGFloat {
            guard width > 0, width.isFinite else { return 0 }

            let inset = textContainerInset
            let availableWidth = max(0, width - inset.width * 2)

            let textStorage = NSTextStorage(attributedString: customTextStorage)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)
            let container = NSTextContainer(size: NSSize(width: availableWidth,
                                                         height: .greatestFiniteMagnitude))
            container.lineFragmentPadding = textContainer?.lineFragmentPadding ?? 0
            layoutManager.addTextContainer(container)
            layoutManager.ensureLayout(for: container)

            return ceil(layoutManager.usedRect(for: container).height + inset.height * 2)
        }

        /// The most recent `bounds.width` seen by ``layout()``, so intrinsic content size is
        /// only re-invalidated when the width — the axis that changes wrapped height — actually
        /// changes. Starts negative so the first real layout pass always invalidates.
        private var lastLayoutWidth: CGFloat = -1

        /// Reports a height that fits the current text wrapped to `bounds.width`, so a
        /// ``CDMarkdownNSTextView`` used directly under AppKit Auto Layout (with no explicit
        /// height constraint) grows to fit its content. Width is left unconstrained.
        override open var intrinsicContentSize: NSSize {
            guard customTextStorage != nil else { return super.intrinsicContentSize }
            return NSSize(width: NSView.noIntrinsicMetric,
                          height: fittingHeight(forWidth: bounds.width))
        }

        override open func layout() {
            super.layout()
            if bounds.width != lastLayoutWidth {
                lastLayoutWidth = bounds.width
                invalidateIntrinsicContentSize()
            }
        }
    }

#endif
