import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 16.0, tvOS 16.0, *)
    @MainActor
    struct CDMarkdownTextLayoutManagerTests {

        @Test func delegateSuppliesCustomFragmentType() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            label.configureTK2()
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("plain `code` text")

            guard let layoutManager = label.tk2LayoutManager as? NSTextLayoutManager else {
                Issue.record("expected a TextKit 2 layout manager")
                return
            }
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            var sawCustomFragment = false
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
                if fragment is CDMarkdownTextLayoutFragment {
                    sawCustomFragment = true
                }
                return true
            }
            #expect(sawCustomFragment)
        }

        @Test func roundAllCornersPropagatesToNewlyCreatedFragments() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            label.configureTK2()
            label.roundAllCorners = true
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("plain `code` text")

            guard let layoutManager = label.tk2LayoutManager as? NSTextLayoutManager else {
                Issue.record("expected a TextKit 2 layout manager")
                return
            }
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            var checkedAtLeastOneFragment = false
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
                if let customFragment = fragment as? CDMarkdownTextLayoutFragment {
                    #expect(customFragment.roundAllCorners == true)
                    checkedAtLeastOneFragment = true
                }
                return true
            }
            #expect(checkedAtLeastOneFragment)
        }

        @Test func changingRoundAllCornersInvalidatesLayoutAndRecreatesFragments() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            label.configureTK2()
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("plain `code` text")

            guard let layoutManager = label.tk2LayoutManager as? NSTextLayoutManager else {
                Issue.record("expected a TextKit 2 layout manager")
                return
            }
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            // Fragments already exist with roundAllCorners == false. Flipping the flag now
            // must invalidate layout and recreate them with the new value.
            label.roundAllCorners = true
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            var sawRoundedFragment = false
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
                if let customFragment = fragment as? CDMarkdownTextLayoutFragment, customFragment.roundAllCorners {
                    sawRoundedFragment = true
                }
                return true
            }
            #expect(sawRoundedFragment)
        }
    }
#endif
