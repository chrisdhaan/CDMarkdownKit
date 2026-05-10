#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownOrderedList: CDMarkdownElement, CDMarkdownStyle {

    fileprivate static let regex = "^(\\d+\\.)([ \\t]+)(.+)$"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        return CDMarkdownOrderedList.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let style = NSMutableParagraphStyle()
            style.paragraphSpacing = 2
            style.paragraphSpacingBefore = 0
            style.firstLineHeadIndent = 0
            style.lineSpacing = 1.0
            self.paragraphStyle = style
        }
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .anchorsMatchLines)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 4 else { return }

        let fullRange    = match.nsRange(atIndex: 0)  // entire line
        let markerRange  = match.nsRange(atIndex: 1)  // "1."
        let spacerRange  = match.nsRange(atIndex: 2)  // whitespace between marker and text
        let contentRange = match.nsRange(atIndex: 3)  // item text

        // Apply style attributes to the content text
        attributedString.addAttributes(attributes, range: contentRange)

        // Compute headIndent so that wrapped lines align under the first content character.
        // This mirrors the logic in CDMarkdownList.addFullAttributes.
        let markerString = (attributedString.string as NSString).substring(with: markerRange)
        let markerLabel = "\(markerString) "
        let markerWidth = markerLabel.sizeWithAttributes(attributes).width
        let updatedStyle = (paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
        updatedStyle.headIndent = markerWidth
        attributedString.addParagraphStyle(updatedStyle, toRange: fullRange)

        // Normalize whitespace after the marker to a single space.
        // This is done last because replaceCharacters changes the string length,
        // which would invalidate the ranges used above.
        attributedString.replaceCharacters(in: spacerRange, with: " ")
    }
}
