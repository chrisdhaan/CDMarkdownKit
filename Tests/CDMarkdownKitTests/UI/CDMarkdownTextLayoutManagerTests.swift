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

        @available(iOS 16.0, tvOS 16.0, *)
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

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func togglingRoundAllCornersAfterInitialLayoutDoesNotRetroactivelyUpdateAlreadyCreatedFragments() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            label.configureTK2()
            let parser = CDMarkdownParser()
            label.attributedText = parser.parse("plain `code` text")

            guard let layoutManager = label.tk2LayoutManager as? NSTextLayoutManager else {
                Issue.record("expected a TextKit 2 layout manager")
                return
            }
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            // KNOWN LIMITATION: flipping roundAllCorners after text is already laid out
            // calls invalidateLayout(for:), but
            // NSTextLayoutManager does not re-invoke the delegate's fragment factory for
            // unchanged content -- it reuses the already-created NSTextLayoutFragment
            // instances, and CDMarkdownTextLayoutFragment.roundAllCorners is a plain stored
            // property set only once at creation time. Verified empirically against the real
            // TextKit 2 API: creationCount does not increase after invalidateLayout + a second
            // ensureLayout call. Set roundAllCorners before assigning attributedText to avoid
            // this -- fragments created after the flag is set do pick it up correctly (see
            // roundAllCornersPropagatesToNewlyCreatedFragments above).
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
            #expect(sawRoundedFragment == false)
        }
    }
#endif
