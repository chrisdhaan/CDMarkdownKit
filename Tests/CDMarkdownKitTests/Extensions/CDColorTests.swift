import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
@testable import CDMarkdownKit

struct CDColorTests {

    // NOTE ON SCOPE: this test does NOT reproduce the original force-unwrap crash
    // that motivated the guards in `CDColor.isEqualTo`. Investigation (see
    // .superpowers/sdd/task-13-report.md) found no documented, non-UB CoreGraphics
    // API that constructs a monochrome CGColor whose `.components` array has fewer
    // than 2 entries: every legitimate construction path (CGColor(gray:alpha:),
    // NSColor(white:/calibratedWhite:/deviceWhite:alpha:).cgColor,
    // CGColorSpaceCreateDeviceGray()/linearGray/genericGrayGamma2_2 fed a correctly
    // sized components array, .copy(alpha:), .converted(to:)) always yields exactly
    // 2 components, because CGColor sizes its storage as
    // colorSpace.numberOfComponents + 1 regardless of caller input. Deliberately
    // passing a too-short array to CGColor(colorSpace:components:) is undefined
    // behavior (a buffer over-read), not a legitimate object state, and even that
    // was observed to still report `.components.count == 2` on this platform, not
    // fewer. So this is a behavioral test of `isEqualTo` for monochrome colors in
    // general — confirming it correctly returns `false` for two colors that are not
    // equal, without crashing — not a regression test forcing the specific guarded
    // branch.
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
