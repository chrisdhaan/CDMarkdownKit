import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownNSMutableAttributedStringExtensionTests {

    @Test func removeBackgroundColorRemovesOnlyBackgroundColorAttribute() {
        let attributedString = NSMutableAttributedString(string: "code span")
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.addBackgroundColor(CDColor.red, toRange: range)
        attributedString.addForegroundColor(CDColor.blue, toRange: range)

        attributedString.removeBackgroundColor(atRange: range)

        let backgroundColor = attributedString.attribute(.backgroundColor, at: 0, effectiveRange: nil)
        #expect(backgroundColor == nil)

        let foregroundColor = attributedString.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? CDColor
        #expect(foregroundColor == CDColor.blue)
    }

    @Test func removeBackgroundColorOnPartialRangeLeavesRestIntact() {
        let attributedString = NSMutableAttributedString(string: "aaaa bbbb")
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addBackgroundColor(CDColor.red, toRange: fullRange)

        let partialRange = NSRange(location: 0, length: 4)
        attributedString.removeBackgroundColor(atRange: partialRange)

        let removedColor = attributedString.attribute(.backgroundColor, at: 0, effectiveRange: nil)
        #expect(removedColor == nil)

        let remainingColor = attributedString.attribute(.backgroundColor, at: 5, effectiveRange: nil) as? CDColor
        #expect(remainingColor == CDColor.red)
    }
}
