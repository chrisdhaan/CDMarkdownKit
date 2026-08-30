//
//  CDMarkdownParser+Support.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 8/29/26.
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

extension CDMarkdownParser {

    // MARK: - Element Extensibility

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

    // MARK: - Reference Definitions

    /// Returns the ranges of all fenced code blocks (``` ... ```) in `string`.
    /// Used to exclude content inside code blocks from reference definition scanning.
    func fencedCodeBlockRanges(in string: String) -> [NSRange] {
        let nsString = string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        let closedPattern = #"^```[^\n]*\n[\s\S]*?^```[ \t]*$"#
        guard let closedRegex = try? NSRegularExpression(pattern: closedPattern, options: .anchorsMatchLines) else {
            return []
        }
        let closedRanges = closedRegex.matches(in: string, options: [], range: fullRange).map(\.range)

        // An opening fence with no matching close: conservatively treat everything from
        // that fence to the end of the string as code, so reference-definition-looking
        // lines inside an unterminated fence aren't mistaken for real definitions.
        guard let openPattern = try? NSRegularExpression(pattern: #"^```[^\n]*$"#, options: .anchorsMatchLines) else {
            return closedRanges
        }
        var ranges = closedRanges
        let openMatches = openPattern.matches(in: string, options: [], range: fullRange)
        for openMatch in openMatches {
            let alreadyCovered = closedRanges.contains { NSLocationInRange(openMatch.range.location, $0) }
            if alreadyCovered {
                continue
            }
            ranges.append(NSRange(location: openMatch.range.location,
                                  length: nsString.length - openMatch.range.location))
            break
        }
        return ranges
    }

    /// Scans `attributedString` for reference link definitions, removes them from the string,
    /// and returns a dictionary mapping lowercased reference IDs to their resolved URLs.
    ///
    /// Supported definition format (one per line):
    /// `[id]: url`
    /// `[id]: url "title"`
    /// `[id]: url 'title'`
    /// `[id]: url (title)`
    func parseReferenceDefinitions(
        from attributedString: NSMutableAttributedString
    ) -> [String: (url: String, title: String?)] {
        var definitions: [String: (url: String, title: String?)] = [:]

        let pattern = #"^\[([^\]]+)\]:\s+(\S+)(?:\s+"([^"]*)"|\s+'([^']*)'|\s+\(([^)]*)\))?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return definitions
        }

        let fullRange = NSRange(location: 0, length: attributedString.length)
        let matches = regex.matches(in: attributedString.string, options: [], range: fullRange)
        let fencedRanges = fencedCodeBlockRanges(in: attributedString.string)

        // Iterate in reverse so that removing ranges doesn't shift subsequent indices
        for match in matches.reversed() {
            let matchRange = match.range(at: 0)
            if fencedRanges.contains(where: { NSLocationInRange(matchRange.location, $0) }) {
                continue
            }
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

            // Remove the definition line (including its trailing line terminator, \n or \r\n, if present)
            var removeRange = match.range(at: 0)
            let nsString = attributedString.string as NSString
            let afterMatch = removeRange.location + removeRange.length
            if afterMatch < attributedString.length {
                let nextCharacter = nsString.character(at: afterMatch)
                if nextCharacter == ("\r" as Unicode.Scalar).value,
                   afterMatch + 1 < attributedString.length,
                   nsString.character(at: afterMatch + 1) == ("\n" as Unicode.Scalar).value {
                    removeRange.length += 2
                } else if nextCharacter == ("\n" as Unicode.Scalar).value {
                    removeRange.length += 1
                }
            }
            attributedString.deleteCharacters(in: removeRange)
        }

        return definitions
    }

    // MARK: - Inline Parsing

    func parseInline(_ string: String) -> NSAttributedString {
        let attrs: [CDAttributedStringKey: AnyObject] = [.font: font as AnyObject,
                                                         .foregroundColor: fontColor as AnyObject]
        let result = NSMutableAttributedString(string: string, attributes: attrs)
        let inlineElements: [any CDMarkdownElement] = [
            link, automaticLink,
            bold, italic, strikethrough,
            code, unescaping
        ]
        for element in inlineElements {
            element.parse(result)
        }
        return result
    }

    // MARK: - Accessibility

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

    // MARK: - Image Resolution

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
    func resolveImages(in attributedString: NSMutableAttributedString) async {
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
}
