import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

struct CDColorTests {

    @Test func isEqualToDoesNotCrashOnMonochromeColorWithUnexpectedComponents() {
        // A genuinely monochrome CGColorSpace color constructed with only 1 component
        // (instead of the assumed [white, alpha] pair) should return false, not crash.
        let monochromeSpace = CGColorSpaceCreateDeviceGray()
        guard let oneComponentColor = CGColor(colorSpace: monochromeSpace, components: [0.5]) else {
            Issue.record("failed to construct test fixture CGColor")
            return
        }
        #if os(macOS)
            guard let color = CDColor(cgColor: oneComponentColor) else {
                Issue.record("failed to construct test CDColor from CGColor")
                return
            }
        #else
            let color = CDColor(cgColor: oneComponentColor)
        #endif
        let other = CDColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        #expect(color.isEqualTo(otherColor: other) == false)
    }
}
