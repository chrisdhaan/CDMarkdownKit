//
//  CDMarkdownLinkReference.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 6/2/26.
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

/// Resolves reference-style links of the form `[text][id]` and `[text][]`
/// against a dictionary of definitions populated by `CDMarkdownParser`.
@MainActor
open class CDMarkdownLinkReference: CDMarkdownElement, CDMarkdownStyle {

    /// Matches:
    ///   [display text][reference id]  — full reference
    ///   [display text][]              — collapsed reference (text is the id)
    /// Group 1: display text
    /// Group 2: reference id (may be empty string for collapsed form)
    fileprivate static let regex = "\\[([^\\]]+)\\]\\[([^\\]]*)\\]"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    /// Populated by `CDMarkdownParser` before Phase 2 runs.
    /// Keys are lowercased reference IDs; values are `(url, optional title)`.
    public var references: [String: (url: String, title: String?)] = [:]

    open var regex: String { CDMarkdownLinkReference.regex }

    public init(font: CDFont? = nil,
                color: CDColor? = CDColor.blue,
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

    open func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex, options: [])
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 3 else { return }

        let fullRange = match.range(at: 0)
        let textRange = match.range(at: 1)
        let idRange = match.range(at: 2)

        let nsString = attributedString.string as NSString
        let displayText = nsString.substring(with: textRange)
        let rawId = nsString.substring(with: idRange)
        let lookupKey = (rawId.isEmpty ? displayText : rawId).lowercased()

        guard let definition = references[lookupKey],
              let url = URL(string: definition.url) else { return }

        // Replace the full `[text][id]` span with just the display text
        attributedString.replaceCharacters(in: fullRange, with: displayText)

        let resolvedRange = NSRange(location: fullRange.location,
                                    length: (displayText as NSString).length)

        // Apply standard link styling
        attributedString.addAttributes(attributes, range: resolvedRange)
        attributedString.addAttribute(.link, value: url as AnyObject, range: resolvedRange)

        // Write the optional title if present
        if let title = definition.title {
            attributedString.addAttribute(.cdMarkdownLinkTitle,
                                          value: title as AnyObject,
                                          range: resolvedRange)
        }
    }
}
