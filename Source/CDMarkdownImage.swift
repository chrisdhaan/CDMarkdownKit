//
//  CDMarkdownImage.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 12/15/16.
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

#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)

    /// Open class: subclasses could add non-Sendable properties, so Sendable cannot be synthesized.
    extension CDMarkdownImage: @unchecked Sendable {}

    /// Renders inline images using `![alt](url)` syntax. Available on iOS, macOS, and tvOS.
    @MainActor
    open class CDMarkdownImage: @preconcurrency CDMarkdownLinkElement {

        fileprivate static let regex = "!\\[([^\\[]*?)\\]\\(([^\\)]*)\\)"

        /// The font associated with the image.
        open var font: CDFont?
        /// The text color for image links.
        open var color: CDColor?
        /// The background color for images.
        open var backgroundColor: CDColor?
        /// The paragraph style for images.
        open var paragraphStyle: NSParagraphStyle?
        /// The preferred size for rendered images.
        open var size: CGSize?
        /// The underline color for image links.
        open var underlineColor: CDColor?
        /// The underline style for image links.
        open var underlineStyle: NSUnderlineStyle?
        /// When true, stores image URLs as attributes for async loading instead of loading synchronously.
        internal var placeholderOnly: Bool = false

        open var regex: String {
            CDMarkdownImage.regex
        }

        open func regularExpression() throws -> NSRegularExpression {
            try NSRegularExpression(pattern: regex,
                                    options: .dotMatchesLineSeparators)
        }

        /// Creates a new image element with optional custom sizing and styling.
        public init(font: CDFont? = nil,
                    color: CDColor? = CDColor.blue,
                    backgroundColor: CDColor? = nil,
                    paragraphStyle: NSParagraphStyle? = nil,
                    size: CGSize? = nil,
                    underlineColor: CDColor? = nil,
                    underlineStyle: NSUnderlineStyle? = nil) {
            self.font = font
            self.color = color
            self.backgroundColor = backgroundColor
            self.paragraphStyle = paragraphStyle
            self.size = size
            self.underlineColor = underlineColor
            self.underlineStyle = underlineStyle
        }

        open func formatText(_ attributedString: NSMutableAttributedString,
                             range: NSRange,
                             link: String) {
            guard let encodedLink = link.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
            else {
                return
            }
            guard let url = URL(string: link) ?? URL(string: encodedLink) else { return }

            attributedString.addLink(url,
                                     toRange: range)
        }

        open func match(_ match: NSTextCheckingResult,
                        attributedString: NSMutableAttributedString) {
            let nsString = attributedString.string as NSString
            let linkStartInResult = nsString.range(of: "(",
                                                   options: .backwards,
                                                   range: match.range).location
            let linkRange = NSRange(location: linkStartInResult,
                                    length: match.range.length + match.range.location - linkStartInResult - 1)
            let linkURLString = nsString.substring(with: NSRange(location: linkRange.location + 1,
                                                                 length: linkRange.length - 1))

            // deleting trailing markdown
            // needs to be called before formattingBlock to support modification of length
            attributedString.deleteCharacters(in: NSRange(location: match.range.location,
                                                          length: linkRange.length + 2))

            if placeholderOnly {
                let placeholderRange = NSRange(location: match.range.location,
                                               length: linkStartInResult - match.range.location - 1)
                if let url = URL(string: linkURLString) {
                    let placeholder = NSMutableAttributedString(string: "\u{FFFC}")
                    placeholder.addAttribute(.cdMarkdownImageURL,
                                             value: url as AnyObject,
                                             range: NSRange(location: 0, length: 1))
                    attributedString.replaceCharacters(in: placeholderRange, with: placeholder)
                }
            } else {
                let textAttachment = NSTextAttachment()
                if let url = URL(string: linkURLString) {
                    let data = try? Data(contentsOf: url)
                    // Try to load image from url
                    if let data,
                       let image = CDImage(data: data) {
                        textAttachment.image = image
                        adjustTextAttachmentSize(textAttachment,
                                                 forImage: image)
                        // Try to load image from local file store
                    } else if let image = CDImage(named: url.path) {
                        textAttachment.image = image
                        adjustTextAttachmentSize(textAttachment,
                                                 forImage: image)
                    }
                }

                // replace text with image
                let textAttachmentAttributedString = NSAttributedString(attachment: textAttachment)
                attributedString.replaceCharacters(in: NSRange(location: match.range.location,
                                                               length: linkStartInResult - match.range.location - 1),
                                                   with: textAttachmentAttributedString)
            }

            let formatRange = NSRange(location: match.range.location,
                                      length: 0)

            formatText(attributedString,
                       range: formatRange,
                       link: linkURLString)
            addAttributes(attributedString,
                          range: formatRange,
                          link: linkURLString)
        }

        open func addAttributes(_ attributedString: NSMutableAttributedString,
                                range: NSRange,
                                link: String) {
            attributedString.addAttributes(attributes,
                                           range: range)
        }

        private func adjustTextAttachmentSize(_ textAttachment: NSTextAttachment,
                                              forImage image: CDImage) {
            guard let size else { return }

            // add padding to image
            let preferredWidth = size.width - 10
            let widthScalingFactor = image.size.width / preferredWidth

            textAttachment.bounds = CGRect(x: 0,
                                           y: 0,
                                           width: image.size.width / widthScalingFactor,
                                           height: image.size.height / widthScalingFactor)
        }
    }

#endif
