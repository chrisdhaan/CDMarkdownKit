#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

/// A value type that bundles visual styling for all CDMarkdownKit elements.
///
/// Pass a theme to `CDMarkdownParser.init(theme:)` to style the entire parser at once.
/// Individual element properties can still be overridden after initialization.
public struct CDMarkdownTheme {

    // MARK: - Base

    /// The default body font used for unstyled text and as a base for element fonts.
    public var font: CDFont
    /// The default foreground colour for unstyled text.
    public var fontColor: CDColor
    /// The background colour of the view (used to size spacing).
    public var backgroundColor: CDColor

    // MARK: - Per-Element Overrides

    public var header: HeaderTheme
    public var bold: InlineTheme
    public var italic: InlineTheme
    public var code: InlineTheme
    public var syntax: InlineTheme
    public var strikethrough: InlineTheme
    public var quote: InlineTheme
    public var list: InlineTheme
    public var orderedList: InlineTheme
    public var link: LinkTheme
    public var linkReference: LinkTheme
    public var taskList: InlineTheme
    public var horizontalRule: InlineTheme

    // MARK: - Nested Types

    /// Styling properties shared by most inline elements.
    public struct InlineTheme: Equatable {
        public var font: CDFont?
        public var color: CDColor?
        public var backgroundColor: CDColor?
        public var paragraphStyle: NSParagraphStyle?
        public var underlineColor: CDColor?
        public var underlineStyle: NSUnderlineStyle?

        public init(font: CDFont? = nil,
                    color: CDColor? = nil,
                    backgroundColor: CDColor? = nil,
                    paragraphStyle: NSParagraphStyle? = nil,
                    underlineColor: CDColor? = nil,
                    underlineStyle: NSUnderlineStyle? = nil) {
            self.font = font
            self.color = color
            self.backgroundColor = backgroundColor
            self.paragraphStyle = paragraphStyle
            self.underlineColor = underlineColor
            self.underlineStyle = underlineStyle
        }
    }

    /// Extends `InlineTheme` with heading-specific sizing.
    public struct HeaderTheme: Equatable {
        public var font: CDFont?
        public var color: CDColor?
        public var fontIncrease: Int
        public var paragraphStyle: NSParagraphStyle?
        public var underlineColor: CDColor?
        public var underlineStyle: NSUnderlineStyle?

        public init(font: CDFont? = nil,
                    color: CDColor? = nil,
                    fontIncrease: Int = 2,
                    paragraphStyle: NSParagraphStyle? = nil,
                    underlineColor: CDColor? = nil,
                    underlineStyle: NSUnderlineStyle? = nil) {
            self.font = font
            self.color = color
            self.fontIncrease = fontIncrease
            self.paragraphStyle = paragraphStyle
            self.underlineColor = underlineColor
            self.underlineStyle = underlineStyle
        }
    }

    /// Extends `InlineTheme` with link-specific underline defaults.
    public struct LinkTheme: Equatable {
        public var font: CDFont?
        public var color: CDColor?
        public var backgroundColor: CDColor?
        public var underlineColor: CDColor?
        public var underlineStyle: NSUnderlineStyle?

        public init(font: CDFont? = nil,
                    color: CDColor? = nil,
                    backgroundColor: CDColor? = nil,
                    underlineColor: CDColor? = nil,
                    underlineStyle: NSUnderlineStyle? = nil) {
            self.font = font
            self.color = color
            self.backgroundColor = backgroundColor
            self.underlineColor = underlineColor
            self.underlineStyle = underlineStyle
        }
    }

    // MARK: - Initializer

    public init(
        font: CDFont = CDFont.systemFont(ofSize: 12),
        fontColor: CDColor = CDColor.black,
        backgroundColor: CDColor = CDColor.clear,
        header: HeaderTheme = HeaderTheme(),
        bold: InlineTheme = InlineTheme(),
        italic: InlineTheme = InlineTheme(),
        code: InlineTheme = InlineTheme(
            font: CDFont(name: "Menlo-Regular", size: 12),
            color: CDColor.codeTextRed(),
            backgroundColor: CDColor.codeBackgroundRed()
        ),
        syntax: InlineTheme = InlineTheme(
            font: CDFont(name: "Menlo-Regular", size: 12),
            color: CDColor.syntaxTextGray(),
            backgroundColor: CDColor.syntaxBackgroundGray()
        ),
        strikethrough: InlineTheme = InlineTheme(),
        quote: InlineTheme = InlineTheme(),
        list: InlineTheme = InlineTheme(),
        orderedList: InlineTheme = InlineTheme(),
        link: LinkTheme = LinkTheme(),
        linkReference: LinkTheme = LinkTheme(),
        taskList: InlineTheme = InlineTheme(),
        horizontalRule: InlineTheme = InlineTheme()
    ) {
        self.font = font
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        self.header = header
        self.bold = bold
        self.italic = italic
        self.code = code
        self.syntax = syntax
        self.strikethrough = strikethrough
        self.quote = quote
        self.list = list
        self.orderedList = orderedList
        self.link = link
        self.linkReference = linkReference
        self.taskList = taskList
        self.horizontalRule = horizontalRule
    }
}

extension CDMarkdownTheme: Equatable {}
extension CDMarkdownTheme: @unchecked Sendable {}

extension CDMarkdownTheme {

    /// The default CDMarkdownKit styling — mirrors the existing `CDMarkdownParser.init()` defaults.
    public static var `default`: CDMarkdownTheme {
        CDMarkdownTheme()
    }

    /// A minimal dark-mode–friendly theme using system colours.
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, visionOS 1.0, *)
    public static var systemDark: CDMarkdownTheme {
        CDMarkdownTheme(
            font: CDFont.systemFont(ofSize: 14),
            fontColor: CDColor.white,
            backgroundColor: CDColor.black,
            code: InlineTheme(
                font: CDFont(name: "Menlo-Regular", size: 13),
                color: CDColor.orange,
                backgroundColor: CDColor.darkGray
            ),
            syntax: InlineTheme(
                font: CDFont(name: "Menlo-Regular", size: 13),
                color: CDColor.lightGray,
                backgroundColor: CDColor.darkGray
            ),
            link: LinkTheme(color: CDColor.systemBlue),
            linkReference: LinkTheme(color: CDColor.systemBlue)
        )
    }
}
