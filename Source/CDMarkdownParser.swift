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
    private var defaultElements: [any CDMarkdownElement]
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
    private var unescaping = CDMarkdownUnescaping()

    // MARK: - Configuration

    /// Enables automatic detection of bare URLs (without explicit Markdown link syntax) via ``CDMarkdownAutomaticLink``.
    /// Default is `true`. Set to `false` to skip automatic link detection.
    open var automaticLinkDetectionEnabled: Bool = true
    /// When enabled, collapses multiple consecutive newlines into a single newline.
    /// Default is `true`. Set to `false` to preserve blank lines exactly as they appear in input.
    open var squashNewlines: Bool = true
    /// When enabled, preserves leading whitespace (spaces and tabs) on each line.
    /// Default is `false` (leading whitespace is stripped). Set to `true` to preserve indentation in code and quoted text.
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

    /// Creates a new parser with custom styling options.
    ///
    /// - Parameters:
    ///   - font: The default font for all parsed text. Defaults to the system font at 12pt.
    ///   - boldFont: Optional custom font for bold text. If `nil`, the parser derives it from `font`.
    ///   - italicFont: Optional custom font for italic text. If `nil`, the parser derives it from `font`.
    ///   - fontColor: The default text color. Defaults to black.
    ///   - backgroundColor: The default background color. Defaults to clear.
    ///   - paragraphStyle: Optional custom paragraph style (spacing, alignment, line height). If `nil`, a default style is created.
    ///   - imageSize: Optional size constraint for images. If `nil`, images render at their natural dimensions.
    ///   - automaticLinkDetectionEnabled: Whether to automatically detect bare URLs as links. Defaults to `true`.
    ///   - squashNewlines: Whether to collapse consecutive blank lines. Defaults to `true`.
    ///   - customElements: Array of custom ``CDMarkdownElement`` implementations to parse. Defaults to an empty array.
    public init(font: CDFont = CDFont.systemFont(ofSize: 12),
                boldFont: CDFont? = nil,
                italicFont: CDFont? = nil,
                fontColor: CDColor = CDColor.black,
                backgroundColor: CDColor = CDColor.clear,
                paragraphStyle: NSParagraphStyle? = nil,
                imageSize: CGSize? = nil,
                automaticLinkDetectionEnabled: Bool = true,
                squashNewlines: Bool = true,
                customElements: [any CDMarkdownElement] = []) {
        self.font = font
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        if let paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 3
            paragraphStyle.paragraphSpacingBefore = 0
            paragraphStyle.lineSpacing = 1.38
            self.paragraphStyle = paragraphStyle
        }

        table = CDMarkdownTable(font: font,
                                color: fontColor,
                                backgroundColor: backgroundColor,
                                paragraphStyle: paragraphStyle)
        horizontalRule = CDMarkdownHorizontalRule(font: font,
                                                  color: fontColor,
                                                  backgroundColor: backgroundColor,
                                                  paragraphStyle: paragraphStyle)
        header = CDMarkdownHeader(font: font,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
        list = CDMarkdownList(font: font,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        orderedList = CDMarkdownOrderedList(font: font,
                                            color: fontColor,
                                            backgroundColor: backgroundColor,
                                            paragraphStyle: paragraphStyle)
        taskList = CDMarkdownTaskList(font: font,
                                      color: fontColor,
                                      backgroundColor: backgroundColor,
                                      paragraphStyle: paragraphStyle)
        quote = CDMarkdownQuote(font: font,
                                color: fontColor,
                                backgroundColor: backgroundColor,
                                paragraphStyle: paragraphStyle)
        link = CDMarkdownLink(font: font,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        automaticLink = CDMarkdownAutomaticLink(font: font,
                                                color: fontColor,
                                                backgroundColor: backgroundColor,
                                                paragraphStyle: paragraphStyle)
        linkReference = CDMarkdownLinkReference(font: font,
                                                color: fontColor,
                                                backgroundColor: backgroundColor,
                                                paragraphStyle: paragraphStyle)
        bold = CDMarkdownBold(font: font,
                              customBoldFont: boldFont,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        italic = CDMarkdownItalic(font: font,
                                  customItalicFont: italicFont,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
        code = CDMarkdownCode(font: font,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        syntax = CDMarkdownSyntax(font: font,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            image = CDMarkdownImage(font: font,
                                    color: fontColor,
                                    backgroundColor: backgroundColor,
                                    paragraphStyle: self.paragraphStyle,
                                    size: imageSize)
        #endif
        strikethrough = CDMarkdownStrikethrough(font: font,
                                                color: fontColor,
                                                backgroundColor: backgroundColor,
                                                paragraphStyle: paragraphStyle)

        self.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled
        self.squashNewlines = squashNewlines
        self.escapingElements = [codeEscaping, escaping]
        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            self.defaultElements = [
                table, horizontalRule, header, taskList, list, orderedList, quote, link,
                automaticLink, linkReference, image, bold, italic, strikethrough
            ]
        #else
            self.defaultElements = [
                table, horizontalRule, header, taskList, list, orderedList, quote, link,
                automaticLink, linkReference, bold, italic, strikethrough
            ]
        #endif
        self.unescapingElements = [code, syntax, unescaping]
        self.customElements = customElements
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

    /// Disables all default elements of the given type from the parsing pipeline.
    ///
    /// - Parameter elementType: The type of element to disable (e.g., `CDMarkdownHeader.self`).
    ///
    /// Use this to opt out of specific default elements without subclassing. For example:
    /// ```swift
    /// parser.disable(CDMarkdownHeader.self)
    /// ```
    public func disable(_ elementType: (some AnyObject).Type) {
        disabledElementTypes.insert(ObjectIdentifier(elementType))
    }

    /// Re-enables all default elements of the given type in the parsing pipeline.
    ///
    /// - Parameter elementType: The type of element to re-enable (e.g., `CDMarkdownHeader.self`).
    public func enable(_ elementType: (some AnyObject).Type) {
        disabledElementTypes.remove(ObjectIdentifier(elementType))
    }

    /// Inserts a custom element into the pipeline immediately before all default elements of a given type.
    ///
    /// - Parameters:
    ///   - element: A ``CDMarkdownElement`` implementation to insert.
    ///   - elementType: The type of default element to insert before (e.g., `CDMarkdownBold.self`).
    ///
    /// If no default element of the specified type exists, the custom element is appended to `customElements`.
    public func insertCustomElement(_ element: any CDMarkdownElement,
                                    before elementType: (some AnyObject).Type) {
        let targetID = ObjectIdentifier(elementType)
        if let index = defaultElements.firstIndex(where: { ObjectIdentifier(type(of: $0)) == targetID }) {
            defaultElements.insert(element, at: index)
        } else {
            customElements.append(element)
        }
    }

    /// Inserts a custom element into the pipeline immediately after all default elements of a given type.
    ///
    /// - Parameters:
    ///   - element: A ``CDMarkdownElement`` implementation to insert.
    ///   - elementType: The type of default element to insert after (e.g., `CDMarkdownBold.self`).
    ///
    /// If no default element of the specified type exists, the custom element is appended to `customElements`.
    public func insertCustomElement(_ element: any CDMarkdownElement,
                                    after elementType: (some AnyObject).Type) {
        let targetID = ObjectIdentifier(elementType)
        if let index = defaultElements.lastIndex(where: { ObjectIdentifier(type(of: $0)) == targetID }) {
            defaultElements.insert(element, at: index + 1)
        } else {
            customElements.append(element)
        }
    }

    // MARK: - Parsing

    /// Parses a Markdown string and returns a styled NSAttributedString.
    ///
    /// - Parameter markdown: The raw Markdown text to parse.
    /// - Returns: An `NSAttributedString` with styling applied for all recognized Markdown syntax.
    ///
    /// Images are not loaded in the synchronous overload. Use the async overload for remote image support.
    @available(*, deprecated, renamed: "parse(_:)")
    open func parse(_ markdown: String) -> NSAttributedString {
        parse(NSAttributedString(string: markdown))
    }

    /// Parses a Markdown NSAttributedString and returns a styled NSAttributedString.
    ///
    /// - Parameter markdown: The attributed Markdown text to parse.
    /// - Returns: An `NSAttributedString` with styling applied for all recognized Markdown syntax.
    ///
    /// Images are not loaded in the synchronous overload. Use the async overload to download remote images.
    @available(*, deprecated, renamed: "parse(_:)")
    open func parse(_ markdown: NSAttributedString) -> NSAttributedString {
        parse(markdown, loadImages: false)
    }

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
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    open func parse(_ attributedString: NSAttributedString) async -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: parse(attributedString, loadImages: false))
        await resolveImages(in: result)
        return result
    }

    private func parseInline(_ string: String) -> NSAttributedString {
        let attrs: [CDAttributedStringKey: AnyObject] = [.font: font as AnyObject,
                                                         .foregroundColor: fontColor as AnyObject]
        let result = NSMutableAttributedString(string: string, attributes: attrs)
        let inlineElements: [any CDMarkdownElement] = [
            codeEscaping, escaping,
            link, automaticLink,
            bold, italic, strikethrough,
            code, unescaping
        ]
        for element in inlineElements {
            element.parse(result)
        }
        return result
    }

    /// Scans `attributedString` for reference link definitions, removes them from the string,
    /// and returns a dictionary mapping lowercased reference IDs to their resolved URLs.
    ///
    /// Supported definition format (one per line):
    /// `[id]: url`
    /// `[id]: url "title"`
    /// `[id]: url 'title'`
    /// `[id]: url (title)`
    private func parseReferenceDefinitions(
        from attributedString: NSMutableAttributedString
    ) -> [String: (url: String, title: String?)] {
        var definitions: [String: (url: String, title: String?)] = [:]

        let pattern = #"^\[([^\]]+)\]:\s+(\S+)(?:\s+"([^"]*)"|\s+'([^']*)'|\s+\(([^)]*)\))?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return definitions
        }

        let fullRange = NSRange(location: 0, length: attributedString.length)
        let matches = regex.matches(in: attributedString.string, options: [], range: fullRange)

        // Iterate in reverse so that removing ranges doesn't shift subsequent indices
        for match in matches.reversed() {
            let idRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            // Title may be in group 3, 4, or 5 depending on which delimiter was used
            let titleRange = [3, 4, 5].compactMap { match.range(at: $0) }
                .first { $0.location != NSNotFound }

            guard let referenceId = Range(idRange, in: attributedString.string).map({ String(attributedString.string[$0]) }),
                  let url = Range(urlRange, in: attributedString.string).map({ String(attributedString.string[$0]) }) else {
                continue
            }

            let title = titleRange.flatMap { Range($0, in: attributedString.string) }
                .map { String(attributedString.string[$0]) }

            definitions[referenceId.lowercased()] = (url: url, title: title)

            // Remove the definition line (including its trailing newline if present)
            var removeRange = match.range(at: 0)
            let nsString = attributedString.string as NSString
            if removeRange.location + removeRange.length < attributedString.length,
               nsString.character(at: removeRange.location + removeRange.length) == (("\n" as Unicode.Scalar).value) {
                removeRange.length += 1
            }
            attributedString.deleteCharacters(in: removeRange)
        }

        return definitions
    }

    private func parse(_ markdown: NSAttributedString, loadImages: Bool) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: markdown)
        let mutableString = attributedString.mutableString
        if squashNewlines {
            mutableString.replaceOccurrences(of: "\n\n+",
                                             with: "\n",
                                             options: .regularExpression,
                                             range: NSRange(location: 0,
                                                            length: mutableString.length))
        }
        mutableString.replaceOccurrences(of: "&nbsp;",
                                         with: " ",
                                         range: NSRange(location: 0,
                                                        length: mutableString.length))
        // Conditionally strip leading whitespace. When preserveLeadingWhitespace is true,
        // skip this step to maintain spaces at the beginning of lines.
        if !preserveLeadingWhitespace {
            // Use [ \t]+ rather than \s+ so blank lines (\n only) are not consumed.
            // \s includes \n, which would collapse blank lines even when squashNewlines is false.
            let regExp = try? NSRegularExpression(pattern: "^[ \\t]+",
                                                  options: .anchorsMatchLines)
            if let regExp {
                regExp.replaceMatches(in: mutableString,
                                      options: [],
                                      range: NSRange(location: 0,
                                                     length: mutableString.length),
                                      withTemplate: "")
            }
        }
        let range = NSRange(location: 0,
                            length: attributedString.length)

        attributedString.addFont(font,
                                 toRange: range)
        attributedString.addForegroundColor(fontColor,
                                            toRange: range)
        attributedString.addBackgroundColor(backgroundColor,
                                            toRange: range)
        attributedString.addParagraphStyle(paragraphStyle,
                                           toRange: range)

        // Phase 1.5 — Extract and strip reference link definitions
        let referenceDefinitions = parseReferenceDefinitions(from: attributedString)
        linkReference.references = referenceDefinitions

        var elements: [any CDMarkdownElement] = escapingElements
        let activeElements = defaultElements.filter { element in
            !disabledElementTypes.contains(ObjectIdentifier(type(of: element)))
        }
        elements.append(contentsOf: activeElements)
        elements.append(contentsOf: customElements)
        elements.append(contentsOf: unescapingElements)

        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            if !loadImages {
                image.placeholderOnly = true
            }
        #endif

        for element in elements {
            if automaticLinkDetectionEnabled || type(of: element) != CDMarkdownAutomaticLink.self {
                element.parse(attributedString)
            }
        }

        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
            if !loadImages {
                image.placeholderOnly = false
            }
        #endif

        return attributedString
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    private func urlSessionData(from url: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }.resume()
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    private func resolveImages(in attributedString: NSMutableAttributedString) async {
        var replacements: [(range: NSRange, url: URL)] = []
        attributedString.enumerateAttribute(.cdMarkdownImageURL,
                                            in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
            if let url = value as? URL {
                replacements.append((range, url))
            }
        }

        for (range, url) in replacements.reversed() {
            if let data = try? await urlSessionData(from: url),
               let image = CDImage(data: data) {
                let attachment = NSTextAttachment()
                attachment.image = image
                #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
                    if let size = self.image.size {
                        let preferredWidth = size.width - 10
                        let widthScalingFactor = image.size.width / preferredWidth
                        attachment.bounds = CGRect(x: 0,
                                                   y: 0,
                                                   width: image.size.width / widthScalingFactor,
                                                   height: image.size.height / widthScalingFactor)
                    }
                #endif
                let replacement = NSAttributedString(attachment: attachment)
                attributedString.replaceCharacters(in: range, with: replacement)
            }
        }
    }

    #if os(iOS) || os(visionOS)
        /// Returns a copy of the attributed string with VoiceOver-compatible accessibility
        /// annotations derived from CDMarkdownKit's custom attributes.
        ///
        /// Pass the result to `UILabel.accessibilityAttributedLabel` or
        /// `UITextView.accessibilityAttributedLabel`.
        public func accessibilityAttributedString(from attributedString: NSAttributedString) -> NSAttributedString {
            let result = NSMutableAttributedString(attributedString: attributedString)
            let fullRange = NSRange(location: 0, length: result.length)

            result.enumerateAttribute(.cdMarkdownHeadingLevel, in: fullRange) { value, range, _ in
                guard let level = value as? Int else { return }
                result.addAttribute(.accessibilityTextHeadingLevel,
                                    value: level as AnyObject,
                                    range: range)
            }

            return result
        }
    #endif
}
