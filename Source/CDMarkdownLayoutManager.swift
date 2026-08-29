//
//  CDMarkdownLayoutManager.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 12/8/16.
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

    /// Custom layout manager that renders background colors with rounded corners for code and syntax blocks.
    open class CDMarkdownLayoutManager: NSLayoutManager {

        /// When true, all background color regions have rounded corners.
        open var roundAllCorners: Bool = false

        /// Fills background rectangles with optional rounded corners for attributed string ranges.
        override open func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>,
                                                   count rectCount: Int,
                                                   forCharacterRange charRange: NSRange,
                                                   color: UIColor) {
            let cornerRadius = roundedCornerRadius(forCharacterRange: charRange)
            let path = roundedBackgroundPath(rectArray, count: rectCount, cornerRadius: cornerRadius)
            fill(path, color: color, lineWidth: cornerRadius * 2)
        }

        private func roundedCornerRadius(forCharacterRange charRange: NSRange) -> CGFloat {
            let hasRoundedAttribute = self.textStorage?.attribute(
                .cdMarkdownRoundedBackground,
                at: charRange.location,
                effectiveRange: nil
            ) as? Bool == true
            return (hasRoundedAttribute || self.roundAllCorners) ? 3 : 0
        }

        /// `cornerRadius` is also used below as the inset on both axes for `rectArray`, which
        /// spans each full line segment for the character range rather than a single narrowed
        /// glyph run. The TextKit 2 path (see `CDMarkdownTextLayoutFragment.roundedBackgroundFills`)
        /// narrows its rect to the exact glyph-run span before filling, so it only applies a small
        /// vertical inset, not a matching horizontal one. This difference has not been verified
        /// pixel-for-pixel against real iOS 15 (TK1) and iOS 16+ (TK2) simulator renders.
        private func roundedBackgroundPath(_ rectArray: UnsafePointer<CGRect>,
                                           count rectCount: Int,
                                           cornerRadius: CGFloat) -> CGPath {
            let path = CGMutablePath()

            if rectCount == 1 ||
                rectCount == 2 && (rectArray[1].maxX < rectArray[0].minX) {
                // 1 rect or 2 rects without edges in contact
                path.addRect(rectArray[0].insetBy(dx: cornerRadius,
                                                  dy: cornerRadius))
                if rectCount == 2 {
                    path.addRect(rectArray[1].insetBy(dx: cornerRadius,
                                                      dy: cornerRadius))
                }
            } else {
                // 2 or 3 rects
                let lastRect: Int = rectCount - 1

                path.move(to: CGPoint(x: rectArray[0].minX + cornerRadius,
                                      y: rectArray[0].maxY + cornerRadius))

                path.addLine(to: CGPoint(x: rectArray[0].minX + cornerRadius,
                                         y: rectArray[0].minY + cornerRadius))
                path.addLine(to: CGPoint(x: rectArray[0].maxX - cornerRadius,
                                         y: rectArray[0].minY + cornerRadius))

                path.addLine(to: CGPoint(x: rectArray[0].maxX - cornerRadius,
                                         y: rectArray[lastRect].minY - cornerRadius))
                path.addLine(to: CGPoint(x: rectArray[lastRect].maxX - cornerRadius,
                                         y: rectArray[lastRect].minY - cornerRadius))

                path.addLine(to: CGPoint(x: rectArray[lastRect].maxX - cornerRadius,
                                         y: rectArray[lastRect].maxY - cornerRadius))
                path.addLine(to: CGPoint(x: rectArray[lastRect].minX + cornerRadius,
                                         y: rectArray[lastRect].maxY - cornerRadius))

                path.addLine(to: CGPoint(x: rectArray[lastRect].minX + cornerRadius,
                                         y: rectArray[0].maxY + cornerRadius))

                path.closeSubpath()
            }

            return path
        }

        private func fill(_ path: CGPath, color: UIColor, lineWidth: CGFloat) {
            color.set()

            let ctx = UIGraphicsGetCurrentContext()
            ctx?.setAllowsAntialiasing(true)
            ctx?.setShouldAntialias(true)

            ctx?.setLineWidth(lineWidth)
            ctx?.setLineJoin(.round)

            ctx?.addPath(path)

            ctx?.drawPath(using: .fillStroke)
        }
    }

#endif
