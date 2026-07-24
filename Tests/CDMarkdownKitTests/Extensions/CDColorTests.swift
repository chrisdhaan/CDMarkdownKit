import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

struct CDColorTests {

    // Every documented CGColor construction path sizes `.components` as
    // colorSpace.numberOfComponents + 1, so a monochrome color with fewer than 2
    // components isn't reachable here — this exercises `isEqualTo`'s normal
    // monochrome comparison, not the defensive guard itself.
    @Test func isEqualToComparesMonochromeColorsWithoutCrashing() {
        let monochromeSpace = CGColorSpaceCreateDeviceGray()
        guard let grayColor = CGColor(colorSpace: monochromeSpace, components: [0.5, 1.0]) else {
            Issue.record("failed to construct test fixture CGColor")
            return
        }
        #if os(macOS)
            guard let color = CDColor(cgColor: grayColor) else {
                Issue.record("failed to construct test CDColor from CGColor")
                return
            }
        #else
            let color = CDColor(cgColor: grayColor)
        #endif
        let other = CDColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        #expect(color.isEqualTo(otherColor: other) == false)
    }
}
