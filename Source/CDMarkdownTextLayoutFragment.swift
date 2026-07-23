#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit

    @available(iOS 16.0, tvOS 16.0, *)
    final class CDMarkdownTextLayoutFragment: NSTextLayoutFragment {

        var roundAllCorners: Bool = false

        override func draw(at renderingOrigin: CGPoint, in context: CGContext) {
            if roundAllCorners {
                drawRoundedBackgrounds(at: renderingOrigin, in: context)
            }
            super.draw(at: renderingOrigin, in: context)
        }

        private func drawRoundedBackgrounds(at origin: CGPoint, in context: CGContext) {
            guard let tlm = textLayoutManager,
                  let tcs = tlm.textContentManager as? NSTextContentStorage,
                  let textStorage = tcs.textStorage else { return }

            // rangeInElement is relative to the document origin (it is not optional on
            // NSTextLayoutFragment), but its NSTextLocation representation must still be
            // translated into an absolute integer offset so we can index into the
            // document-wide textStorage. Without this translation, every paragraph after
            // the first looks up attributes at the wrong location.
            let fragmentDocumentRange = rangeInElement
            let fragmentStart = tcs.offset(from: tcs.documentRange.location, to: fragmentDocumentRange.location)

            for lineFragment in textLineFragments {
                let lineRange = lineFragment.characterRange
                let absoluteLocation = fragmentStart + lineRange.location
                let absoluteRange = NSRange(location: absoluteLocation, length: lineRange.length)
                guard absoluteRange.location >= 0,
                      NSMaxRange(absoluteRange) <= textStorage.length else { continue }

                textStorage.enumerateAttribute(
                    .cdMarkdownRoundedBackground,
                    in: absoluteRange,
                    options: []
                ) { value, subrange, _ in
                    guard value != nil else { return }
                    let backgroundColor = textStorage.attribute(.backgroundColor, at: subrange.location, effectiveRange: nil) as? UIColor
                        ?? UIColor.codeBackgroundRed()

                    // Restrict the fill rect to the actual background sub-range within this
                    // line, not the entire line's typographic bounds, so plain text sharing a
                    // line with a code span doesn't get painted too. locationForCharacter(at:)
                    // returns the horizontal position (line-fragment-local coordinates, upstream
                    // glyph edge) of a character index within the line; it is not optional.
                    let subrangeInLine = NSRange(location: subrange.location - absoluteLocation,
                                                 length: subrange.length)
                    let lowerBound = lineFragment.locationForCharacter(at: subrangeInLine.location)
                    let upperBound = lineFragment.locationForCharacter(at: NSMaxRange(subrangeInLine))

                    let fillRect = CGRect(x: min(lowerBound.x, upperBound.x),
                                          y: lineFragment.typographicBounds.minY,
                                          width: abs(upperBound.x - lowerBound.x),
                                          height: lineFragment.typographicBounds.height)
                        .offsetBy(dx: origin.x, dy: origin.y)
                        .insetBy(dx: 0, dy: 1)
                    let path = UIBezierPath(roundedRect: fillRect, cornerRadius: 3)
                    context.saveGState()
                    backgroundColor.setFill()
                    path.fill()
                    context.restoreGState()
                }
            }
        }
    }
#endif
