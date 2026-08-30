//
//  CDMarkdownParser.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright © 2016-2026 Christopher de Haan <contact@christopherdehaan.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

/// Parser for converting Markdown text into styled NSAttributedString.
@MainActor
open class CDMarkdownParser {

    // MARK: - Element Arrays

    private var escapingElements: [any CDMarkdownElement]
    // Not private: `insertCustomElement(before:after:)` reads/writes this from
    // CDMarkdownParser+Support.swift.
    var defaultElements: [any CDMarkdownElement]
    private var unescapingElements: [any CDMarkdownElement]

    /// Custom Markdown elements to parse in addition to built-in elements.
    /// Use ``addCustomElement(_:)`` and ``removeCustomElement(_:)`` to modify this collection safely.
    open var customElements: [any CDMarkdownElement]

    // MARK: - Basic Elements

    /// Handles GFM table syntax (pipe-delimited rows).
    public let table: CDMarkdownTable
    /// Handles horizontal rule syntax (---, ***, ___).
    public let horizontalRule: CDMarkdownHorizontalRule
    /// Handles heading syntax (#, ##, etc.).
    public let header: CDMarkdownHeader
    /// Handles unordered list syntax (*, -, +).
    public let list: CDMarkdownList
    /// Handles ordered list syntax (1., 2., 3., etc.).
    public let orderedList: CDMarkdownOrderedList
    /// Handles GFM task list syntax (`- [ ]`, `- [x]`).
    public let taskList: CDMarkdownTaskList
    /// Handles blockquote syntax (>).
    public let quote: CDMarkdownQuote
    /// Handles inline links using `[text](url)` syntax.
    public let link: CDMarkdownLink
    /// Handles automatic link detection for bare URLs.
    public let automaticLink: CDMarkdownAutomaticLink
    /// Handles reference-style links using `[text][ref]` syntax.
    public let linkReference: CDMarkdownLinkReference
    /// Handles bold text (**text** or __text__).
    public let bold: CDMarkdownBold
    /// Handles italic text (*text* or _text_).
    public let italic: CDMarkdownItalic
    /// Handles inline code (`code`).
    public let code: CDMarkdownCode
    /// Handles fenced code blocks using triple-backtick syntax.
    public let syntax: CDMarkdownSyntax
    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
        /// Handles image syntax using `![alt](url)` syntax. Not available on watchOS.
        public let image: CDMarkdownImage
    #endif
    /// Handles strikethrough text (~~text~~).
    public let strikethrough: CDMarkdownStrikethrough

    // MARK: - Escaping Elements

    private var codeEscaping = CDMarkdownCodeEscaping()
    private var escaping = CDMarkdownEscaping()
    /// Not private: `parseInline` reads this from CDMarkdownParser+Support.swift.
    var unescaping = CDMarkdownUnescaping()

    // MARK: - Configuration

    /// Enables automatic detection of bare URLs (without explicit Markdown link syntax) via ``CDMarkdownAutomaticLink``.
    /// Default is `true`. Set to `false` to skip automatic link detection.
    open var automaticLinkDetectionEnabled: Bool = true
    /// When enabled, collapses multiple consecutive newlines into a single newline, except inside
    /// fenced code blocks, where blank lines are always preserved.
    /// Default is `true`. Set to `false` to preserve blank lines exactly as they appear in input.
    open var squashNewlines: Bool = true
    /// When enabled, preserves leading whitespace (spaces and tabs) on each line exactly as written.
    /// Default is `false`, in which case the document is dedented: only the whitespace common to
    /// every line is removed, so relative indentation between lines (e.g. nested list markers) is
    /// preserved while incidental uniform indentation is still cleaned up. Set to `true` to skip
    /// this entirely and preserve indentation in code and quoted text unconditionally.
    open var preserveLeadingWhitespace: Bool = false
    /// Element types listed here are excluded from the parsing pipeline.
    /// Use this to opt out of specific default elements without subclassing.
    ///
    /// Example — disable header parsing:
    /// ```swift
    /// parser.disabledElementTypes.insert(ObjectIdentifier(CDMarkdownHeader.self))
    /// ```
    open var disabledElementTypes: Set<ObjectIdentifier> = []
    /// The default font used for all parsed text.
    public let font: CDFont
    /// The default text color for all parsed text.
    public let fontColor: CDColor
    /// The default background color for all parsed text.
    public let backgroundColor: CDColor
    /// The default paragraph style for all parsed text.
    public let paragraphStyle: NSParagraphStyle

    // MARK: - Initializer

    // swiftlint:disable function_body_length
    /// Creates a new parser with custom styling options.
    ///
    /// - Parameters:
    ///   - font: The default font for all parsed text. Defaults to the system font at 12pt.
    ///   - boldFont: Optional custom font for bold text. If `nil`, the parser derives it from `font`.
    ///   - italicFont: Optional custom font for italic text. If `nil`, the parser derives it from `font`.
    ///   - fontColor: The default text color. Defaults to the primary label color, which adapts to light and dark mode.
    ///   - backgroundColor: The default background color. Defaults to clear.
    ///   - paragraphStyle: Optional custom paragraph style (spacing, alignment, line height). If `nil`, a default style is created.
    ///   - imageSize: Optional size constraint for images. If `nil`, images render at their natural dimensions.
    ///   - automaticLinkDetectionEnabled: Whether to automatically detect bare URLs as links. Defaults to `true`.
    ///   - squashNewlines: Whether to collapse consecutive blank lines. Defaults to `true`.
    ///   - customElements: Array of custom ``CDMarkdownElement`` implementations to parse. Defaults to an empty array.
    ///
    /// Element construction itself is factored out to `CDMarkdownParser+Initialization.swift`;
    /// what remains here is individually assigning each of this type's 14 public element
    /// properties (a stable, deliberate public API — each is independently addressable as
    /// `parser.table`, `parser.bold`, etc.) plus the handful of array-building assignments that
    /// Swift's two-phase initialization requires to happen inline. That floor sits a few lines
    /// above the project's function_body_length limit without either breaking that public API
    /// or writing deliberately denser, less readable code purely to dodge the metric.
    public init(font: CDFont = CDFont.systemFont(ofSize: 12),
                boldFont: CDFont? = nil,
                italicFont: CDFont? = nil,
                fontColor: CDColor = CDColor.label,
                backgroundColor: CDColor = CDColor.clear,
                paragraphStyle: NSParagraphStyle? = nil,
                imageSize: CGSize? = nil,
                automaticLinkDetectionEnabled: Bool = true,
                squashNewlines: Bool = true,
                customElements: [any CDMarkdownElement] = []) {
        self.font = font
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle ?? Self.makeDefaultParagraphStyle()

        let style = CDMarkdownElementStyle(font: font,
                                           fontColor: fontColor,
                                           backgroundColor: backgroundColor,
                                           paragraphStyle: self.paragraphStyle)
        let elements = Self.makeElements(style: style, boldFont: boldFont, italicFont: italicFont)
        table = elements.table
        horizontalRule = elements.horizontalRule
        header = elements.header
        list = elements.list
        orderedList = elements.orderedList
        taskList = elements.taskList
        quote = elements.quote
        link = elements.link
        automaticLink = elements.automaticLink
        linkReference = elements.linkReference
        bold = elements.bold
        italic = elements.italic
        code = elements.code
        syntax = elements.syntax
        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            image = CDMarkdownImage(font: font,
                                    color: fontColor,
                                    backgroundColor: backgroundColor,
                                    paragraphStyle: self.paragraphStyle,
                                    size: imageSize)
        #endif
        strikethrough = elements.strikethrough

        self.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled
        self.squashNewlines = squashNewlines
        self.escapingElements = [codeEscaping, escaping]
        var defaultElementsList: [any CDMarkdownElement] = [
            table, horizontalRule, header, taskList, list, orderedList, quote, link, automaticLink, linkReference
        ]
        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            defaultElementsList.append(image)
        #endif
        defaultElementsList.append(contentsOf: [bold, italic, strikethrough] as [any CDMarkdownElement])
        self.defaultElements = defaultElementsList
        self.unescapingElements = [code, syntax, unescaping]
        self.customElements = customElements

        wireCrossElementReferences()
    }
    // swiftlint:enable function_body_length

    /// Wires up references between elements that can only be established once every
    /// element on the parser has been constructed. Must run after every stored property
    /// has an initial value (Swift's two-phase initialization requires this), so it's
    /// called as the very last step of `init(font:...)` rather than being inlined there.
    private func wireCrossElementReferences() {
        code.parser = self
        syntax.parser = self

        // Wire inline parsing for table cells after all elements are initialized
        table.inlineParser = { [weak self] cellText in
            guard let self else { return NSAttributedString(string: cellText) }
            return self.parseInline(cellText)
        }
    }

    // MARK: - Element Extensibility

    /// Adds a custom Markdown element to the parser.
    ///
    /// - Parameter element: A ``CDMarkdownElement`` implementation to add to the parsing pipeline.
    ///
    /// Custom elements are parsed after built-in elements (headers, lists, links, etc.) but before
    /// the unescaping pass. This allows custom syntax to take priority over default parsing.
    open func addCustomElement(_ element: any CDMarkdownElement) {
        customElements.append(element)
    }

    /// Removes a custom Markdown element from the parser.
    ///
    /// - Parameter element: The ``CDMarkdownElement`` instance to remove.
    ///
    /// This method uses instance identity (`===`) to find and remove the element.
    open func removeCustomElement(_ element: any CDMarkdownElement) {
        guard let index = customElements.firstIndex(where: { someElement -> Bool in
            return element === someElement
        }) else {
            return
        }
        customElements.remove(at: index)
    }

    // MARK: - Parsing

    /// Asynchronously parses a Markdown string with image loading support.
    ///
    /// - Parameter string: The raw Markdown text to parse.
    /// - Returns: An `NSAttributedString` with styling applied and remote images downloaded and injected.
    ///
    /// Use this overload for Markdown containing image references. Remote images are downloaded
    /// asynchronously.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    open func parse(_ string: String) async -> NSAttributedString {
        await parse(NSAttributedString(string: string))
    }

    /// Asynchronously parses a Markdown NSAttributedString with image loading support.
    ///
    /// - Parameter attributedString: The attributed Markdown text to parse.
    /// - Returns: An `NSAttributedString` with styling applied and remote images downloaded and injected.
    ///
    /// Use this overload for Markdown containing image references. Remote images are downloaded
    /// asynchronously.
    ///
    /// Note: Input attributes other than font, foregroundColor, backgroundColor, and paragraphStyle are not guaranteed to survive parsing, as the
    /// leading-whitespace dedent step performs a full-string replacement that can collapse attribute-run boundaries.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    open func parse(_ attributedString: NSAttributedString) async -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: runParsePipeline(attributedString))
        await resolveImages(in: result)
        return result
    }

    private func squashConsecutiveNewlines(in mutableString: NSMutableString) {
        guard squashNewlines,
              let squashRegex = try? NSRegularExpression(pattern: "(?:\r?\n){2,}") else {
            return
        }
        let fencedRanges = fencedCodeBlockRanges(in: mutableString as String)
        let fullRange = NSRange(location: 0, length: mutableString.length)
        let matches = squashRegex.matches(in: mutableString as String, options: [], range: fullRange)
        for match in matches.reversed() {
            let matchRange = match.range
            let isInsideFencedBlock = fencedRanges.contains { NSLocationInRange(matchRange.location, $0) }
            if isInsideFencedBlock {
                continue
            }
            mutableString.replaceCharacters(in: matchRange, with: "\n")
        }
    }

    private func normalizeWhitespace(in attributedString: NSMutableAttributedString) {
        let mutableString = attributedString.mutableString
        mutableString.replaceOccurrences(of: "&nbsp;",
                                         with: " ",
                                         range: NSRange(location: 0,
                                                        length: mutableString.length))
        // Conditionally dedent leading whitespace. When preserveLeadingWhitespace is true,
        // skip this step to maintain spaces at the beginning of lines.
        if !preserveLeadingWhitespace {
            let original = mutableString as String
            let dedented = CDMarkdownParser.dedent(original)
            if dedented != original {
                mutableString.setString(dedented)
            }
        }
    }

    private func applyBaseAttributes(to attributedString: NSMutableAttributedString) {
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.addFont(font,
                                 toRange: range)
        attributedString.addForegroundColor(fontColor,
                                            toRange: range)
        attributedString.addBackgroundColor(backgroundColor,
                                            toRange: range)
        attributedString.addParagraphStyle(paragraphStyle,
                                           toRange: range)
    }

    private func buildPipelineElements() -> [any CDMarkdownElement] {
        var elements: [any CDMarkdownElement] = escapingElements
        let activeElements = defaultElements.filter { element in
            !disabledElementTypes.contains(ObjectIdentifier(type(of: element)))
        }
        elements.append(contentsOf: activeElements)
        elements.append(contentsOf: customElements)
        elements.append(contentsOf: unescapingElements)
        return elements
    }

    private func runParsePipeline(_ markdown: NSAttributedString) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: markdown)
        squashConsecutiveNewlines(in: attributedString.mutableString)
        normalizeWhitespace(in: attributedString)
        applyBaseAttributes(to: attributedString)

        // Phase 1.5 — Extract and strip reference link definitions
        let referenceDefinitions = parseReferenceDefinitions(from: attributedString)
        linkReference.references = referenceDefinitions

        let elements = buildPipelineElements()

        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            image.placeholderOnly = true
        #endif

        for element in elements {
            if automaticLinkDetectionEnabled || type(of: element) != CDMarkdownAutomaticLink.self {
                element.parse(attributedString)
            }
        }

        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            image.placeholderOnly = false
        #endif

        return attributedString
    }

}
