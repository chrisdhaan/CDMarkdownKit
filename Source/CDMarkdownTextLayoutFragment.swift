#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit

    @available(iOS 16.0, tvOS 16.0, *)
    final class CDMarkdownTextLayoutFragment: NSTextLayoutFragment {

        /// One rounded-corner background rectangle computed for a single attribute run within
        /// a laid-out line.
        struct RoundedBackgroundFill: Equatable {
            let rect: CGRect
            let color: UIColor
        }

        /// Shared with the `CDMarkdownTextLayoutDelegate` that created this fragment; see
        /// `CDMarkdownRoundAllCornersBox`. Reading its `.value` live at draw time (rather than
        /// copying a `Bool` onto this fragment at creation time) is what lets a `roundAllCorners`
        /// toggle reach fragments `NSTextLayoutManager` already created and is reusing across an
        /// `invalidateLayout(for:)`.
        var roundAllCornersBox: CDMarkdownRoundAllCornersBox?

        var roundAllCorners: Bool {
            roundAllCornersBox?.value ?? false
        }

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

            let fragmentStart = tcs.offset(from: tcs.documentRange.location, to: rangeInElement.location)

            for fill in Self.roundedBackgroundFills(fragmentRangeStart: fragmentStart,
                                                    textLineFragments: textLineFragments,
                                                    textStorage: textStorage,
                                                    origin: origin) {
                let path = UIBezierPath(roundedRect: fill.rect, cornerRadius: 3)
                context.saveGState()
                fill.color.setFill()
                path.fill()
                context.restoreGState()
            }
        }

        /// Computes the rounded-background fill rectangles for a set of laid-out line
        /// fragments, restricted to the `.cdMarkdownRoundedBackground`-attributed sub-ranges
        /// within each line.
        ///
        /// Pulled out of `drawRoundedBackgrounds` as a pure function (no `CGContext`, no live
        /// `NSTextLayoutManager`) so the geometry math — including the document-absolute
        /// offset translation and the per-run rect narrowing — can be unit tested directly
        /// with real-but-manually-driven `NSTextLineFragment`/`NSTextStorage` instances,
        /// instead of only being exercisable by rendering and diffing pixels.
        ///
        /// - Parameters:
        ///   - fragmentRangeStart: The document-absolute character offset where this text
        ///     layout fragment's range begins. Every paragraph after the first has a non-zero
        ///     offset; using the fragment-local range directly here (instead of translating
        ///     it) was a cross-paragraph bug.
        ///   - textLineFragments: The line fragments belonging to this text layout fragment.
        ///   - textStorage: The document's text storage, used to read
        ///     `.cdMarkdownRoundedBackground` and `.backgroundColor` attributes.
        ///   - origin: The rendering origin the caller is about to draw at.
        static func roundedBackgroundFills(fragmentRangeStart: Int,
                                           textLineFragments: [NSTextLineFragment],
                                           textStorage: NSTextStorage,
                                           origin: CGPoint) -> [RoundedBackgroundFill] {
            var fills: [RoundedBackgroundFill] = []

            for lineFragment in textLineFragments {
                let lineRange = lineFragment.characterRange
                let absoluteLocation = fragmentRangeStart + lineRange.location
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
                    // line with a code span doesn't get painted too.
                    let subrangeInLine = NSRange(location: subrange.location - absoluteLocation,
                                                 length: subrange.length)
                    let lowerBound = lineFragment.locationForCharacter(at: subrangeInLine.location)
                    let upperBound = lineFragment.locationForCharacter(at: NSMaxRange(subrangeInLine))

                    let rect = CGRect(x: min(lowerBound.x, upperBound.x),
                                      y: lineFragment.typographicBounds.minY,
                                      width: abs(upperBound.x - lowerBound.x),
                                      height: lineFragment.typographicBounds.height)
                        .offsetBy(dx: origin.x, dy: origin.y)
                        .insetBy(dx: 0, dy: 1)
                    fills.append(RoundedBackgroundFill(rect: rect, color: backgroundColor))
                }
            }

            return fills
        }
    }
#endif
