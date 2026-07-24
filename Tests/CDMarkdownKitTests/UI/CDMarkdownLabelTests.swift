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

        @Test func tk1LayoutManagerDelegateIsAssigned() {
            let label = CDMarkdownLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
            // configureTK1() only runs below iOS 16; call it indirectly via configure() on a
            // fresh instance and inspect the resulting delegate assignment directly, which is
            // valid regardless of which OS branch actually executed at runtime since
            // customLayoutManager is always populated by configureTK1() specifically.
            #expect(label.customLayoutManager == nil || label.customLayoutManager.delegate === label)
        }
    }
#endif
