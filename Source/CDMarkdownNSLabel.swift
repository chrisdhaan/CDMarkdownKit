#if os(macOS)

    import Cocoa

    /// A lightweight read-only `NSView` subclass that renders `NSAttributedString` output from
    /// `CDMarkdownParser`. Supports rounded-corner backgrounds for code spans via `NSLayoutManager`.
    ///
    /// Use ``CDMarkdownNSLabel`` for simple markdown display without link interaction. For text
    /// with clickable links, use ``CDMarkdownNSTextView`` instead.
    @MainActor
    open class CDMarkdownNSLabel: NSView {

        // MARK: - Public Properties

        /// The attributed string to display. Setting this value triggers a layout update and redraw.
        open var attributedText: NSAttributedString = NSAttributedString() {
            didSet {
                textStorage.setAttributedString(attributedText)
                invalidateIntrinsicContentSize()
                needsDisplay = true
            }
        }

        /// When `true`, all background color regions (code blocks, syntax blocks, etc.) are drawn with rounded corners.
        /// When `false` (default), backgrounds are drawn as rectangles. Set to `true` for a softer appearance.
        open var roundAllCorners: Bool = false {
            didSet {
                layoutManager.roundAllCorners = roundAllCorners
            }
        }

        /// The maximum number of lines to display. Set to 0 (default) for unlimited lines.
        open var numberOfLines: Int = 0 {
            didSet {
                textContainer.maximumNumberOfLines = numberOfLines
                invalidateIntrinsicContentSize()
                needsDisplay = true
            }
        }

        // MARK: - Private Text Stack

        private let textStorage = NSTextStorage()
        private let layoutManager = CDMarkdownNSLayoutManager()
        private let textContainer = NSTextContainer()

        // MARK: - Initializers

        override public init(frame: NSRect) {
            super.init(frame: frame)
            configure()
        }

        public required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }

        // MARK: - Configuration

        private func configure() {
            textContainer.lineFragmentPadding = 0
            textContainer.maximumNumberOfLines = 0
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
        }

        // MARK: - Layout

        override open var intrinsicContentSize: NSSize {
            textContainer.containerSize = NSSize(width: bounds.width,
                                                 height: CGFloat.greatestFiniteMagnitude)
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            return NSSize(width: NSView.noIntrinsicMetric, height: ceil(usedRect.height))
        }

        override open func layout() {
            super.layout()
            textContainer.containerSize = NSSize(width: bounds.width,
                                                 height: CGFloat.greatestFiniteMagnitude)
        }

        // MARK: - Drawing

        override open func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
            layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
        }
    }

#endif
