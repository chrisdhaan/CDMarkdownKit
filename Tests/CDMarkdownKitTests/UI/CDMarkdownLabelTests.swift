import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @MainActor
    struct CDMarkdownLabelTests {

        @Test func settingAttributedTextToNilDoesNotCrash() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("Hello **world**")
            label.attributedText = nil
            #expect(label.attributedText == nil || label.attributedText?.string.isEmpty == true)
        }

        @Test func configureTK1SetsUpCustomLayoutManagerAndTextContainer() {
            // #available alone can never select the TK1 branch on a modern simulator, so this
            // calls configureTK1() directly (Task 1 made it `internal` for exactly this reason).
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
            label.configureTK1()
            #expect(label.customLayoutManager != nil)
            #expect(label.customLayoutManager.delegate === label)
            #expect(label.customTextContainer != nil)
            #expect(label.customLayoutManager.textContainers.first === label.customTextContainer)
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func configureTK2SetsUpContentStorageLayoutManagerAndDelegate() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
            label.configureTK2()
            #expect(label.tk2ContentStorage is NSTextContentStorage)
            #expect(label.tk2LayoutManager is NSTextLayoutManager)
            #expect(label.tk2LayoutDelegate is CDMarkdownTextLayoutDelegate)
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func urlRangeAtLocationFindsLinkTK2() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
            label.configureTK2()
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("[a link](https://example.com)")

            guard let layoutManager = label.tk2LayoutManager as? NSTextLayoutManager else {
                Issue.record("expected a TextKit 2 layout manager")
                return
            }
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            var firstFragmentFrame: CGRect = .zero
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
                firstFragmentFrame = fragment.layoutFragmentFrame
                return false
            }
            #expect(firstFragmentFrame != .zero)

            let glyphsPosition = label.calculateGlyphsPositionInView()
            let hitPoint = CGPoint(x: glyphsPosition.x + firstFragmentFrame.midX,
                                   y: glyphsPosition.y + firstFragmentFrame.midY)

            #expect(label.urlRange(at: hitPoint)?.url == URL(string: "https://example.com"))
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func urlRangeAtLocationReturnsNilFarOutsideTextTK2() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
            label.configureTK2()
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("[a link](https://example.com)")

            guard let layoutManager = label.tk2LayoutManager as? NSTextLayoutManager else {
                Issue.record("expected a TextKit 2 layout manager")
                return
            }
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            #expect(label.urlRange(at: CGPoint(x: -1000, y: -1000)) == nil)
        }

        @Test func urlRangeAtLocationFindsLinkTK1() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
            // Force the TK1 dispatch branch: urlRange(at:) routes on whether tk2LayoutManager
            // holds an NSTextLayoutManager, while attributedText's setter routes separately on
            // tk2ContentStorage, so both must be cleared before assigning attributedText.
            label.tk2LayoutManager = nil
            label.tk2ContentStorage = nil
            label.tk2LayoutDelegate = nil
            label.configureTK1()
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("[a link](https://example.com)")

            label.customLayoutManager.ensureLayout(for: label.customTextContainer)
            let glyphRange = label.customLayoutManager.glyphRange(for: label.customTextContainer)
            let boundingRect = label.customLayoutManager.boundingRect(forGlyphRange: glyphRange, in: label.customTextContainer)
            #expect(boundingRect != .zero)

            let glyphsPosition = label.calculateGlyphsPositionInView()
            let hitPoint = CGPoint(x: glyphsPosition.x + boundingRect.midX,
                                   y: glyphsPosition.y + boundingRect.midY)

            #expect(label.urlRange(at: hitPoint)?.url == URL(string: "https://example.com"))
        }

        @Test func urlRangeAtLocationReturnsNilOutsideBoundingRectTK1() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
            label.tk2LayoutManager = nil
            label.tk2ContentStorage = nil
            label.tk2LayoutDelegate = nil
            label.configureTK1()
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("[a link](https://example.com)")

            label.customLayoutManager.ensureLayout(for: label.customTextContainer)

            #expect(label.urlRange(at: CGPoint(x: -1000, y: -1000)) == nil)
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func roundAllCornersPropagatesToTK2Delegate() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
            label.configureTK2()
            label.roundAllCorners = true

            guard let delegate = label.tk2LayoutDelegate as? CDMarkdownTextLayoutDelegate else {
                Issue.record("expected a CDMarkdownTextLayoutDelegate")
                return
            }
            #expect(delegate.roundAllCorners == true)
        }

        @Test func roundAllCornersPropagatesToTK1LayoutManagerWhenTK2NotConfigured() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
            // roundAllCorners's didSet routes on whether tk2LayoutDelegate currently holds a
            // CDMarkdownTextLayoutDelegate; clear it so the TK1 branch is exercised even
            // though init() already ran configureTK2() on a modern simulator.
            label.tk2LayoutDelegate = nil
            label.configureTK1()
            label.roundAllCorners = true

            #expect(label.customLayoutManager.roundAllCorners == true)
        }

        @Test func textRectForBoundsReturnsNonZeroForLaidOutText() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("some text to measure")

            let rect = label.textRect(forBounds: label.bounds, limitedToNumberOfLines: 0)
            #expect(rect != .zero)
        }

        @Test func drawTextDoesNotCrashForTK2ConfiguredLabel() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("plain `code` text")

            let renderer = UIGraphicsImageRenderer(bounds: label.bounds)
            _ = renderer.image { _ in
                label.drawText(in: label.bounds)
            }
        }
    }
#endif
