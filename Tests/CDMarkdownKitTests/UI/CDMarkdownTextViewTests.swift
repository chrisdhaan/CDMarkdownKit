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
    }
#endif
