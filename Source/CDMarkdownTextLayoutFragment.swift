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

            for lineFragment in textLineFragments {
                let lineRange = lineFragment.characterRange
                textStorage.enumerateAttribute(
                    .cdMarkdownRoundedBackground,
                    in: lineRange,
                    options: []
                ) { value, range, _ in
                    guard value != nil else { return }
                    let backgroundColor = textStorage.attribute(.backgroundColor, at: range.location, effectiveRange: nil) as? UIColor
                        ?? UIColor.codeBackgroundRed()
                    let fillRect = lineFragment.typographicBounds
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
