//
//  CDMarkdownParser.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright © 2016-2022 Christopher de Haan <contact@christopherdehaan.me>
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

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

/// Parser for converting Markdown text into styled NSAttributedString.
@MainActor
open class CDMarkdownParser {

    // MARK: - Element Arrays
    fileprivate var escapingElements: [any CDMarkdownElement]
    fileprivate var defaultElements: [any CDMarkdownElement]
    fileprivate var unescapingElements: [any CDMarkdownElement]

    /// Custom Markdown elements to parse in addition to built-in elements.
    open var customElements: [any CDMarkdownElement]

    // MARK: - Basic Elements
    /// Handles heading syntax (#, ##, etc.).
    public let header: CDMarkdownHeader
    /// Handles unordered list syntax (*, -, +).
    public let list: CDMarkdownList
    /// Handles blockquote syntax (>).
    public let quote: CDMarkdownQuote
    /// Handles inline links ([text](url)).
    public let link: CDMarkdownLink
    /// Handles automatic link detection for bare URLs.
    public let automaticLink: CDMarkdownAutomaticLink
    /// Handles bold text (**text** or __text__).
    public let bold: CDMarkdownBold
    /// Handles italic text (*text* or _text_).
    public let italic: CDMarkdownItalic
    /// Handles inline code (`code`).
    public let code: CDMarkdownCode
    /// Handles fenced code blocks (```code```).
    public let syntax: CDMarkdownSyntax
#if os(iOS) || os(macOS) || os(tvOS)
    /// Handles image syntax (![alt](url)). Not available on watchOS.
    public let image: CDMarkdownImage
#endif
    /// Handles strikethrough text (~~text~~).
    public let strikethrough: CDMarkdownStrikethrough

    // MARK: - Escaping Elements
    fileprivate var codeEscaping = CDMarkdownCodeEscaping()
    fileprivate var escaping = CDMarkdownEscaping()
    fileprivate var unescaping = CDMarkdownUnescaping()

    // MARK: - Configuration
    /// Enables automatic detection of URLs without explicit Markdown syntax.
    open var automaticLinkDetectionEnabled: Bool = true
    /// When enabled, collapses multiple consecutive newlines into a single newline.
    open var squashNewlines: Bool = true
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
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 3
            paragraphStyle.paragraphSpacingBefore = 0
            paragraphStyle.lineSpacing = 1.38
            self.paragraphStyle = paragraphStyle
        }

        header = CDMarkdownHeader(font: font,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
        list = CDMarkdownList(font: font,
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
#if os(iOS) || os(macOS) || os(tvOS)
        image = CDMarkdownImage(font: font,
                                color: fontColor,
                                backgroundColor: backgroundColor,
                                paragraphStyle: paragraphStyle,
                                size: imageSize)
#endif
        strikethrough = CDMarkdownStrikethrough(font: font,
                                                color: fontColor,
                                                backgroundColor: backgroundColor,
                                                paragraphStyle: paragraphStyle)

        self.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled
        self.squashNewlines = squashNewlines
        self.escapingElements = [codeEscaping, escaping]
#if os(iOS) || os(macOS) || os(tvOS)
        self.defaultElements = [header, list, quote, link, automaticLink, image, bold, italic, strikethrough]
#else
        self.defaultElements = [header, list, quote, link, automaticLink, bold, italic, strikethrough]
#endif
        self.unescapingElements = [code, syntax, unescaping]
        self.customElements = customElements
    }

    // MARK: - Element Extensibility
    /// Adds a custom Markdown element to the parser.
    open func addCustomElement(_ element: any CDMarkdownElement) {
        customElements.append(element)
    }

    /// Removes a custom Markdown element from the parser.
    open func removeCustomElement(_ element: any CDMarkdownElement) {
        guard let index = customElements.firstIndex(where: { someElement -> Bool in
            return element === someElement
        }) else {
            return
        }
        customElements.remove(at: index)
    }

    // MARK: - Parsing
    /// Parses a Markdown string and returns a styled NSAttributedString.
    open func parse(_ markdown: String) -> NSAttributedString {
        return parse(NSAttributedString(string: markdown))
    }

    /// Parses a Markdown NSAttributedString and returns a styled NSAttributedString.
    open func parse(_ markdown: NSAttributedString) -> NSAttributedString {
        return parse(markdown, loadImages: true)
    }

    /// Asynchronously parses a Markdown string with image loading support.
    open func parse(_ string: String) async -> NSAttributedString {
        return await parse(NSAttributedString(string: string))
    }

    /// Asynchronously parses a Markdown NSAttributedString with image loading support.
    open func parse(_ attributedString: NSAttributedString) async -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: parse(attributedString, loadImages: false))
        await resolveImages(in: result)
        return result
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
        let regExp = try? NSRegularExpression(pattern: "^\\s+",
                                              options: .anchorsMatchLines)
        if let regExp = regExp {
            regExp.replaceMatches(in: mutableString,
                                  options: [],
                                  range: NSRange(location: 0,
                                                 length: mutableString.length),
                                  withTemplate: "")
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

        var elements: [any CDMarkdownElement] = escapingElements
        elements.append(contentsOf: defaultElements)
        elements.append(contentsOf: customElements)
        elements.append(contentsOf: unescapingElements)

        #if os(iOS) || os(macOS) || os(tvOS)
        if !loadImages {
            image.placeholderOnly = true
        }
        #endif

        elements.forEach { element in
            if automaticLinkDetectionEnabled || type(of: element) != CDMarkdownAutomaticLink.self {
                element.parse(attributedString)
            }
        }

        #if os(iOS) || os(macOS) || os(tvOS)
        if !loadImages {
            image.placeholderOnly = false
        }
        #endif

        return attributedString
    }

    private func resolveImages(in attributedString: NSMutableAttributedString) async {
        var replacements: [(range: NSRange, url: URL)] = []
        attributedString.enumerateAttribute(.cdMarkdownImageURL,
                                            in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
            if let url = value as? URL {
                replacements.append((range, url))
            }
        }

        for (range, url) in replacements.reversed() {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = CDImage(data: data) {
                let attachment = NSTextAttachment()
                attachment.image = image
                #if os(iOS) || os(macOS) || os(tvOS)
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
}
