#if os(macOS)

    import Cocoa

    /// A macOS `NSLayoutManager` subclass that draws rounded-corner backgrounds for code spans.
    ///
    /// This class mirrors `CDMarkdownLayoutManager` (iOS) but uses `NSBezierPath` and `NSColor`
    /// for AppKit drawing. When `roundAllCorners` is `true` or the character has a
    /// `.cdMarkdownRoundedBackground` attribute, background rectangles are drawn with 3pt rounded corners.
    open class CDMarkdownNSLayoutManager: NSLayoutManager {

        /// When `true`, all background color regions (code blocks, syntax blocks) are drawn with rounded corners.
        /// When `false` (default), backgrounds are drawn as rectangles. Set to `true` for a softer appearance.
        open var roundAllCorners: Bool = false

        override open func fillBackgroundRectArray(_ rectArray: UnsafePointer<NSRect>,
                                                   count rectCount: Int,
                                                   forCharacterRange charRange: NSRange,
                                                   color: NSColor) {
            guard roundAllCorners || hasRoundedAttribute(at: charRange) else {
                super.fillBackgroundRectArray(rectArray, count: rectCount,
                                              forCharacterRange: charRange, color: color)
                return
            }

            color.setFill()
            for i in 0..<rectCount {
                let rect = rectArray[i].insetBy(dx: 0, dy: 1)
                let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
                path.fill()
            }
        }

        private func hasRoundedAttribute(at charRange: NSRange) -> Bool {
            guard charRange.location < (textStorage?.length ?? 0) else { return false }
            return textStorage?.attribute(.cdMarkdownRoundedBackground,
                                           at: charRange.location,
                                           effectiveRange: nil) as? Bool == true
        }
    }

#endif
