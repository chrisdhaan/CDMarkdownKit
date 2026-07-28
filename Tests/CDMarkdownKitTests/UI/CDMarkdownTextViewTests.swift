import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @MainActor
    struct CDMarkdownTextViewTests {

        @Test func secondAttributedTextAssignmentKeepsLayoutManagerAttachedToRealTextStorage() {
            // Build a self-consistent TK1 stack (textStorage -> layoutManager -> textContainer)
            // up front, mirroring the end state that `configureTK1()` produces on a real device
            // running iOS/tvOS 15 -- `UITextView(frame:textContainer:)` requires the container it
            // is given to already belong to a layout manager, so the layout manager and text
            // storage must be wired together before construction.
            let layoutManager = CDMarkdownLayoutManager()
            let textContainer = NSTextContainer(size: CGSize(width: 200, height: 200))
            layoutManager.addTextContainer(textContainer)
            let textStorage = NSTextStorage()
            textStorage.addLayoutManager(layoutManager)

            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 200, height: 200),
                                              textContainer: textContainer,
                                              layoutManager: layoutManager)
            // Force the TK1 configuration path directly, since it's only auto-selected below iOS 16.
            let parser = CDMarkdownParser()
            textView.attributedText = parser.parse("first")
            textView.attributedText = parser.parse("second")

            #expect(textView.textStorage.layoutManagers.contains(where: { $0 === textView.customLayoutManager }))
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func configureTK2SetsTK2Delegate() {
            // A nil textContainer lets UIKit set up its own native TextKit 2 stack. A bare,
            // unattached NSTextContainer() would crash: UIKit's TextKit-1-compatibility
            // layout controller requires the container to already have a layout manager
            // attached before it's handed to UITextView's initializer.
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK2()
            #expect(textView.tk2Delegate is CDMarkdownTextLayoutDelegate)
        }

        @Test func configureTK1AttachesCustomLayoutManagerToTextStorage() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK1()
            #expect(textView.customLayoutManager != nil)
            #expect(textView.textStorage.layoutManagers.contains(where: { $0 === textView.customLayoutManager }))
        }

        @Test func makeTextViewFactoryConfiguresTextView() {
            let textView = CDMarkdownTextView.makeTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            #expect(textView.isScrollEnabled == true)
            #expect(textView.isSelectable == false)
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func roundAllCornersPropagatesToTK2Delegate() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK2()
            textView.roundAllCorners = true

            guard let delegate = textView.tk2Delegate as? CDMarkdownTextLayoutDelegate else {
                Issue.record("expected a CDMarkdownTextLayoutDelegate")
                return
            }
            #expect(delegate.roundAllCorners == true)
        }

        @Test func roundAllCornersPropagatesToTK1LayoutManagerWhenTK2NotConfigured() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK1()
            textView.roundAllCorners = true

            #expect(textView.customLayoutManager.roundAllCorners == true)
        }
    }
#endif
