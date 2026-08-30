//
//  CDMarkdownLabel+TextKitConfiguration.swift
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

#if os(iOS) || os(tvOS) || os(visionOS)

    import UIKit

    extension CDMarkdownLabel {

        /// Internal (not `private`) so tests can force the TextKit 2 configuration path
        /// deterministically via `@testable import`, independent of the automatic
        /// `configure()` call already made during `init`.
        @available(iOS 16.0, tvOS 16.0, *)
        internal func configureTK2() {
            if customTextContainer == nil {
                customTextContainer = NSTextContainer()
                customTextContainer.lineFragmentPadding = 0
                customTextContainer.maximumNumberOfLines = 0
                customTextContainer.lineBreakMode = lineBreakMode
                customTextContainer.size = frame.size
            }

            let contentStorage = NSTextContentStorage()
            let layoutManager = NSTextLayoutManager()
            let delegate = CDMarkdownTextLayoutDelegate()
            delegate.layoutManager = layoutManager
            layoutManager.delegate = delegate
            layoutManager.textContainer = customTextContainer
            contentStorage.addTextLayoutManager(layoutManager)

            tk2Stack = TK2Stack(contentStorage: contentStorage, layoutManager: layoutManager, delegate: delegate)
        }

        /// Enumerates every text layout fragment in `layoutManager`'s document, forcing each
        /// one to complete real layout via `.ensuresLayout`. Internal (not `private`) so tests
        /// can verify this doesn't yield degenerate zero-frame fragments for content taller
        /// than the label's own container (e.g. a fixed-height label with no scroll view) —
        /// a bare `enumerateTextLayoutFragments(options: [])` hands back zero-sized fragments
        /// for content beyond what fits, which still get drawn (at the view's origin) and
        /// corrupt the visible text with overlapping garbage above the real content.
        @available(iOS 16.0, tvOS 16.0, *)
        internal func enumerateTK2Fragments(_ layoutManager: NSTextLayoutManager, _ body: (NSTextLayoutFragment) -> Bool) {
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: [.ensuresLayout], using: body)
        }

        /// Internal (not `private`) so tests can force the TextKit 1 fallback path via
        /// `@testable import` — every CI/local simulator is iOS 16+, so `#available` alone
        /// can never select this branch inside a test.
        internal func configureTK1() {
            customLayoutManager = CDMarkdownLayoutManager()
            customLayoutManager.delegate = self

            if let textContainer = customTextContainer {
                customLayoutManager.addTextContainer(textContainer)
            } else {
                customTextContainer = NSTextContainer()
                customTextContainer.lineFragmentPadding = 0
                customTextContainer.maximumNumberOfLines = 0
                customTextContainer.lineBreakMode = lineBreakMode
                customTextContainer.size = frame.size

                customLayoutManager.addTextContainer(customTextContainer)
            }
        }

        @available(iOS 16.0, tvOS 16.0, *)
        internal func drawTextTK2(in rect: CGRect, layoutManager: NSTextLayoutManager) {
            guard let context = UIGraphicsGetCurrentContext() else { return }

            let glyphsPosition = calculateGlyphsPositionInView()
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            enumerateTK2Fragments(layoutManager) { fragment in
                let fragmentOrigin = CGPoint(
                    x: glyphsPosition.x + fragment.layoutFragmentFrame.origin.x,
                    y: glyphsPosition.y + fragment.layoutFragmentFrame.origin.y
                )
                fragment.draw(at: fragmentOrigin, in: context)
                return true
            }
        }

        internal func drawTextTK1(in rect: CGRect) {
            let glyphRange = customLayoutManager.glyphRange(for: customTextContainer)
            let glyphsPosition = calculateGlyphsPositionInView()
            customLayoutManager.drawBackground(forGlyphRange: glyphRange,
                                               at: glyphsPosition)
            customLayoutManager.drawGlyphs(forGlyphRange: glyphRange,
                                           at: glyphsPosition)
        }

        /// Internal (not `private`) so tests can compute the same view-space offset the
        /// hit-testing and drawing code uses, to build correct input points for `urlRange(at:)`.
        internal func calculateGlyphsPositionInView() -> CGPoint {
            // Returns the XY offset of the range of glyphs from the view's origin
            var textOffset = CGPoint.zero

            if #available(iOS 16.0, tvOS 16.0, *), let tk2 = (tk2Stack as? TK2Stack)?.layoutManager {
                tk2.ensureLayout(for: tk2.documentRange)
                var maxY: CGFloat = 0
                enumerateTK2Fragments(tk2) { fragment in
                    let bottom = fragment.layoutFragmentFrame.maxY
                    if bottom > maxY {
                        maxY = bottom
                    }
                    return true
                }
                let textHeight = ceil(maxY)
                if textHeight < self.bounds.size.height {
                    textOffset.y = (self.bounds.height - textHeight) / 2
                }
            } else {
                var textBounds = self.customLayoutManager.usedRect(for: self.customTextContainer)
                textBounds.size.width = ceil(textBounds.width)
                textBounds.size.height = ceil(textBounds.height)
                if textBounds.size.height < self.bounds.size.height {
                    let paddingHeight = (self.bounds.height - textBounds.size.height) / 2
                    textOffset.y = paddingHeight
                }
            }

            return textOffset
        }
    }

#endif
