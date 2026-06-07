#if os(iOS) || os(tvOS)
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
              let fragmentRange = rangeInElement else { return }

        for lineFragment in textLineFragments {
            guard let lineRange = lineFragment.characterRange else { continue }
            let attrString = tcs.textStorage ?? NSTextStorage()
            attrString.enumerateAttribute(
                .cdMarkdownRoundedBackground,
                in: lineRange,
                options: []
            ) { value, range, _ in
                guard value != nil else { return }
                var fillRect = lineFragment.typographicBounds
                    .offsetBy(dx: origin.x + renderingOrigin.x,
                              dy: origin.y + renderingOrigin.y)
                    .insetBy(dx: 0, dy: 1)
                let path = UIBezierPath(roundedRect: fillRect, cornerRadius: 3)
                context.saveGState()
                UIColor.codeBackgroundRed().setFill()
                path.fill()
                context.restoreGState()
            }
        }
    }
}
#endif
