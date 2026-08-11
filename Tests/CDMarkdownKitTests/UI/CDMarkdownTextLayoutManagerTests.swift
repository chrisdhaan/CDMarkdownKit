import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @MainActor
    struct CDMarkdownTextLayoutManagerTests {

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func delegateSuppliesCustomFragmentType() async {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            label.configureTK2()
            let parser = CDMarkdownParser()
            label.attributedText = await parser.parse("plain `code` text")

            guard let layoutManager = (label.tk2Stack as? CDMarkdownLabel.TK2Stack)?.layoutManager else {
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

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func roundAllCornersPropagatesToNewlyCreatedFragments() async {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            label.configureTK2()
            label.roundAllCorners = true
            let parser = CDMarkdownParser()
            label.attributedText = await parser.parse("plain `code` text")

            guard let layoutManager = (label.tk2Stack as? CDMarkdownLabel.TK2Stack)?.layoutManager else {
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

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func togglingRoundAllCornersAfterInitialLayoutRetroactivelyUpdatesAlreadyCreatedFragments() async {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            label.configureTK2()
            let parser = CDMarkdownParser()
            label.attributedText = await parser.parse("plain `code` text")

            guard let layoutManager = (label.tk2Stack as? CDMarkdownLabel.TK2Stack)?.layoutManager else {
                Issue.record("expected a TextKit 2 layout manager")
                return
            }
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            // CDMarkdownTextLayoutFragment.roundAllCorners reads live from the delegate
            // (mirroring the TK1 CDMarkdownLayoutManager approach) instead of caching a value
            // snapshotted at fragment-creation time, so already-created fragments pick up a
            // post-layout toggle without needing to be recreated.
            label.roundAllCorners = true
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            var sawRoundedFragment = false
            var checkedAtLeastOneFragment = false
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
                if let customFragment = fragment as? CDMarkdownTextLayoutFragment {
                    checkedAtLeastOneFragment = true
                    if customFragment.roundAllCorners {
                        sawRoundedFragment = true
                    }
                }
                return true
            }
            #expect(checkedAtLeastOneFragment)
            #expect(sawRoundedFragment == true)
        }
    }
#endif
