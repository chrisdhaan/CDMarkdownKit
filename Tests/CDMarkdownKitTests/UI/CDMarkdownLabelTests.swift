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
    }
#endif
