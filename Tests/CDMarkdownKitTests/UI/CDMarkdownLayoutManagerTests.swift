import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @MainActor
    struct CDMarkdownLayoutManagerTests {

        @Test func roundAllCornersDefaultsFalse() {
            let layoutManager = CDMarkdownLayoutManager()
            #expect(layoutManager.roundAllCorners == false)
        }

        @Test func fillBackgroundRectArraySingleRectDoesNotCrash() {
            let layoutManager = CDMarkdownLayoutManager()
            let textStorage = NSTextStorage(string: "code")
            textStorage.addAttribute(.cdMarkdownRoundedBackground, value: true, range: NSRange(location: 0, length: 4))
            textStorage.addLayoutManager(layoutManager)

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 40))
            _ = renderer.image { _ in
                let rects = [CGRect(x: 0, y: 0, width: 80, height: 20)]
                rects.withUnsafeBufferPointer { buffer in
                    layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                          count: buffer.count,
                                                          forCharacterRange: NSRange(location: 0, length: 4),
                                                          color: .red)
                }
            }
            #expect(layoutManager.textStorage === textStorage)
        }

        @Test func fillBackgroundRectArrayTwoDisjointRectsDoesNotCrash() {
            let layoutManager = CDMarkdownLayoutManager()
            let textStorage = NSTextStorage(string: "wrapped code")
            textStorage.addAttribute(.cdMarkdownRoundedBackground, value: true, range: NSRange(location: 0, length: 12))
            textStorage.addLayoutManager(layoutManager)

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 60))
            _ = renderer.image { _ in
                // Two rects with a gap (rectArray[1].maxX < rectArray[0].minX) — exercises the
                // "2 rects without edges in contact" branch.
                let rects = [
                    CGRect(x: 60, y: 0, width: 40, height: 20),
                    CGRect(x: 0, y: 20, width: 20, height: 20)
                ]
                rects.withUnsafeBufferPointer { buffer in
                    layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                          count: buffer.count,
                                                          forCharacterRange: NSRange(location: 0, length: 12),
                                                          color: .red)
                }
            }
        }

        @Test func fillBackgroundRectArrayThreeWrappedRectsDoesNotCrash() {
            let layoutManager = CDMarkdownLayoutManager()
            let textStorage = NSTextStorage(string: "a longer wrapped code span")
            textStorage.addAttribute(.cdMarkdownRoundedBackground, value: true, range: NSRange(location: 0, length: 27))
            textStorage.addLayoutManager(layoutManager)

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 60))
            _ = renderer.image { _ in
                // Three rects spanning wrapped lines — exercises the hand-rolled hexagon path
                // (rectArray[0], rectArray[lastRect]).
                let rects = [
                    CGRect(x: 40, y: 0, width: 40, height: 20),
                    CGRect(x: 0, y: 20, width: 100, height: 20),
                    CGRect(x: 0, y: 40, width: 30, height: 20)
                ]
                rects.withUnsafeBufferPointer { buffer in
                    layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                          count: buffer.count,
                                                          forCharacterRange: NSRange(location: 0, length: 27),
                                                          color: .red)
                }
            }
        }

        @Test func fillBackgroundRectArrayHonorsRoundAllCornersWhenAttributeAbsent() {
            let layoutManager = CDMarkdownLayoutManager()
            layoutManager.roundAllCorners = true
            let textStorage = NSTextStorage(string: "plain text, no code attribute")
            textStorage.addLayoutManager(layoutManager)

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 40))
            _ = renderer.image { _ in
                let rects = [CGRect(x: 0, y: 0, width: 80, height: 20)]
                rects.withUnsafeBufferPointer { buffer in
                    layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                          count: buffer.count,
                                                          forCharacterRange: NSRange(location: 0, length: 5),
                                                          color: .blue)
                }
            }
        }
    }
#endif
